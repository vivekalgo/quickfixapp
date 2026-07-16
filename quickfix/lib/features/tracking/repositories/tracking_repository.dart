abstract class TrackingRepository {
  Future<Map<String, dynamic>> getBookingDetails(String bookingId);
  Future<Map<String, dynamic>> respondToQuotation({
    required String bookingId,
    required String responseType,
    String? comment,
  });
}
