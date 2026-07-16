import 'package:quickfix/core/network/dio_client.dart';
import 'package:quickfix/core/network/api_response_validator.dart';

class NotificationsRemoteDataSource {
  final DioClient _client;

  NotificationsRemoteDataSource(this._client);

  Future<List<Map<String, dynamic>>> getNotifications() async {
    final response = await _client.get('/notifications');
    final list = ApiResponseValidator.requireList(
      response.data,
      context: 'getNotifications',
    );
    return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }
}
