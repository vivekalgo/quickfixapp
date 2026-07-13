import 'dart:math';
import 'package:flutter/foundation.dart';

class CrashReporter {
  // Breadcrumb buffer for crash analytics
  static final List<String> _breadcrumbs = [];
  static const int _maxBreadcrumbs = 50;

  /// Generate a unique 8-character alphanumeric Error ID (e.g. "ERR-A9F32X")
  static String generateErrorId() {
    final rand = Random();
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final code = List.generate(6, (_) => chars[rand.nextInt(chars.length)]).join();
    return 'ERR-$code';
  }

  /// Add lightweight runtime breadcrumb (retains last 50 events in memory for OOM or crash dumps)
  static void logBreadcrumb(String message) {
    _breadcrumbs.add('${DateTime.now().toIso8601String()}: $message');
    if (_breadcrumbs.length > _maxBreadcrumbs) {
      _breadcrumbs.removeAt(0);
    }
  }

  /// Reports a fatal or non-fatal exception to the production logging collector
  static void report(dynamic error, StackTrace? stackTrace, {required String errorId, String? reason}) {
    if (kReleaseMode) {
      // PROD CODE: Here is where Firebase Crashlytics would be integrated:
      // FirebaseCrashlytics.instance.setCustomKey('error_id', errorId);
      // FirebaseCrashlytics.instance.setCustomKey('reason', reason ?? 'unknown');
      // _breadcrumbs.forEach((bc) => FirebaseCrashlytics.instance.log(bc));
      // FirebaseCrashlytics.instance.recordError(error, stackTrace, fatal: false);
    } else {
      // Debug mock reporting
      debugPrint('[CrashReporter] Mock reported error $errorId: $reason');
      debugPrint('  Breadcrumbs Dump:');
      for (final bc in _breadcrumbs) {
        debugPrint('    - $bc');
      }
    }
  }
}
