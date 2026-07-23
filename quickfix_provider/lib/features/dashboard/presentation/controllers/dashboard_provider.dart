import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quickfix_provider/features/auth/presentation/controllers/auth_provider.dart';
import 'package:quickfix_provider/features/dashboard/models/dashboard_stats_model.dart';
import 'package:quickfix_provider/features/dashboard/repositories/dashboard_repository_impl.dart';
import 'package:quickfix_provider/core/network/error_handler.dart';

/// Represents the state of the partner dashboard analytics and toggle status.
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

/// Controller responsible for loading provider dashboard KPIs (bookings, revenue, ratings)
/// and toggling active online/offline dispatch status.
class DashboardNotifier extends StateNotifier<DashboardState> {
  final Ref _ref;

  DashboardNotifier(this._ref)
    : super(DashboardState(stats: DashboardStatsModel.empty())) {
    fetchStats();
  }

  Future<void> fetchStats() async {
    final shop = _ref.read(authProvider).shop;
    if (shop == null) return;

    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final repository = _ref.read(dashboardRepositoryProvider);
      final stats = await repository.fetchStats(shop.id);

      if (stats != null) {
        state = DashboardState(
          isLoading: false,
          stats: stats,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Failed to parse dashboard stats',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: ErrorHandler.handle(e).message,
      );
    }
  }

  Future<bool> toggleOnlineStatus(bool isOnline) async {
    try {
      final repository = _ref.read(dashboardRepositoryProvider);
      final success = await repository.toggleOnlineStatus(isOnline);

      if (success) {
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

final dashboardProvider =
    StateNotifierProvider<DashboardNotifier, DashboardState>((ref) {
      return DashboardNotifier(ref);
    });
