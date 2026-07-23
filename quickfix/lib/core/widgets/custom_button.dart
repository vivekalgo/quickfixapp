import 'package:flutter/material.dart';
import 'package:quickfix/core/theme/app_colors.dart';
import 'package:quickfix/core/theme/app_text_styles.dart';

enum CustomButtonType { primary, secondary, actionRed, outlined, text }

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final CustomButtonType type;
  final bool isLoading;
  final bool isFullWidth;
  final double height;
  final double? width;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? textColor;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.type = CustomButtonType.primary,
    this.isLoading = false,
    this.isFullWidth = true,
    this.height = 50,
    this.width,
    this.icon,
    this.backgroundColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Color buttonColor;
    Color contentColor;
    BorderSide borderSide = BorderSide.none;

    switch (type) {
      case CustomButtonType.primary:
        buttonColor = backgroundColor ?? AppColors.primary;
        contentColor = textColor ?? Colors.white;
        break;
      case CustomButtonType.actionRed:
        buttonColor = backgroundColor ?? AppColors.actionRed;
        contentColor = textColor ?? Colors.white;
        break;
      case CustomButtonType.secondary:
        buttonColor =
            backgroundColor ??
            (isDark ? AppColors.surfaceDark : AppColors.primaryAccent);
        contentColor = textColor ?? Colors.white;
        break;
      case CustomButtonType.outlined:
        buttonColor = Colors.transparent;
        contentColor =
            textColor ?? (isDark ? Colors.white : AppColors.textPrimaryLight);
        borderSide = BorderSide(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
          width: 1.5,
        );
        break;
      case CustomButtonType.text:
        buttonColor = Colors.transparent;
        contentColor = textColor ?? AppColors.primaryAccent;
        break;
    }

    final buttonStyle = ElevatedButton.styleFrom(
      backgroundColor: buttonColor,
      foregroundColor: contentColor,
      elevation: type == CustomButtonType.primary || type == CustomButtonType.actionRed ? 0 : 0,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: borderSide,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 18),
    );

    Widget child = isLoading
        ? SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(contentColor),
            ),
          )
        : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: contentColor),
                const SizedBox(width: 8),
              ],
              Text(
                text,
                style: AppTextStyles.buttonText.copyWith(color: contentColor),
              ),
            ],
          );

    return SizedBox(
      height: height,
      width: isFullWidth ? double.infinity : width,
      child: type == CustomButtonType.text || type == CustomButtonType.outlined
          ? TextButton(
              onPressed: isLoading ? null : onPressed,
              style: buttonStyle,
              child: child,
            )
          : ElevatedButton(
              onPressed: isLoading ? null : onPressed,
              style: buttonStyle,
              child: child,
            ),
    );
  }
}
