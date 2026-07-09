import '../../../../core/network/dio_client.dart';
import '../../../../core/network/api_endpoints.dart';

class BookingRemoteDataSource {
  final DioClient _client;

  BookingRemoteDataSource(this._client);

  Future<Map<String, dynamic>> validateCoupon(String code, double orderAmount) async {
    final response = await _client.post(
      ApiEndpoints.validateCoupon,
      data: {
        'code': code,
        'amount': orderAmount,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> createBooking({
    required List<Map<String, dynamic>> items,
    required String date,
    required String slot,
    required String address,
    required String paymentMethod,
    required double totalAmount,
    String? couponCode,
  }) async {
    final response = await _client.post(
      ApiEndpoints.createBooking,
      data: {
        'items': items,
        'date': date,
        'slot': slot,
        'address': address,
        'paymentMethod': paymentMethod,
        'totalAmount': totalAmount,
        'couponCode': couponCode,
      },
    );
    return response.data as Map<String, dynamic>;
  }
}
