import 'package:quickfix/core/network/dio_client.dart';
import 'package:quickfix/core/network/api_response_validator.dart';

class TrackingRemoteDataSource {
  final DioClient _client;

  TrackingRemoteDataSource(this._client);

  Future<Map<String, dynamic>> getBookingDetails(String bookingId) async {
    final response = await _client.get('/bookings/details/$bookingId');
    return ApiResponseValidator.requireMap(
      response.data,
      context: 'getBookingDetails',
    );
  }

  Future<Map<String, dynamic>> respondToQuotation({
    required String bookingId,
    required String responseType,
    String? comment,
  }) async {
    final response = await _client.post(
      '/bookings/$bookingId/quotation/respond',
      data: {'response': responseType, 'comment': comment ?? ''},
    );
    return ApiResponseValidator.requireMap(
      response.data,
      context: 'respondToQuotation',
    );
  }
}
