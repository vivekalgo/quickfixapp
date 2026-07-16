import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quickfix_provider/features/auth/presentation/controllers/auth_provider.dart';
import 'package:quickfix_provider/features/payments/repositories/payments_repository_impl.dart';

// ─── State Model ─────────────────────────────────────────────────────────────

class PaymentsState {
  final bool isLoading;
  final String? errorMessage;

  // Wallet
  final double walletBalance;
  final double commissionRate;
  final List<dynamic> transactions;

  // Payment Dashboard (from new API)
  final double todayEarnings;
  final double todayCash;
  final double todayOnline;
  final double todayCommission;
  final double totalEarnings;
  final double totalCommission;
  final double commissionDue;
  final int cashJobsCount;
  final int onlineJobsCount;

  // Settlements
  final double pendingSettlementAmount;
  final int pendingSettlementCount;
  final double totalSettled;
  final int completedSettlementCount;
  final List<dynamic> settlementHistory;

  // Ledger
  final List<dynamic> ledgerEntries;

  // Flags
  final bool hasDashboardData;

  PaymentsState({
    this.isLoading = false,
    this.errorMessage,
    this.walletBalance = 0.0,
    this.commissionRate = 20.0,
    this.transactions = const [],
    this.todayEarnings = 0.0,
    this.todayCash = 0.0,
    this.todayOnline = 0.0,
    this.todayCommission = 0.0,
    this.totalEarnings = 0.0,
    this.totalCommission = 0.0,
    this.commissionDue = 0.0,
    this.cashJobsCount = 0,
    this.onlineJobsCount = 0,
    this.pendingSettlementAmount = 0.0,
    this.pendingSettlementCount = 0,
    this.totalSettled = 0.0,
    this.completedSettlementCount = 0,
    this.settlementHistory = const [],
    this.ledgerEntries = const [],
    this.hasDashboardData = false,
  });

  PaymentsState copyWith({
    bool? isLoading,
    String? errorMessage,
    double? walletBalance,
    double? commissionRate,
    List<dynamic>? transactions,
    double? todayEarnings,
    double? todayCash,
    double? todayOnline,
    double? todayCommission,
    double? totalEarnings,
    double? totalCommission,
    double? commissionDue,
    int? cashJobsCount,
    int? onlineJobsCount,
    double? pendingSettlementAmount,
    int? pendingSettlementCount,
    double? totalSettled,
    int? completedSettlementCount,
    List<dynamic>? settlementHistory,
    List<dynamic>? ledgerEntries,
    bool? hasDashboardData,
  }) {
    return PaymentsState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      walletBalance: walletBalance ?? this.walletBalance,
      commissionRate: commissionRate ?? this.commissionRate,
      transactions: transactions ?? this.transactions,
      todayEarnings: todayEarnings ?? this.todayEarnings,
      todayCash: todayCash ?? this.todayCash,
      todayOnline: todayOnline ?? this.todayOnline,
      todayCommission: todayCommission ?? this.todayCommission,
      totalEarnings: totalEarnings ?? this.totalEarnings,
      totalCommission: totalCommission ?? this.totalCommission,
      commissionDue: commissionDue ?? this.commissionDue,
      cashJobsCount: cashJobsCount ?? this.cashJobsCount,
      onlineJobsCount: onlineJobsCount ?? this.onlineJobsCount,
      pendingSettlementAmount:
          pendingSettlementAmount ?? this.pendingSettlementAmount,
      pendingSettlementCount:
          pendingSettlementCount ?? this.pendingSettlementCount,
      totalSettled: totalSettled ?? this.totalSettled,
      completedSettlementCount:
          completedSettlementCount ?? this.completedSettlementCount,
      settlementHistory: settlementHistory ?? this.settlementHistory,
      ledgerEntries: ledgerEntries ?? this.ledgerEntries,
      hasDashboardData: hasDashboardData ?? this.hasDashboardData,
    );
  }
}

// ─── Notifier ────────────────────────────────────────────────────────────────

class PaymentsNotifier extends StateNotifier<PaymentsState> {
  final Ref _ref;

  PaymentsNotifier(this._ref) : super(PaymentsState()) {
    fetchEarnings();
  }

  /// Fetches basic earnings
  Future<void> fetchEarnings() async {
    final shop = _ref.read(authProvider).shop;
    if (shop == null) return;

    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final repository = _ref.read(paymentsRepositoryProvider);
      final data = await repository.fetchEarnings(shop.id);

      if (data != null) {
        state = state.copyWith(
          isLoading: false,
          walletBalance: (data['walletBalance'] as num?)?.toDouble() ?? 0.0,
          commissionRate: (data['commissionRate'] as num?)?.toDouble() ?? 20.0,
          transactions: data['walletTransactions'] as List? ?? [],
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Failed to load earnings info',
        );
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }

    // Also fetch the enhanced payment dashboard
    await fetchPaymentDashboard();
  }

