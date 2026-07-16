import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quickfix/core/network/dio_client.dart';

final dioClientProvider = Provider<DioClient>((ref) {
  return DioClient();
});
