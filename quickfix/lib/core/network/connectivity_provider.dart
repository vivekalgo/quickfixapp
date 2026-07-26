import 'dart:async';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final connectivityProvider = StreamProvider<bool>((ref) {
  final controller = StreamController<bool>();
  bool? lastStatus;
  int consecutiveFailures = 0;

  Future<void> checkConnection() async {
    bool isConnected = false;
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 5));
      isConnected = result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      isConnected = false;
    }

    if (isConnected) {
      consecutiveFailures = 0;
      if (lastStatus != true) {
        lastStatus = true;
        controller.add(true);
      }
    } else {
      consecutiveFailures++;
      // Require 2 consecutive failures before marking offline to avoid false alarms
      if (consecutiveFailures >= 2 && lastStatus != false) {
        lastStatus = false;
        controller.add(false);
      }
    }
  }

  // Initial check
  checkConnection();

  // Poll connection status every 8 seconds
  final timer = Timer.periodic(const Duration(seconds: 8), (_) {
    checkConnection();
  });

  ref.onDispose(() {
    timer.cancel();
    controller.close();
  });

  return controller.stream;
});
