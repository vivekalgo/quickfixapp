import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quickfix_provider/core/network/network_providers.dart';
import 'package:quickfix_provider/core/storage/hive_service.dart';
import 'package:quickfix_provider/features/auth/datasources/auth_remote_data_source.dart';
import 'package:quickfix_provider/features/auth/models/shop_model.dart';
import 'package:quickfix_provider/features/auth/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;

  AuthRepositoryImpl(this._remoteDataSource);

  @override
  Future<ShopModel?> login(String shopId, String password) async {
    final response = await _remoteDataSource.login(shopId, password);
    final data = response.data;
    if (data != null && data['success'] == true) {
      final token = data['token'].toString();
      final shopJson = data['shop'] as Map<String, dynamic>;
      final shop = ShopModel.fromJson(shopJson);

      await HiveService.saveAuthToken(token);
      await HiveService.saveShopProfile(shop.toJson());
      return shop;
    }
    return null;
  }

  @override
  Future<bool> changePassword(String oldPassword, String newPassword) async {
    final response = await _remoteDataSource.changePassword(oldPassword, newPassword);
    if (response.data != null && response.data['success'] == true) {
      return true;
    }
    return false;
  }

  @override
  Future<ShopModel?> updateShopDetails(Map<String, dynamic> data) async {
    final response = await _remoteDataSource.updateShopDetails(data);
    if (response.data != null && response.data['success'] == true) {
      final shopJson = response.data['shop'] as Map<String, dynamic>;
      final shop = ShopModel.fromJson(shopJson);
      await HiveService.saveShopProfile(shop.toJson());
      return shop;
    }
    return null;
  }

  @override
  Future<ShopModel?> getProfile() async {
    final response = await _remoteDataSource.getProfile();
    if (response.data != null && response.data['success'] == true) {
      final shopJson = response.data['shop'] as Map<String, dynamic>;
      final shop = ShopModel.fromJson(shopJson);
      await HiveService.saveShopProfile(shop.toJson());
      return shop;
    }
    return null;
  }

  @override
  Future<String?> uploadShopBanner(String base64Image, String mimeType) async {
    final response = await _remoteDataSource.uploadShopBanner(base64Image, mimeType);
    if (response.data != null && response.data['success'] == true) {
      final newImagePath = response.data['imagePath']?.toString() ?? '';
      return newImagePath;
    }
    return null;
  }

  @override
  Future<List<String>?> uploadPortfolioImage(String base64Image, String mimeType) async {
    final response = await _remoteDataSource.uploadPortfolioImage(base64Image, mimeType);
    if (response.data != null && response.data['success'] == true) {
      return List<String>.from(response.data['portfolioImages'] as List);
    }
    return null;
  }

  @override
  Future<List<String>?> deletePortfolioImage(String imageUrl) async {
    final response = await _remoteDataSource.deletePortfolioImage(imageUrl);
    if (response.data != null && response.data['success'] == true) {
      return List<String>.from(response.data['portfolioImages'] as List);
    }
    return null;
  }
}

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  return AuthRemoteDataSourceImpl(ref.watch(dioClientProvider));
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(ref.watch(authRemoteDataSourceProvider));
});
