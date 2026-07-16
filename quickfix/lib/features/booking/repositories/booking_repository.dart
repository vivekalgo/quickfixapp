abstract class BookingRepository {
  Future<Map<String, dynamic>> createBooking(Map<String, dynamic> bookingData);
  Future<Map<String, dynamic>> createQuickBooking(Map<String, dynamic> bookingData);
  Future<Map<String, dynamic>> calculateCheckout(Map<String, dynamic> checkoutData);
  Future<List<Map<String, dynamic>>> getOffers();
  Future<Map<String, dynamic>> applyOffer(String code);
  Future<Map<String, dynamic>> getBookingLedger(String bookingId);
  Future<Map<String, dynamic>> getBookingReceipt(String bookingId);
}
