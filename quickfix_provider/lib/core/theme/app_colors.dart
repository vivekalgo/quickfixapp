import 'package:flutter/material.dart';

class AppColors {
  // Brand color identity (deep royal violet/indigo for service partners)
  static const Color primary = Color(0xFF7C3AED); // Modern Violet Accent
  static const Color secondary = Color(0xFF0F172A); // Deep Slate
  
  static const Color backgroundLight = Color(0xFFF8FAFC);
  static const Color backgroundDark = Color(0xFF0B0F19);
  
  static const Color surfaceLight = Colors.white;
  static const Color surfaceDark = Color(0xFF131B2E);
  
  static const Color borderLight = Color(0xFFE2E8F0);
  static const Color borderDark = Color(0xFF1E293B);
  
  static const Color textPrimaryLight = Color(0xFF0F172A);
  static const Color textPrimaryDark = Color(0xFFF8FAFC);
  static const Color textSecondaryLight = Color(0xFF64748B);
  static const Color textSecondaryDark = Color(0xFF94A3B8);
  
  static const Color success = Color(0xFF10B981);
  static const Color info = Color(0xFF0EA5E9);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFEF4444);

  // Gradient definitions for premium look
  static const LinearGradient plusGradient = LinearGradient(
    colors: [Color(0xFF7C3AED), Color(0xFF5B21B6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient activeGradient = LinearGradient(
    colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
