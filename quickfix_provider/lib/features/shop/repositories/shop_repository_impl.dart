import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quickfix_provider/core/network/network_providers.dart';
import 'package:quickfix_provider/features/shop/datasources/shop_remote_data_source.dart';
import 'package:quickfix_provider/features/shop/repositories/shop_repository.dart';

class ShopRepositoryImpl implements ShopRepository {
  final ShopRemoteDataSource _remoteDataSource;

  ShopRepositoryImpl(this._remoteDataSource);

  @override
  Future<bool> updateServices(Map<String, dynamic> data) async {
    final response = await _remoteDataSource.updateServices(data);
    if (response.data != null && response.data['success'] == true) {
      return true;
    }
    return false;
  }

  @override
  Future<String?> uploadServiceImage(String base64Image, String mimeType) async {
    final response = await _remoteDataSource.uploadServiceImage(base64Image, mimeType);
    if (response.data != null && response.data['success'] == true) {
      return response.data['imageUrl']?.toString();
    }
    return null;
  }
}

final shopRemoteDataSourceProvider = Provider<ShopRemoteDataSource>((ref) {
  return ShopRemoteDataSourceImpl(ref.watch(dioClientProvider));
});

final shopRepositoryProvider = Provider<ShopRepository>((ref) {
  return ShopRepositoryImpl(ref.watch(shopRemoteDataSourceProvider));
});
