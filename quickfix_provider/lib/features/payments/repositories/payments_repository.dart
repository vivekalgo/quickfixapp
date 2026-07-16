abstract class PaymentsRepository {
  Future<Map<String, dynamic>?> fetchEarnings(String shopId);
  Future<Map<String, dynamic>?> fetchPaymentDashboard(String shopId);
  Future<List<dynamic>?> fetchSettlementHistory(String shopId);
  Future<List<dynamic>?> fetchLedger(String shopId);
  Future<Map<String, dynamic>?> requestSettlementWithdrawal({
    required String shopId,
    required double amount,
  });
  Future<bool> confirmCashCollected(String bookingId);
}
