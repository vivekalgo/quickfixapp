import 'package:flutter/material.dart';
import 'package:quickfix_provider/core/theme/app_colors.dart';
import 'package:quickfix_provider/core/theme/app_text_styles.dart';
import 'package:quickfix_provider/core/utils/validators.dart';

class ContactOnboardingStep extends StatelessWidget {
  final TextEditingController mobileController;
  final GlobalKey<FormState> formKey;
  final VoidCallback onSubmit;

  const ContactOnboardingStep({
    super.key,
    required this.mobileController,
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
          Text('Contact Number', style: AppTextStyles.headingMedium(true)),
          const SizedBox(height: 8),
          Text(
            'Enter your primary contact mobile number to be associated with this shop.',
            style: AppTextStyles.bodyMedium(true),
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: mobileController,
            style: const TextStyle(color: Colors.white),
            keyboardType: TextInputType.phone,
            validator: Validators.validatePhone,
            decoration: InputDecoration(
              labelText: 'Mobile Number',
              labelStyle: const TextStyle(color: AppColors.textSecondaryDark),
              prefixText: '+91 ',
              prefixStyle: const TextStyle(color: Colors.white),
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
