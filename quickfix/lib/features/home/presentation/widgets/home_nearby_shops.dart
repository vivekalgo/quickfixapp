import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quickfix/core/theme/app_colors.dart';
import 'package:quickfix/core/utils/haptics.dart';
import 'package:quickfix/core/widgets/shimmer_loading.dart';
import 'package:quickfix/core/widgets/section_header.dart';
import 'package:quickfix/features/home/presentation/controllers/home_providers.dart';
import 'package:quickfix/core/network/error_handler.dart';
import 'package:quickfix/features/home/models/home_models.dart';
import 'package:quickfix/core/widgets/notify_me_dialog.dart';

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
          title: 'Featured Services',
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
              height: 286,
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
                          width: 268,
                          margin: const EdgeInsets.only(right: 16, bottom: 8),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.surfaceDark
                                : Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(
                                  alpha: isDark ? 0.35 : 0.06,
                                ),
                                blurRadius: 24,
                                spreadRadius: 0,
                                offset: const Offset(0, 8),
                              ),
                            ],
                            border: Border.all(
                              color: isDark
                                  ? AppColors.borderDark
                                  : const Color(0xFFF0F4F8),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // ── Shop Image ──────────────────────────────
                              Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(24),
                                    ),
                                    child: Image.network(
                                      shop.imagePath,
                                      height: 148,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                      cacheWidth: 540,
                                      errorBuilder: (_, __, ___) => Container(
                                        height: 148,
                                        color: isDark
                                            ? AppColors.surfaceDark
                                            : const Color(0xFFF1F5F9),
                                        child: const Center(
                                          child: Icon(
                                            Icons.store_outlined,
                                            size: 40,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  // Rating badge
                                  Positioned(
                                    top: 12,
                                    right: 12,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 9,
                                        vertical: 5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(
                                          alpha: 0.95,
                                        ),
                                        borderRadius: BorderRadius.circular(10),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(
                                              alpha: 0.08,
                                            ),
                                            blurRadius: 6,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.star_rounded,
                                            color: Color(0xFFFFB800),
                                            size: 13,
                                          ),
                                          const SizedBox(width: 3),
                                          Text(
                                            shop.rating.toStringAsFixed(1),
                                            style: GoogleFonts.outfit(
                                              color: AppColors.primary,
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                          if (shop.reviewsCount > 0) ...[
                                            const SizedBox(width: 2),
                                            Text(
                                              '(${shop.reviewsCount})',
                                              style: GoogleFonts.inter(
                                                color: AppColors
                                                    .textSecondaryLight,
                                                fontSize: 9.5,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ),
                                  // Favourite button
                                  Positioned(
                                    top: 12,
                                    left: 12,
                                    child: GestureDetector(
                                      onTap: () {
                                        AppHaptics.mediumTap();
                                        ref
                                            .read(wishlistProvider.notifier)
                                            .toggleFavourite(shop.id);
                                        final isNowFav = ref
                                            .read(wishlistProvider.notifier)
                                            .isFavourite(shop.id);
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              isNowFav
                                                  ? 'Added ${shop.name} to Wishlist'
                                                  : 'Removed ${shop.name} from Wishlist',
                                            ),
                                            duration: const Duration(
                                              seconds: 1,
                                            ),
                                            behavior: SnackBarBehavior.floating,
                                          ),
                                        );
                                      },
                                      child: Container(
                                        width: 34,
                                        height: 34,
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(
                                            alpha: 0.88,
                                          ),
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withValues(
                                                alpha: 0.08,
                                              ),
                                              blurRadius: 8,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: Icon(
                                          ref
                                                  .watch(wishlistProvider)
                                                  .contains(shop.id)
                                              ? Icons.favorite_rounded
                                              : Icons.favorite_border_rounded,
                                          color: ref
                                                  .watch(wishlistProvider)
                                                  .contains(shop.id)
                                              ? const Color(0xFFEF4444)
                                              : const Color(0xFF94A3B8),
                                          size: 16,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              // ── Info Row ────────────────────────────────
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  14,
                                  12,
                                  14,
                                  12,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            shop.name,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: GoogleFonts.outfit(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w800,
                                              letterSpacing: -0.3,
                                              color: isDark
                                                  ? Colors.white
                                                  : AppColors.textPrimaryLight,
                                            ),
                                          ),
                                        ),
                                        // Verified badge
                                        const Icon(
                                          Icons.verified_rounded,
                                          size: 15,
                                          color: Color(0xFF3B82F6),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      shop.categories.join(' • '),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        color: isDark
                                            ? AppColors.textSecondaryDark
                                            : const Color(0xFF6B7280),
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Row(
                                      children: [
                                        _InfoPill(
                                          icon:
                                              Icons.access_time_filled_rounded,
                                          label: shop.estimatedTimeDisplay,
                                          isDark: isDark,
                                        ),
                                        const SizedBox(width: 6),
                                        _InfoPill(
                                          icon: Icons.near_me_rounded,
                                          label: '${shop.distanceKm} km',
                                          isDark: isDark,
                                        ),
                                        const Spacer(),
                                        Text(
                                          shop.priceRange,
                                          style: GoogleFonts.outfit(
                                            color: AppColors.primaryAccent,
                                            fontWeight: FontWeight.w800,
                                            fontSize: 13,
                                            letterSpacing: -0.2,
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
                      )
                      .animate(delay: (index * 80).ms)
                      .fadeIn(duration: 400.ms, curve: Curves.easeOutCubic)
                      .slideY(
                        begin: 0.12,
                        end: 0,
                        duration: 450.ms,
                        curve: Curves.easeOutCubic,
                      );
                },
              ),
            );
          },
          loading: () => SizedBox(
            height: 286,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: 3,
              itemBuilder: (context, index) => const Padding(
                padding: EdgeInsets.only(right: 16),
                child: ShimmerLoading(
                  width: 268,
                  height: 240,
                  borderRadius: 24,
                ),
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

  Widget _buildComingSoonCard(
    BuildContext context,
    WidgetRef ref,
    bool isDark,
  ) {
    final currentLoc = ref.watch(currentAddressProvider);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? AppColors.borderDark
              : AppColors.primaryAccent.withValues(alpha: 0.15),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryAccent.withValues(alpha: 0.06),
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
              color: AppColors.primaryAccent.withValues(alpha: 0.08),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.primaryAccent.withValues(alpha: 0.2),
                width: 2,
              ),
            ),
            child: const Icon(
              Icons.rocket_launch_outlined,
              color: AppColors.primaryAccent,
              size: 36,
            ),
          ).animate().scale(
            delay: 100.ms,
            duration: 500.ms,
            curve: Curves.elasticOut,
          ),

          const SizedBox(height: 20),

          Text(
            "We're Coming Soon! 🚀",
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
              color: isDark ? Colors.white : AppColors.primary,
            ),
          ).animate().fadeIn(delay: 200.ms),

          const SizedBox(height: 8),

          Text(
            'QuickFix is expanding! We\'re onboarding trusted service partners near you. Be the first to know when we go live.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 12.5,
              height: 1.55,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
          ).animate().fadeIn(delay: 300.ms),

          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () =>
                  _showNotifyMeDialog(context, ref, isDark, currentLoc),
              icon: const Icon(Icons.notifications_active_outlined, size: 18),
              label: const Text('Notify Me When Available'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
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
                  label: const Text(
                    'Change Area',
                    style: TextStyle(fontSize: 12),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: isDark
                        ? Colors.white70
                        : AppColors.textPrimaryLight,
                    side: BorderSide(
                      color: isDark
                          ? AppColors.borderDark
                          : AppColors.borderLight,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    AppHaptics.lightTap();
                    ref
                        .read(currentAddressProvider.notifier)
                        .fetchGPSLocation(requestPermission: true);
                  },
                  icon: const Icon(Icons.my_location_outlined, size: 16),
                  label: const Text(
                    'Detect Location',
                    style: TextStyle(fontSize: 12),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primaryAccent,
                    side: const BorderSide(color: AppColors.primaryAccent),
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ).animate().fadeIn(delay: 500.ms),
        ],
      ),
    );
  }

  void _showNotifyMeDialog(
    BuildContext context,
    WidgetRef ref,
    bool isDark,
    UserLocation currentLoc,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => NotifyMeDialog(isDark: isDark, currentLoc: currentLoc),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// INTERNAL WIDGETS
// ─────────────────────────────────────────────────────────────────────────────

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;

  const _InfoPill({
    required this.icon,
    required this.label,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 11,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              color: isDark
                  ? const Color(0xFFCBD5E1)
                  : const Color(0xFF374151),
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
