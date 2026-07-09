import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/validators.dart';
import '../providers/auth_provider.dart';

class FirstLoginScreen extends ConsumerStatefulWidget {
  const FirstLoginScreen({super.key});

  @override
  ConsumerState<FirstLoginScreen> createState() => _FirstLoginScreenState();
}

class _FirstLoginScreenState extends ConsumerState<FirstLoginScreen> {
  int _currentStep = 0;
  final _formKeyPassword = GlobalKey<FormState>();
  final _formKeyMobile = GlobalKey<FormState>();
  final _formKeyBank = GlobalKey<FormState>();
  final _formKeyDocs = GlobalKey<FormState>();

  // Step 1 Controllers
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Step 2 Controllers
  final _mobileController = TextEditingController();
  final _otpController = TextEditingController();
  bool _otpSent = false;
  bool _mobileVerified = false;

  // Step 3 Controllers
  final _bankAccountController = TextEditingController();
  final _ifscController = TextEditingController();
  final _upiIdController = TextEditingController();

  // Step 4 Controllers
  final _gstController = TextEditingController();
  final _panController = TextEditingController();

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _mobileController.dispose();
    _otpController.dispose();
    _bankAccountController.dispose();
    _ifscController.dispose();
    _upiIdController.dispose();
    _gstController.dispose();
    _panController.dispose();
    super.dispose();
  }

  Future<void> _submitPasswordChange() async {
    if (!_formKeyPassword.currentState!.validate()) return;

    if (_newPasswordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match'), backgroundColor: AppColors.danger),
      );
      return;
    }

    final success = await ref.read(authProvider.notifier).changePassword(
      _oldPasswordController.text,
      _newPasswordController.text,
    );

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password updated successfully'), backgroundColor: AppColors.success),
      );
      setState(() {
        _currentStep = 1;
      });
    }
  }

  void _sendOtp() {
    if (!_formKeyMobile.currentState!.validate()) return;
    setState(() {
      _otpSent = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Simulated OTP code "123456" sent successfully!'), backgroundColor: AppColors.info),
    );
  }

  void _verifyOtp() {
    if (_otpController.text.trim() == '123456') {
      setState(() {
        _mobileVerified = true;
        _currentStep = 2;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mobile number verified successfully!'), backgroundColor: AppColors.success),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid OTP code. Enter 123456'), backgroundColor: AppColors.danger),
      );
    }
  }

  Future<void> _submitBankDetails() async {
    if (!_formKeyBank.currentState!.validate()) return;
    setState(() {
      _currentStep = 3;
    });
  }

  Future<void> _finishOnboarding() async {
    if (!_formKeyDocs.currentState!.validate()) return;

    // Call update hours to store details and finish first login
    final success = await ref.read(authProvider.notifier).updateShopDetails(
      bankAccountNumber: _bankAccountController.text.trim(),
      ifscCode: _ifscController.text.trim().toUpperCase(),
      upiId: _upiIdController.text.trim().toLowerCase(),
      gst: _gstController.text.trim().toUpperCase(),
      pan: _panController.text.trim().toUpperCase(),
      ownerPhone: _mobileController.text.trim(),
      isFirstLogin: false, // Mark first login complete
    );

    if (success && mounted) {
      context.go('/main');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: const Text('Partner Onboarding'),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: Stepper(
        type: StepperType.horizontal,
        currentStep: _currentStep,
        onStepTapped: (step) {
          // Prevent skipping steps before password and mobile are verified
          if (step > _currentStep && (_currentStep == 0 || (_currentStep == 1 && !_mobileVerified))) {
            return;
          }
          setState(() {
            _currentStep = step;
          });
        },
        controlsBuilder: (context, details) {
          return const SizedBox.shrink(); // Custom buttons inside step widgets
        },
        steps: [
          Step(
            title: const Text('Password'),
            isActive: _currentStep >= 0,
            state: _currentStep > 0 ? StepState.complete : StepState.editing,
            content: _buildPasswordStep(authState.isLoading),
          ),
          Step(
            title: const Text('Contact'),
            isActive: _currentStep >= 1,
            state: _currentStep > 1 ? StepState.complete : StepState.editing,
            content: _buildContactStep(),
          ),
          Step(
            title: const Text('Bank Accounts'),
            isActive: _currentStep >= 2,
            state: _currentStep > 2 ? StepState.complete : StepState.editing,
            content: _buildBankStep(),
          ),
          Step(
            title: const Text('Documents'),
            isActive: _currentStep >= 3,
            state: _currentStep > 3 ? StepState.complete : StepState.editing,
            content: _buildDocsStep(authState.isLoading),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordStep(bool isLoading) {
    return Form(
      key: _formKeyPassword,
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
            controller: _oldPasswordController,
            style: const TextStyle(color: Colors.white),
            obscureText: true,
            validator: Validators.validatePassword,
            decoration: InputDecoration(
              labelText: 'Temporary/Current Password',
              labelStyle: const TextStyle(color: AppColors.textSecondaryDark),
              filled: true,
              fillColor: AppColors.surfaceDark,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _newPasswordController,
            style: const TextStyle(color: Colors.white),
            obscureText: true,
            validator: Validators.validatePassword,
            decoration: InputDecoration(
              labelText: 'New Password',
              labelStyle: const TextStyle(color: AppColors.textSecondaryDark),
              filled: true,
              fillColor: AppColors.surfaceDark,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _confirmPasswordController,
            style: const TextStyle(color: Colors.white),
            obscureText: true,
            validator: Validators.validatePassword,
            decoration: InputDecoration(
              labelText: 'Confirm New Password',
              labelStyle: const TextStyle(color: AppColors.textSecondaryDark),
              filled: true,
              fillColor: AppColors.surfaceDark,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: isLoading ? null : _submitPasswordChange,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: isLoading
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Text('Update Password & Continue', style: AppTextStyles.buttonText),
          ),
        ],
      ),
    );
  }

  Widget _buildContactStep() {
    return Form(
      key: _formKeyMobile,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 12),
          Text('Verify Contact Number', style: AppTextStyles.headingMedium(true)),
          const SizedBox(height: 8),
          Text('Enter your primary mobile number. We will send a confirmation OTP code.', style: AppTextStyles.bodyMedium(true)),
          const SizedBox(height: 24),
          TextFormField(
            controller: _mobileController,
            style: const TextStyle(color: Colors.white),
            keyboardType: TextInputType.phone,
            validator: Validators.validatePhone,
            enabled: !_otpSent,
            decoration: InputDecoration(
              labelText: 'Mobile Number',
              labelStyle: const TextStyle(color: AppColors.textSecondaryDark),
              prefixText: '+91 ',
              prefixStyle: const TextStyle(color: Colors.white),
              filled: true,
              fillColor: AppColors.surfaceDark,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          if (_otpSent) ...[
            const SizedBox(height: 16),
            TextFormField(
              controller: _otpController,
              style: const TextStyle(color: Colors.white),
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Enter OTP (Simulated: 123456)',
                labelStyle: const TextStyle(color: AppColors.textSecondaryDark),
                filled: true,
                fillColor: AppColors.surfaceDark,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
          const SizedBox(height: 32),
          if (!_otpSent)
            ElevatedButton(
              onPressed: _sendOtp,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text('Send Verification OTP', style: AppTextStyles.buttonText),
            )
          else
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => setState(() => _otpSent = false),
                    child: const Text('Change Number', style: TextStyle(color: AppColors.primary)),
                  ),
                ),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _verifyOtp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('Verify OTP', style: AppTextStyles.buttonText),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildBankStep() {
    return Form(
      key: _formKeyBank,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 12),
          Text('Bank Settlement Details', style: AppTextStyles.headingMedium(true)),
          const SizedBox(height: 8),
          Text('Enter details of the bank account where payouts and bookings payments should be settled.', style: AppTextStyles.bodyMedium(true)),
          const SizedBox(height: 24),
          TextFormField(
            controller: _bankAccountController,
            style: const TextStyle(color: Colors.white),
            keyboardType: TextInputType.number,
            validator: (val) => val == null || val.trim().isEmpty ? 'Account number required' : null,
            decoration: InputDecoration(
              labelText: 'Bank Account Number',
              labelStyle: const TextStyle(color: AppColors.textSecondaryDark),
              filled: true,
              fillColor: AppColors.surfaceDark,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _ifscController,
            style: const TextStyle(color: Colors.white),
            textCapitalization: TextCapitalization.characters,
            validator: (val) => val == null || val.trim().length < 5 ? 'Valid IFSC code required' : null,
            decoration: InputDecoration(
              labelText: 'IFSC Code',
              labelStyle: const TextStyle(color: AppColors.textSecondaryDark),
              filled: true,
              fillColor: AppColors.surfaceDark,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _upiIdController,
            style: const TextStyle(color: Colors.white),
            validator: (val) => val == null || !val.contains('@') ? 'Valid UPI ID required (e.g. name@upi)' : null,
            decoration: InputDecoration(
              labelText: 'UPI ID (For Instant Settling)',
              labelStyle: const TextStyle(color: AppColors.textSecondaryDark),
              filled: true,
              fillColor: AppColors.surfaceDark,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _submitBankDetails,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Save & Continue', style: AppTextStyles.buttonText),
          ),
        ],
      ),
    );
  }

  Widget _buildDocsStep(bool isLoading) {
    return Form(
      key: _formKeyDocs,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 12),
          Text('GST & PAN Documents', style: AppTextStyles.headingMedium(true)),
          const SizedBox(height: 8),
          Text('Submit your identification numbers to verify shop registration compliance.', style: AppTextStyles.bodyMedium(true)),
          const SizedBox(height: 24),
          TextFormField(
            controller: _gstController,
            style: const TextStyle(color: Colors.white),
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(
              labelText: 'GSTIN Number (Optional)',
              labelStyle: const TextStyle(color: AppColors.textSecondaryDark),
              filled: true,
              fillColor: AppColors.surfaceDark,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _panController,
            style: const TextStyle(color: Colors.white),
            textCapitalization: TextCapitalization.characters,
            validator: (val) => val == null || val.trim().length != 10 ? 'Valid 10-digit PAN ID required' : null,
            decoration: InputDecoration(
              labelText: 'PAN Card Number',
              labelStyle: const TextStyle(color: AppColors.textSecondaryDark),
              filled: true,
              fillColor: AppColors.surfaceDark,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: isLoading ? null : _finishOnboarding,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: isLoading
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Text('Complete Onboarding', style: AppTextStyles.buttonText),
          ),
        ],
      ),
    );
  }
}
