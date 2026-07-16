import 'package:flutter/material.dart';
import 'package:quickfix/core/theme/app_colors.dart';
import 'package:quickfix/core/theme/app_text_styles.dart';
import 'package:quickfix/core/widgets/custom_button.dart';
import 'package:quickfix/core/widgets/spacing.dart';

class CommonErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final String buttonText;

  const CommonErrorWidget({
    super.key,
    this.message = 'Something went wrong. Please try again.',
    this.onRetry,
    this.buttonText = 'Retry',
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: AppSpacing.all24,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: AppColors.error,
              size: 48,
            ),
            AppSpacing.height16,
            Text(
              'Oops!',
              style: AppTextStyles.headingMedium(isDark),
              textAlign: TextAlign.center,
            ),
            AppSpacing.height8,
            Text(
              message,
              style: AppTextStyles.bodyMedium(isDark),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              AppSpacing.height24,
              CustomButton(
                text: buttonText,
                onPressed: onRetry,
                isFullWidth: false,
                width: 140,
                height: 40,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class EmptyStateWidget extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;
  final VoidCallback? onAction;
  final String? actionText;

  const EmptyStateWidget({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.inbox_outlined,
    this.onAction,
    this.actionText,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: AppSpacing.all24,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
              size: 64,
            ),
            AppSpacing.height16,
            Text(
              title,
              style: AppTextStyles.headingMedium(isDark),
              textAlign: TextAlign.center,
            ),
            AppSpacing.height8,
            Text(
              message,
              style: AppTextStyles.bodyMedium(isDark),
              textAlign: TextAlign.center,
            ),
            if (onAction != null && actionText != null) ...[
              AppSpacing.height24,
              CustomButton(
                text: actionText!,
                onPressed: onAction,
                isFullWidth: false,
                width: 160,
                height: 40,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
