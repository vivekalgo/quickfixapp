import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quickfix/core/providers/network_providers.dart';
import 'package:quickfix/features/booking/services/booking_remote_data_source.dart';
import 'package:quickfix/features/booking/repositories/booking_repository.dart';
import 'package:quickfix/features/booking/repositories/booking_repository_impl.dart';

final bookingRemoteDataSourceProvider = Provider<BookingRemoteDataSource>((ref) {
  final client = ref.watch(dioClientProvider);
  return BookingRemoteDataSource(client);
});

final bookingRepositoryProvider = Provider<BookingRepository>((ref) {
  final remote = ref.watch(bookingRemoteDataSourceProvider);
  return BookingRepositoryImpl(remote);
});
