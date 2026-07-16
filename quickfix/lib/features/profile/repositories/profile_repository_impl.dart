import 'package:quickfix/features/profile/datasources/profile_remote_data_source.dart';
import 'package:quickfix/features/profile/repositories/profile_repository.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileRemoteDataSource _remoteDataSource;

  ProfileRepositoryImpl(this._remoteDataSource);

  @override
  Future<String?> reverseGeocode(double lat, double lng) {
    return _remoteDataSource.reverseGeocode(lat, lng);
  }

  @override
  Future<List<Map<String, dynamic>>> getOffers() {
    return _remoteDataSource.getOffers();
  }

  @override
  Future<List<Map<String, dynamic>>> getBookings(String customerId) {
    return _remoteDataSource.getBookings(customerId);
  }

  @override
  Future<void> cancelBooking(String orderId) {
    return _remoteDataSource.cancelBooking(orderId);
  }

  @override
  Future<void> submitReview(Map<String, dynamic> reviewData) {
    return _remoteDataSource.submitReview(reviewData);
  }

  @override
  Future<Map<String, dynamic>> getReferralInfo() {
    return _remoteDataSource.getReferralInfo();
  }
}
