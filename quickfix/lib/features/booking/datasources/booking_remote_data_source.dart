import 'package:quickfix/core/network/dio_client.dart';
import 'package:quickfix/core/network/api_response_validator.dart';

class BookingRemoteDataSource {
  final DioClient _client;

  BookingRemoteDataSource(this._client);

  Future<Map<String, dynamic>> createBooking(Map<String, dynamic> bookingData) async {
    final response = await _client.post('/bookings', data: bookingData);
    return ApiResponseValidator.requireMap(
      response.data,
      context: 'createBooking',
    );
  }

  Future<Map<String, dynamic>> createQuickBooking(Map<String, dynamic> bookingData) async {
    final response = await _client.post('/bookings/create', data: bookingData);
    return ApiResponseValidator.requireMap(
      response.data,
      context: 'createQuickBooking',
    );
  }

  Future<Map<String, dynamic>> calculateCheckout(Map<String, dynamic> checkoutData) async {
    final response = await _client.post('/checkout/calculate', data: checkoutData);
    return ApiResponseValidator.requireMap(
      response.data,
      context: 'calculateCheckout',
    );
  }

  Future<List<Map<String, dynamic>>> getOffers() async {
    final response = await _client.get('/offers');
    final list = ApiResponseValidator.requireList(
      response.data,
      context: 'getOffers',
    );
    return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<Map<String, dynamic>> applyOffer(String code) async {
    final response = await _client.post('/offers/apply', data: {'code': code});
    return ApiResponseValidator.requireMap(
      response.data,
      context: 'applyOffer',
    );
  }

  Future<Map<String, dynamic>> getBookingLedger(String bookingId) async {
    final response = await _client.get('/payments/ledger/$bookingId');
    return ApiResponseValidator.requireMap(
      response.data,
      context: 'getBookingLedger',
    );
  }

  Future<Map<String, dynamic>> getBookingReceipt(String bookingId) async {
    final response = await _client.get('/bookings/receipt/$bookingId');
    return ApiResponseValidator.requireMap(
      response.data,
      context: 'getBookingReceipt',
    );
  }
}
