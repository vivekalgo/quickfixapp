abstract class ProfileRepository {
  Future<String?> reverseGeocode(double lat, double lng);
  Future<List<Map<String, dynamic>>> getOffers();
  Future<List<Map<String, dynamic>>> getBookings(String customerId);
  Future<void> cancelBooking(String orderId);
  Future<void> submitReview(Map<String, dynamic> reviewData);
  Future<Map<String, dynamic>> getReferralInfo();
}
