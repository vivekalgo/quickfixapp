import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:quickfix/core/theme/app_colors.dart';
import 'package:quickfix/core/theme/app_text_styles.dart';
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
          height: 180,
          child: professionalsAsync.when(
            data: (professionals) {
              if (professionals.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Text(
                      'No experts active currently.',
                      style: TextStyle(color: Colors.grey.shade500),
                    ),
                  ),
                );
              }
              return ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
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
                      width: 220,
                      margin: const EdgeInsets.only(right: 16, bottom: 8),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.surfaceDark : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                        border: isDark
                            ? Border.all(color: AppColors.borderDark)
                            : Border.all(
                                color: AppColors.borderLight.withValues(
                                  alpha: 0.6,
                                ),
                              ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundImage: ResizeImage(
                                  NetworkImage(
                                    prof.avatarUrl.isNotEmpty
                                        ? prof.avatarUrl
                                        : 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150',
                                  ),
                                  width: 150,
                                ),
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
                                            style: AppTextStyles.headingSmall(
                                              isDark,
                                            ).copyWith(fontSize: 14),
                                          ),
                                        ),
                                        if (prof.verifiedBadge) ...[
                                          const SizedBox(width: 4),
                                          const Icon(
                                            Icons.verified,
                                            color: Colors.blue,
                                            size: 14,
                                          ),
                                        ],
                                      ],
                                    ),
                                    Text(
                                      '${prof.specialty}${prof.experience.isNotEmpty ? " • ${prof.experience}" : ""}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTextStyles.bodySmall(
                                        isDark,
                                      ).copyWith(fontSize: 11),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.star,
                                    color: Colors.amber,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${prof.rating} (${prof.reviewsCount} reviews)',
                                    style: AppTextStyles.bodySmall(
                                      isDark,
                                    ).copyWith(fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: prof.availability
                                      ? Colors.green.withValues(alpha: 0.1)
                                      : Colors.red.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  prof.availability ? 'Online' : 'Offline',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: prof.availability
                                        ? Colors.green
                                        : Colors.red,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              IconButton(
                                icon: Icon(
                                  isFav
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  color: Colors.redAccent,
                                  size: 20,
                                ),
                                onPressed: () {
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
                              ),
                              ElevatedButton(
                                onPressed: () {
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
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 6,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  elevation: 0,
                                ),
                                child: const Text(
                                  'Book',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
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
                padding: EdgeInsets.only(right: 16),
                child: ShimmerLoading(
                  width: 220,
                  height: 160,
                  borderRadius: 16,
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
