import 'dart:async';
import 'package:dio/dio.dart';
import 'package:quickfix/core/logging/app_logger.dart';

/// Interceptor to automatically retry failed network requests (specifically GET requests)
/// when connection errors or timeouts occur, to support network recovery.
class RetryInterceptor extends Interceptor {
  final Dio dio;
  final int maxRetries;
  final Duration initialDelay;

  RetryInterceptor({
    required this.dio,
    this.maxRetries = 3,
    this.initialDelay = const Duration(seconds: 1),
  });

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final requestOptions = err.requestOptions;

    // Only retry GET requests (safe requests) to avoid duplicate state mutations (like double payments)
    final isSafeMethod = requestOptions.method.toUpperCase() == 'GET';
    final hasNotExceededMax = (requestOptions.extra['retry_count'] ?? 0) < maxRetries;

    // Retry only on network-level failure or timeouts
    final isRetryableError =
        err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.sendTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.connectionError;

    if (isSafeMethod && hasNotExceededMax && isRetryableError) {
      final retryCount = (requestOptions.extra['retry_count'] ?? 0) + 1;
      requestOptions.extra['retry_count'] = retryCount;

      // Exponential backoff delay: initialDelay * 2^(retryCount-1)
      final delay = initialDelay * (1 << (retryCount - 1));

      AppLogger.warning(
        'Retrying request: ${requestOptions.method} ${requestOptions.uri} (Attempt $retryCount of $maxRetries) in ${delay.inMilliseconds}ms...',
        tag: 'RETRY_INTERCEPTOR',
        error: err,
      );

      await Future.delayed(delay);

      try {
        final response = await _retry(requestOptions);
        return handler.resolve(response);
      } on DioException catch (retryErr) {
        return handler.next(retryErr);
      }
    }

    return handler.next(err);
  }

  Future<Response<dynamic>> _retry(RequestOptions requestOptions) {
    final options = Options(
      method: requestOptions.method,
      headers: requestOptions.headers,
      extra: requestOptions.extra,
      responseType: requestOptions.responseType,
      contentType: requestOptions.contentType,
      validateStatus: requestOptions.validateStatus,
      receiveTimeout: requestOptions.receiveTimeout,
      sendTimeout: requestOptions.sendTimeout,
    );

    return dio.request<dynamic>(
      requestOptions.path,
      data: requestOptions.data,
      queryParameters: requestOptions.queryParameters,
      options: options,
    );
  }
}
