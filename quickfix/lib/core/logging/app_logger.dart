import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'crash_reporter.dart';

enum LogLevel { debug, info, warning, error }

class AppLogger {
  static void debug(String message, {String? tag}) {
    _log(LogLevel.debug, message, tag: tag);
  }

  static void info(String message, {String? tag}) {
    _log(LogLevel.info, message, tag: tag);
  }

  static void warning(String message, {String? tag, dynamic error, StackTrace? stackTrace}) {
    _log(LogLevel.warning, message, tag: tag, error: error, stackTrace: stackTrace);
  }

  static String error(String message, {String? tag, dynamic error, StackTrace? stackTrace}) {
    // Generate unique error code for tracing/diagnostics
    final errorId = CrashReporter.generateErrorId();
    final enrichedMessage = '$message (Error ID: $errorId)';
    
    _log(LogLevel.error, enrichedMessage, tag: tag, error: error, stackTrace: stackTrace);
    
    // Log to production crash reporting if in release
    CrashReporter.report(error ?? enrichedMessage, stackTrace, errorId: errorId, reason: message);
    
    return errorId;
  }

  static void _log(LogLevel level, String message, {String? tag, dynamic error, StackTrace? stackTrace}) {
    // Write logs to console only in debug mode
    if (kDebugMode) {
      final time = DateFormat('yyyy-MM-dd HH:mm:ss.SSS').format(DateTime.now());
      final levelStr = level.toString().split('.').last.toUpperCase();
      final tagStr = tag != null ? ' [$tag]' : '';
      
      print('[$time] [$levelStr]$tagStr: $message');
      if (error != null) {
        print('  ErrorDetails: $error');
      }
      if (stackTrace != null) {
        print('  StackTrace:\n$stackTrace');
      }
    } else {
      // In production/release, add breadcrumbs for crash diagnostics
      final tagStr = tag != null ? '[$tag] ' : '';
      CrashReporter.logBreadcrumb('$tagStr$message');
    }
  }
}
