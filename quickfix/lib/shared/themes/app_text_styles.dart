import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quickfix/shared/themes/app_colors.dart';

class AppTextStyles {
  // Headings (using Outfit)
  static TextStyle headingXLarge(bool isDark) => GoogleFonts.outfit(
        fontSize: 28,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.6,
        height: 1.2,
        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
      );

  static TextStyle headingLarge(bool isDark) => GoogleFonts.outfit(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.4,
        height: 1.25,
        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
      );

  static TextStyle headingMedium(bool isDark) => GoogleFonts.outfit(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
        height: 1.3,
        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
      );

  static TextStyle headingSmall(bool isDark) => GoogleFonts.outfit(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.1,
        height: 1.3,
        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
      );

  // Body Text (using Inter)
  static TextStyle bodyLarge(bool isDark) => GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        height: 1.45,
        letterSpacing: 0.1,
        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
      );

  static TextStyle bodyMedium(bool isDark) => GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        height: 1.4,
        letterSpacing: 0.1,
        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
      );

  static TextStyle bodySmall(bool isDark) => GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w400,
        height: 1.35,
        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
      );

  // Buttons & Badges
  static TextStyle buttonText = GoogleFonts.outfit(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.2,
    color: Colors.white,
  );

  static TextStyle badgeText = GoogleFonts.inter(
    fontSize: 10,
    fontWeight: FontWeight.bold,
    letterSpacing: 0.5,
    color: Colors.white,
  );

  // Section label — for small uppercase section tags
  static TextStyle sectionLabel = GoogleFonts.inter(
    fontSize: 10.5,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.0,
    color: AppColors.primary,
  );

  // Caption — smallest readable text
  static TextStyle captionText(bool isDark) => GoogleFonts.inter(
        fontSize: 10,
        fontWeight: FontWeight.w400,
        height: 1.3,
        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
      );

  // Price text — for showing monetary values
  static TextStyle priceText(bool isDark) => GoogleFonts.outfit(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
      );
}
