import 'package:flutter/material.dart';
import 'package:quickfix/core/theme/app_colors.dart';
import 'package:quickfix/core/theme/app_text_styles.dart';
import 'package:quickfix/features/home/models/home_models.dart';

class ShopDetailsHeader extends StatelessWidget {
  final Shop shop;
  final bool isDark;

  const ShopDetailsHeader({
    super.key,
    required this.shop,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      shop.name,
                      style: AppTextStyles.headingLarge(isDark),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: shop.categories
                          .map(
                            (c) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.08)
                                    : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                c,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: isDark
                                      ? Colors.white70
                                      : AppColors.textSecondaryLight,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.success.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      color: Color(0xFFFFB300),
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      shop.rating.toStringAsFixed(1),
                      style: TextStyle(
                        color: isDark ? Colors.white : AppColors.secondary,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    if (shop.reviewsCount > 0) ...[
                      const SizedBox(width: 4),
                      Text(
                        '(${shop.reviewsCount})',
                        style: TextStyle(
                          color: isDark
                              ? Colors.white70
                              : AppColors.textSecondaryLight,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 12),

          // Metadata Grid (Timings, Radius, Visiting Fees)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMetaColumn(
                Icons.access_time_outlined,
                'Timings',
                shop.timings,
                isDark,
              ),
              _buildMetaColumn(
                Icons.location_on_outlined,
                'Distance',
                '${shop.distanceKm.toStringAsFixed(1)} km',
                isDark,
              ),
              _buildMetaColumn(
                Icons.payments_outlined,
                'Visiting Charge',
                '₹${shop.visitingCharges.toInt()}',
                isDark,
              ),
            ],
          ),

          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 16),

          // About Shop / Address
          Text(
            'About Shop & Location',
            style: AppTextStyles.headingSmall(isDark),
          ),
          const SizedBox(height: 8),
          Text(
            shop.address.isNotEmpty ? shop.address : 'No address specified.',
            style: AppTextStyles.bodyMedium(isDark),
          ),
          if (shop.phone.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(
                  Icons.phone_outlined,
                  size: 16,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  shop.phone,
                  style: AppTextStyles.bodySmall(isDark).copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
          if (shop.technicians.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Technicians available: ${shop.technicians.join(', ')}',
              style: AppTextStyles.bodySmall(isDark).copyWith(
                fontStyle: FontStyle.italic,
              ),
            ),
          ],

          // Portfolio / Gallery
          if (shop.portfolioImages.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text(
              'Work Gallery',
              style: AppTextStyles.headingSmall(isDark),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: shop.portfolioImages.length,
                itemBuilder: (context, i) => Container(
                  margin: const EdgeInsets.only(right: 12),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      shop.portfolioImages[i],
                      width: 120,
                      height: 100,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ),
          ],

          const SizedBox(height: 24),
          Text(
            'Available Services',
            style: AppTextStyles.headingSmall(isDark),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildMetaColumn(
    IconData icon,
    String label,
    String value,
    bool isDark,
  ) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: isDark ? Colors.white60 : AppColors.textSecondaryLight,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : AppColors.secondary,
          ),
        ),
      ],
    );
  }
}
