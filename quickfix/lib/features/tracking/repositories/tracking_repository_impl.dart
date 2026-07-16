import 'package:quickfix/features/tracking/datasources/tracking_remote_data_source.dart';
import 'package:quickfix/features/tracking/repositories/tracking_repository.dart';

class TrackingRepositoryImpl implements TrackingRepository {
  final TrackingRemoteDataSource _remoteDataSource;

  TrackingRepositoryImpl(this._remoteDataSource);

  @override
  Future<Map<String, dynamic>> getBookingDetails(String bookingId) {
    return _remoteDataSource.getBookingDetails(bookingId);
  }

  @override
  Future<Map<String, dynamic>> respondToQuotation({
    required String bookingId,
    required String responseType,
    String? comment,
  }) {
    return _remoteDataSource.respondToQuotation(
      bookingId: bookingId,
      responseType: responseType,
      comment: comment,
    );
  }
}
