import 'dart:io';
import 'package:dio/dio.dart';

class DioClient {
  static final String baseUrl = Platform.isAndroid 
      ? 'http://10.0.2.2:3000/api' 
      : 'http://localhost:3000/api';

  final Dio dio = Dio(BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: const Duration(seconds: 8),
    receiveTimeout: const Duration(seconds: 8),
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
  ));

  DioClient() {
    dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
    ));
  }
}
