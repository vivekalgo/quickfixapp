import 'package:dio/dio.dart';
import 'package:quickfix_provider/core/network/api_endpoints.dart';
import 'package:quickfix_provider/core/network/dio_client.dart';

abstract class ShopRemoteDataSource {
  Future<Response> updateServices(Map<String, dynamic> data);
  Future<Response> uploadServiceImage(String base64Image, String mimeType);
}

class ShopRemoteDataSourceImpl implements ShopRemoteDataSource {
  final DioClient _dioClient;

  ShopRemoteDataSourceImpl(this._dioClient);

  @override
  Future<Response> updateServices(Map<String, dynamic> data) {
    return _dioClient.post(
      ApiEndpoints.updateServices,
      data: data,
    );
  }

  @override
  Future<Response> uploadServiceImage(String base64Image, String mimeType) {
    return _dioClient.post(
      ApiEndpoints.uploadServiceImage,
      data: {'base64Image': base64Image, 'mimeType': mimeType},
    );
  }
}
