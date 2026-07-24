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
          title: 'Top Professionals',
          isDark: isDark,
          onSeeAll: () {
            AppHaptics.lightTap();
            context.push('/shops');
          },
        ),

        SizedBox(
          height: 210,
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
                      width: 240,
                      margin: const EdgeInsets.only(right: 14, bottom: 8),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.surfaceDark : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 16,
                            spreadRadius: 0,
                            offset: const Offset(0, 4),
                          ),
                        ],
                        border: isDark
                            ? Border.all(color: AppColors.borderDark)
                            : Border.all(
                                color: const Color(0xFFF0F4F8),
                              ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── Avatar + Info Row ────────────────────────────
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Avatar with ring
                              Stack(
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: AppColors.primaryAccent,
                                        width: 2,
                                      ),
                                    ),
                                    padding: const EdgeInsets.all(2),
                                    child: CircleAvatar(
                                      radius: 26,
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
                                  // Availability dot
                                  Positioned(
                                    right: 1,
                                    bottom: 1,
                                    child: Container(
                                      width: 12,
                                      height: 12,
                                      decoration: BoxDecoration(
                                        color: prof.availability
                                            ? AppColors.success
                                            : AppColors.error,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: isDark
                                              ? AppColors.surfaceDark
                                              : Colors.white,
                                          width: 2,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 12),
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
                                              letterSpacing: -0.3,
                                              color: isDark
                                                  ? Colors.white
                                                  : AppColors.textPrimaryLight,
                                            ),
                                          ),
                                        ),
                                        if (prof.verifiedBadge) ...[
                                          const SizedBox(width: 4),
                                          const Icon(
                                            Icons.verified_rounded,
                                            color: Color(0xFF3B82F6),
                                            size: 14,
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    // Specialty pill
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? AppColors.primaryAccent.withValues(
                                                alpha: 0.12,
                                              )
                                            : AppColors.primaryAccent.withValues(
                                                alpha: 0.08,
                                              ),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        prof.specialty,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.inter(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.primaryAccent,
                                        ),
                                      ),
                                    ),
                                    if (prof.experience.isNotEmpty) ...[
                                      const SizedBox(height: 3),
                                      Text(
                                        prof.experience,
                                        style: GoogleFonts.inter(
                                          fontSize: 10.5,
                                          color: isDark
                                              ? AppColors.textSecondaryDark
                                              : AppColors.textSecondaryLight,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),

                          // ── Stats Row ────────────────────────────────────
                          Row(
                            children: [
                              const Icon(
                                Icons.star_rounded,
                                color: Color(0xFFFFB800),
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                prof.rating.toString(),
                                style: GoogleFonts.outfit(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: isDark
                                      ? Colors.white
                                      : AppColors.textPrimaryLight,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '(${prof.reviewsCount})',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: isDark
                                      ? AppColors.textSecondaryDark
                                      : AppColors.textSecondaryLight,
                                ),
                              ),
                              const Spacer(),
                              // Availability badge
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: prof.availability
                                      ? AppColors.success.withValues(alpha: 0.10)
                                      : AppColors.error.withValues(alpha: 0.10),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  prof.availability ? 'Online' : 'Offline',
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: prof.availability
                                        ? AppColors.success
                                        : AppColors.error,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const Spacer(),

                          // ── Action Row ───────────────────────────────────
                          Row(
                            children: [
                              // Favorite icon button
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
                                  ),
                                  child: Icon(
                                    isFav
                                        ? Icons.favorite_rounded
                                        : Icons.favorite_border_rounded,
                                    color: isFav
                                        ? const Color(0xFFEF4444)
                                        : const Color(0xFF94A3B8),
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
                                      color: AppColors.primary,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Center(
                                      child: Text(
                                        'Book Now',
                                        style: GoogleFonts.outfit(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                          letterSpacing: -0.1,
                                        ),
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
                padding: EdgeInsets.only(right: 14),
                child: ShimmerLoading(
                  width: 240,
                  height: 200,
                  borderRadius: 20,
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
