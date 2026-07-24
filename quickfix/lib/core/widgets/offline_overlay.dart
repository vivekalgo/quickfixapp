import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quickfix/core/network/connectivity_provider.dart';
import 'package:quickfix/core/theme/app_colors.dart';
import 'package:quickfix/core/widgets/custom_button.dart';

class OfflineOverlay extends ConsumerWidget {
  final Widget child;

  const OfflineOverlay({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectionAsync = ref.watch(connectivityProvider);
    final isOnline = connectionAsync.value ?? true;

    return Stack(
      children: [
        child,
        if (!isOnline)
          Positioned.fill(
            child: Container(
              color: Colors.black.withValues(alpha: 0.70),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Container(
                    padding: const EdgeInsets.all(24.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.wifi_off_rounded,
                            color: Colors.red,
                            size: 40,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'No Internet Connection',
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Please check your network settings and try again.',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: AppColors.textSecondaryLight,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        CustomButton(
                          text: 'Retry',
                          type: CustomButtonType.accent,
                          onPressed: () {
                            ref.invalidate(connectivityProvider);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
