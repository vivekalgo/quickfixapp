import 'dart:async';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final connectivityProvider = StreamProvider<bool>((ref) {
  final controller = StreamController<bool>();
  bool? lastStatus;

  Future<void> checkConnection() async {
    try {
      final result = await InternetAddress.lookup(
        'google.com',
      ).timeout(const Duration(seconds: 3));
      final isConnected = result.isNotEmpty && result[0].rawAddress.isNotEmpty;
      if (lastStatus != isConnected) {
        lastStatus = isConnected;
        controller.add(isConnected);
      }
    } catch (_) {
      if (lastStatus != false) {
        lastStatus = false;
        controller.add(false);
      }
    }
  }

  // Run initial check
  checkConnection();

  // Poll connection status every 5 seconds
  final timer = Timer.periodic(const Duration(seconds: 5), (_) {
    checkConnection();
  });

  ref.onDispose(() {
    timer.cancel();
    controller.close();
  });

  return controller.stream;
});
