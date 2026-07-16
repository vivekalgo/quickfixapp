import 'package:dio/dio.dart';
import 'package:quickfix_provider/core/network/api_endpoints.dart';
import 'package:quickfix_provider/core/network/dio_client.dart';

abstract class AuthRemoteDataSource {
  Future<Response> login(String shopId, String password);
  Future<Response> changePassword(String oldPassword, String newPassword);
  Future<Response> updateShopDetails(Map<String, dynamic> data);
  Future<Response> getProfile();
  Future<Response> uploadShopBanner(String base64Image, String mimeType);
  Future<Response> uploadPortfolioImage(String base64Image, String mimeType);
  Future<Response> deletePortfolioImage(String imageUrl);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final DioClient _dioClient;

  AuthRemoteDataSourceImpl(this._dioClient);

  @override
  Future<Response> login(String shopId, String password) {
    return _dioClient.post(
      ApiEndpoints.login,
      data: {'shopId': shopId, 'password': password},
    );
  }

  @override
  Future<Response> changePassword(String oldPassword, String newPassword) {
    return _dioClient.post(
      ApiEndpoints.changePassword,
      data: {'oldPassword': oldPassword, 'newPassword': newPassword},
    );
  }

  @override
  Future<Response> updateShopDetails(Map<String, dynamic> data) {
    return _dioClient.post(
      ApiEndpoints.updateHours,
      data: data,
    );
  }

  @override
  Future<Response> getProfile() {
    return _dioClient.get('/provider/profile');
  }

  @override
  Future<Response> uploadShopBanner(String base64Image, String mimeType) {
    return _dioClient.post(
      '/provider/upload-banner',
      data: {'base64Image': base64Image, 'mimeType': mimeType},
    );
  }

  @override
  Future<Response> uploadPortfolioImage(String base64Image, String mimeType) {
    return _dioClient.post(
      '/provider/upload-portfolio',
      data: {'base64Image': base64Image, 'mimeType': mimeType},
    );
  }

  @override
  Future<Response> deletePortfolioImage(String imageUrl) {
    return _dioClient.post(
      '/provider/delete-portfolio',
      data: {'imageUrl': imageUrl},
    );
  }
}
