import 'package:quickfix_provider/features/dashboard/models/dashboard_stats_model.dart';

abstract class DashboardRepository {
  Future<DashboardStatsModel?> fetchStats(String shopId);
  Future<bool> toggleOnlineStatus(bool isOnline);
}
