import 'package:flutter/material.dart';
import 'package:quickfix/core/theme/app_colors.dart';
import 'package:quickfix/core/theme/app_text_styles.dart';
import 'package:quickfix/core/widgets/custom_button.dart';
import 'package:quickfix/core/widgets/spacing.dart';

class CommonErrorWidget extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback? onRetry;
  final String buttonText;
  final IconData icon;

  const CommonErrorWidget({
    super.key,
    this.title = 'Connection Issue',
    this.message = 'We couldn\'t load the details. Please check your internet connection and try again.',
    this.onRetry,
    this.buttonText = 'Try Again',
    this.icon = Icons.wifi_off_rounded,
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
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: AppColors.error,
                size: 40,
              ),
            ),
            AppSpacing.height20,
            Text(
              title,
              style: AppTextStyles.headingMedium(isDark),
              textAlign: TextAlign.center,
            ),
            AppSpacing.height8,
            Text(
              message,
              style: AppTextStyles.bodyMedium(isDark).copyWith(
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              AppSpacing.height24,
              CustomButton(
                text: buttonText,
                onPressed: onRetry,
                isFullWidth: false,
                width: 160,
                height: 44,
                icon: Icons.refresh_rounded,
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
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.surfaceDark
                    : AppColors.backgroundLight,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                ),
              ),
              child: Icon(
                icon,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
                size: 48,
              ),
            ),
            AppSpacing.height20,
            Text(
              title,
              style: AppTextStyles.headingMedium(isDark),
              textAlign: TextAlign.center,
            ),
            AppSpacing.height8,
            Text(
              message,
              style: AppTextStyles.bodyMedium(isDark).copyWith(
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
              textAlign: TextAlign.center,
            ),
            if (onAction != null && actionText != null) ...[
              AppSpacing.height24,
              CustomButton(
                text: actionText!,
                onPressed: onAction,
                isFullWidth: false,
                width: 180,
                height: 44,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
