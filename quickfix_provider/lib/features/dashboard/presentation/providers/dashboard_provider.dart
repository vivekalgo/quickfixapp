import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quickfix_provider/core/network/api_endpoints.dart';
import 'package:quickfix_provider/core/network/network_providers.dart';
import 'package:quickfix_provider/features/auth/presentation/providers/auth_provider.dart';
import 'package:quickfix_provider/features/dashboard/data/models/dashboard_stats_model.dart';

class DashboardState {
  final bool isLoading;
  final String? errorMessage;
  final DashboardStatsModel stats;

  DashboardState({
    this.isLoading = false,
    this.errorMessage,
    required this.stats,
  });

  DashboardState copyWith({
    bool? isLoading,
    String? errorMessage,
    DashboardStatsModel? stats,
  }) {
    return DashboardState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      stats: stats ?? this.stats,
    );
  }
}

class DashboardNotifier extends StateNotifier<DashboardState> {
  final Ref _ref;

  DashboardNotifier(this._ref) : super(DashboardState(stats: DashboardStatsModel.empty())) {
    fetchStats();
  }

  Future<void> fetchStats() async {
    final shop = _ref.read(authProvider).shop;
    if (shop == null) return;

    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final dio = _ref.read(dioClientProvider);
      final response = await dio.get(ApiEndpoints.dashboard(shop.id));
      
      final data = response.data;
      if (data != null) {
        state = DashboardState(
          isLoading: false,
          stats: DashboardStatsModel.fromJson(data),
        );
      } else {
        state = state.copyWith(isLoading: false, errorMessage: 'Failed to parse dashboard stats');
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<bool> toggleOnlineStatus(bool isOnline) async {
    try {
      final dio = _ref.read(dioClientProvider);
      final response = await dio.post(
        ApiEndpoints.toggleOnline,
        data: {'isOnline': isOnline},
      );
      if (response.data != null && response.data['success'] == true) {
        // Update stats model locally
        final updatedStats = DashboardStatsModel(
          todayOrders: state.stats.todayOrders,
          pendingOrders: state.stats.pendingOrders,
          acceptedOrders: state.stats.acceptedOrders,
          completedOrders: state.stats.completedOrders,
          cancelledOrders: state.stats.cancelledOrders,
          revenue: state.stats.revenue,
          totalRevenue: state.stats.totalRevenue,
          walletBalance: state.stats.walletBalance,
          rating: state.stats.rating,
          reviewsCount: state.stats.reviewsCount,
          isOnline: isOnline,
        );
        state = state.copyWith(stats: updatedStats);
        
        // Also refresh auth profile cache
        await _ref.read(authProvider.notifier).refreshProfile();
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }
}

final dashboardProvider = StateNotifierProvider<DashboardNotifier, DashboardState>((ref) {
  return DashboardNotifier(ref);
});
