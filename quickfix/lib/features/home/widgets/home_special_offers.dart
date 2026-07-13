import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:quickfix/shared/themes/app_colors.dart';
import 'package:quickfix/shared/themes/app_text_styles.dart';
import 'package:quickfix/shared/themes/app_shadows.dart';
import 'package:quickfix/shared/utils/haptics.dart';
import 'package:quickfix/shared/utils/cta_handler.dart';
import 'package:quickfix/shared/widgets/section_header.dart';
import 'package:quickfix/features/home/providers/home_providers.dart';

class HomeSpecialForYou extends ConsumerWidget {
  const HomeSpecialForYou({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(isDarkModeProvider);
    final cardsAsync = ref.watch(specialCardsProvider);

    return cardsAsync.when(
      data: (cards) {
        if (cards.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(title: 'Special For You 🔥', isDark: isDark),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: cards.length,
                itemBuilder: (context, index) {
                  final item = cards[index];
                  
                  Color bgColor = isDark ? AppColors.surfaceDark : Colors.white;
                  try {
                    if (item.backgroundColor.isNotEmpty && !isDark) {
                      bgColor = Color(int.parse(item.backgroundColor.replaceAll('#', '0xFF')));
                    }
                  } catch (e) {
                    // Fallback
                  }

                  IconData iconData = Icons.star_outline;
                  if (item.icon == 'water_drop_outlined') {
                    iconData = Icons.water_drop_outlined;
                  } else if (item.icon == 'flash_on_outlined') iconData = Icons.flash_on_outlined;
                  else if (item.icon == 'discount_outlined') iconData = Icons.discount_outlined;
                  else if (item.icon == 'cleaning_services_outlined') iconData = Icons.cleaning_services_outlined;
                  else if (item.icon == 'plumbing_outlined') iconData = Icons.plumbing_outlined;
                  else if (item.icon == 'bolt_outlined') iconData = Icons.bolt_outlined;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8, left: 16, right: 16),
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: isDark ? [] : AppShadows.card,
                      border: Border.all(
                        color: isDark ? AppColors.borderDark : AppColors.borderLight,
                      ),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                      onTap: () {
                        AppHaptics.lightTap();
                        handleCtaAction(context, item.ctaAction, item.ctaActionValue);
                      },
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.08),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(iconData, color: AppColors.primary, size: 22),
                      ),
                      title: Text(
                        item.title,
                        style: AppTextStyles.headingSmall(isDark).copyWith(fontSize: 14),
                      ),
                      subtitle: Text(
                        item.subtitle.isNotEmpty ? item.subtitle : item.description,
                        style: AppTextStyles.bodySmall(isDark),
                      ),
                      trailing: Icon(
                        Icons.chevron_right_rounded,
                        size: 20,
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      ),
                    ),
                  );
                },
              ),
            ],
          );
      },
      loading: () => const SizedBox.shrink(),
      error: (e, s) => const SizedBox.shrink(),
    );
  }
}

class HomeOfferPromoSection extends ConsumerWidget {
  const HomeOfferPromoSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 150,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFECFDF5), Color(0xFFD1FAE5)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.green.withValues(alpha: 0.15)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Refer & Earn',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green.shade800),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Get ₹100\nfor every friend',
                        style: AppTextStyles.headingSmall(false).copyWith(
                          color: AppColors.secondary,
                          fontWeight: FontWeight.bold,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                  ElevatedButton(
                    onPressed: () {
                      AppHaptics.heavyTap();
                      context.push('/profile');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      minimumSize: const Size(80, 32),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Refer Now', style: AppTextStyles.badgeText.copyWith(fontSize: 11)),
                        const Icon(Icons.chevron_right, size: 12),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Container(
              height: 150,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFEEF2FF), Color(0xFFE0E7FF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.blue.withValues(alpha: 0.15)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Flat 15% OFF',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blue.shade800),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'On First App\nBooking',
                        style: AppTextStyles.headingSmall(false).copyWith(
                          color: AppColors.secondary,
                          fontWeight: FontWeight.bold,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                  ElevatedButton(
                    onPressed: () {
                      AppHaptics.heavyTap();
                      context.push('/category/all');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      minimumSize: const Size(80, 32),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Book Now', style: AppTextStyles.badgeText.copyWith(fontSize: 11)),
                        const Icon(Icons.chevron_right, size: 12),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
