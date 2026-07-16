import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:quickfix_provider/core/theme/app_colors.dart';
import 'package:quickfix_provider/features/auth/presentation/controllers/auth_provider.dart';
import 'package:quickfix_provider/features/auth/presentation/widgets/password_onboarding_step.dart';
import 'package:quickfix_provider/features/auth/presentation/widgets/contact_onboarding_step.dart';
import 'package:quickfix_provider/features/auth/presentation/widgets/bank_onboarding_step.dart';
import 'package:quickfix_provider/features/auth/presentation/widgets/documents_onboarding_step.dart';

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
        const SnackBar(
          content: Text('Passwords do not match'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    final success = await ref
        .read(authProvider.notifier)
        .changePassword(
          _oldPasswordController.text,
          _newPasswordController.text,
        );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password updated successfully'),
          backgroundColor: AppColors.success,
        ),
      );
      setState(() {
        _currentStep = 1;
      });
    }
  }

  void _submitMobileNumber() {
    if (!_formKeyMobile.currentState!.validate()) return;
    setState(() {
      _mobileVerified = true;
      _currentStep = 2;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Mobile number saved successfully!'),
        backgroundColor: AppColors.success,
      ),
    );
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
    final success = await ref
        .read(authProvider.notifier)
        .updateShopDetails(
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
          if (step > _currentStep &&
              (_currentStep == 0 || (_currentStep == 1 && !_mobileVerified))) {
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
            content: PasswordOnboardingStep(
              isLoading: authState.isLoading,
              oldPasswordController: _oldPasswordController,
              newPasswordController: _newPasswordController,
              confirmPasswordController: _confirmPasswordController,
              formKey: _formKeyPassword,
              onSubmit: _submitPasswordChange,
            ),
          ),
          Step(
            title: const Text('Contact'),
            isActive: _currentStep >= 1,
            state: _currentStep > 1 ? StepState.complete : StepState.editing,
            content: ContactOnboardingStep(
              mobileController: _mobileController,
              formKey: _formKeyMobile,
              onSubmit: _submitMobileNumber,
            ),
          ),
          Step(
            title: const Text('Bank Accounts'),
            isActive: _currentStep >= 2,
            state: _currentStep > 2 ? StepState.complete : StepState.editing,
            content: BankOnboardingStep(
              bankAccountController: _bankAccountController,
              ifscController: _ifscController,
              upiIdController: _upiIdController,
              formKey: _formKeyBank,
              onSubmit: _submitBankDetails,
            ),
          ),
          Step(
            title: const Text('Documents'),
            isActive: _currentStep >= 3,
            state: _currentStep > 3 ? StepState.complete : StepState.editing,
            content: DocumentsOnboardingStep(
              isLoading: authState.isLoading,
              gstController: _gstController,
              panController: _panController,
              formKey: _formKeyDocs,
              onSubmit: _finishOnboarding,
            ),
          ),
        ],
      ),
    );
  }
}
