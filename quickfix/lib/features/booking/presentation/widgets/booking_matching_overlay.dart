import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:quickfix/core/theme/app_colors.dart';
import 'package:quickfix/core/theme/app_text_styles.dart';

class BookingMatchingOverlay extends StatelessWidget {
  final bool isDark;
  final String matchingStatus;
  final int matchingStep;

  const BookingMatchingOverlay({
    super.key,
    required this.isDark,
    required this.matchingStatus,
    required this.matchingStep,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        color: isDark
            ? Colors.black87.withValues(alpha: 0.85)
            : Colors.white.withValues(alpha: 0.92),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                RadarPulse(
                  child: Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.4),
                          blurRadius: 22,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.build_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ),
                const SizedBox(height: 50),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40.0),
                  child: Column(
                    children: [
                      Text(
                        'Finding Your Expert',
                        style: AppTextStyles.headingMedium(
                          isDark,
                        ).copyWith(fontSize: 22, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: Text(
                          matchingStatus,
                          key: ValueKey<String>(matchingStatus),
                          style: AppTextStyles.bodyMedium(isDark).copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(4, (index) {
                    final isActive = index <= matchingStep;
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: isActive
                            ? AppColors.primary
                            : (isDark ? Colors.white24 : Colors.black12),
                        shape: BoxShape.circle,
                      ),
                    );
                  }),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Text(
                    'Instant dispatch is covered by QuickFix Safety Insurance.',
                    style: AppTextStyles.bodySmall(isDark).copyWith(
                      color: isDark ? Colors.white38 : Colors.black38,
                      fontSize: 11,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class RadarPulse extends StatefulWidget {
  final Widget child;
  const RadarPulse({super.key, required this.child});

  @override
  State<RadarPulse> createState() => _RadarPulseState();
}

class _RadarPulseState extends State<RadarPulse>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        for (int i = 0; i < 3; i++)
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final double progress = (_controller.value + (i / 3)) % 1.0;
              final double size = 76.0 + (progress * 150.0);
              final double opacity = (1.0 - progress) * 0.45;
              return Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withValues(alpha: opacity),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: opacity * 1.5),
                    width: 1.5,
                  ),
                ),
              );
            },
          ),
        widget.child,
      ],
    );
  }
}
