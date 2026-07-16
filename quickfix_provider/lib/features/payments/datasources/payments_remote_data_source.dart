import 'package:dio/dio.dart';
import 'package:quickfix_provider/core/network/api_endpoints.dart';
import 'package:quickfix_provider/core/network/dio_client.dart';

abstract class PaymentsRemoteDataSource {
  Future<Response> fetchEarnings(String shopId);
  Future<Response> fetchPaymentDashboard(String shopId);
  Future<Response> fetchSettlementHistory(String shopId);
  Future<Response> fetchLedger(String shopId);
  Future<Response> requestSettlementWithdrawal({
    required String shopId,
    required double amount,
  });
  Future<Response> confirmCashCollected(String bookingId);
}

class PaymentsRemoteDataSourceImpl implements PaymentsRemoteDataSource {
  final DioClient _dioClient;

  PaymentsRemoteDataSourceImpl(this._dioClient);

  @override
  Future<Response> fetchEarnings(String shopId) {
    return _dioClient.get(ApiEndpoints.earnings(shopId));
  }

  @override
  Future<Response> fetchPaymentDashboard(String shopId) {
    return _dioClient.get(ApiEndpoints.paymentDashboard(shopId));
  }

  @override
  Future<Response> fetchSettlementHistory(String shopId) {
    return _dioClient.get(ApiEndpoints.providerSettlements(shopId));
  }

  @override
  Future<Response> fetchLedger(String shopId) {
    return _dioClient.get(ApiEndpoints.providerLedger(shopId));
  }

  @override
  Future<Response> requestSettlementWithdrawal({
    required String shopId,
    required double amount,
  }) {
    return _dioClient.post(
      ApiEndpoints.requestSettlement,
      data: {
        'shopId': shopId,
        'amount': amount,
        'settlementType': 'manual',
      },
    );
  }

  @override
  Future<Response> confirmCashCollected(String bookingId) {
    return _dioClient.post(ApiEndpoints.cashConfirm(bookingId));
  }
}
