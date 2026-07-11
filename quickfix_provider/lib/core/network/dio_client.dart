import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'api_endpoints.dart';
import 'error_handler.dart';
import '../storage/hive_service.dart';

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
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
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
          // Trust Railway's cert when connecting via IP
          return host == _railwayEdgeIp || host.endsWith(_railwayDomain);
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
          }
          return handler.next(e);
        },
      ),
    );

    // Add debug logger interceptor
    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      logPrint: (obj) => print('[Dio API Log]: $obj'),
    ));
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
