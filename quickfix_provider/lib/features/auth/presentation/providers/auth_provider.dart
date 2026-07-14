import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quickfix_provider/core/network/api_endpoints.dart';
import 'package:quickfix_provider/core/network/network_providers.dart';
import 'package:quickfix_provider/core/storage/hive_service.dart';
import 'package:quickfix_provider/features/auth/data/models/shop_model.dart';
import 'package:quickfix_provider/core/services/notification_service.dart';

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

        // Request permissions and sync FCM token with backend
        NotificationService.requestPermissions().then((_) async {
          final fcmToken = await NotificationService.getToken();
          if (fcmToken != null) {
            await NotificationService.syncTokenWithBackend(fcmToken);
          }
        });

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
    String? estimatedServiceTime,
    String? priceRange,
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
      if (estimatedServiceTime != null) dataToSend['estimatedServiceTime'] = estimatedServiceTime;
      if (priceRange != null) dataToSend['priceRange'] = priceRange;

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
      final response = await dio.get('/provider/profile');
      if (response.data != null && response.data['success'] == true) {
        final shopJson = response.data['shop'] as Map<String, dynamic>;
        final updatedShop = ShopModel.fromJson(shopJson);
        await HiveService.saveShopProfile(updatedShop.toJson());
        state = state.copyWith(shop: updatedShop);
      }
    } catch (e) {
      print('Refresh profile error: $e');
    }
  }

  Future<bool> uploadShopBanner(String base64Image, String mimeType) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final dio = _ref.read(dioClientProvider);
      final response = await dio.post(
        '/provider/upload-banner',
        data: {
          'base64Image': base64Image,
          'mimeType': mimeType,
        },
      );

      if (response.data != null && response.data['success'] == true) {
        final newImagePath = response.data['imagePath']?.toString() ?? '';
        if (state.shop != null && newImagePath.isNotEmpty) {
          final updatedShopJson = state.shop!.toJson();
          updatedShopJson['imagePath'] = newImagePath;
          final updatedShop = ShopModel.fromJson(updatedShopJson);
          await HiveService.saveShopProfile(updatedShop.toJson());
          state = state.copyWith(isLoading: false, shop: updatedShop);
          return true;
        }
      }
      state = state.copyWith(isLoading: false, errorMessage: 'Failed to upload shop banner.');
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> uploadPortfolioImage(String base64Image, String mimeType) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final dio = _ref.read(dioClientProvider);
      final response = await dio.post(
        '/provider/upload-portfolio',
        data: {
          'base64Image': base64Image,
          'mimeType': mimeType,
        },
      );

      if (response.data != null && response.data['success'] == true) {
        final newImages = List<String>.from(response.data['portfolioImages'] as List);
        if (state.shop != null) {
          final updatedShopJson = state.shop!.toJson();
          updatedShopJson['portfolioImages'] = newImages;
          final updatedShop = ShopModel.fromJson(updatedShopJson);
          await HiveService.saveShopProfile(updatedShop.toJson());
          state = state.copyWith(isLoading: false, shop: updatedShop);
          return true;
        }
      }
      state = state.copyWith(isLoading: false, errorMessage: 'Failed to upload portfolio image.');
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> deletePortfolioImage(String imageUrl) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final dio = _ref.read(dioClientProvider);
      final response = await dio.post(
        '/provider/delete-portfolio',
        data: {
          'imageUrl': imageUrl,
        },
      );

      if (response.data != null && response.data['success'] == true) {
        final newImages = List<String>.from(response.data['portfolioImages'] as List);
        if (state.shop != null) {
          final updatedShopJson = state.shop!.toJson();
          updatedShopJson['portfolioImages'] = newImages;
          final updatedShop = ShopModel.fromJson(updatedShopJson);
          await HiveService.saveShopProfile(updatedShop.toJson());
          state = state.copyWith(isLoading: false, shop: updatedShop);
          return true;
        }
      }
      state = state.copyWith(isLoading: false, errorMessage: 'Failed to delete portfolio image.');
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
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
