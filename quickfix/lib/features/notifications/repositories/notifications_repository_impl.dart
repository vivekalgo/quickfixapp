import 'package:quickfix/features/notifications/datasources/notifications_remote_data_source.dart';
import 'package:quickfix/features/notifications/repositories/notifications_repository.dart';

class NotificationsRepositoryImpl implements NotificationsRepository {
  final NotificationsRemoteDataSource _remoteDataSource;

  NotificationsRepositoryImpl(this._remoteDataSource);

  @override
  Future<List<Map<String, dynamic>>> getNotifications() {
    return _remoteDataSource.getNotifications();
  }
}