  /// Fetches the full payment dashboard from new API
  Future<void> fetchPaymentDashboard() async {
    final shop = _ref.read(authProvider).shop;
    if (shop == null) return;

    try {
      final repository = _ref.read(paymentsRepositoryProvider);
      final data = await repository.fetchPaymentDashboard(shop.id);
      if (data == null) return;

      final today = data['today'] as Map<String, dynamic>? ?? {};
      final overall = data['overall'] as Map<String, dynamic>? ?? {};
      final settlement = data['settlement'] as Map<String, dynamic>? ?? {};

      state = state.copyWith(
        walletBalance:
            (data['walletBalance'] as num?)?.toDouble() ?? state.walletBalance,
        commissionRate:
            (data['commissionRate'] as num?)?.toDouble() ??
            state.commissionRate,
        todayEarnings: (today['totalEarnings'] as num?)?.toDouble() ?? 0.0,
        todayCash: (today['cashCollected'] as num?)?.toDouble() ?? 0.0,
        todayOnline: (today['onlineEarnings'] as num?)?.toDouble() ?? 0.0,
        todayCommission:
            (today['commissionDeducted'] as num?)?.toDouble() ?? 0.0,
        totalEarnings: (overall['totalEarnings'] as num?)?.toDouble() ?? 0.0,
        totalCommission:
            (overall['totalCommission'] as num?)?.toDouble() ?? 0.0,
        commissionDue: (overall['commissionDue'] as num?)?.toDouble() ?? 0.0,
        cashJobsCount: (overall['cashJobsCount'] as num?)?.toInt() ?? 0,
        onlineJobsCount: (overall['onlineJobsCount'] as num?)?.toInt() ?? 0,
        pendingSettlementAmount:
            (settlement['pendingAmount'] as num?)?.toDouble() ?? 0.0,
        pendingSettlementCount:
            (settlement['pendingCount'] as num?)?.toInt() ?? 0,
        totalSettled: (settlement['totalSettled'] as num?)?.toDouble() ?? 0.0,
        completedSettlementCount:
            (settlement['completedCount'] as num?)?.toInt() ?? 0,
        hasDashboardData: true,
      );
    } catch (e) {
      debugPrint('Payment dashboard fetch failed: $e');
    }
  }

  /// Fetches settlement history for the provider
  Future<void> fetchSettlementHistory() async {
    final shop = _ref.read(authProvider).shop;
    if (shop == null) return;

    try {
      final repository = _ref.read(paymentsRepositoryProvider);
      final settlements = await repository.fetchSettlementHistory(shop.id);
      if (settlements != null) {
        state = state.copyWith(settlementHistory: settlements);
      }
    } catch (e) {
      debugPrint('Settlement history fetch failed: $e');
    }
  }

  /// Fetches payment ledger for the provider
  Future<void> fetchLedger() async {
    final shop = _ref.read(authProvider).shop;
    if (shop == null) return;

    try {
      final repository = _ref.read(paymentsRepositoryProvider);
      final ledgers = await repository.fetchLedger(shop.id);
      if (ledgers != null) {
        state = state.copyWith(ledgerEntries: ledgers);
      }
    } catch (e) {
      debugPrint('Ledger fetch failed: $e');
    }
  }

  /// Requests a settlement via new API
  Future<bool> requestSettlementWithdrawal(double amount) async {
    final shop = _ref.read(authProvider).shop;
    if (shop == null) return false;

    if (amount <= 0 || amount > state.walletBalance) {
      state = state.copyWith(errorMessage: 'Invalid withdrawal amount entered');
      return false;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final repository = _ref.read(paymentsRepositoryProvider);
      final data = await repository.requestSettlementWithdrawal(
        shopId: shop.id,
        amount: amount,
      );
      if (data != null && data['success'] == true) {
        await fetchEarnings();
        await fetchSettlementHistory();
        return true;
      }
      state = state.copyWith(
        isLoading: false,
        errorMessage: data?['error'] ?? 'Settlement request failed.',
      );
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  /// Provider confirms cash collected for a booking
  Future<bool> confirmCashCollected(String bookingId) async {
    try {
      final repository = _ref.read(paymentsRepositoryProvider);
      final success = await repository.confirmCashCollected(bookingId);
      if (success) {
        await fetchLedger();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Cash confirm failed: $e');
      return false;
    }
  }
}

// ─── Provider ────────────────────────────────────────────────────────────────

final paymentsProvider = StateNotifierProvider<PaymentsNotifier, PaymentsState>(
  (ref) {
    return PaymentsNotifier(ref);
  },
);
