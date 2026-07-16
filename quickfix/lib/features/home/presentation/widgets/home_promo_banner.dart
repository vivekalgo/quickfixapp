import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:quickfix/core/theme/app_colors.dart';
import 'package:quickfix/core/theme/app_text_styles.dart';
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
            Color bgColor = const Color(0xFFFFF1F0);
            Color txtColor = AppColors.primary;
            Color btnColor = AppColors.primary;
            Color btnTxtColor = Colors.white;

            try {
              if (promo.backgroundColor.isNotEmpty) {
                bgColor = Color(
                  int.parse(promo.backgroundColor.replaceAll('#', '0xFF')),
                );
              }
              if (promo.textColor.isNotEmpty) {
                txtColor = Color(
                  int.parse(promo.textColor.replaceAll('#', '0xFF')),
                );
              }
              if (promo.buttonColor.isNotEmpty) {
                btnColor = Color(
                  int.parse(promo.buttonColor.replaceAll('#', '0xFF')),
                );
              }
              if (promo.buttonTextColor.isNotEmpty) {
                btnTxtColor = Color(
                  int.parse(promo.buttonTextColor.replaceAll('#', '0xFF')),
                );
              }
            } catch (e) {
              // Safe fallback
            }

            if (isDark) {
              bgColor = AppColors.surfaceDark;
              if (txtColor.computeLuminance() < 0.2) {
                txtColor = AppColors.primary;
              }
            }

            return Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 6,
              ),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark
                        ? AppColors.borderDark
                        : txtColor.withValues(alpha: 0.15),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    if (promo.bannerImage.isNotEmpty) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          promo.bannerImage,
                          width: 44,
                          height: 44,
                          fit: BoxFit.cover,
                          errorBuilder: (c, o, s) => Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF2A2A38)
                                  : Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.card_giftcard,
                              color: txtColor,
                              size: 24,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ] else ...[
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF2A2A38)
                              : Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.card_giftcard,
                          color: txtColor,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            promo.title,
                            style: AppTextStyles.bodySmall(isDark).copyWith(
                              fontWeight: FontWeight.bold,
                              color: txtColor,
                            ),
                          ),
                          Text(
                            promo.subtitle,
                            style: AppTextStyles.headingSmall(isDark).copyWith(
                              color: isDark
                                  ? Colors.white
                                  : AppColors.secondary,
                            ),
                          ),
                          if (promo.description.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              promo.description,
                              style: AppTextStyles.bodySmall(isDark).copyWith(
                                color: isDark
                                    ? Colors.white70
                                    : AppColors.textSecondaryLight,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        AppHaptics.heavyTap();
                        handleCtaAction(
                          context,
                          promo.ctaButtonAction,
                          promo.ctaButtonActionValue,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: btnColor,
                        foregroundColor: btnTxtColor,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(
                            promo.ctaButtonText.isNotEmpty
                                ? promo.ctaButtonText
                                : 'Grab Now',
                            style: AppTextStyles.badgeText.copyWith(
                              fontSize: 12,
                              color: btnTxtColor,
                            ),
                          ),
                          Icon(
                            Icons.chevron_right,
                            size: 14,
                            color: btnTxtColor,
                          ),
                        ],
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
      padding: const EdgeInsets.all(16.0),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: AppColors.plusGradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.12),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.amber.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: const Icon(Icons.stars, color: AppColors.accent, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'QuickFix Plus',
                    style: AppTextStyles.headingSmall(true).copyWith(
                      color: AppColors.accent,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Free Delivery • Priority Booking • Exclusive Offers',
                    style: AppTextStyles.bodySmall(
                      true,
                    ).copyWith(color: Colors.white70),
                  ),
                  Text(
                    'And much more!',
                    style: AppTextStyles.bodySmall(
                      true,
                    ).copyWith(color: Colors.white54),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: () {
                AppHaptics.heavyTap();
                context.push('/refer-earn');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
              child: Row(
                children: [
                  Text(
                    'Join Now',
                    style: AppTextStyles.badgeText.copyWith(fontSize: 12),
                  ),
                  const Icon(Icons.chevron_right, size: 14),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
