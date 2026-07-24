import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quickfix/core/theme/app_colors.dart';
import 'package:quickfix/core/utils/haptics.dart';
import 'package:quickfix/core/utils/cta_handler.dart';
import 'package:quickfix/features/home/presentation/controllers/home_providers.dart';

class HomeFestiveOfferBanner extends ConsumerWidget {
  const HomeFestiveOfferBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(isDarkModeProvider);
    final promosAsync = ref.watch(promotionsProvider);

    return promosAsync.when(
      data: (promos) {
        if (promos.isEmpty) return const SizedBox.shrink();

        return Column(
          children: promos.map((promo) {
            Color bgColor = isDark
                ? AppColors.surfaceDark
                : const Color(0xFFFFF7F0);
            Color txtColor = AppColors.primary;

            try {
              if (promo.backgroundColor.isNotEmpty && !isDark) {
                bgColor = Color(
                  int.parse(promo.backgroundColor.replaceAll('#', '0xFF')),
                );
              }
              if (promo.textColor.isNotEmpty) {
                txtColor = Color(
                  int.parse(promo.textColor.replaceAll('#', '0xFF')),
                );
              }
            } catch (e) {
              // Safe fallback
            }

            if (isDark) {
              bgColor = AppColors.surfaceDark;
              if (txtColor.computeLuminance() < 0.2) {
                txtColor = Colors.white;
              }
            }

            Color buttonColor = AppColors.primaryAccent;
            Color buttonTextColor = Colors.white;
            try {
              if (promo.buttonColor.isNotEmpty) {
                buttonColor = Color(
                  int.parse(promo.buttonColor.replaceAll('#', '0xFF')),
                );
              }
              if (promo.buttonTextColor.isNotEmpty) {
                buttonTextColor = Color(
                  int.parse(promo.buttonTextColor.replaceAll('#', '0xFF')),
                );
              }
            } catch (e) {
              // Safe fallback
            }

            return Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 6,
              ),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isDark
                        ? AppColors.borderDark
                        : txtColor.withValues(alpha: 0.12),
                    width: 1,
                  ),
                  boxShadow: isDark
                      ? []
                      : [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                ),
                child: Row(
                  children: [
                    // Icon / Image
                    if (promo.bannerImage.isNotEmpty) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          promo.bannerImage,
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                          errorBuilder: (c, o, s) => Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF1E293B)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.card_giftcard_rounded,
                              color: AppColors.primaryAccent,
                              size: 24,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ] else ...[
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF1E293B)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.card_giftcard_rounded,
                          color: AppColors.primaryAccent,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    // Text
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            promo.title,
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w700,
                              fontSize: 11.5,
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondaryLight,
                            ),
                          ),
                          Text(
                            promo.subtitle,
                            style: GoogleFonts.outfit(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                              color: isDark ? Colors.white : AppColors.primary,
                            ),
                          ),
                          if (promo.description.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              promo.description,
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: isDark
                                    ? AppColors.textSecondaryDark
                                    : AppColors.textSecondaryLight,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    // CTA Button
                    GestureDetector(
                      onTap: () {
                        AppHaptics.heavyTap();
                        handleCtaAction(
                          context,
                          promo.ctaButtonAction,
                          promo.ctaButtonActionValue,
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          color: buttonColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          promo.ctaButtonText.isNotEmpty
                              ? promo.ctaButtonText
                              : 'Grab',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: buttonTextColor,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (e, s) => const SizedBox.shrink(),
    );
  }
}

class HomeQuickFixPlusBanner extends ConsumerWidget {
  const HomeQuickFixPlusBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.30),
              blurRadius: 18,
              spreadRadius: 0,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                color: const Color(0xFFFFB800).withValues(alpha: 0.14),
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFFFFB800).withValues(alpha: 0.30),
                  width: 1.5,
                ),
              ),
              child: const Icon(
                Icons.stars_rounded,
                color: Color(0xFFFFB800),
                size: 30,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'QuickFix Plus',
                    style: GoogleFonts.outfit(
                      color: const Color(0xFFFFB800),
                      fontWeight: FontWeight.w900,
                      fontSize: 17,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Free Delivery · Priority Booking · Exclusive Offers',
                    style: GoogleFonts.inter(
                      color: Colors.white.withValues(alpha: 0.65),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: () {
                AppHaptics.heavyTap();
                context.push('/refer-earn');
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.20),
                    width: 1,
                  ),
                ),
                child: Text(
                  'Join Now',
                  style: GoogleFonts.outfit(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -0.1,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
