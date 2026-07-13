import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:quickfix/shared/themes/app_colors.dart';
import 'package:quickfix/shared/themes/app_text_styles.dart';
import 'package:quickfix/shared/utils/haptics.dart';
import 'package:quickfix/features/home/providers/home_providers.dart';
import 'package:quickfix/features/booking/data/models/service_package.dart';
import 'package:quickfix/features/booking/providers/cart_provider.dart';

class ServiceDetailsScreen extends ConsumerWidget {
  final String serviceId;
  const ServiceDetailsScreen({super.key, required this.serviceId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(isDarkModeProvider);
    final cart = ref.watch(cartProvider);
    
    // Find the package from database
    final pkg = packageDatabase.firstWhere(
      (p) => p.id == serviceId,
      orElse: () => packageDatabase.first,
    );

    final isInCart = cart.containsKey(pkg.id);
    final cartItem = cart[pkg.id];
    final quantity = cartItem?.quantity ?? 0;

    final List<Map<String, String>> faqs = [
      {
        'q': 'What tools/chemicals do the professionals bring?',
        'a': 'Our professionals carry premium, eco-friendly, and non-toxic cleaning agents along with heavy-duty vacuum machines and micro-fiber cloths. You do not need to provide anything.',
      },
      {
        'q': 'Do I need to be present during the service?',
        'a': 'While not mandatory, we recommend being present at the start of the service to align on specific areas and at the end to inspect and verify satisfaction.',
      },
      {
        'q': 'Is there a warranty or re-work guarantee?',
        'a': 'Yes, QuickFix provides a 100% satisfaction guarantee. If you are not satisfied with the quality, we will schedule a free re-work session within 30 days.',
      },
    ];

    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // 1. Image Banner Header with back button & Hero animation
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            stretch: true,
            backgroundColor: isDark ? AppColors.backgroundDark : Colors.white,
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircleAvatar(
                backgroundColor: isDark ? Colors.black54 : Colors.white.withOpacity(0.9),
                child: IconButton(
                  icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : AppColors.secondary, size: 20),
                  onPressed: () {
                    AppHaptics.lightTap();
                    context.pop();
                  },
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [StretchMode.zoomBackground],
              background: Hero(
                tag: pkg.id,
                child: Image.network(
                  pkg.imageUrl,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),

          // 2. Content Details Layout
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title, rating and category
                  Text(
                    pkg.subCategory.toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    pkg.title,
                    style: AppTextStyles.headingLarge(isDark),
                  ),
                  const SizedBox(height: 8),
                  
                  // Rating & Reviews row
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.success.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.star, color: AppColors.success, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              '${pkg.rating}',
                              style: const TextStyle(fontSize: 12, color: AppColors.success, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${pkg.reviewsCount} verified reviews',
                        style: AppTextStyles.bodySmall(isDark).copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 16),

                  // Pricing Panel
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '₹${pkg.price.toInt()}',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : AppColors.secondary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '₹${pkg.originalPrice.toInt()}',
                        style: const TextStyle(
                          fontSize: 16,
                          color: AppColors.textSecondaryLight,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${((pkg.originalPrice - pkg.price) / pkg.originalPrice * 100).toInt()}% OFF',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.timer_outlined, size: 16, color: AppColors.textSecondaryLight),
                      const SizedBox(width: 6),
                      Text(
                        'Duration: ${pkg.durationText}',
                        style: AppTextStyles.bodyMedium(isDark).copyWith(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),
                  
                  // Key Highlights / Bullet points
                  Text(
                    'Service Highlights',
                    style: AppTextStyles.headingSmall(isDark),
                  ),
                  const SizedBox(height: 12),
                  ...pkg.bulletPoints.map((bullet) => Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(top: 6.0, right: 10.0),
                              child: Icon(Icons.check_circle_outline, size: 16, color: AppColors.success),
                            ),
                            Expanded(
                              child: Text(
                                bullet,
                                style: AppTextStyles.bodyMedium(isDark),
                              ),
                            ),
                          ],
                        ),
                      )),

                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 20),

                  // What is included
                  Text('What is Included', style: AppTextStyles.headingSmall(isDark)),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green.withOpacity(0.15)),
                    ),
                    child: Column(
                      children: [
                        _buildCheckRow('Trained & Background Verified Experts', Colors.green),
                        const SizedBox(height: 8),
                        _buildCheckRow('Eco-friendly, child & pet safe cleaning sprays', Colors.green),
                        const SizedBox(height: 8),
                        _buildCheckRow('Post-service cleanup and vacuuming', Colors.green),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),
                  
                  // What is excluded
                  Text('What is Excluded', style: AppTextStyles.headingSmall(isDark)),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.withOpacity(0.15)),
                    ),
                    child: Column(
                      children: [
                        _buildCheckRow('Moving of heavy wooden beds/wardrobes', Colors.red, isClose: true),
                        const SizedBox(height: 8),
                        _buildCheckRow('Hard water stain cleaning inside tiles (requires specialized chemical treatment)', Colors.red, isClose: true),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),
                  const Divider(),
                  const SizedBox(height: 20),

                  // FAQ accordion
                  Text('Frequently Asked Questions', style: AppTextStyles.headingSmall(isDark)),
                  const SizedBox(height: 12),
                  ...faqs.map((faq) => Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.surfaceDark : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                        ),
                        child: ExpansionTile(
                          shape: const Border(),
                          title: Text(
                            faq['q']!,
                            style: AppTextStyles.bodyMedium(isDark).copyWith(fontWeight: FontWeight.bold),
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 16.0),
                              child: Text(
                                faq['a']!,
                                style: AppTextStyles.bodySmall(isDark),
                              ),
                            ),
                          ],
                        ),
                      )),
                  
                  const SizedBox(height: 100), // Spacing for floating footer
                ],
              ),
            ),
          ),
        ],
      ),
      
      // Floating Bottom Action Bar
      bottomSheet: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          border: Border(
            top: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Price info column
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '₹${pkg.price.toInt()}',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppColors.secondary,
                    ),
                  ),
                  Text(
                    'Total Price (Incl. of taxes)',
                    style: AppTextStyles.bodySmall(isDark),
                  ),
                ],
              ),
            ),

            // ADD / Quantities toggle or PROCEED
            SizedBox(
              width: 160,
              height: 48,
              child: isInCart
                  ? ElevatedButton(
                      onPressed: () {
                        AppHaptics.heavyTap();
                        context.push('/checkout');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Text('Proceed', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          SizedBox(width: 8),
                          Icon(Icons.chevron_right),
                        ],
                      ),
                    )
                  : ElevatedButton(
                      onPressed: () {
                        AppHaptics.heavyTap();
                        ref.read(cartProvider.notifier).addItem(pkg.id, pkg.title, pkg.price);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary, width: 2),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: const Text('Add to Cart', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    ),
            ),
          ],
        ),
      ).animate().slideY(begin: 1.0, end: 0.0, duration: 300.ms, curve: Curves.easeOutQuad),
    );
  }

  Widget _buildCheckRow(String text, Color color, {bool isClose = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          isClose ? Icons.cancel_outlined : Icons.check_circle_outline,
          color: color,
          size: 14,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: isClose ? Colors.red.shade800 : Colors.green.shade800,
            ),
          ),
        ),
      ],
    );
  }
}
