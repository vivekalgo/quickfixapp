import 'package:flutter/foundation.dart';
import 'package:quickfix/core/logging/app_logger.dart';

class PerformanceMonitor {
  static final Map<String, Stopwatch> _activeTraces = {};

  /// Trace the execution duration of an synchronous/asynchronous code block
  static Future<T> trace<T>(String name, Future<T> Function() action) async {
    if (!kDebugMode) {
      return await action();
    }

    final stopwatch = Stopwatch()..start();
    AppLogger.info('Starting performance trace: "$name"', tag: 'PERF');
    try {
      return await action();
    } finally {
      stopwatch.stop();
      AppLogger.info(
        'Finished performance trace: "$name" completed in ${stopwatch.elapsedMilliseconds}ms',
        tag: 'PERF',
      );
    }
  }

  /// Manually starts a custom stopwatch trace
  static void startTrace(String name) {
    if (!kDebugMode) return;

    if (_activeTraces.containsKey(name)) {
      AppLogger.warning(
        'Trace "$name" was already started. Restarting...',
        tag: 'PERF',
      );
    }
    _activeTraces[name] = Stopwatch()..start();
    AppLogger.info('Trace "$name" started.', tag: 'PERF');
  }

  /// Manually stops and logs the duration of a trace
  static void endTrace(String name) {
    if (!kDebugMode) return;

    final stopwatch = _activeTraces.remove(name);
    if (stopwatch == null) {
      AppLogger.warning(
        'Attempted to end trace "$name" but it was never started.',
        tag: 'PERF',
      );
      return;
    }
    stopwatch.stop();
    AppLogger.info(
      'Trace "$name" completed in ${stopwatch.elapsedMilliseconds}ms',
      tag: 'PERF',
    );
  }
}
