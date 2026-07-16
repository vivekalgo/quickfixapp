import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quickfix/core/theme/app_colors.dart';
import 'package:quickfix/core/theme/app_text_styles.dart';
import 'package:quickfix/core/widgets/shimmer_loading.dart';
import 'package:quickfix/core/widgets/section_header.dart';
import 'package:quickfix/features/home/models/home_models.dart';
import 'package:quickfix/features/home/presentation/controllers/home_providers.dart';
import 'package:quickfix/core/network/error_handler.dart';

class HomeCustomerReviews extends ConsumerWidget {
  final Map<String, dynamic>? settings;

  const HomeCustomerReviews({super.key, this.settings});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(isDarkModeProvider);
    final reviewsAsync = ref.watch(customerReviewsProvider);
    final String layout = settings?['layout']?.toString() ?? 'slider';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: 'What Our Customers Say', isDark: isDark),
        reviewsAsync.when(
          data: (reviews) {
            if (reviews.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Column(
                    children: [
                      Icon(
                        Icons.rate_review_outlined,
                        color: Colors.grey.shade400,
                        size: 44,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'No reviews yet. Be the first to review!',
                        style: TextStyle(color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                ),
              );
            }

            if (layout == 'grid') {
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 1.15,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: reviews.length,
                itemBuilder: (context, index) =>
                    _buildReviewCard(reviews[index], isDark),
              );
            } else if (layout == 'list') {
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: reviews.length,
                itemBuilder: (context, index) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _buildReviewCard(reviews[index], isDark),
                ),
              );
            } else {
              return SizedBox(
                height: 175,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: reviews.length,
                  itemBuilder: (context, index) {
                    return SizedBox(
                      width: 280,
                      child: _buildReviewCard(reviews[index], isDark),
                    );
                  },
                ),
              );
            }
          },
          loading: () => ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: 2,
            itemBuilder: (context, index) => const Padding(
              padding: EdgeInsets.only(right: 16),
              child: ShimmerLoading(width: 280, height: 155, borderRadius: 16),
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

  Widget _buildReviewCard(Review r, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(right: 16, bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
        border: isDark
            ? Border.all(color: AppColors.borderDark)
            : Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundImage: ResizeImage(
                        NetworkImage(
                          r.userAvatar.isNotEmpty
                              ? r.userAvatar
                              : 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150',
                        ),
                        width: 100,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            r.userName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.headingSmall(
                              isDark,
                            ).copyWith(fontSize: 13),
                          ),
                          Text(
                            '${r.serviceName}${r.providerName.isNotEmpty ? " • ${r.providerName}" : ""}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.bodySmall(
                              isDark,
                            ).copyWith(fontSize: 9),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    Text(
                      r.rating.toString(),
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Icon(Icons.star, color: Colors.green, size: 10),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Text(
              r.comment,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodySmall(
                isDark,
              ).copyWith(fontSize: 11, fontStyle: FontStyle.italic),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                r.date.isNotEmpty ? r.date : 'Verified Booking',
                style: TextStyle(
                  fontSize: 9,
                  color: Colors.green.shade700,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (r.verifiedBadge)
                const Icon(Icons.verified_user, color: Colors.green, size: 12),
            ],
          ),
        ],
      ),
    );
  }
}
