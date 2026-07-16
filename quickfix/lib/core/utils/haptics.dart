import 'package:flutter/services.dart';

class AppHaptics {
  static void lightTap() {
    HapticFeedback.lightImpact();
  }

  static void mediumTap() {
    HapticFeedback.mediumImpact();
  }

  static void heavyTap() {
    HapticFeedback.heavyImpact();
  }

  static void selectionClick() {
    HapticFeedback.selectionClick();
  }

  static void successNotification() {
    HapticFeedback.vibrate();
  }
}
