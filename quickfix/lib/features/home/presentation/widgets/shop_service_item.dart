import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quickfix/core/theme/app_colors.dart';
import 'package:quickfix/features/home/models/home_models.dart';

class ShopServiceItem extends StatelessWidget {
  final ShopService service;
  final int quantity;
  final bool isInCart;
  final bool isDark;
  final VoidCallback onAddToCart;
  final VoidCallback onRemoveFromCart;

  const ShopServiceItem({
    super.key,
    required this.service,
    required this.quantity,
    required this.isInCart,
    required this.isDark,
    required this.onAddToCart,
    required this.onRemoveFromCart,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate discount if available
    final hasDiscount = service.pricingType == 'fixed' &&
        service.originalPrice > service.price;
    final discountPercent = hasDiscount
        ? ((service.originalPrice - service.price) / service.originalPrice * 100)
            .toInt()
        : 0;

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: isDark ? 0.25 : 0.05,
            ),
            blurRadius: 16,
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left Content: Title, Badges, Pricing, Inclusions
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Service Title
                Text(
                  service.title,
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                    color: isDark ? Colors.white : AppColors.primary,
                  ),
                ),
                const SizedBox(height: 6),

                // Pricing Badges & Free Inspection Tag
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    if (service.pricingType == 'fixed')
                      _buildPillBadge('Fixed Price', const Color(0xFF10B981))
                    else if (service.pricingType == 'starting')
                      _buildPillBadge('Starts From', const Color(0xFFF59E0B))
                    else if (service.pricingType == 'range')
                      _buildPillBadge('Price Range', const Color(0xFF3B82F6))
                    else if (service.pricingType == 'inspection')
                      _buildPillBadge('Quote Required', const Color(0xFF8B5CF6)),

                    if (service.isFreeInspection)
                      _buildPillBadge('FREE INSPECTION', const Color(0xFF059669)),
                  ],
                ),

                const SizedBox(height: 8),

                // Price Display Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      service.pricingType == 'inspection'
                          ? 'Quote Required'
                          : service.pricingType == 'starting'
                              ? '₹${service.price.toInt()}'
                              : service.pricingType == 'range'
                                  ? '₹${service.minPrice.toInt()} - ₹${service.maxPrice.toInt()}'
                                  : '₹${service.price.toInt()}',
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white : AppColors.primary,
                      ),
                    ),
                    if (service.pricingType == 'starting') ...[
                      const SizedBox(width: 4),
                      Text(
                        'onwards',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: isDark ? Colors.white60 : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                    if (hasDiscount) ...[
                      const SizedBox(width: 8),
                      Text(
                        '₹${service.originalPrice.toInt()}',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDC2626).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '$discountPercent% OFF',
                          style: GoogleFonts.outfit(
                            fontSize: 10,
                            color: const Color(0xFFDC2626),
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: 8),

                // Duration Chip
                Row(
                  children: [
                    const Icon(
                      Icons.schedule_rounded,
                      size: 13,
                      color: Color(0xFF64748B),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      service.durationText,
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white70 : const Color(0xFF475569),
                      ),
                    ),
                  ],
                ),

                // Inclusions / Bullet Points with Green Checkmarks
                if (service.bulletPoints.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  ...service.bulletPoints.map(
                    (bullet) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 2.0, right: 6.0),
                            child: Icon(
                              Icons.check_circle_rounded,
                              size: 13,
                              color: Color(0xFF10B981),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              bullet,
                              style: GoogleFonts.inter(
                                fontSize: 11.5,
                                height: 1.3,
                                color: isDark
                                    ? Colors.white70
                                    : const Color(0xFF475569),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ] else ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        Icons.check_circle_rounded,
                        size: 13,
                        color: Color(0xFF10B981),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '30-Day Money Back Warranty included',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF10B981),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(width: 14),

          // Right Content: Image Stack & Urban Style ADD / Stepper Button
          Column(
            children: [
              Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.bottomCenter,
                children: [
                  // Service Image
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: isDark
                          ? const Color(0xFF1E293B)
                          : const Color(0xFFF1F5F9),
                      border: Border.all(
                        color: isDark
                            ? AppColors.borderDark
                            : const Color(0xFFE2E8F0),
                        width: 1,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: service.imageUrl.isNotEmpty
                          ? Image.network(
                              service.imageUrl,
                              width: 96,
                              height: 96,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.build_rounded,
                                color: Colors.grey,
                                size: 28,
                              ),
                            )
                          : const Icon(
                              Icons.handyman_rounded,
                              color: Colors.grey,
                              size: 28,
                            ),
                    ),
                  ),

                  // Urban Company Style ADD Button / Quantity Stepper
                  Positioned(
                    bottom: -14,
                    child: SizedBox(
                      width: 86,
                      height: 34,
                      child: isInCart
                          ? Container(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    AppColors.primary,
                                    AppColors.primaryAccent,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withValues(alpha: 0.35),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  GestureDetector(
                                    onTap: onRemoveFromCart,
                                    behavior: HitTestBehavior.opaque,
                                    child: const Padding(
                                      padding:
                                          EdgeInsets.symmetric(horizontal: 8.0),
                                      child: Icon(
                                        Icons.remove_rounded,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '$quantity',
                                    style: GoogleFonts.outfit(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 13,
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: onAddToCart,
                                    behavior: HitTestBehavior.opaque,
                                    child: const Padding(
                                      padding:
                                          EdgeInsets.symmetric(horizontal: 8.0),
                                      child: Icon(
                                        Icons.add_rounded,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ElevatedButton(
                              onPressed: onAddToCart,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isDark
                                    ? AppColors.surfaceDark
                                    : Colors.white,
                                foregroundColor: isDark ? Colors.white : AppColors.primary,
                                elevation: 3,
                                shadowColor: Colors.black.withValues(alpha: 0.12),
                                padding: EdgeInsets.zero,
                                side: BorderSide(
                                  color: isDark ? AppColors.primaryAccent : AppColors.primary,
                                  width: 1.5,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'ADD',
                                    style: GoogleFonts.outfit(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 13,
                                      letterSpacing: 0.5,
                                      color: isDark ? Colors.white : AppColors.primary,
                                    ),
                                  ),
                                  const SizedBox(width: 3),
                                  Icon(
                                    Icons.add_rounded,
                                    size: 15,
                                    color: isDark ? Colors.white : AppColors.primary,
                                  ),
                                ],
                              ),
                            ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
            ],
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.05, end: 0);
  }

  Widget _buildPillBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: color.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: Text(
        label,
        style: GoogleFonts.outfit(
          color: color,
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
