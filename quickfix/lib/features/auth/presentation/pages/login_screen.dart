import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:quickfix/core/storage/hive_service.dart';
import 'package:quickfix/core/theme/app_colors.dart';
import 'package:quickfix/core/theme/app_text_styles.dart';
import 'package:quickfix/core/utils/haptics.dart';
import 'package:quickfix/features/home/presentation/controllers/home_providers.dart';
import 'package:quickfix/features/auth/presentation/controllers/auth_providers.dart';
import 'package:quickfix/core/utils/input_sanitizer.dart';
import 'package:quickfix/core/network/error_handler.dart';
import 'package:quickfix/core/config/app_config.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();

  bool _isOtpSent = false;
  bool _isLoading = false;
  int _timerCount = 30;
  String? _verificationId;

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  void _startTimer() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      setState(() {
        if (_timerCount > 0) {
          _timerCount--;
        }
      });
      return _timerCount > 0;
    });
  }

  void _sendOtp() async {
    final phone = _phoneController.text.trim();
    if (!InputSanitizer.isValidPhone(phone)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid 10-digit phone number'),
        ),
      );
      return;
    }

    AppHaptics.heavyTap();
    setState(() {
      _isLoading = true;
    });

    try {
      // First, trigger our backend OTP logging for reference/fallback if configured
      try {
        final repository = ref.read(authRepositoryProvider);
        await repository.requestOtp(phone);
      } catch (e) {
        debugPrint('Backend OTP notification failed: $e');
      }

      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: '+91$phone',
        verificationCompleted: (PhoneAuthCredential credential) async {
          if (!mounted) return;
          _otpController.text = credential.smsCode ?? '';
          if (_otpController.text.isNotEmpty) {
            _verifyOtpWithCredential(credential);
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          if (!mounted) return;
          
          if (!AppConfig.isProduction) {
            debugPrint('Firebase phone verification failed: ${e.message}. Using development mock OTP fallback.');
            setState(() {
              _verificationId = 'mock-verification-id-$phone';
              _isLoading = false;
              _isOtpSent = true;
              _timerCount = 30;
            });
            _startTimer();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Firebase failed. Switched to Mock OTP (use 123456) for local development.'),
              ),
            );
            return;
          }

          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Verification failed: ${e.message ?? e.toString()}',
              ),
            ),
          );
        },
        codeSent: (String verificationId, int? resendToken) {
          if (!mounted) return;
          setState(() {
            _verificationId = verificationId;
            _isLoading = false;
            _isOtpSent = true;
            _timerCount = 30;
          });
          _startTimer();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Verification OTP code sent to your phone number.'),
            ),
          );
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          if (mounted) {
            _verificationId = verificationId;
          }
        },
        timeout: const Duration(seconds: 60),
      );
    } catch (e) {
      if (mounted) {
        if (!AppConfig.isProduction) {
          debugPrint('Firebase phone verification initiation failed: $e. Using dev mock OTP fallback.');
          setState(() {
            _verificationId = 'mock-verification-id-$phone';
            _isLoading = false;
            _isOtpSent = true;
            _timerCount = 30;
          });
          _startTimer();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Firebase failed. Switched to Mock OTP (use 123456) for local development.'),
            ),
          );
          return;
        }

        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to initialize verification: ${e.toString()}'),
          ),
        );
      }
    }
  }

  void _verifyOtp() async {
    final otp = _otpController.text.trim();
    if (!InputSanitizer.isValidOtp(otp)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid 6-digit OTP code')),
      );
      return;
    }

    AppHaptics.heavyTap();
    setState(() {
      _isLoading = true;
    });

    try {
      if (_verificationId == null) {
        throw Exception(
          "Verification session expired. Please request OTP again.",
        );
      }

      // Check if it's a mock session in development
      if (_verificationId!.startsWith('mock-verification-id-')) {
        if (otp != '123456') {
          throw Exception("Invalid OTP code. Please enter '123456'.");
        }
        final phone = _phoneController.text.trim();
        final mockToken = 'mock-firebase-token-for-$phone';
        
        await ref
            .read(authProvider.notifier)
            .login(phone, otp, firebaseToken: mockToken);

        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          AppHaptics.successNotification();
          final shouldCompletePermissionFlow =
              !HiveService.isInitialPermissionFlowComplete();
          context.go(shouldCompletePermissionFlow ? '/location' : '/home');
        }
        return;
      }

      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: otp,
      );

      await _verifyOtpWithCredential(credential);
    } catch (e, s) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        final mapped = ErrorHandler.handle(e, s);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(mapped.message)));
      }
    }
  }

  Future<void> _verifyOtpWithCredential(PhoneAuthCredential credential) async {
    final phone = _phoneController.text.trim();
    try {
      final userCredential = await FirebaseAuth.instance.signInWithCredential(
        credential,
      );
      final idToken = await userCredential.user?.getIdToken();

      if (idToken == null) {
        throw Exception("Firebase authentication token retrieval failed.");
      }

      await ref
          .read(authProvider.notifier)
          .login(phone, credential.smsCode ?? '', firebaseToken: idToken);

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        AppHaptics.successNotification();
        final shouldCompletePermissionFlow =
            !HiveService.isInitialPermissionFlowComplete();
        context.go(shouldCompletePermissionFlow ? '/location' : '/home');
      }
    } catch (e, s) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        final mapped = ErrorHandler.handle(e, s);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(mapped.message)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(isDarkModeProvider);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),

              // App logo
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.build,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'QuickFix',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppColors.secondary,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              if (!_isOtpSent) ...[
                // PHONE NUMBER ENTRY STATE
                Text(
                  'Verify Your Phone',
                  style: AppTextStyles.headingLarge(isDark),
                ).animate().fadeIn().slideY(begin: 0.1, end: 0),
                const SizedBox(height: 6),
                Text(
                  'We will send a 6-digit verification code.',
                  style: AppTextStyles.bodyMedium(isDark),
                ).animate().fadeIn(delay: 100.ms),

                const SizedBox(height: 36),

                // Phone Input field
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceDark : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark
                          ? AppColors.borderDark
                          : AppColors.borderLight,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Text(
                        '+91 ',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          maxLength: 10,
                          decoration: const InputDecoration(
                            hintText: 'Enter phone number',
                            border: InputBorder.none,
                            counterText: '',
                          ),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 200.ms),

                const SizedBox(height: 24),

                // Action button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _sendOtp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                          )
                        : const Text(
                            'Send Verification OTP',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                  ),
                ).animate().fadeIn(delay: 250.ms),
              ] else ...[
                // OTP CODE VERIFICATION STATE
                Text(
                  'Enter Code',
                  style: AppTextStyles.headingLarge(isDark),
                ).animate().fadeIn().slideY(begin: 0.1, end: 0),
                const SizedBox(height: 6),
                Text(
                  'Enter the 6-digit code sent to +91 ${_phoneController.text}',
                  style: AppTextStyles.bodyMedium(isDark),
                ).animate().fadeIn(delay: 100.ms),

                const SizedBox(height: 36),

                // OTP pin Input field
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceDark : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark
                          ? AppColors.borderDark
                          : AppColors.borderLight,
                    ),
                  ),
                  child: TextField(
                    controller: _otpController,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    decoration: const InputDecoration(
                      hintText: 'Enter 6-digit OTP code',
                      border: InputBorder.none,
                      counterText: '',
                    ),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 8.0,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ).animate().fadeIn(delay: 200.ms),

                const SizedBox(height: 16),

                // Timer & Resend
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _timerCount > 0
                          ? 'Resend code in ${_timerCount}s'
                          : 'Didn\'t receive code?',
                      style: AppTextStyles.bodySmall(isDark),
                    ),
                    if (_timerCount == 0)
                      TextButton(
                        onPressed: () {
                          AppHaptics.lightTap();
                          setState(() {
                            _timerCount = 30;
                            _otpController.clear();
                          });
                          _startTimer();
                        },
                        child: const Text(
                          'Resend OTP',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ).animate().fadeIn(delay: 250.ms),

                const SizedBox(height: 24),

                // Verify Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _verifyOtp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                          )
                        : const Text(
                            'Verify & Proceed',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                  ),
                ).animate().fadeIn(delay: 300.ms),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
