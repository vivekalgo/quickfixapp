import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quickfix/core/theme/app_colors.dart';
import 'package:quickfix/core/utils/haptics.dart';
import 'package:quickfix/core/widgets/shimmer_loading.dart';
import 'package:quickfix/core/widgets/section_header.dart';
import 'package:quickfix/features/home/presentation/controllers/home_providers.dart';
import 'package:quickfix/core/network/error_handler.dart';

class HomeProfessionalsSection extends ConsumerWidget {
  const HomeProfessionalsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(isDarkModeProvider);
    final professionalsAsync = ref.watch(topProfessionalsProvider);
    final wishlist = ref.watch(wishlistProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Top Professionals ⭐',
          isDark: isDark,
          onSeeAll: () {
            AppHaptics.lightTap();
            context.push('/shops');
          },
        ),

        SizedBox(
          height: 184,
          child: professionalsAsync.when(
            data: (professionals) {
              if (professionals.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Text(
                      'No experts active currently.',
                      style: GoogleFonts.inter(
                        color: Colors.grey.shade500,
                        fontSize: 13,
                      ),
                    ),
                  ),
                );
              }
              return ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                physics: const BouncingScrollPhysics(),
                itemCount: professionals.length,
                itemBuilder: (context, index) {
                  final prof = professionals[index];
                  final isFav = wishlist.contains(prof.id);

                  return GestureDetector(
                    onTap: () {
                      AppHaptics.mediumTap();
                      if (prof.shopId.isNotEmpty) {
                        context.push('/shop/${prof.shopId}');
                      } else {
                        final spec = prof.specialty.toLowerCase();
                        String categoryId = 'plumbing';
                        if (spec.contains('electrician')) {
                          categoryId = 'electrician';
                        } else if (spec.contains('clean')) {
                          categoryId = 'cleaning';
                        } else if (spec.contains('plumb')) {
                          categoryId = 'plumbing';
                        } else if (spec.contains('appliance')) {
                          categoryId = 'appliances';
                        } else if (spec.contains('carpent')) {
                          categoryId = 'carpentry';
                        } else if (spec.contains('paint')) {
                          categoryId = 'painting';
                        } else if (spec.contains('pest')) {
                          categoryId = 'pestcontrol';
                        }
                        context.push('/category/$categoryId');
                      }
                    },
                    child: Container(
                      width: 236,
                      margin: const EdgeInsets.only(right: 12, bottom: 6, top: 2),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.surfaceDark : Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: isDark
                                ? Colors.black.withValues(alpha: 0.3)
                                : const Color(0xFF0F172A).withValues(alpha: 0.05),
                            blurRadius: 14,
                            spreadRadius: 0,
                            offset: const Offset(0, 4),
                          ),
                        ],
                        border: Border.all(
                          color: isDark
                              ? AppColors.borderDark
                              : const Color(0xFFE2E8F0),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── Top Header Row: Avatar + Info ─────────────────────
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Avatar with Gradient Ring & Online Dot
                              Stack(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: LinearGradient(
                                        colors: [
                                          Color(0xFF3B82F6),
                                          Color(0xFF8B5CF6),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                    ),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: isDark
                                            ? AppColors.surfaceDark
                                            : Colors.white,
                                      ),
                                      padding: const EdgeInsets.all(1.5),
                                      child: CircleAvatar(
                                        radius: 22,
                                        backgroundImage: ResizeImage(
                                          NetworkImage(
                                            prof.avatarUrl.isNotEmpty
                                                ? prof.avatarUrl
                                                : 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150',
                                          ),
                                          width: 150,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    right: 0,
                                    bottom: 0,
                                    child: Container(
                                      width: 11,
                                      height: 11,
                                      decoration: BoxDecoration(
                                        color: prof.availability
                                            ? const Color(0xFF10B981)
                                            : const Color(0xFFEF4444),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: isDark
                                              ? AppColors.surfaceDark
                                              : Colors.white,
                                          width: 1.5,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            prof.name,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: GoogleFonts.outfit(
                                              fontSize: 14.5,
                                              fontWeight: FontWeight.w800,
                                              letterSpacing: -0.2,
                                              color: isDark
                                                  ? Colors.white
                                                  : AppColors.textPrimaryLight,
                                            ),
                                          ),
                                        ),
                                        if (prof.verifiedBadge) ...[
                                          const SizedBox(width: 4),
                                          Container(
                                            padding: const EdgeInsets.all(1.5),
                                            decoration: const BoxDecoration(
                                              color: Color(0xFF2563EB),
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.check_rounded,
                                              color: Colors.white,
                                              size: 9,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 3),
                                    // Specialty Pill Tag & Experience
                                    Row(
                                      children: [
                                        Flexible(
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: isDark
                                                  ? const Color(0xFF3B82F6).withValues(
                                                      alpha: 0.16,
                                                    )
                                                  : const Color(0xFFEFF6FF),
                                              borderRadius: BorderRadius.circular(5),
                                              border: Border.all(
                                                color: isDark
                                                    ? const Color(0xFF3B82F6).withValues(
                                                        alpha: 0.3,
                                                      )
                                                    : const Color(0xFFBFDBFE),
                                                width: 0.8,
                                              ),
                                            ),
                                            child: Text(
                                              prof.specialty,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: GoogleFonts.inter(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w700,
                                                color: isDark
                                                    ? const Color(0xFF60A5FA)
                                                    : const Color(0xFF1D4ED8),
                                              ),
                                            ),
                                          ),
                                        ),
                                        if (prof.experience.isNotEmpty) ...[
                                          const SizedBox(width: 5),
                                          Text(
                                            '• ${prof.experience}',
                                            style: GoogleFonts.inter(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w500,
                                              color: isDark
                                                  ? AppColors.textSecondaryDark
                                                  : AppColors.textSecondaryLight,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 10),

                          // ── Ratings & Quick Badges Bar ───────────────────────
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEF3C7),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.star_rounded,
                                      color: Color(0xFFD97706),
                                      size: 13,
                                    ),
                                    const SizedBox(width: 2),
                                    Text(
                                      prof.rating.toStringAsFixed(1),
                                      style: GoogleFonts.outfit(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w900,
                                        color: const Color(0xFF92400E),
                                      ),
                                    ),
                                    if (prof.reviewsCount > 0) ...[
                                      const SizedBox(width: 2),
                                      Text(
                                        '(${prof.reviewsCount})',
                                        style: GoogleFonts.inter(
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w600,
                                          color: const Color(0xFFB45309),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.06)
                                      : const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: isDark
                                        ? AppColors.borderDark
                                        : const Color(0xFFE2E8F0),
                                    width: 0.8,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.bolt_rounded,
                                      color: Color(0xFF10B981),
                                      size: 12,
                                    ),
                                    const SizedBox(width: 2),
                                    Text(
                                      '30 min',
                                      style: GoogleFonts.inter(
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w600,
                                        color: isDark
                                            ? AppColors.textSecondaryDark
                                            : const Color(0xFF475569),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: prof.availability
                                      ? const Color(0xFFD1FAE5)
                                      : const Color(0xFFFEE2E2),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  prof.availability ? 'Available' : 'Offline',
                                  style: GoogleFonts.inter(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w700,
                                    color: prof.availability
                                        ? const Color(0xFF047857)
                                        : const Color(0xFFB91C1C),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 10),

                          // ── Action Row: Wishlist + Book Now CTA ───────────────
                          Row(
                            children: [
                              GestureDetector(
                                onTap: () {
                                  AppHaptics.mediumTap();
                                  ref
                                      .read(wishlistProvider.notifier)
                                      .toggleFavourite(prof.id);
                                  final isNowFav = ref
                                      .read(wishlistProvider.notifier)
                                      .isFavourite(prof.id);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        isNowFav
                                            ? 'Added ${prof.name} to Wishlist'
                                            : 'Removed ${prof.name} from Wishlist',
                                      ),
                                      duration: const Duration(seconds: 1),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                },
                                child: Container(
                                  width: 34,
                                  height: 34,
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? AppColors.borderDark
                                        : const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: isDark
                                          ? AppColors.borderDark
                                          : const Color(0xFFE2E8F0),
                                    ),
                                  ),
                                  child: Icon(
                                    isFav
                                        ? Icons.favorite_rounded
                                        : Icons.favorite_border_rounded,
                                    color: isFav
                                        ? const Color(0xFFEF4444)
                                        : const Color(0xFF64748B),
                                    size: 16,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    AppHaptics.heavyTap();
                                    if (prof.shopId.isNotEmpty) {
                                      context.push('/shop/${prof.shopId}');
                                    } else {
                                      final spec = prof.specialty.toLowerCase();
                                      String categoryId = 'plumbing';
                                      if (spec.contains('electrician')) {
                                        categoryId = 'electrician';
                                      } else if (spec.contains('clean')) {
                                        categoryId = 'cleaning';
                                      } else if (spec.contains('plumb')) {
                                        categoryId = 'plumbing';
                                      } else if (spec.contains('appliance')) {
                                        categoryId = 'appliances';
                                      } else if (spec.contains('carpent')) {
                                        categoryId = 'carpentry';
                                      } else if (spec.contains('paint')) {
                                        categoryId = 'painting';
                                      } else if (spec.contains('pest')) {
                                        categoryId = 'pestcontrol';
                                      }
                                      context.push('/category/$categoryId');
                                    }
                                  },
                                  child: Container(
                                    height: 34,
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          AppColors.primary,
                                          AppColors.primaryAccent,
                                        ],
                                        begin: Alignment.centerLeft,
                                        end: Alignment.centerRight,
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.primary.withValues(
                                            alpha: 0.3,
                                          ),
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Center(
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            'Book Expert',
                                            style: GoogleFonts.outfit(
                                              fontSize: 12.5,
                                              fontWeight: FontWeight.w800,
                                              color: Colors.white,
                                              letterSpacing: -0.1,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          const Icon(
                                            Icons.arrow_forward_rounded,
                                            color: Colors.white,
                                            size: 13,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
            loading: () => ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: 2,
              itemBuilder: (context, index) => const Padding(
                padding: EdgeInsets.only(right: 12),
                child: ShimmerLoading(
                  width: 236,
                  height: 184,
                  borderRadius: 18,
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
        ),
      ],
    );
  }
}
