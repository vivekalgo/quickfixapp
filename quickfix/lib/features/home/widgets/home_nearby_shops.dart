import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:quickfix/shared/themes/app_colors.dart';
import 'package:quickfix/shared/themes/app_text_styles.dart';
import 'package:quickfix/shared/themes/app_shadows.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:quickfix/shared/themes/app_colors.dart';
import 'package:quickfix/shared/themes/app_text_styles.dart';
import 'package:quickfix/shared/themes/app_shadows.dart';
import 'package:quickfix/shared/utils/haptics.dart';
import 'package:quickfix/shared/widgets/shimmer_loading.dart';
import 'package:quickfix/shared/widgets/section_header.dart';
import 'package:quickfix/core/providers/network_providers.dart';
import 'package:quickfix/features/home/providers/home_providers.dart';
import 'package:quickfix/core/network/error_handler.dart';
import 'package:quickfix/features/home/models/home_models.dart';
import 'package:quickfix/shared/widgets/notify_me_dialog.dart';

class HomeNearbyShops extends ConsumerWidget {
  const HomeNearbyShops({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(isDarkModeProvider);
    final shopsAsync = ref.watch(nearbyShopsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Nearby Service Centers',
          isDark: isDark,
          onSeeAll: () {
            AppHaptics.lightTap();
            context.push('/shops');
          },
        ),

        const SizedBox(height: 4),

        shopsAsync.when(
          data: (shops) {
            if (shops.isEmpty) {
              return _buildComingSoonCard(context, ref, isDark);
            }
            return SizedBox(
              height: 258,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: shops.length,
                itemBuilder: (context, index) {
                  final shop = shops[index];
                  return GestureDetector(
                    onTap: () {
                      AppHaptics.mediumTap();
                      context.push('/shop/${shop.id}', extra: shop);
                    },
                    child: Container(
                      width: 260,
                      margin: const EdgeInsets.only(right: 16, bottom: 12),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.surfaceDark : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                        border: Border.all(
                          color: isDark ? AppColors.borderDark : AppColors.borderLight,
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Stack(
                            children: [
                              ClipRRect(
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                                child: Image.network(
                                  shop.imagePath,
                                  height: 130,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  cacheWidth: 520,
                                ),
                              ),
                              Positioned.fill(
                                child: Container(
                                  decoration: const BoxDecoration(
                                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                                    gradient: LinearGradient(
                                      colors: [Colors.black54, Colors.transparent],
                                      begin: Alignment.bottomCenter,
                                      end: Alignment.topCenter,
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 12,
                                right: 12,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.1),
                                        blurRadius: 4,
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.star_rounded, color: Color(0xFFFFB800), size: 14),
                                      const SizedBox(width: 3),
                                      Text(
                                        shop.rating.toStringAsFixed(1),
                                        style: const TextStyle(
                                          color: AppColors.secondary,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      if (shop.reviewsCount > 0) ...[
                                        const SizedBox(width: 3),
                                        Text(
                                          '(${shop.reviewsCount})',
                                          style: TextStyle(
                                            color: AppColors.textSecondaryLight,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 12,
                                left: 12,
                                child: GestureDetector(
                                  onTap: () {
                                    AppHaptics.mediumTap();
                                    ref.read(wishlistProvider.notifier).toggleFavourite(shop.id);
                                    final isNowFav = ref.read(wishlistProvider.notifier).isFavourite(shop.id);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          isNowFav
                                              ? 'Added ${shop.name} to Wishlist'
                                              : 'Removed ${shop.name} from Wishlist',
                                        ),
                                        duration: const Duration(seconds: 1),
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(alpha: 0.35),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      ref.watch(wishlistProvider).contains(shop.id)
                                          ? Icons.favorite
                                          : Icons.favorite_border,
                                      color: ref.watch(wishlistProvider).contains(shop.id)
                                          ? Colors.red
                                          : Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  shop.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyles.headingSmall(isDark).copyWith(fontSize: 14),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  shop.categories.join(', '),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyles.bodySmall(isDark).copyWith(fontSize: 11),
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.access_time_filled_rounded, size: 14, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                                        const SizedBox(width: 4),
                                        Text(
                                          shop.estimatedTimeDisplay,
                                          style: AppTextStyles.bodySmall(isDark).copyWith(fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        Icon(Icons.near_me_rounded, size: 14, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${shop.distanceKm} km',
                                          style: AppTextStyles.bodySmall(isDark).copyWith(fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      shop.priceRange,
                                      style: TextStyle(
                                        color: isDark ? Colors.white70 : AppColors.secondary,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 13,
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
                },
              ),
            );
          },
          loading: () => SizedBox(
            height: 258,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: 3,
              itemBuilder: (context, index) => const Padding(
                padding: EdgeInsets.only(right: 16),
                child: ShimmerLoading(width: 260, height: 220, borderRadius: 16),
              ),
            ),
          ),
          error: (e, s) => Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                ErrorHandler.handle(e, s).message,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildComingSoonCard(BuildContext context, WidgetRef ref, bool isDark) {
    final currentLoc = ref.watch(currentAddressProvider);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF1E1E2A), const Color(0xFF252535)]
              : [const Color(0xFFF0F4FF), const Color(0xFFE8F0FE)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? AppColors.borderDark
              : AppColors.primary.withValues(alpha: 0.15),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.primary, AppColors.secondary],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.35),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(Icons.rocket_launch_outlined, color: Colors.white, size: 38),
          ).animate().scale(delay: 100.ms, duration: 500.ms, curve: Curves.elasticOut),

          const SizedBox(height: 20),

          Text(
            'We\'re Coming Soon! 🚀',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppColors.secondary,
              letterSpacing: -0.3,
            ),
          ).animate().fadeIn(delay: 200.ms),

          const SizedBox(height: 8),

          Text(
            'QuickFix is expanding! We\'re onboarding trusted service partners near you. Be the first to know when we go live.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySmall(isDark).copyWith(
              fontSize: 12.5,
              height: 1.55,
            ),
          ).animate().fadeIn(delay: 300.ms),

          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _showNotifyMeDialog(context, ref, isDark, currentLoc),
              icon: const Icon(Icons.notifications_active_outlined, size: 18),
              label: const Text('Notify Me When Available'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2, end: 0),
          ),

          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    AppHaptics.lightTap();
                    context.push('/location-selector');
                  },
                  icon: const Icon(Icons.edit_location_alt_outlined, size: 16),
                  label: const Text('Change Area', style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: isDark ? Colors.white70 : AppColors.secondary,
                    side: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    AppHaptics.lightTap();
                    ref.read(currentAddressProvider.notifier).fetchGPSLocation(requestPermission: true);
                  },
                  icon: const Icon(Icons.my_location_outlined, size: 16),
                  label: const Text('Detect Location', style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ).animate().fadeIn(delay: 500.ms),
        ],
      ),
    );
  }

  void _showNotifyMeDialog(BuildContext context, WidgetRef ref, bool isDark, UserLocation currentLoc) {
    showDialog(
      context: context,
      builder: (ctx) => NotifyMeDialog(
        isDark: isDark,
        currentLoc: currentLoc,
      ),
    );
  }
}
