import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:quickfix/core/theme/app_colors.dart';
import 'package:quickfix/core/theme/app_text_styles.dart';
import 'package:quickfix/core/utils/haptics.dart';
import 'package:quickfix/core/storage/hive_service.dart';
import 'package:quickfix/features/home/presentation/controllers/home_providers.dart';

class OnboardingPage {
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  const OnboardingPage({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  final List<OnboardingPage> _pages = const [
    OnboardingPage(
      title: 'Find Premium Local Services',
      description:
          'Connect with verified electricians, plumbers, and cleaning experts nearSwamp Nagar in minutes.',
      icon: Icons.search,
      color: AppColors.catCleaningIcon,
    ),
    OnboardingPage(
      title: 'Schedule on Your Terms',
      description:
          'Select your preferred date and time slot. Track provider arrival real-time on live map overlays.',
      icon: Icons.event_note,
      color: AppColors.catCarpentryIcon,
    ),
    OnboardingPage(
      title: '100% Assured Quality',
      description:
          'QuickFix offers a 30-day rework warranty on all orders with secure payment protection.',
      icon: Icons.verified_outlined,
      color: AppColors.catPlumbingIcon,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onNext() async {
    AppHaptics.mediumTap();
    if (_currentIndex < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      await HiveService.setOnboardingComplete();
      if (mounted) {
        context.go('/location');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(isDarkModeProvider);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              // Top Skip Row
              Align(
                alignment: Alignment.topRight,
                child: TextButton(
                  onPressed: () async {
                    AppHaptics.lightTap();
                    await HiveService.setOnboardingComplete();
                    if (mounted) {
                      context.go('/location');
                    }
                  },
                  child: Text(
                    'Skip',
                    style: TextStyle(
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              // Page View carousel
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentIndex = index;
                    });
                  },
                  itemCount: _pages.length,
                  itemBuilder: (context, index) {
                    final p = _pages[index];
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                              padding: const EdgeInsets.all(28),
                              decoration: BoxDecoration(
                                color: p.color.withValues(alpha: 0.08),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(p.icon, color: p.color, size: 72),
                            )
                            .animate(key: ValueKey(index))
                            .scale(duration: 400.ms, curve: Curves.easeOutBack),

                        const SizedBox(height: 36),

                        Text(
                          p.title,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.headingLarge(
                            isDark,
                          ).copyWith(fontSize: 24),
                        ),

                        const SizedBox(height: 12),

                        Text(
                          p.description,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.bodyMedium(isDark),
                        ),
                      ],
                    );
                  },
                ),
              ),

              // Bottom indicators & Navigation Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Indicators
                  Row(
                    children: List.generate(_pages.length, (index) {
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _currentIndex == index ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _currentIndex == index
                              ? AppColors.primary
                              : (isDark
                                    ? AppColors.borderDark
                                    : AppColors.borderLight),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),

                  // Action primary button
                  ElevatedButton(
                    onPressed: _onNext,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(
                          _currentIndex == _pages.length - 1
                              ? 'Get Started'
                              : 'Next',
                          style: AppTextStyles.badgeText.copyWith(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.arrow_forward, size: 14),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
