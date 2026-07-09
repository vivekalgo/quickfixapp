import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/network_providers.dart';
import '../../../../core/database/hive_service.dart';
import '../../data/sources/auth_remote_data_source.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../data/repositories/auth_repository_impl.dart';

class AuthState {
  final bool isAuthenticated;
  final Map<String, dynamic>? user;
  final bool isLoading;
  final String? error;

  AuthState({
    required this.isAuthenticated,
    this.user,
    this.isLoading = false,
    this.error,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    Map<String, dynamic>? user,
    bool? isLoading,
    String? error,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;

  AuthNotifier(this._repository) : super(AuthState(isAuthenticated: false, isLoading: true)) {
    checkSession();
  }

  Future<void> checkSession() async {
    final token = HiveService.getAuthToken();
    if (token == null) {
      state = AuthState(isAuthenticated: false, isLoading: false);
      return;
    }

    final cached = HiveService.getCachedProfile();
    if (cached != null) {
      state = AuthState(isAuthenticated: true, user: cached, isLoading: false);
      _refreshProfileSilently();
    } else {
      try {
        state = AuthState(isAuthenticated: false, isLoading: true);
        final profile = await _repository.fetchUserProfile();
        await HiveService.saveCachedProfile(profile);
        state = AuthState(isAuthenticated: true, user: profile, isLoading: false);
      } catch (e) {
        if (HiveService.getAuthToken() == null) {
          state = AuthState(isAuthenticated: false, isLoading: false);
        } else {
          // Offline mode: minimal fallback with NO hardcoded fake data
          state = AuthState(
            isAuthenticated: true,
            isLoading: false,
            error: 'Offline mode: Could not load latest profile.',
            user: {
              'phone': 'Unknown',
              'name': '',
              'email': '',
              'membership': 'basic',
              'walletBalance': 0.0,
              'savedAddresses': <dynamic>[],
              'avatarUrl': '',
              'isPhoneVerified': true,
              'accountStatus': 'active',
              'referralCode': '',
              'referralCount': 0,
              'referralRewardsEarned': 0,
            }
          );
        }
      }
    }
  }

  Future<void> _refreshProfileSilently() async {
    try {
      final profile = await _repository.fetchUserProfile();
      await HiveService.saveCachedProfile(profile);
      state = AuthState(isAuthenticated: true, user: profile, isLoading: false);
    } catch (e) {
      if (HiveService.getAuthToken() == null) {
        state = AuthState(isAuthenticated: false, isLoading: false);
      }
      // Silently keep cached state on network error
    }
  }

  Future<void> login(String phone, String code, {String? firebaseToken}) async {
    state = AuthState(isAuthenticated: false, isLoading: true);
    try {
      await _repository.verifyCode(phone, code, firebaseToken: firebaseToken);
      final profile = await _repository.fetchUserProfile();
      await HiveService.saveCachedProfile(profile);
      state = AuthState(isAuthenticated: true, user: profile, isLoading: false);
    } catch (e) {
      state = AuthState(isAuthenticated: false, isLoading: false, error: e.toString());
      rethrow;
    }
  }

  Future<void> updateProfile(Map<String, dynamic> updateData) async {
    state = state.copyWith(isLoading: true);
    try {
      final updatedProfile = await _repository.updateUserProfile(updateData);
      await HiveService.saveCachedProfile(updatedProfile);
      state = AuthState(isAuthenticated: true, user: updatedProfile, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  Future<String> uploadAvatar(String base64Image, String mimeType) async {
    state = state.copyWith(isLoading: true);
    try {
      final avatarUrl = await _repository.uploadAvatar(base64Image, mimeType);
      if (state.user != null) {
        final updatedUser = Map<String, dynamic>.from(state.user!);
        updatedUser['avatarUrl'] = avatarUrl;
        await HiveService.saveCachedProfile(updatedUser);
        state = AuthState(isAuthenticated: true, user: updatedUser, isLoading: false);
      } else {
        state = state.copyWith(isLoading: false);
      }
      return avatarUrl;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  Future<void> addMoney(double amount) async {
    state = state.copyWith(isLoading: true);
    try {
      final res = await _repository.addMoneyToWallet(amount);
      if (state.user != null) {
        final updatedUser = Map<String, dynamic>.from(state.user!);
        updatedUser['walletBalance'] = res['walletBalance'];
        updatedUser['walletTransactions'] = res['walletTransactions'];
        await HiveService.saveCachedProfile(updatedUser);
        state = AuthState(isAuthenticated: true, user: updatedUser, isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  Future<void> deleteAccount() async {
    state = state.copyWith(isLoading: true);
    try {
      await _repository.deleteAccount();
      await HiveService.clearAuthToken();
      await HiveService.clearCachedProfile();
      state = AuthState(isAuthenticated: false, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  Future<void> logout() async {
    state = AuthState(isAuthenticated: false, isLoading: true);
    await HiveService.clearAuthToken();
    await HiveService.clearCachedProfile();
    state = AuthState(isAuthenticated: false, isLoading: false);
  }
}

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  final client = ref.watch(dioClientProvider);
  return AuthRemoteDataSource(client);
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final remote = ref.watch(authRemoteDataSourceProvider);
  return AuthRepositoryImpl(remote);
});

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return AuthNotifier(repo);
});

// Profile Future Provider (reactive fallback wrapper for screen compatibility)
final userProfileProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final auth = ref.watch(authProvider);
  if (auth.user != null) {
    return auth.user!;
  }
  final repository = ref.watch(authRepositoryProvider);
  return repository.fetchUserProfile();
});
