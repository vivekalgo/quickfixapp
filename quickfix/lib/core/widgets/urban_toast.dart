import 'package:flutter/material.dart';
import 'package:quickfix/core/theme/app_colors.dart';
import 'package:quickfix/core/theme/app_shadows.dart';

enum ToastType { success, error, warning, info }

class UrbanToast {
  UrbanToast._();

  static void show(
    BuildContext context, {
    required String message,
    String? title,
    ToastType type = ToastType.info,
    Duration duration = const Duration(seconds: 3),
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    IconData icon;
    Color iconColor;
    Color borderColor;

    switch (type) {
      case ToastType.success:
        icon = Icons.check_circle_rounded;
        iconColor = AppColors.success;
        borderColor = AppColors.success.withValues(alpha: 0.3);
        break;
      case ToastType.error:
        icon = Icons.error_rounded;
        iconColor = AppColors.error;
        borderColor = AppColors.error.withValues(alpha: 0.3);
        break;
      case ToastType.warning:
        icon = Icons.warning_rounded;
        iconColor = AppColors.warning;
        borderColor = AppColors.warning.withValues(alpha: 0.3);
        break;
      case ToastType.info:
        icon = Icons.info_rounded;
        iconColor = AppColors.primaryAccent;
        borderColor = AppColors.primaryAccent.withValues(alpha: 0.3);
        break;
    }

    final snackBar = SnackBar(
      elevation: 0,
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.transparent,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      padding: EdgeInsets.zero,
      duration: duration,
      content: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppColors.borderDark : borderColor,
            width: 1,
          ),
          boxShadow: AppShadows.floating,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (title != null && title.isNotEmpty) ...[
                    Text(
                      title,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimaryLight,
                      ),
                    ),
                    const SizedBox(height: 2),
                  ],
                  Text(
                    message,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w400,
                      fontSize: 13,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(snackBar);
  }

  static void showSuccess(BuildContext context, String message, {String? title}) {
    show(context, message: message, title: title ?? 'Success', type: ToastType.success);
  }

  static void showError(BuildContext context, String message, {String? title}) {
    show(context, message: message, title: title ?? 'Error', type: ToastType.error);
  }

  static void showWarning(BuildContext context, String message, {String? title}) {
    show(context, message: message, title: title ?? 'Notice', type: ToastType.warning);
  }

  static void showInfo(BuildContext context, String message, {String? title}) {
    show(context, message: message, title: title, type: ToastType.info);
  }
}
