import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quickfix/core/services/dio_client.dart';

final dioClientProvider = Provider<DioClient>((ref) {
  return DioClient();
});
