import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:quickfix/core/theme/app_colors.dart';
import 'package:quickfix/core/utils/haptics.dart';
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
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. VERIFIED PARTNER BADGE & RATING ROW
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Verified partner badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFF10B981).withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.verified_user_rounded,
                            color: Color(0xFF10B981),
                            size: 13,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'QUICKFIX VERIFIED PARTNER',
                            style: GoogleFonts.outfit(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                              color: const Color(0xFF10B981),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Shop Name
                    Text(
                      shop.name,
                      style: GoogleFonts.outfit(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                        color: isDark ? Colors.white : AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Categories wrap
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: shop.categories
                          .map(
                            (c) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.08)
                                    : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                c,
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: isDark
                                      ? Colors.white70
                                      : const Color(0xFF475569),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Rating distribution card
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [
                            const Color(0xFF1E293B),
                            const Color(0xFF0F172A),
                          ]
                        : [
                            const Color(0xFFFFFBEB),
                            const Color(0xFFFEF3C7),
                          ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.4),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          color: Color(0xFFF59E0B),
                          size: 18,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          shop.rating.toStringAsFixed(1),
                          style: GoogleFonts.outfit(
                            color: isDark ? Colors.white : const Color(0xFF78350F),
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      shop.reviewsCount > 0
                          ? '${shop.reviewsCount}+ ratings'
                          : '4.8★ Recommended',
                      style: GoogleFonts.inter(
                        color: isDark
                            ? Colors.white70
                            : const Color(0xFF92400E),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // 2. METADATA HIGHLIGHTS GRID (Urban Company Style)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.surfaceDark
                  : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark
                    ? AppColors.borderDark
                    : const Color(0xFFE2E8F0),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildUrbanMetaItem(
                  Icons.access_time_filled_rounded,
                  'Operating Hours',
                  shop.timings,
                  const Color(0xFF3B82F6),
                  isDark,
                ),
                Container(
                  height: 32,
                  width: 1,
                  color: isDark ? AppColors.borderDark : const Color(0xFFCBD5E1),
                ),
                _buildUrbanMetaItem(
                  Icons.near_me_rounded,
                  'Distance',
                  '${shop.distanceKm.toStringAsFixed(1)} km away',
                  const Color(0xFF10B981),
                  isDark,
                ),
                Container(
                  height: 32,
                  width: 1,
                  color: isDark ? AppColors.borderDark : const Color(0xFFCBD5E1),
                ),
                _buildUrbanMetaItem(
                  Icons.payments_rounded,
                  'Visiting Charge',
                  '₹${shop.visitingCharges.toInt()}',
                  const Color(0xFF8B5CF6),
                  isDark,
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // 3. URBAN COMPANY OFFER / PROMO BANNER
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF4F46E5).withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.local_offer_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        shop.offerBannerText.isNotEmpty
                            ? shop.offerBannerText
                            : 'Flat ₹100 OFF on First Booking',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        shop.offerBannerSubtext.isNotEmpty
                            ? shop.offerBannerSubtext
                            : 'Use code ${shop.offerBannerCode.isNotEmpty ? shop.offerBannerCode : 'QUICK100'} at checkout • Free inspection included',
                        style: GoogleFonts.inter(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 10.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // 4. QUICKFIX SAFETY & TRUST ASSURANCE CHIPS
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildTrustBadgeChip(
                  Icons.shield_outlined,
                  '30-Day Warranty',
                  const Color(0xFF0284C7),
                  isDark,
                ),
                const SizedBox(width: 8),
                _buildTrustBadgeChip(
                  Icons.badge_outlined,
                  'Verified Pros',
                  const Color(0xFF16A34A),
                  isDark,
                ),
                const SizedBox(width: 8),
                _buildTrustBadgeChip(
                  Icons.sanitizer_outlined,
                  'Hygienic Tools',
                  const Color(0xFFD97706),
                  isDark,
                ),
                const SizedBox(width: 8),
                _buildTrustBadgeChip(
                  Icons.price_check_outlined,
                  'Transparent Pricing',
                  const Color(0xFF9333EA),
                  isDark,
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 5. ABOUT SHOP & LOCATION CARD
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'About Shop & Location',
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : AppColors.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.location_on_rounded,
                      size: 16,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        shop.address.isNotEmpty
                            ? shop.address
                            : 'Verified QuickFix Service Hub.',
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          height: 1.35,
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : const Color(0xFF475569),
                        ),
                      ),
                    ),
                  ],
                ),
                if (shop.phone.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: () async {
                      AppHaptics.mediumTap();
                      final Uri phoneUri = Uri(
                        scheme: 'tel',
                        path: shop.phone,
                      );
                      try {
                        await launchUrl(phoneUri);
                      } catch (_) {}
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.phone_in_talk_rounded,
                            size: 13,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Call Shop: ${shop.phone}',
                            style: GoogleFonts.inter(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                if (shop.technicians.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(
                        Icons.groups_rounded,
                        size: 15,
                        color: Color(0xFF64748B),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Expert Pros: ${shop.technicians.join(', ')}',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : const Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // 6. WORK GALLERY
          if (shop.portfolioImages.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text(
              'Work Gallery & Past Repairs',
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : AppColors.primary,
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 110,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: shop.portfolioImages.length,
                itemBuilder: (context, i) => Container(
                  margin: const EdgeInsets.only(right: 10),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.network(
                      shop.portfolioImages[i],
                      width: 140,
                      height: 110,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 140,
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.broken_image, color: Colors.grey),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildUrbanMetaItem(
    IconData icon,
    String label,
    String value,
    Color accentColor,
    bool isDark,
  ) {
    return Column(
      children: [
        Icon(icon, color: accentColor, size: 18),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10,
            color: isDark ? Colors.white60 : const Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : AppColors.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildTrustBadgeChip(
    IconData icon,
    String label,
    Color color,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
