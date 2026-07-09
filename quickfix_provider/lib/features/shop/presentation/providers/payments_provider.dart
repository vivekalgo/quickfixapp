import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/network_providers.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class PaymentsState {
  final bool isLoading;
  final String? errorMessage;
  final double walletBalance;
  final double commissionRate;
  final List<dynamic> transactions;

  PaymentsState({
    this.isLoading = false,
    this.errorMessage,
    this.walletBalance = 0.0,
    this.commissionRate = 15.0,
    this.transactions = const [],
  });

  PaymentsState copyWith({
    bool? isLoading,
    String? errorMessage,
    double? walletBalance,
    double? commissionRate,
    List<dynamic>? transactions,
  }) {
    return PaymentsState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      walletBalance: walletBalance ?? this.walletBalance,
      commissionRate: commissionRate ?? this.commissionRate,
      transactions: transactions ?? this.transactions,
    );
  }
}

class PaymentsNotifier extends StateNotifier<PaymentsState> {
  final Ref _ref;

  PaymentsNotifier(this._ref) : super(PaymentsState()) {
    fetchEarnings();
  }

  Future<void> fetchEarnings() async {
    final shop = _ref.read(authProvider).shop;
    if (shop == null) return;

    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final dio = _ref.read(dioClientProvider);
      final response = await dio.get(ApiEndpoints.earnings(shop.id));
      
      final data = response.data;
      if (data != null) {
        state = PaymentsState(
          isLoading: false,
          walletBalance: (data['walletBalance'] as num?)?.toDouble() ?? 0.0,
          commissionRate: (data['commissionRate'] as num?)?.toDouble() ?? 15.0,
          transactions: data['walletTransactions'] as List? ?? [],
        );
      } else {
        state = state.copyWith(isLoading: false, errorMessage: 'Failed to load earnings info');
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<bool> requestSettlementWithdrawal(double amount) async {
    final shop = _ref.read(authProvider).shop;
    if (shop == null) return false;

    if (amount <= 0 || amount > state.walletBalance) {
      state = state.copyWith(errorMessage: 'Invalid withdrawal amount entered');
      return false;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final dio = _ref.read(dioClientProvider);
      
      // We simulate a withdrawal transaction in the shop profile
      // Deduct from wallet and append to transactions array
      final updatedTxList = List<Map<String, dynamic>>.from(
        shop.toJson()['walletTransactions'] as List? ?? []
      );
      
      updatedTxList.add({
        'id': 'TX-SETTLE-${DateTime.now().millisecondsSinceEpoch}',
        'title': 'Wallet Settlement Payout Request',
        'amount': amount,
        'type': 'debit',
        'date': DateTime.now().toIso8601String(),
        'status': 'pending'
      });

      final newBalance = (shop.walletBalance) - amount;

      final success = await _ref.read(authProvider.notifier).updateShopDetails(
        walletBalance: newBalance,
        walletTransactions: updatedTxList
      );

      if (success) {
        await fetchEarnings();
        return true;
      }
      state = state.copyWith(isLoading: false, errorMessage: 'Settlement request failed.');
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }
}

final paymentsProvider = StateNotifierProvider<PaymentsNotifier, PaymentsState>((ref) {
  return PaymentsNotifier(ref);
});
