import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quickfix_provider/core/network/api_endpoints.dart';
import 'package:quickfix_provider/core/network/network_providers.dart';
import 'package:quickfix_provider/core/storage/hive_service.dart';
import 'package:quickfix_provider/features/auth/data/models/shop_model.dart';

class AuthState {
  final bool isLoading;
  final String? errorMessage;
  final ShopModel? shop;
  final bool isAuthenticated;

  AuthState({
    this.isLoading = false,
    this.errorMessage,
    this.shop,
    this.isAuthenticated = false,
  });

  AuthState copyWith({
    bool? isLoading,
    String? errorMessage,
    ShopModel? shop,
    bool? isAuthenticated,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      shop: shop ?? this.shop,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final Ref _ref;

  AuthNotifier(this._ref) : super(AuthState()) {
    checkSession();
  }

  void checkSession() {
    final token = HiveService.getAuthToken();
    final cachedProfile = HiveService.getShopProfile();
    if (token != null && cachedProfile != null) {
      state = AuthState(
        isAuthenticated: true,
        shop: ShopModel.fromJson(cachedProfile),
      );
    }
  }

  Future<bool> login(String shopId, String password) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final dio = _ref.read(dioClientProvider);
      final response = await dio.post(
        ApiEndpoints.login,
        data: {
          'shopId': shopId,
          'password': password,
        },
      );

      final data = response.data;
      if (data != null && data['success'] == true) {
        final token = data['token'].toString();
        final shopJson = data['shop'] as Map<String, dynamic>;
        final shop = ShopModel.fromJson(shopJson);

        await HiveService.saveAuthToken(token);
        await HiveService.saveShopProfile(shop.toJson());

        state = AuthState(
          isAuthenticated: true,
          shop: shop,
        );
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Login failed. Please check credentials.',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  Future<bool> changePassword(String oldPassword, String newPassword) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final dio = _ref.read(dioClientProvider);
      final response = await dio.post(
        ApiEndpoints.changePassword,
        data: {
          'oldPassword': oldPassword,
          'newPassword': newPassword,
        },
      );

      if (response.data != null && response.data['success'] == true) {
        // Password changed, update local shop cache to set isFirstLogin = false
        if (state.shop != null) {
          final updatedShopJson = state.shop!.toJson();
          updatedShopJson['isFirstLogin'] = false;
          final updatedShop = ShopModel.fromJson(updatedShopJson);
          await HiveService.saveShopProfile(updatedShop.toJson());
          state = state.copyWith(isLoading: false, shop: updatedShop);
        } else {
          state = state.copyWith(isLoading: false);
        }
        return true;
      }
      state = state.copyWith(isLoading: false, errorMessage: 'Failed to update password.');
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> updateShopDetails({
    Map<String, dynamic>? workingHours,
    List<String>? holidays,
    double? serviceRadius,
    double? visitingCharges,
    bool? emergencyAvailable,
    String? gst,
    String? pan,
    String? bankAccountNumber,
    String? ifscCode,
    String? upiId,
    bool? isFirstLogin,
    double? walletBalance,
    List<dynamic>? walletTransactions,
    String? ownerPhone,
    String? ownerEmail,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final dio = _ref.read(dioClientProvider);
      
      final dataToSend = <String, dynamic>{};
      if (workingHours != null) dataToSend['workingHours'] = workingHours;
      if (holidays != null) dataToSend['holidays'] = holidays;
      if (serviceRadius != null) dataToSend['serviceRadius'] = serviceRadius;
      if (visitingCharges != null) dataToSend['visitingCharges'] = visitingCharges;
      if (emergencyAvailable != null) dataToSend['emergencyAvailable'] = emergencyAvailable;
      if (gst != null) dataToSend['gst'] = gst;
      if (pan != null) dataToSend['pan'] = pan;
      if (bankAccountNumber != null) dataToSend['bankAccountNumber'] = bankAccountNumber;
      if (ifscCode != null) dataToSend['ifscCode'] = ifscCode;
      if (upiId != null) dataToSend['upiId'] = upiId;
      if (isFirstLogin != null) dataToSend['isFirstLogin'] = isFirstLogin;
      if (walletBalance != null) dataToSend['walletBalance'] = walletBalance;
      if (walletTransactions != null) dataToSend['walletTransactions'] = walletTransactions;
      if (ownerPhone != null) dataToSend['ownerPhone'] = ownerPhone;
      if (ownerEmail != null) dataToSend['ownerEmail'] = ownerEmail;

      // We call the update hours endpoint which updates general details
      final response = await dio.post(ApiEndpoints.updateHours, data: dataToSend);

      if (response.data != null && response.data['success'] == true) {
        final shopJson = response.data['shop'] as Map<String, dynamic>;
        final shop = ShopModel.fromJson(shopJson);
        await HiveService.saveShopProfile(shop.toJson());
        state = state.copyWith(isLoading: false, shop: shop);
        return true;
      }
      state = state.copyWith(isLoading: false, errorMessage: 'Failed to update shop details.');
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<void> refreshProfile() async {
    if (state.shop == null) return;
    try {
      final dio = _ref.read(dioClientProvider);
      // Fetch shop details via get nearbies query using shopDisplayId or phone
      final response = await dio.get('/shops');
      if (response.data is List) {
        final list = response.data as List;
        final matched = list.firstWhere(
          (element) => element['id'] == state.shop!.id,
          orElse: () => null,
        );
        if (matched != null) {
          final updatedShop = ShopModel.fromJson(matched);
          await HiveService.saveShopProfile(updatedShop.toJson());
          state = state.copyWith(shop: updatedShop);
        }
      }
    } catch (e) {
      print('Refresh profile error: $e');
    }
  }

  Future<void> logout() async {
    await HiveService.clearSession();
    state = AuthState();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref);
});
