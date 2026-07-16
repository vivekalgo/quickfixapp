import 'package:flutter/material.dart';
import 'package:quickfix_provider/core/theme/app_colors.dart';
import 'package:quickfix_provider/core/theme/app_text_styles.dart';

class BankOnboardingStep extends StatelessWidget {
  final TextEditingController bankAccountController;
  final TextEditingController ifscController;
  final TextEditingController upiIdController;
  final GlobalKey<FormState> formKey;
  final VoidCallback onSubmit;

  const BankOnboardingStep({
    super.key,
    required this.bankAccountController,
    required this.ifscController,
    required this.upiIdController,
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
            'Bank Settlement Details',
            style: AppTextStyles.headingMedium(true),
          ),
          const SizedBox(height: 8),
          Text(
            'Enter details of the bank account where payouts and bookings payments should be settled.',
            style: AppTextStyles.bodyMedium(true),
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: bankAccountController,
            style: const TextStyle(color: Colors.white),
            keyboardType: TextInputType.number,
            validator: (val) => val == null || val.trim().isEmpty
                ? 'Account number required'
                : null,
            decoration: InputDecoration(
              labelText: 'Bank Account Number',
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
            controller: ifscController,
            style: const TextStyle(color: Colors.white),
            textCapitalization: TextCapitalization.characters,
            validator: (val) => val == null || val.trim().length < 5
                ? 'Valid IFSC code required'
                : null,
            decoration: InputDecoration(
              labelText: 'IFSC Code',
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
            controller: upiIdController,
            style: const TextStyle(color: Colors.white),
            validator: (val) => val == null || !val.contains('@')
                ? 'Valid UPI ID required (e.g. name@upi)'
                : null,
            decoration: InputDecoration(
              labelText: 'UPI ID (For Instant Settling)',
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
            onPressed: onSubmit,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text('Save & Continue', style: AppTextStyles.buttonText),
          ),
        ],
      ),
    );
  }
}
