import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:quickfix/core/services/hive_service.dart';
import 'package:quickfix/app.dart';

import 'dart:ui';
import 'package:quickfix/core/logging/app_logger.dart';
import 'package:quickfix/core/logging/performance_monitor.dart';

import 'package:quickfix/core/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Global unhandled error monitoring and crash reporting hooks
  FlutterError.onError = (details) {
    AppLogger.error(
      'Global Flutter framework error',
      tag: 'UNHANDLED',
      error: details.exception,
      stackTrace: details.stack,
    );
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    AppLogger.error(
      'Global Asynchronous error',
      tag: 'UNHANDLED',
      error: error,
      stackTrace: stack,
    );
    return true;
  };
  
  // Set image cache limits to optimize memory consumption (50MB / 100 images)
  PaintingBinding.instance.imageCache.maximumSizeBytes = 50 * 1024 * 1024;
  PaintingBinding.instance.imageCache.maximumSize = 100;
  
  // Initialize SDKs concurrently to optimize startup time
  await PerformanceMonitor.trace('Concurrent SDK Initialization', () async {
    await Future.wait([
      Future(() async {
        try {
          await Firebase.initializeApp();
        } catch (e) {
          debugPrint('Firebase initialization failed: $e');
        }
      }),
      HiveService.init(),
    ]);
  });

  // Initialize Notification Service — must be awaited so Hive boxes are ready
  await NotificationService.init();

  runApp(
    const ProviderScope(
      child: QuickFixApp(),
    ),
  );
}
