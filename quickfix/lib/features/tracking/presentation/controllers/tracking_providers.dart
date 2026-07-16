import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quickfix/core/network/network_providers.dart';
import 'package:quickfix/features/tracking/datasources/tracking_remote_data_source.dart';
import 'package:quickfix/features/tracking/repositories/tracking_repository.dart';
import 'package:quickfix/features/tracking/repositories/tracking_repository_impl.dart';

final trackingRemoteDataSourceProvider = Provider<TrackingRemoteDataSource>((ref) {
  final client = ref.watch(dioClientProvider);
  return TrackingRemoteDataSource(client);
});

final trackingRepositoryProvider = Provider<TrackingRepository>((ref) {
  final remote = ref.watch(trackingRemoteDataSourceProvider);
  return TrackingRepositoryImpl(remote);
});
