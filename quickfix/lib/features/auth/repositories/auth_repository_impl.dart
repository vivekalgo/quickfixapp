import 'package:quickfix/features/auth/repositories/auth_repository.dart';
import 'package:quickfix/features/auth/datasources/auth_remote_data_source.dart';
import 'package:quickfix/core/storage/hive_service.dart';
import 'package:quickfix/core/storage/secure_token_manager.dart';

/// Implementation of [AuthRepository] managing user security, credentials, and profile operations.
/// 
/// Interacts with [AuthRemoteDataSource] to query the remote REST server,
/// and delegates authentication caching to [SecureTokenManager] and [HiveService].
class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;

  AuthRepositoryImpl(this._remoteDataSource);

  @override
  Future<void> requestOtp(String phone) async {
    await _remoteDataSource.sendOtp(phone);
  }

  @override
  Future<String> verifyCode(
    String phone,
    String code, {
    String? firebaseToken,
  }) async {
    final data = await _remoteDataSource.verifyOtp(
      phone,
      code,
      firebaseToken: firebaseToken,
    );
    final token = data['token']?.toString();
    if (token == null || token.isEmpty) {
      throw Exception('Verification failed: Token was not returned by server');
    }
    // Cache authorization token in SecureTokenManager (memory) + Hive (encrypted disk)
    await SecureTokenManager.saveToken(
      token,
      persistCallback: HiveService.saveAuthToken,
    );
    return token;
  }

  @override
  Future<Map<String, dynamic>> fetchUserProfile() async {
    return await _remoteDataSource.getProfile();
  }

  @override
  Future<Map<String, dynamic>> updateUserProfile(
    Map<String, dynamic> updateData,
  ) async {
    final response = await _remoteDataSource.updateProfile(updateData);
    final profile = response['profile'] as Map<String, dynamic>?;
    if (profile == null) {
      throw Exception("Profile update failed: Invalid response format");
    }
    return profile;
  }

  @override
  Future<Map<String, dynamic>> addMoneyToWallet(double amount) async {
    return await _remoteDataSource.addMoney(amount);
  }

  @override
  Future<String> uploadAvatar(String base64Image, String mimeType) async {
    return await _remoteDataSource.uploadAvatar(base64Image, mimeType);
  }

  @override
  Future<Map<String, dynamic>> getReferralInfo() async {
    return await _remoteDataSource.getReferralInfo();
  }

  @override
  Future<void> applyReferralCode(String code) async {
    await _remoteDataSource.applyReferralCode(code);
  }

  @override
  Future<void> deleteAccount() async {
    await _remoteDataSource.deleteAccount();
  }
}
