import 'dart:io';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:quickfix/core/logging/app_logger.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic originalError;
  final String? errorId;

  ApiException(this.message, [this.statusCode, this.originalError, this.errorId]);

  @override
  String toString() => message;
}

class ErrorHandler {
  static ApiException handle(dynamic error, [StackTrace? stackTrace]) {
    // If it's already an ApiException, just return it
    if (error is ApiException) {
      return error;
    }

    // Log the error via AppLogger.error to get a Unique Error ID
    final errorId = AppLogger.error(
      'Exception intercepted by ErrorHandler',
      tag: 'ERROR_HANDLER',
      error: error,
      stackTrace: stackTrace,
    );

    // Map standard exceptions
    if (error is DioException) {
      return _handleDioException(error, errorId);
    } else if (error is SocketException) {
      return ApiException(
        'Offline mode. Please check your internet connection and try again.',
        null,
        error,
        errorId,
      );
    } else if (error is FirebaseAuthException) {
      return _handleFirebaseAuthException(error, errorId);
    } else if (error is FirebaseException) {
      return ApiException(
        'Firebase service error: ${error.message ?? "Something went wrong with our cloud services."}',
        null,
        error,
        errorId,
      );
    } else if (error is FormatException) {
      return ApiException(
        'Data parsing/format failure. Please verify connection or contact support.',
        null,
        error,
        errorId,
      );
    } else if (error is TypeError) {
      return ApiException(
        'Data processing type mismatch. Please make sure you are on the latest app version.',
        null,
        error,
        errorId,
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
        errorId,
      );
    }

    if (lowerErrorStr.contains('permission_denied') ||
        lowerErrorStr.contains('permission denied') ||
        lowerErrorStr.contains('denied') ||
        lowerErrorStr.contains('permanently_denied')) {
      return ApiException(
        'Access denied. Please grant the required permissions (e.g., location, storage) in device settings.',
        null,
        error,
        errorId,
      );
    }

    if (lowerErrorStr.contains('timeout') || lowerErrorStr.contains('timedout')) {
      return ApiException(
        'Connection timed out. The server could not be reached. Please try again.',
        null,
        error,
        errorId,
      );
    }

    return ApiException(
      'An unexpected exception occurred. Please try again.',
      null,
      error,
      errorId,
    );
  }

  static ApiException _handleDioException(DioException error, String errorId) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return ApiException(
          'Connection timed out. The server could not be reached.\n\nTip: If you are using mobile data (Jio/Airtel), our server may be blocked by your operator. Try switching to Wi-Fi, using a VPN, or changing your phone\'s Private DNS to "dns.google" or "1.1.1.1".',
          null,
          error,
          errorId,
        );

      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        final responseData = error.response?.data;
        String errorMessage = 'Something went wrong. Please try again.';

        if (responseData != null && responseData is Map) {
          errorMessage = responseData['message']?.toString() ??
              responseData['error']?.toString() ??
              errorMessage;
        }

        switch (statusCode) {
          case 400:
            return ApiException(errorMessage, statusCode, error, errorId);
          case 401:
            return ApiException('Session expired. Please log in again.', statusCode, error, errorId);
          case 403:
            return ApiException('You do not have permission to access this resource.', statusCode, error, errorId);
          case 404:
            return ApiException(errorMessage, statusCode, error, errorId);
          case 500:
            return ApiException('Internal Server Error. Please try again later.', statusCode, error, errorId);
          default:
            return ApiException(errorMessage, statusCode, error, errorId);
        }

      case DioExceptionType.cancel:
        return ApiException('Request was cancelled.', null, error, errorId);

      case DioExceptionType.connectionError:
        if (error.error is SocketException) {
          return ApiException(
            'Offline mode. The server could not be reached. Please check your internet connection.',
            null,
            error,
            errorId,
          );
        }
        return ApiException(
          'Connection error. The server could not be reached.\n\nTip: If you are using mobile data (Jio/Airtel), our server may be blocked by your operator. Try switching to Wi-Fi, using a VPN, or changing your phone\'s Private DNS to "dns.google" or "1.1.1.1".',
          null,
          error,
          errorId,
        );

      default:
        return ApiException(
          'Failed to connect to QuickFix servers. Please check your connection.',
          null,
          error,
          errorId,
        );
    }
  }

  static ApiException _handleFirebaseAuthException(FirebaseAuthException error, String errorId) {
    switch (error.code) {
      case 'invalid-email':
        return ApiException('The email address is badly formatted.', null, error, errorId);
      case 'user-disabled':
        return ApiException('This user account has been disabled.', null, error, errorId);
      case 'user-not-found':
        return ApiException('No account found with this email.', null, error, errorId);
      case 'wrong-password':
        return ApiException('Incorrect password. Please try again.', null, error, errorId);
      case 'email-already-in-use':
        return ApiException('An account already exists with this email.', null, error, errorId);
      case 'weak-password':
        return ApiException('The password is too weak.', null, error, errorId);
      case 'operation-not-allowed':
        return ApiException('This operation is not enabled.', null, error, errorId);
      case 'network-request-failed':
        return ApiException('Network error during authentication. Please check if you are online.', null, error, errorId);
      case 'invalid-verification-code':
        return ApiException('The verification code is invalid.', null, error, errorId);
      case 'session-expired':
        return ApiException('SMS verification code expired. Please request a new one.', null, error, errorId);
      default:
        return ApiException(error.message ?? 'Authentication failed. Please try again.', null, error, errorId);
    }
  }
}
