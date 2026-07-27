import 'package:quickfix/core/network/dio_client.dart';
import 'package:quickfix/core/network/api_response_validator.dart';
import 'package:quickfix/core/storage/hive_service.dart';

class NotificationsRemoteDataSource {
  final DioClient _client;

  NotificationsRemoteDataSource(this._client);

  Future<List<Map<String, dynamic>>> getNotifications() async {
    try {
      final response = await _client.get('/notifications');
      final list = ApiResponseValidator.requireList(
        response.data,
        context: 'getNotifications',
      );
      final res = list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      await HiveService.saveDataCache('user_notifications', res);
      return res;
    } catch (e) {
      final cached = HiveService.getDataCache('user_notifications');
      if (cached != null && cached is List) {
        return cached.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
      rethrow;
    }
  }
}

