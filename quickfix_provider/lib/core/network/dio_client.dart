import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:quickfix_provider/core/network/api_endpoints.dart';
import 'package:quickfix_provider/core/network/error_handler.dart';
import 'package:quickfix_provider/core/storage/hive_service.dart';
import 'package:quickfix_provider/core/logging/app_logger.dart';

import 'package:quickfix_provider/core/network/dns_bypass_helper.dart';

import 'package:quickfix_provider/core/network/retry_interceptor.dart';
import 'dart:async';

class DioClient {
  late final Dio _dio;
  final StreamController<void> _unauthorizedController = StreamController<void>.broadcast();

  Stream<void> get onUnauthorized => _unauthorizedController.stream;

  DioClient() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiEndpoints.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        contentType: Headers.jsonContentType,
      ),
    );

    // ── Operator-Block Bypass (Jio / Airtel) ─────────────────────────────────
    if (DnsBypassHelper.shouldBypass(ApiEndpoints.baseUrl)) {
      ((_dio.httpClientAdapter) as IOHttpClientAdapter).createHttpClient = () {
        final client = HttpClient();
        client.badCertificateCallback = DnsBypassHelper.verifyCertificate;
        return client;
      };
    }
    // ─────────────────────────────────────────────────────────────────────────

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          // Jio/Airtel operator DNS bypass
          if (DnsBypassHelper.shouldBypass(options.baseUrl)) {
            options.baseUrl = DnsBypassHelper.bypassUrl(
              options.baseUrl,
              options.headers,
            );
          }

          // Fetch token from local storage
          final token = HiveService.getAuthToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException e, handler) {
          // Auto logout on unauthorized error
          if (e.response?.statusCode == 401) {
            HiveService.clearSession();
            _unauthorizedController.add(null);
          }
          return handler.next(e);
        },
      ),
    );

    _dio.interceptors.add(RetryInterceptor(dio: _dio));

    // Structured sanitized API logging interceptor for runtime troubleshooting
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final sanitizedHeaders = AppLogger.sanitize(options.headers);
          final sanitizedData = AppLogger.sanitize(options.data);

          AppLogger.info('--> ${options.method} ${options.uri}', tag: 'API');
          AppLogger.info('Request Headers: $sanitizedHeaders', tag: 'API');
          if (sanitizedData != null) {
            AppLogger.info('Request Payload: $sanitizedData', tag: 'API');
          }
          return handler.next(options);
        },
        onResponse: (response, handler) {
          final sanitizedResponseData = AppLogger.sanitize(response.data);

          AppLogger.info(
            '<-- ${response.statusCode} ${response.requestOptions.uri}',
            tag: 'API',
          );
          if (sanitizedResponseData != null) {
            AppLogger.info(
              'Response Payload: $sanitizedResponseData',
              tag: 'API',
            );
          }
          return handler.next(response);
        },
        onError: (DioException e, handler) {
          AppLogger.warning(
            'API Error [${e.response?.statusCode}]: ${e.message}',
            tag: 'API',
            error: e,
            stackTrace: e.stackTrace,
          );
          return handler.next(e);
        },
      ),
    );
  }

  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.get(
        path,
        queryParameters: queryParameters,
        options: options,
      );
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  Future<Response> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  Future<Response> delete(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.delete(
        path,
        queryParameters: queryParameters,
        options: options,
      );
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }
}
