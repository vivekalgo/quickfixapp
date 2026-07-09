abstract class BookingRepository {
  Future<double> getCouponDiscount(String code, double orderAmount);
  Future<String> placeOrder({
    required List<Map<String, dynamic>> items,
    required DateTime date,
    required String slot,
    required String address,
    required String paymentMethod,
    required double totalAmount,
    String? couponCode,
  });
}
