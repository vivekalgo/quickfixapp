import 'package:quickfix/features/booking/datasources/booking_remote_data_source.dart';
import 'package:quickfix/features/booking/repositories/booking_repository.dart';

class BookingRepositoryImpl implements BookingRepository {
  final BookingRemoteDataSource _remoteDataSource;

  BookingRepositoryImpl(this._remoteDataSource);

  @override
  Future<Map<String, dynamic>> createBooking(Map<String, dynamic> bookingData) {
    return _remoteDataSource.createBooking(bookingData);
  }

  @override
  Future<Map<String, dynamic>> createQuickBooking(Map<String, dynamic> bookingData) {
    return _remoteDataSource.createQuickBooking(bookingData);
  }

  @override
  Future<Map<String, dynamic>> calculateCheckout(Map<String, dynamic> checkoutData) {
    return _remoteDataSource.calculateCheckout(checkoutData);
  }

  @override
  Future<List<Map<String, dynamic>>> getOffers() {
    return _remoteDataSource.getOffers();
  }

  @override
  Future<Map<String, dynamic>> applyOffer(String code) {
    return _remoteDataSource.applyOffer(code);
  }

  @override
  Future<Map<String, dynamic>> getBookingLedger(String bookingId) {
    return _remoteDataSource.getBookingLedger(bookingId);
  }

  @override
  Future<Map<String, dynamic>> getBookingReceipt(String bookingId) {
    return _remoteDataSource.getBookingReceipt(bookingId);
  }
}
