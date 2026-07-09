import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTextStyles {
  static TextStyle headingLarge(bool isDark) => TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
  );

  static TextStyle headingMedium(bool isDark) => TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
  );

  static TextStyle headingSmall(bool isDark) => TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.bold,
    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
  );

  static TextStyle bodyLarge(bool isDark) => TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.normal,
    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
  );

  static TextStyle bodyMedium(bool isDark) => TextStyle(
    fontSize: 13.5,
    fontWeight: FontWeight.normal,
    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
  );

  static TextStyle bodySmall(bool isDark) => TextStyle(
    fontSize: 11.5,
    fontWeight: FontWeight.normal,
    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
  );

  static const TextStyle buttonText = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );

  static const TextStyle badgeText = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );
}
