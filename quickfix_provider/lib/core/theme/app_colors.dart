import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF9d4edd); // Purple accent
  static const Color secondary = Color(0xFF1e293b); // Slate blue
  static const Color backgroundLight = Color(0xFFf8fafc);
  static const Color backgroundDark = Color(0xFF0b0f19);
  
  static const Color surfaceLight = Colors.white;
  static const Color surfaceDark = Color(0xFF131b2e);
  
  static const Color borderLight = Color(0xFFe2e8f0);
  static const Color borderDark = Color(0xFF1e293b);
  
  static const Color textPrimaryLight = Color(0xFF0f172a);
  static const Color textPrimaryDark = Color(0xFFf8fafc);
  static const Color textSecondaryLight = Color(0xFF64748b);
  static const Color textSecondaryDark = Color(0xFF94a3b8);
  
  static const Color success = Color(0xFF10b981);
  static const Color info = Color(0xFF06b6d4);
  static const Color warning = Color(0xFFf59e0b);
  static const Color danger = Color(0xFFef4444);

  static const LinearGradient plusGradient = LinearGradient(
    colors: [Color(0xFF9d4edd), Color(0xFF7b2cbf)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
