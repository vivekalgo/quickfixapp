import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quickfix_provider/core/theme/app_colors.dart';

class AppTextStyles {
  static TextStyle headingLarge(bool isDark) => GoogleFonts.inter(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
  );

  static TextStyle headingMedium(bool isDark) => GoogleFonts.inter(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
  );

  static TextStyle headingSmall(bool isDark) => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.bold,
    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
  );

  static TextStyle bodyLarge(bool isDark) => GoogleFonts.inter(
    fontSize: 15,
    fontWeight: FontWeight.normal,
    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
  );

  static TextStyle bodyMedium(bool isDark) => GoogleFonts.inter(
    fontSize: 13.5,
    fontWeight: FontWeight.normal,
    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
  );

  static TextStyle bodySmall(bool isDark) => GoogleFonts.inter(
    fontSize: 11.5,
    fontWeight: FontWeight.normal,
    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
  );

  static TextStyle buttonText = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );

  static TextStyle badgeText = GoogleFonts.inter(
    fontSize: 10,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );
}
