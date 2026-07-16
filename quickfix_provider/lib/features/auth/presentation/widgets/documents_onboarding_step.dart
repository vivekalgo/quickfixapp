import 'package:flutter/material.dart';
import 'package:quickfix_provider/core/theme/app_colors.dart';
import 'package:quickfix_provider/core/theme/app_text_styles.dart';

class DocumentsOnboardingStep extends StatelessWidget {
  final bool isLoading;
  final TextEditingController gstController;
  final TextEditingController panController;
  final GlobalKey<FormState> formKey;
  final VoidCallback onSubmit;

  const DocumentsOnboardingStep({
    super.key,
    required this.isLoading,
    required this.gstController,
    required this.panController,
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
          Text('GST & PAN Documents', style: AppTextStyles.headingMedium(true)),
          const SizedBox(height: 8),
          Text(
            'Submit your identification numbers to verify shop registration compliance.',
            style: AppTextStyles.bodyMedium(true),
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: gstController,
            style: const TextStyle(color: Colors.white),
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(
              labelText: 'GSTIN Number (Optional)',
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
            controller: panController,
            style: const TextStyle(color: Colors.white),
            textCapitalization: TextCapitalization.characters,
            validator: (val) => val == null || val.trim().length != 10
                ? 'Valid 10-digit PAN ID required'
                : null,
            decoration: InputDecoration(
              labelText: 'PAN Card Number',
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
                : Text('Complete Onboarding', style: AppTextStyles.buttonText),
          ),
        ],
      ),
    );
  }
}
