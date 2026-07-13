import 'package:flutter/material.dart';

/// Unified shadow system for the entire app.
/// Use these instead of inline BoxShadow definitions to maintain consistency.
class AppShadows {
  AppShadows._();

  /// Soft card elevation — used on all content cards
  static List<BoxShadow> card = [
    BoxShadow(
      color: const Color(0xFF000000).withValues(alpha: 0.06),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  /// Elevated card — used on banners and hero cards
  static List<BoxShadow> elevated = [
    BoxShadow(
      color: const Color(0xFF000000).withValues(alpha: 0.10),
      blurRadius: 20,
      offset: const Offset(0, 6),
    ),
  ];

  /// Pinned header shadow
  static List<BoxShadow> header = [
    BoxShadow(
      color: const Color(0xFF000000).withValues(alpha: 0.08),
      blurRadius: 12,
      offset: const Offset(0, 3),
    ),
  ];

  /// Button/fab shadow tinted with brand color
  static List<BoxShadow> primaryButton = [
    BoxShadow(
      color: const Color(0xFFFF4E36).withValues(alpha: 0.30),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  /// Inline/chip style shadow
  static List<BoxShadow> chip = [
    BoxShadow(
      color: const Color(0xFF000000).withValues(alpha: 0.04),
      blurRadius: 6,
      offset: const Offset(0, 2),
    ),
  ];
}
