import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quickfix/core/network/network_providers.dart';
import 'package:quickfix/features/profile/datasources/profile_remote_data_source.dart';
import 'package:quickfix/features/profile/repositories/profile_repository.dart';
import 'package:quickfix/features/profile/repositories/profile_repository_impl.dart';

final profileRemoteDataSourceProvider = Provider<ProfileRemoteDataSource>((ref) {
  final client = ref.watch(dioClientProvider);
  return ProfileRemoteDataSource(client);
});

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  final remote = ref.watch(profileRemoteDataSourceProvider);
  return ProfileRepositoryImpl(remote);
});

final profileOffersProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final repository = ref.watch(profileRepositoryProvider);
  return repository.getOffers();
});

final referralInfoProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final repository = ref.watch(profileRepositoryProvider);
  return repository.getReferralInfo();
});
