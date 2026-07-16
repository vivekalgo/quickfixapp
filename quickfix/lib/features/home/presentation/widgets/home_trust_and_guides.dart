import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:quickfix/core/theme/app_colors.dart';
import 'package:quickfix/core/theme/app_text_styles.dart';
import 'package:quickfix/core/utils/haptics.dart';
import 'package:quickfix/core/widgets/section_header.dart';
import 'package:quickfix/features/home/presentation/controllers/home_providers.dart';

class HomeTrustBadges extends ConsumerWidget {
  const HomeTrustBadges({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(isDarkModeProvider);

    final List<Map<String, dynamic>> badges = [
      {
        'title': 'Genuine\nProfessionals',
        'icon': Icons.verified_user_outlined,
        'color': AppColors.success,
      },
      {
        'title': 'Background\nVerified',
        'icon': Icons.security_outlined,
        'color': AppColors.catAppliancesIcon,
      },
      {
        'title': 'Upfront\nPricing',
        'icon': Icons.monetization_on_outlined,
        'color': AppColors.accent,
      },
      {
        'title': 'On-time\nService',
        'icon': Icons.alarm_outlined,
        'color': AppColors.info,
      },
      {
        'title': '24x7\nSupport',
        'icon': Icons.headset_mic_outlined,
        'color': AppColors.error,
      },
    ];

    return SizedBox(
      height: 110,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: badges.length,
        itemBuilder: (context, index) {
          final b = badges[index];
          return Container(
            width: 100,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(b['icon'], color: b['color'], size: 24),
                const SizedBox(height: 8),
                Text(
                  b['title'],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textPrimaryLight,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class HomeHowItWorksSection extends ConsumerWidget {
  const HomeHowItWorksSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(isDarkModeProvider);

    final List<Map<String, dynamic>> steps = [
      {
        'num': '1',
        'title': 'Search',
        'desc': 'Choose the service you need',
        'icon': Icons.search_outlined,
        'color': AppColors.success,
      },
      {
        'num': '2',
        'title': 'Choose',
        'desc': 'Select from top rated professionals',
        'icon': Icons.thumb_up_alt_outlined,
        'color': AppColors.accent,
      },
      {
        'num': '3',
        'title': 'Book',
        'desc': 'Pick a time slot & confirm booking',
        'icon': Icons.calendar_month_outlined,
        'color': AppColors.info,
      },
      {
        'num': '4',
        'title': 'Relax',
        'desc': 'Professional arrives & gets it done',
        'icon': Icons.sentiment_satisfied_alt_outlined,
        'color': AppColors.primary,
      },
    ];

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(title: 'How QuickFix Works?', isDark: isDark),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List.generate(steps.length, (index) {
              final step = steps[index];
              return Expanded(
                child: Column(
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: step['color'].withValues(alpha: 0.08),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: step['color'].withValues(alpha: 0.3),
                              width: 1.5,
                            ),
                          ),
                          child: Icon(
                            step['icon'],
                            color: step['color'],
                            size: 20,
                          ),
                        ),
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: step['color'],
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              step['num'],
                              style: const TextStyle(
                                fontSize: 8,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      step['title'],
                      style: AppTextStyles.bodySmall(isDark).copyWith(
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? Colors.white
                            : AppColors.textPrimaryLight,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      step['desc'],
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 9,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class HomeBrandLogos extends ConsumerWidget {
  const HomeBrandLogos({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(isDarkModeProvider);
    final List<String> brands = [
      'DAIKIN',
      'orient',
      'HAVELLS',
      'Crompton',
      'hindware',
      'PHILIPS',
    ];

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Trusted by Leading Brands',
            style: AppTextStyles.headingSmall(isDark).copyWith(
              fontWeight: FontWeight.bold,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.surfaceDark.withValues(alpha: 0.5)
                  : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: List.generate(brands.length, (index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      brands[index],
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                        color: isDark ? Colors.white24 : Colors.black26,
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class HomeNeedHelpCard extends ConsumerWidget {
  const HomeNeedHelpCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(isDarkModeProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppColors.borderDark : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 30,
              backgroundImage: NetworkImage(
                'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=150',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Need Help?', style: AppTextStyles.headingSmall(isDark)),
                  Text(
                    'Our support team is always here for you',
                    style: AppTextStyles.bodySmall(isDark),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '24x7 Support • Instant Response • 100% Satisfaction',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.amber : AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {
                          AppHaptics.mediumTap();
                          context.push('/support');
                        },
                        icon: const Icon(
                          Icons.chat_bubble_outline,
                          size: 14,
                          color: Colors.white,
                        ),
                        label: Text(
                          'Chat Now',
                          style: AppTextStyles.badgeText.copyWith(fontSize: 11),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDark
                              ? AppColors.primary
                              : AppColors.secondary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: () {
                          AppHaptics.mediumTap();
                          // Simulating Call Action
                        },
                        icon: Icon(
                          Icons.phone_outlined,
                          size: 14,
                          color: isDark ? Colors.white : AppColors.secondary,
                        ),
                        label: Text(
                          'Call Us',
                          style: AppTextStyles.badgeText.copyWith(
                            fontSize: 11,
                            color: isDark ? Colors.white : AppColors.secondary,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: isDark
                                ? Colors.white38
                                : AppColors.secondary,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
