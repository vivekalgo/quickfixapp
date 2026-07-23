import 'package:quickfix/core/network/dio_client.dart';
import 'package:quickfix/core/network/api_response_validator.dart';
import 'package:dio/dio.dart';

class ProfileRemoteDataSource {
  final DioClient _client;

  ProfileRemoteDataSource(this._client);

  Future<String?> reverseGeocode(double lat, double lng) async {
    final dio = Dio();
    dio.options.headers['User-Agent'] = 'QuickFixApp/1.0';
    final response = await dio.get(
      'https://nominatim.openstreetmap.org/reverse',
      queryParameters: {
        'lat': lat,
        'lon': lng,
        'format': 'json',
        'addressdetails': 1,
      },
    );
    if (response.statusCode == 200 && response.data != null) {
      return response.data['display_name'] as String?;
    }
    return null;
  }

  Future<List<Map<String, dynamic>>> getOffers() async {
    try {
      final response = await _client.get('/offers');
      final list = ApiResponseValidator.requireList(
        response.data,
        context: 'getOffers',
      );
      return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (_) {
      return [
        {
          'id': 'off-quick20',
          'code': 'QUICK20',
          'title': 'Get 20% Instant Discount',
          'description': 'Save 20% on all repair and cleaning services above ₹499.',
          'minOrderAmount': 499,
          'maxDiscount': 200,
          'isActive': true,
          'expiryDate': '2026-12-31'
        },
        {
          'id': 'off-first15',
          'code': 'FIRST15',
          'title': 'Flat 15% Welcome Offer',
          'description': 'Exclusive 15% discount for your first service booking.',
          'minOrderAmount': 299,
          'maxDiscount': 150,
          'isActive': true,
          'expiryDate': '2026-12-31'
        },
        {
          'id': 'off-festive100',
          'code': 'FESTIVE100',
          'title': 'Flat ₹100 Off',
          'description': 'Get ₹100 instant cashback on orders above ₹799.',
          'minOrderAmount': 799,
          'maxDiscount': 100,
          'isActive': true,
          'expiryDate': '2026-12-31'
        }
      ];
    }
  }

  Future<List<Map<String, dynamic>>> getBookings(String customerId) async {
    final response = await _client.get(
      '/bookings',
      queryParameters: {if (customerId.isNotEmpty) 'customerId': customerId},
    );
    final list = ApiResponseValidator.requireList(
      response.data,
      context: 'getBookings',
    );
    return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<void> cancelBooking(String orderId) async {
    await _client.post(
      '/bookings/cancel',
      data: {'id': orderId},
    );
  }

  Future<void> submitReview(Map<String, dynamic> reviewData) async {
    await _client.post(
      '/reviews',
      data: reviewData,
    );
  }

  Future<Map<String, dynamic>> getReferralInfo() async {
    final response = await _client.get('/auth/referral');
    return ApiResponseValidator.requireMap(
      response.data,
      context: 'getReferralInfo',
    );
  }
}
