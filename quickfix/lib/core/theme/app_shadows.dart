import 'package:flutter/material.dart';

/// Unified Urban Company & Zomato style shadow system.
class AppShadows {
  AppShadows._();

  /// Soft Urban Company card elevation
  static List<BoxShadow> card = [
    BoxShadow(
      color: const Color(0xFF0F172A).withValues(alpha: 0.05),
      blurRadius: 16,
      spreadRadius: 0,
      offset: const Offset(0, 4),
    ),
  ];

  /// Urban Floating Shadow (used for search bar, floating bottom bar, toasts)
  static List<BoxShadow> floating = [
    BoxShadow(
      color: const Color(0xFF0F172A).withValues(alpha: 0.08),
      blurRadius: 24,
      spreadRadius: 0,
      offset: const Offset(0, 8),
    ),
  ];

  /// Elevated Hero Card Shadow
  static List<BoxShadow> elevated = [
    BoxShadow(
      color: const Color(0xFF0F172A).withValues(alpha: 0.12),
      blurRadius: 28,
      spreadRadius: 0,
      offset: const Offset(0, 10),
    ),
  ];

  /// Pinned Header Shadow
  static List<BoxShadow> header = [
    BoxShadow(
      color: const Color(0xFF0F172A).withValues(alpha: 0.04),
      blurRadius: 10,
      offset: const Offset(0, 2),
    ),
  ];

  /// Primary Slate Button Shadow
  static List<BoxShadow> primaryButton = [
    BoxShadow(
      color: const Color(0xFF0F172A).withValues(alpha: 0.20),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  /// Red CTA Action Button Shadow (Zomato style)
  static List<BoxShadow> actionButton = [
    BoxShadow(
      color: const Color(0xFFFF4E36).withValues(alpha: 0.25),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  /// Inline Chip / Category Pill Shadow
  static List<BoxShadow> chip = [
    BoxShadow(
      color: const Color(0xFF0F172A).withValues(alpha: 0.03),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];
}
