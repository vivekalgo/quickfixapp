import 'dart:io';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:quickfix/core/logging/app_logger.dart';

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
        ApiExceptionType.networkOffline,
      );
    } else if (error is FirebaseAuthException) {
      return _handleFirebaseAuthException(error, errorId);
    } else if (error is FirebaseException) {
      return ApiException(
        _cleanTechnicalErrorString(
          error.message ?? 'Service temporarily unavailable. Please try again.',
        ),
        null,
        error,
        errorId,
        ApiExceptionType.firebaseError,
      );
    } else if (error is FormatException) {
      return ApiException(
        'Data parsing/format failure. Please verify connection or contact support.',
        null,
        error,
        errorId,
        ApiExceptionType.parsingError,
      );
    } else if (error is TypeError) {
      return ApiException(
        'Data processing type mismatch. Please make sure you are on the latest app version.',
        null,
        error,
        errorId,
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
        errorId,
        ApiExceptionType.networkOffline,
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
        ApiExceptionType.forbidden,
      );
    }

    if (lowerErrorStr.contains('timeout') ||
        lowerErrorStr.contains('timedout')) {
      return ApiException(
        'Connection timed out. The server could not be reached. Please try again.',
        null,
        error,
        errorId,
        ApiExceptionType.timeout,
      );
    }

    return ApiException(
      'An unexpected exception occurred. Please try again.',
      null,
      error,
      errorId,
      ApiExceptionType.unexpected,
    );
  }

  static ApiException _handleDioException(DioException error, String errorId) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return ApiException(
          'Connection timed out. The server could not be reached. Please check your network and try again.',
          null,
          error,
          errorId,
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
              errorId,
              ApiExceptionType.badRequest,
            );
          case 401:
            return ApiException(
              errorMessage != 'Something went wrong. Please try again.'
                  ? errorMessage
                  : 'Session expired. Please log in again.',
              statusCode,
              error,
              errorId,
              ApiExceptionType.unauthorized,
            );
          case 403:
            return ApiException(
              'You do not have permission to access this resource.',
              statusCode,
              error,
              errorId,
              ApiExceptionType.forbidden,
            );
          case 404:
            return ApiException(
              errorMessage,
              statusCode,
              error,
              errorId,
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
              errorId,
              ApiExceptionType.serverError,
            );
          default:
            return ApiException(
              errorMessage,
              statusCode,
              error,
              errorId,
              ApiExceptionType.unexpected,
            );
        }

      case DioExceptionType.cancel:
        return ApiException(
          'Request was cancelled.',
          null,
          error,
          errorId,
          ApiExceptionType.unexpected,
        );

      case DioExceptionType.connectionError:
        if (error.error is SocketException) {
          return ApiException(
            'Offline mode. The server could not be reached. Please check your internet connection.',
            null,
            error,
            errorId,
            ApiExceptionType.networkOffline,
          );
        }
        return ApiException(
          'Connection error. The server could not be reached. Please verify your internet settings and try again.',
          null,
          error,
          errorId,
          ApiExceptionType.networkOffline,
        );

      default:
        return ApiException(
          'Failed to connect to QuickFix servers. Please check your connection.',
          null,
          error,
          errorId,
          ApiExceptionType.networkOffline,
        );
    }
  }

  static ApiException _handleFirebaseAuthException(
    FirebaseAuthException error,
    String errorId,
  ) {
    String msg;
    switch (error.code) {
      case 'invalid-email':
        msg = 'The email address is badly formatted.';
        break;
      case 'user-disabled':
        msg = 'This user account has been disabled.';
        break;
      case 'user-not-found':
        msg = 'No account found with this email.';
        break;
      case 'wrong-password':
        msg = 'Incorrect password. Please try again.';
        break;
      case 'email-already-in-use':
        msg = 'An account already exists with this email.';
        break;
      case 'weak-password':
        msg = 'The password is too weak.';
        break;
      case 'operation-not-allowed':
        msg = 'This operation is not enabled.';
        break;
      case 'network-request-failed':
        msg = 'Network error during authentication. Please check if you are online.';
        break;
      case 'invalid-verification-code':
      case 'invalid-credential':
        msg = 'The OTP code entered is incorrect. Please check and try again.';
        break;
      case 'invalid-phone-number':
        msg = 'Invalid mobile number. Please enter a valid 10-digit phone number.';
        break;
      case 'session-expired':
      case 'code-expired':
        msg = 'SMS verification code expired. Please request a new OTP.';
        break;
      case 'too-many-requests':
        msg = 'Too many attempts. Please try again after some time.';
        break;
      case 'quota-exceeded':
        msg = 'Authentication service is temporarily busy. Please try again later.';
        break;
      default:
        final raw = error.message ?? 'Authentication failed. Please try again.';
        msg = _cleanTechnicalErrorString(raw);
    }
    return ApiException(
      msg,
      null,
      error,
      errorId,
      ApiExceptionType.firebaseError,
    );
  }

  /// Removes raw exception prefixes, bracketed code tags like [firebase_auth/...], 
  /// stack traces, and internal database jargon to show clean user messages.
  static String _cleanTechnicalErrorString(String message) {
    String clean = message;

    // Strip out square bracketed error codes e.g. [firebase_auth/invalid-verification-code]
    clean = clean.replaceAll(RegExp(r'\[[\w\-/]+\]\s*'), '');

    // Strip out common exception type prefixes
    clean = clean.replaceAll(RegExp(r'^(Exception|FirebaseAuthException|FirebaseException|DioException|SocketException|FormatException|TypeError):\s*'), '');

    clean = clean.trim();

    // Fallback if message becomes empty or still contains unreadable technical jargon
    if (clean.isEmpty || clean.contains('Stack trace:') || clean.toLowerCase().contains('firebase_auth')) {
      return 'Something went wrong. Please check your inputs and try again.';
    }

    return clean;
  }
}
