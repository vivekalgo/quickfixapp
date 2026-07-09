import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/network_providers.dart';
import '../../data/sources/booking_remote_data_source.dart';
import '../../domain/repositories/booking_repository.dart';
import '../../data/repositories/booking_repository_impl.dart';

final bookingRemoteDataSourceProvider = Provider<BookingRemoteDataSource>((ref) {
  final client = ref.watch(dioClientProvider);
  return BookingRemoteDataSource(client);
});

final bookingRepositoryProvider = Provider<BookingRepository>((ref) {
  final remote = ref.watch(bookingRemoteDataSourceProvider);
  return BookingRepositoryImpl(remote);
});
