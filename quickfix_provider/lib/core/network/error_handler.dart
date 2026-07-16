import 'dart:io';
import 'package:dio/dio.dart';

enum ApiExceptionType {
  networkOffline,
  timeout,
  unauthorized,
  forbidden,
  notFound,
  badRequest,
  serverError,
  firebaseError,
  parsingError,
  unexpected,
}

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic originalError;
  final String? errorId;
  final ApiExceptionType type;

  ApiException(
    this.message, [
    this.statusCode,
    this.originalError,
    this.errorId,
    this.type = ApiExceptionType.unexpected,
  ]);

  @override
  String toString() => message;
}

class ErrorHandler {
  static ApiException handle(dynamic error) {
    // If it's already an ApiException, just return it
    if (error is ApiException) {
      return error;
    }

    // Map standard exceptions
    if (error is DioException) {
      return _handleDioException(error);
    } else if (error is SocketException) {
      return ApiException(
        'Offline mode. Please check your internet connection and try again.',
        null,
        error,
        null,
        ApiExceptionType.networkOffline,
      );
    } else if (error is FormatException) {
      return ApiException(
        'Data parsing/format failure. Please verify connection or contact support.',
        null,
        error,
        null,
        ApiExceptionType.parsingError,
      );
    } else if (error is TypeError) {
      return ApiException(
        'Data processing type mismatch. Please make sure you are on the latest app version.',
        null,
        error,
        null,
        ApiExceptionType.parsingError,
      );
    }

    // Inspect the error string for common platform exceptions
    final errorStr = error?.toString() ?? 'An unexpected error occurred';
    final lowerErrorStr = errorStr.toLowerCase();

    if (lowerErrorStr.contains('socketexception') ||
        lowerErrorStr.contains('connection failed') ||
        lowerErrorStr.contains('network_error') ||
        lowerErrorStr.contains('failed host lookup')) {
      return ApiException(
        'Offline mode. The server could not be reached. Please check your internet connection.',
        null,
        error,
        null,
        ApiExceptionType.networkOffline,
      );
    }

    if (lowerErrorStr.contains('permission_denied') ||
        lowerErrorStr.contains('permission denied') ||
        lowerErrorStr.contains('denied') ||
        lowerErrorStr.contains('permanently_denied')) {
      return ApiException(
        'Access denied. Please grant the required permissions in device settings.',
        null,
        error,
        null,
        ApiExceptionType.forbidden,
      );
    }

    if (lowerErrorStr.contains('timeout') ||
        lowerErrorStr.contains('timedout')) {
      return ApiException(
        'Connection timed out. The server could not be reached. Please try again.',
        null,
        error,
        null,
        ApiExceptionType.timeout,
      );
    }

    return ApiException(
      'An unexpected exception occurred. Please try again.',
      null,
      error,
      null,
      ApiExceptionType.unexpected,
    );
  }

  static ApiException _handleDioException(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return ApiException(
          'Connection timed out. The server could not be reached. Please check your network and try again.',
          null,
          error,
          null,
          ApiExceptionType.timeout,
        );

      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        final responseData = error.response?.data;
        String errorMessage = 'Something went wrong. Please try again.';

        if (responseData != null && responseData is Map) {
          errorMessage =
              responseData['message']?.toString() ??
              responseData['error']?.toString() ??
              errorMessage;
        }

        switch (statusCode) {
          case 400:
            return ApiException(
              errorMessage,
              statusCode,
              error,
              null,
              ApiExceptionType.badRequest,
            );
          case 401:
            return ApiException(
              'Session expired. Please log in again.',
              statusCode,
              error,
              null,
              ApiExceptionType.unauthorized,
            );
          case 403:
            return ApiException(
              'You do not have permission to access this resource.',
              statusCode,
              error,
              null,
              ApiExceptionType.forbidden,
            );
          case 404:
            return ApiException(
              errorMessage,
              statusCode,
              error,
              null,
              ApiExceptionType.notFound,
            );
          case 500:
          case 502:
          case 503:
          case 504:
            return ApiException(
              'Internal Server Error. Please try again later.',
              statusCode,
              error,
              null,
              ApiExceptionType.serverError,
            );
          default:
            return ApiException(
              errorMessage,
              statusCode,
              error,
              null,
              ApiExceptionType.unexpected,
            );
        }

      case DioExceptionType.cancel:
        return ApiException(
          'Request was cancelled.',
          null,
          error,
          null,
          ApiExceptionType.unexpected,
        );

      case DioExceptionType.connectionError:
        if (error.error is SocketException) {
          return ApiException(
            'Offline mode. The server could not be reached. Please check your internet connection.',
            null,
            error,
            null,
            ApiExceptionType.networkOffline,
          );
        }
        return ApiException(
          'Connection error. The server could not be reached. Please verify your internet settings and try again.',
          null,
          error,
          null,
          ApiExceptionType.networkOffline,
        );

      default:
        return ApiException(
          'Failed to connect to QuickFix servers. Please check your connection.',
          null,
          error,
          null,
          ApiExceptionType.networkOffline,
        );
    }
  }
}
