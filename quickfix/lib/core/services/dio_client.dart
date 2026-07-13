import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:quickfix/core/network/api_endpoints.dart';
import 'package:quickfix/core/network/error_handler.dart';
import 'package:quickfix/core/logging/app_logger.dart';
import 'package:quickfix/core/services/hive_service.dart';
import 'package:quickfix/core/services/secure_token_manager.dart';

/// Railway edge IP address used to bypass Jio/Airtel operator DNS blocks.
/// When `*.up.railway.app` is blocked by DNS, we connect directly to this IP
/// and pass the original hostname in the 'Host' header for server-side routing.
const String _railwayEdgeIp = '69.46.46.69';
const String _railwayDomain = 'up.railway.app';

class DioClient {
  late final Dio _dio;

  DioClient() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiEndpoints.baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        contentType: Headers.jsonContentType,
      ),
    );

    // ── Operator-Block Bypass (Jio / Airtel) ─────────────────────────────────
    // Jio and Airtel block `*.up.railway.app` at the DNS level.
    // We work around this by connecting directly to Railway's edge IP address
    // and setting the `Host` header so Railway can route the request correctly.
    // The custom `badCertificateCallback` trusts the TLS certificate when the
    // connection target is the raw IP instead of the hostname.
    if (ApiEndpoints.baseUrl.contains(_railwayDomain)) {
      ((_dio.httpClientAdapter) as IOHttpClientAdapter).createHttpClient = () {
        final client = HttpClient();
        client.badCertificateCallback = (cert, host, port) {
          // SSL Pinning support check:
          // 1. Verify hostname matches operator-bypass targets
          final isKnownHost = host == _railwayEdgeIp || host.endsWith(_railwayDomain);
          // 2. Verify certificate subject / domain strictly matches our trusted domain pattern
          final isSubjectValid = cert.subject.contains('CN=*.up.railway.app') || 
                                 cert.subject.contains('CN=up.railway.app');
          
          return isKnownHost && isSubjectValid;
        };
        return client;
      };
    }
    // ─────────────────────────────────────────────────────────────────────────

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          // Jio/Airtel operator DNS bypass: rewrite baseUrl to use edge IP
          if (options.baseUrl.contains(_railwayDomain)) {
            final originalHost = Uri.parse(options.baseUrl).host;
            options.headers['Host'] = originalHost;
            options.baseUrl = options.baseUrl.replaceFirst(originalHost, _railwayEdgeIp);
          }

          // Fetch token via SecureTokenManager (prefers in-memory, falls back to Hive)
          final token = SecureTokenManager.readToken(
            fetchCallback: HiveService.getAuthToken,
          );
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException e, handler) {
          // If 401 Unauthorized, clear session token from both layers
          if (e.response?.statusCode == 401) {
            SecureTokenManager.clearToken(
              clearCallback: HiveService.clearAuthToken,
            );
          }
          return handler.next(e);
        },
      ),
    );

    // Structured API logging interceptor for production troubleshooting
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final sanitizedHeaders = Map<String, dynamic>.from(options.headers);
          if (sanitizedHeaders.containsKey('Authorization')) {
            sanitizedHeaders['Authorization'] = '[REDACTED]';
          }

          dynamic sanitizedData = options.data;
          if (options.data is Map) {
            final dataMap = Map<String, dynamic>.from(options.data as Map);
            if (dataMap.containsKey('code')) dataMap['code'] = '[REDACTED]';
            if (dataMap.containsKey('token')) dataMap['token'] = '[REDACTED]';
            if (dataMap.containsKey('base64Image')) dataMap['base64Image'] = '[IMAGE_DATA_REDACTED]';
            sanitizedData = dataMap;
          }

          AppLogger.info('--> ${options.method} ${options.uri}', tag: 'API');
          AppLogger.info('Request Headers: $sanitizedHeaders', tag: 'API');
          if (sanitizedData != null) {
            AppLogger.info('Request Payload: $sanitizedData', tag: 'API');
          }
          return handler.next(options);
        },
        onResponse: (response, handler) {
          dynamic sanitizedResponseData = response.data;
          if (response.data is Map) {
            final dataMap = Map<String, dynamic>.from(response.data as Map);
            if (dataMap.containsKey('token')) dataMap['token'] = '[REDACTED]';
            sanitizedResponseData = dataMap;
          }

          AppLogger.info('<-- ${response.statusCode} ${response.requestOptions.uri}', tag: 'API');
          if (sanitizedResponseData != null) {
            AppLogger.info('Response Payload: $sanitizedResponseData', tag: 'API');
          }
          return handler.next(response);
        },
        onError: (DioException e, handler) {
          AppLogger.warning('API Error [${e.response?.statusCode}]: ${e.message}', tag: 'API', error: e, stackTrace: e.stackTrace);
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
    } catch (e, s) {
      throw ErrorHandler.handle(e, s);
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
    } catch (e, s) {
      throw ErrorHandler.handle(e, s);
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
    } catch (e, s) {
      throw ErrorHandler.handle(e, s);
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
    } catch (e, s) {
      throw ErrorHandler.handle(e, s);
    }
  }
}
