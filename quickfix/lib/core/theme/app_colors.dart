import 'package:flutter/material.dart';

class AppColors {
  // Urban Company Signature Brand Palette
  static const Color primary = Color(0xFF0F172A); // Deep Urban Slate / Onyx
  static const Color primaryAccent = Color(0xFF6E42E5); // Signature Urban Purple/Indigo Accent
  static const Color secondary = Color(0xFF0F172A); // Deep Slate secondary
  static const Color actionRed = Color(0xFFFF4E36); // Vibrant Coral Red (CTA accent)
  static const Color accentGold = Color(0xFFFFB800); // Premium Star Rating Gold
  static const Color accent = Color(0xFFFFB800); // Rating Gold Alias

  // Neutral Colors (Light Theme)
  static const Color backgroundLight = Color(0xFFF8FAFC); // Clean Canvas Background
  static const Color surfaceLight = Color(0xFFFFFFFF); // Pure Crisp White Surface
  static const Color textPrimaryLight = Color(0xFF0F172A); // High-contrast Onyx Text
  static const Color textSecondaryLight = Color(0xFF64748B); // Slate Muted Subtitle
  static const Color borderLight = Color(0xFFE2E8F0); // Elegant 1px Card Border
  static const Color dividerLight = Color(0xFFF1F5F9);

  // Neutral Colors (Dark Theme)
  static const Color backgroundDark = Color(0xFF090D16); // Obsidian Dark Background
  static const Color surfaceDark = Color(0xFF131B2E); // Elevated Dark Card
  static const Color textPrimaryDark = Color(0xFFF8FAFC);
  static const Color textSecondaryDark = Color(0xFF94A3B8);
  static const Color borderDark = Color(0xFF1E293B);
  static const Color dividerDark = Color(0xFF1E293B);

  // Category & Badge Colors (Urban Company Soft Pastel Tones)
  static const Color catCleaning = Color(0xFFF0F3FF);
  static const Color catCleaningIcon = Color(0xFF6E42E5);

  static const Color catPlumbing = Color(0xFFECFDF5);
  static const Color catPlumbingIcon = Color(0xFF059669);

  static const Color catElectrician = Color(0xFFFFFBEB);
  static const Color catElectricianIcon = Color(0xFFD97706);

  static const Color catAppliances = Color(0xFFF5F3FF);
  static const Color catAppliancesIcon = Color(0xFF7C3AED);

  static const Color catCarpentry = Color(0xFFFFF7ED);
  static const Color catCarpentryIcon = Color(0xFFEA580C);

  static const Color catMore = Color(0xFFF1F5F9);
  static const Color catMoreIcon = Color(0xFF475569);

  // Semantic Feedback Colors
  static const Color success = Color(0xFF10B981); // Verified Green
  static const Color warning = Color(0xFFF59E0B); // Amber Warning
  static const Color error = Color(0xFFEF4444); // Crimson Error
  static const Color info = Color(0xFF3B82F6); // Info Blue

  // Premium Gradients
  static const Gradient primaryGradient = LinearGradient(
    colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const Gradient accentGradient = LinearGradient(
    colors: [Color(0xFF6E42E5), Color(0xFF8B5CF6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const Gradient actionGradient = LinearGradient(
    colors: [Color(0xFFFF4E36), Color(0xFFFF6F5C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const Gradient plusGradient = LinearGradient(
    colors: [Color(0xFF6E42E5), Color(0xFF4F46E5)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const Gradient goldGradient = LinearGradient(
    colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const Gradient cardOverlayGradient = LinearGradient(
    colors: [Colors.black87, Colors.transparent],
    begin: Alignment.bottomCenter,
    end: Alignment.topCenter,
  );
}

