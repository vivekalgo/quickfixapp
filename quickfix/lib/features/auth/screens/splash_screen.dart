import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:quickfix/shared/themes/app_colors.dart';
import 'package:quickfix/shared/themes/app_text_styles.dart';
import 'package:quickfix/core/services/hive_service.dart';
import 'package:quickfix/features/home/providers/home_providers.dart';
import 'package:quickfix/features/auth/providers/auth_providers.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  bool _minDelayPassed = false;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    // Start auth session check
    Future.microtask(() => ref.read(authProvider.notifier).checkSession());
    // Ensure minimum 2.5s splash display
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) {
        setState(() => _minDelayPassed = true);
        _tryNavigate();
      }
    });
  }

  void _tryNavigate() {
    if (!mounted || _navigated) return;
    final authState = ref.read(authProvider);
    // Only navigate when min delay has passed AND auth check completed
    if (_minDelayPassed && !authState.isLoading) {
      _navigated = true;
      final isOnboarded = HiveService.isOnboardingComplete();
      if (!isOnboarded) {
        context.go('/onboarding');
        return;
      }
      final hasCompletedPermissionFlow = HiveService.isInitialPermissionFlowComplete();
      if (!hasCompletedPermissionFlow) {
        context.go('/location');
        return;
      }
      if (authState.isAuthenticated) {
        context.go('/home');
      } else {
        context.go('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(isDarkModeProvider);
    
    // Listen to authState changes to trigger navigation side-effects reactively
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (!next.isLoading && _minDelayPassed) {
        _tryNavigate();
      }
    });

    return Scaffold(
      body: Stack(
        alignment: Alignment.center,
        children: [
          // Background subtle gradient
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.backgroundDark : Colors.white,
              ),
            ),
          ),

          // Central Logo and Title
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Animated logo circle
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.35),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.build,
                    color: Colors.white,
                    size: 36,
                  ),
                ).animate()
                 .scale(duration: 800.ms, curve: Curves.elasticOut)
                 .rotate(duration: 800.ms),

                const SizedBox(height: 20),

                Text(
                  'QuickFix',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.secondary,
                    letterSpacing: -1.0,
                  ),
                ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1, end: 0),

                const SizedBox(height: 6),

                Text(
                  'Fix Fast, Live Easy',
                  style: AppTextStyles.bodyMedium(isDark).copyWith(
                    letterSpacing: 1.0,
                    fontWeight: FontWeight.w600,
                  ),
                ).animate().fadeIn(delay: 500.ms),
              ],
            ),
          ),

          // Footer version info
          Positioned(
            bottom: 24,
            child: Text(
              'v1.0.0 • Enterprise Edition',
              style: AppTextStyles.bodySmall(isDark),
            ).animate().fadeIn(delay: 800.ms),
          ),
        ],
      ),
    );
  }
}
