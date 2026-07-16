import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quickfix_provider/core/network/network_providers.dart';
import 'package:quickfix_provider/features/payments/datasources/payments_remote_data_source.dart';
import 'package:quickfix_provider/features/payments/repositories/payments_repository.dart';

class PaymentsRepositoryImpl implements PaymentsRepository {
  final PaymentsRemoteDataSource _remoteDataSource;

  PaymentsRepositoryImpl(this._remoteDataSource);

  @override
  Future<Map<String, dynamic>?> fetchEarnings(String shopId) async {
    final response = await _remoteDataSource.fetchEarnings(shopId);
    if (response.data != null) {
      return response.data as Map<String, dynamic>;
    }
    return null;
  }

  @override
  Future<Map<String, dynamic>?> fetchPaymentDashboard(String shopId) async {
    final response = await _remoteDataSource.fetchPaymentDashboard(shopId);
    if (response.data != null) {
      return response.data as Map<String, dynamic>;
    }
    return null;
  }

  @override
  Future<List<dynamic>?> fetchSettlementHistory(String shopId) async {
    final response = await _remoteDataSource.fetchSettlementHistory(shopId);
    if (response.data != null && response.data['settlements'] != null) {
      return response.data['settlements'] as List;
    }
    return null;
  }

  @override
  Future<List<dynamic>?> fetchLedger(String shopId) async {
    final response = await _remoteDataSource.fetchLedger(shopId);
    if (response.data != null && response.data['ledgers'] != null) {
      return response.data['ledgers'] as List;
    }
    return null;
  }

  @override
  Future<Map<String, dynamic>?> requestSettlementWithdrawal({
    required String shopId,
    required double amount,
  }) async {
    final response = await _remoteDataSource.requestSettlementWithdrawal(
      shopId: shopId,
      amount: amount,
    );
    if (response.data != null) {
      return response.data as Map<String, dynamic>;
    }
    return null;
  }

  @override
  Future<bool> confirmCashCollected(String bookingId) async {
    final response = await _remoteDataSource.confirmCashCollected(bookingId);
    if (response.data != null && response.data['success'] == true) {
      return true;
    }
    return false;
  }
}

final paymentsRemoteDataSourceProvider = Provider<PaymentsRemoteDataSource>((ref) {
  return PaymentsRemoteDataSourceImpl(ref.watch(dioClientProvider));
});

final paymentsRepositoryProvider = Provider<PaymentsRepository>((ref) {
  return PaymentsRepositoryImpl(ref.watch(paymentsRemoteDataSourceProvider));
});
