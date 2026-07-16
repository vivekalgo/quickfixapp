import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quickfix_provider/core/network/network_providers.dart';
import 'package:quickfix_provider/features/dashboard/datasources/dashboard_remote_data_source.dart';
import 'package:quickfix_provider/features/dashboard/models/dashboard_stats_model.dart';
import 'package:quickfix_provider/features/dashboard/repositories/dashboard_repository.dart';

class DashboardRepositoryImpl implements DashboardRepository {
  final DashboardRemoteDataSource _remoteDataSource;

  DashboardRepositoryImpl(this._remoteDataSource);

  @override
  Future<DashboardStatsModel?> fetchStats(String shopId) async {
    final response = await _remoteDataSource.fetchStats(shopId);
    if (response.data != null) {
      return DashboardStatsModel.fromJson(response.data as Map<String, dynamic>);
    }
    return null;
  }

  @override
  Future<bool> toggleOnlineStatus(bool isOnline) async {
    final response = await _remoteDataSource.toggleOnlineStatus(isOnline);
    if (response.data != null && response.data['success'] == true) {
      return true;
    }
    return false;
  }
}

final dashboardRemoteDataSourceProvider = Provider<DashboardRemoteDataSource>((ref) {
  return DashboardRemoteDataSourceImpl(ref.watch(dioClientProvider));
});

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepositoryImpl(ref.watch(dashboardRemoteDataSourceProvider));
});
