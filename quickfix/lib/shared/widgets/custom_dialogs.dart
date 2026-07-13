import 'package:flutter/material.dart';
import 'package:quickfix/shared/themes/app_colors.dart';
import 'package:quickfix/shared/themes/app_text_styles.dart';
import 'package:quickfix/shared/widgets/custom_button.dart';

class CustomDialogs {
  static Future<T?> showConfirmationDialog<T>({
    required BuildContext context,
    required String title,
    required String message,
    String confirmLabel = 'Confirm',
    String cancelLabel = 'Cancel',
    bool isDestructive = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return showDialog<T>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          title,
          style: AppTextStyles.headingMedium(isDark),
        ),
        content: Text(
          message,
          style: AppTextStyles.bodyMedium(isDark),
        ),
        actionsPadding: const EdgeInsets.only(bottom: 16, right: 16, left: 16),
        actions: [
          Row(
            children: [
              Expanded(
                child: CustomButton(
                  text: cancelLabel,
                  type: CustomButtonType.outlined,
                  onPressed: () => Navigator.of(context).pop(false),
                  height: 44,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CustomButton(
                  text: confirmLabel,
                  backgroundColor: isDestructive ? AppColors.error : AppColors.primary,
                  onPressed: () => Navigator.of(context).pop(true),
                  height: 44,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static Future<T?> showAlertDialog<T>({
    required BuildContext context,
    required String title,
    required String message,
    String buttonLabel = 'OK',
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return showDialog<T>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          title,
          style: AppTextStyles.headingMedium(isDark),
        ),
        content: Text(
          message,
          style: AppTextStyles.bodyMedium(isDark),
        ),
        actions: [
          CustomButton(
            text: buttonLabel,
            onPressed: () => Navigator.of(context).pop(),
            isFullWidth: false,
            height: 40,
          ),
        ],
      ),
    );
  }
}
