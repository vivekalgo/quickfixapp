import 'package:flutter/material.dart';
import 'package:quickfix_provider/core/theme/app_colors.dart';
import 'package:quickfix_provider/core/theme/app_text_styles.dart';
import 'package:quickfix_provider/core/utils/validators.dart';

class PasswordOnboardingStep extends StatelessWidget {
  final bool isLoading;
  final TextEditingController oldPasswordController;
  final TextEditingController newPasswordController;
  final TextEditingController confirmPasswordController;
  final GlobalKey<FormState> formKey;
  final VoidCallback onSubmit;

  const PasswordOnboardingStep({
    super.key,
    required this.isLoading,
    required this.oldPasswordController,
    required this.newPasswordController,
    required this.confirmPasswordController,
    required this.formKey,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 12),
          Text(
            'Security Password Change',
            style: AppTextStyles.headingMedium(true),
          ),
          const SizedBox(height: 8),
          Text(
            'You are logging in for the first time. For security reasons, you must change your temporary password.',
            style: AppTextStyles.bodyMedium(true),
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: oldPasswordController,
            style: const TextStyle(color: Colors.white),
            obscureText: true,
            validator: Validators.validatePassword,
            decoration: InputDecoration(
              labelText: 'Temporary/Current Password',
              labelStyle: const TextStyle(color: AppColors.textSecondaryDark),
              filled: true,
              fillColor: AppColors.surfaceDark,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: newPasswordController,
            style: const TextStyle(color: Colors.white),
            obscureText: true,
            validator: Validators.validatePassword,
            decoration: InputDecoration(
              labelText: 'New Password',
              labelStyle: const TextStyle(color: AppColors.textSecondaryDark),
              filled: true,
              fillColor: AppColors.surfaceDark,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: confirmPasswordController,
            style: const TextStyle(color: Colors.white),
            obscureText: true,
            validator: Validators.validatePassword,
            decoration: InputDecoration(
              labelText: 'Confirm New Password',
              labelStyle: const TextStyle(color: AppColors.textSecondaryDark),
              filled: true,
              fillColor: AppColors.surfaceDark,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: isLoading ? null : onSubmit,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    'Update Password & Continue',
                    style: AppTextStyles.buttonText,
                  ),
          ),
        ],
      ),
    );
  }
}
