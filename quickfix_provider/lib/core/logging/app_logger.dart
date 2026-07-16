import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

/// Levels of logging priority.
enum LogLevel { verbose, debug, info, warning, error }

/// Unified enterprise logger managing runtime traces, API requests/responses, and navigation tracking for the Provider app.
/// 
/// Automatically suppresses debug/verbose trace categories in production builds,
/// while sanitizing critical security strings (e.g. passwords, authentication tokens) and PII.
class AppLogger {
  static const Set<String> _sensitiveKeys = {
    'password',
    'oldpassword',
    'newpassword',
    'token',
    'authtoken',
    'fcmtoken',
    'firebasetoken',
    'authorization',
    'phone',
    'ownerphone',
    'email',
    'owneremail',
    'name',
    'ownername',
    'address',
    'savedaddresses',
    'pan',
    'gst',
    'bankaccountnumber',
    'ifsc',
    'upiid',
    'code',
  };

  static final RegExp _emailRegex = RegExp(
    r'[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\.[a-zA-Z0-9-.]+',
  );
  static final RegExp _phoneRegex = RegExp(
    r'\b(?:\+?91|0)?[6-9]\d{9}\b',
  );
  static final RegExp _jwtRegex = RegExp(
    r'\beyJ[a-zA-Z0-9-_]+\.[a-zA-Z0-9-_]+\.[a-zA-Z0-9-_]+\b',
  );

  /// Recursively scrubs sensitive parameters from collections.
  static dynamic sanitize(dynamic data) {
    if (data == null) return null;
    if (data is String) {
      return _sanitizeString(data);
    }
    if (data is Map) {
      final Map<String, dynamic> sanitizedMap = {};
      data.forEach((key, value) {
        final keyStr = key.toString().toLowerCase();
        if (_sensitiveKeys.contains(keyStr)) {
          sanitizedMap[key.toString()] = '[REDACTED]';
        } else {
          sanitizedMap[key.toString()] = sanitize(value);
        }
      });
      return sanitizedMap;
    }
    if (data is List) {
      return data.map((item) => sanitize(item)).toList();
    }
    return data;
  }

  /// Scrapes sensitive text strings using Regex matching.
  static String _sanitizeString(String val) {
    var result = val;
    result = result.replaceAllMapped(_emailRegex, (m) => '[PII_EMAIL_REDACTED]');
    result = result.replaceAllMapped(_phoneRegex, (m) => '[PII_PHONE_REDACTED]');
    result = result.replaceAllMapped(_jwtRegex, (m) => '[TOKEN_REDACTED]');
    return result;
  }

  static void verbose(String message, {String? tag}) {
    _log(LogLevel.verbose, message, tag: tag);
  }

  static void debug(String message, {String? tag}) {
    _log(LogLevel.debug, message, tag: tag);
  }

  static void info(String message, {String? tag}) {
    _log(LogLevel.info, message, tag: tag);
  }

  static void warning(
    String message, {
    String? tag,
    dynamic error,
    StackTrace? stackTrace,
  }) {
    _log(
      LogLevel.warning,
      message,
      tag: tag,
      error: error,
      stackTrace: stackTrace,
    );
  }

  static void error(
    String message, {
    String? tag,
    dynamic error,
    StackTrace? stackTrace,
  }) {
    _log(
      LogLevel.error,
      message,
      tag: tag,
      error: error,
      stackTrace: stackTrace,
    );
  }

  static void _log(
    LogLevel level,
    String message, {
    String? tag,
    dynamic error,
    StackTrace? stackTrace,
  }) {
    // 1. Enforce production visibility guidelines
    if (!kDebugMode) {
      // Production: completely disable debug & verbose logs
      if (level == LogLevel.debug || level == LogLevel.verbose) {
        return;
      }
    }

    // 2. Perform enterprise redaction
    final String sanitizedMessage = _sanitizeString(message);
    final dynamic sanitizedError = sanitize(error);

    if (kDebugMode) {
      final time = DateFormat('yyyy-MM-dd HH:mm:ss.SSS').format(DateTime.now());
      final levelStr = level.toString().split('.').last.toUpperCase();
      final tagStr = tag != null ? ' [$tag]' : '';

      print('[$time] [$levelStr]$tagStr: $sanitizedMessage');
      if (sanitizedError != null) {
        print('  ErrorDetails: $sanitizedError');
      }
      if (stackTrace != null) {
        print('  StackTrace:\n$stackTrace');
      }
    }
  }
}
