import 'package:dio/dio.dart';
import 'package:quickfix_provider/core/network/api_endpoints.dart';
import 'package:quickfix_provider/core/network/dio_client.dart';

abstract class DashboardRemoteDataSource {
  Future<Response> fetchStats(String shopId);
  Future<Response> toggleOnlineStatus(bool isOnline);
}

class DashboardRemoteDataSourceImpl implements DashboardRemoteDataSource {
  final DioClient _dioClient;

  DashboardRemoteDataSourceImpl(this._dioClient);

  @override
  Future<Response> fetchStats(String shopId) {
    return _dioClient.get(ApiEndpoints.dashboard(shopId));
  }

  @override
  Future<Response> toggleOnlineStatus(bool isOnline) {
    return _dioClient.post(
      ApiEndpoints.toggleOnline,
      data: {'isOnline': isOnline},
    );
  }
}
