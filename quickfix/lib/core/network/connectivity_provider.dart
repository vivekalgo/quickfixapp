import 'dart:async';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final connectivityProvider = StreamProvider<bool>((ref) {
  final controller = StreamController<bool>();
  bool? lastStatus;
  int consecutiveFailures = 0;

  Future<void> checkConnection({bool isInitial = false}) async {
    bool isConnected = false;
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 2));
      isConnected = result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      isConnected = false;
    }

    if (isConnected) {
      consecutiveFailures = 0;
      if (lastStatus != true) {
        lastStatus = true;
        if (!controller.isClosed) controller.add(true);
      }
    } else {
      consecutiveFailures++;
      // Emit offline immediately on initial boot or after 2 failures during polling
      if ((isInitial || consecutiveFailures >= 2) && lastStatus != false) {
        lastStatus = false;
        if (!controller.isClosed) controller.add(false);
      }
    }
  }

  // Initial check
  checkConnection(isInitial: true);

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

