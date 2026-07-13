import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:quickfix/shared/themes/app_colors.dart';
import 'package:quickfix/shared/themes/app_text_styles.dart';
import 'package:quickfix/shared/utils/haptics.dart';
import 'package:quickfix/core/services/hive_service.dart';
import 'package:quickfix/features/home/providers/home_providers.dart';
import 'package:quickfix/features/auth/providers/auth_providers.dart';

class LocationPermissionScreen extends ConsumerStatefulWidget {
  const LocationPermissionScreen({super.key});

  @override
  ConsumerState<LocationPermissionScreen> createState() => _LocationPermissionScreenState();
}

class _LocationPermissionScreenState extends ConsumerState<LocationPermissionScreen> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !HiveService.isInitialPermissionFlowComplete()) {
        _finishFlow(requestLocation: true);
      }
    });
  }

  Future<PermissionStatus> _requestNotificationPermission() async {
    return Permission.notification.request();
  }

  Future<void> _finishFlow({bool requestLocation = true}) async {
    if (_isLoading) return;

    AppHaptics.heavyTap();
    setState(() {
      _isLoading = true;
    });

    try {
      if (requestLocation) {
        await ref.read(currentAddressProvider.notifier).fetchGPSLocation(requestPermission: true);
      }

      await _requestNotificationPermission();
      await HiveService.setInitialPermissionFlowComplete();
      _goToNextStep();
    } catch (e) {
      await HiveService.setInitialPermissionFlowComplete();
      _goToNextStep();
    }
  }

  void _goToNextStep() {
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        AppHaptics.successNotification();
        final isAuthenticated = ref.read(authProvider).isAuthenticated;
        context.go(isAuthenticated ? '/home' : '/login');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(isDarkModeProvider);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),

              // Animated location pin map illustration
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.share_location,
                  color: AppColors.primary,
                  size: 80,
                ),
              ).animate()
               .scale(duration: 500.ms, curve: Curves.easeOutBack)
               .shake(delay: 600.ms, duration: 400.ms),

              const SizedBox(height: 36),

              Text(
                'Enable Location and Notifications',
                textAlign: TextAlign.center,
                style: AppTextStyles.headingLarge(isDark).copyWith(fontSize: 24),
              ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1, end: 0),

              const SizedBox(height: 12),

              Text(
                'QuickFix uses your location to find nearby experts and notifications to keep booking updates, arrival alerts, and offers in sync.',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium(isDark),
              ).animate().fadeIn(delay: 350.ms),

              const Spacer(),

              // Action buttons
              Column(
                children: [
                  ElevatedButton(
                    onPressed: _isLoading ? null : () => _finishFlow(requestLocation: true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 52),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 4,
                      shadowColor: AppColors.primary.withOpacity(0.25),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(Colors.white))
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.gps_fixed, size: 18),
                              SizedBox(width: 8),
                              Text('Continue', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            ],
                          ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: _isLoading ? null : () async {
                      AppHaptics.lightTap();
                      await HiveService.setInitialPermissionFlowComplete();
                      final isAuthenticated = ref.read(authProvider).isAuthenticated;
                      if (mounted) {
                        context.go(isAuthenticated ? '/home' : '/login');
                      }
                    },
                    child: Text(
                      'Enter Address Manually',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.textSecondaryDark : AppColors.secondary,
                      ),
                    ),
                  ),
                ],
              ).animate().fadeIn(delay: 500.ms),
            ],
          ),
        ),
      ),
    );
  }
}
