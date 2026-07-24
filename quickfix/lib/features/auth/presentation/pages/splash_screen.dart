import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quickfix/core/theme/app_colors.dart';
import 'package:quickfix/core/storage/hive_service.dart';
import 'package:quickfix/features/home/presentation/controllers/home_providers.dart';
import 'package:quickfix/features/auth/presentation/controllers/auth_providers.dart';

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
      final hasCompletedPermissionFlow =
          HiveService.isInitialPermissionFlowComplete();
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
    ref.watch(isDarkModeProvider);

    // Listen to authState changes to trigger navigation side-effects reactively
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (!next.isLoading && _minDelayPassed) {
        _tryNavigate();
      }
    });

    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Stack(
        alignment: Alignment.center,
        children: [
          // Central Logo and Title
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Animated logo circle
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primaryAccent.withValues(alpha: 0.2),
                  ),
                  child: Center(
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: AppColors.primaryAccent,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryAccent.withValues(alpha: 0.5),
                            blurRadius: 20,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.build,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                  ),
                )
                .animate(onPlay: (controller) => controller.repeat(reverse: true))
                .scale(begin: const Offset(0.9, 0.9), end: const Offset(1.1, 1.1), duration: 1000.ms, curve: Curves.easeInOut),

                const SizedBox(height: 24),

                Text(
                  'QuickFix',
                  style: GoogleFonts.outfit(
                    fontSize: 38,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1, end: 0),

                const SizedBox(height: 8),

                Text(
                  'Fix Fast, Live Easy',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.white60,
                  ),
                ).animate().fadeIn(delay: 500.ms),
              ],
            ),
          ),

          // Footer progress indicator
          Positioned(
            bottom: 48,
            child: const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation(AppColors.primaryAccent),
            ).animate().fadeIn(delay: 800.ms),
          ),
        ],
      ),
    );
  }
}
