import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/haptics.dart';
import '../../presentation/providers/home_providers.dart';
import '../../data/models/home_models.dart';
import '../../../../features/booking/presentation/providers/cart_provider.dart';
import '../../../booking/data/models/service_package.dart';

class CategoryScreen extends ConsumerStatefulWidget {
  final String categoryId;
  const CategoryScreen({super.key, required this.categoryId});

  @override
  ConsumerState<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends ConsumerState<CategoryScreen> {
  String _selectedSub = '';
  final List<String> _subCategories = [];

  @override
  void initState() {
    super.initState();
    if (widget.categoryId == 'all') {
      _subCategories.add('All');
      final matches = packageDatabase.map((p) => p.categoryId).toSet().toList();
      _subCategories.addAll(matches);
      _selectedSub = 'All';
    } else {
      final matches = packageDatabase.where((p) => p.categoryId == widget.categoryId).map((p) => p.subCategory).toSet().toList();
      if (matches.isNotEmpty) {
        _subCategories.addAll(matches);
        _selectedSub = _subCategories.first;
      }
    }
  }

  String _getCategoryTitle() {
    switch (widget.categoryId) {
      case 'cleaning':
        return 'Cleaning Services';
      case 'plumbing':
        return 'Plumbing Services';
      case 'electrician':
        return 'Electrical Services';
      case 'appliances':
        return 'Appliances Repair';
      case 'carpentry':
        return 'Carpentry Services';
      case 'all':
        return 'All Services';
      default:
        return 'QuickFix Premium';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(isDarkModeProvider);
    final cart = ref.watch(cartProvider);
    final totalItems = ref.watch(cartTotalItemsProvider);
    final totalAmount = ref.watch(cartTotalAmountProvider);

    // Filter packages matching category and subcategory
    final packages = packageDatabase.where((p) {
      if (widget.categoryId == 'all') {
        if (_selectedSub == 'All') return true;
        return p.categoryId == _selectedSub;
      }
      return p.categoryId == widget.categoryId && (_selectedSub.isEmpty || p.subCategory == _selectedSub);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(_getCategoryTitle(), style: AppTextStyles.headingMedium(isDark)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            AppHaptics.lightTap();
            context.pop();
          },
        ),
      ),
      body: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Horizontal subcategory tags row
              if (_subCategories.isNotEmpty) ...[
                const SizedBox(height: 8),
                SizedBox(
                  height: 38,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _subCategories.length,
                    itemBuilder: (context, index) {
                      final sub = _subCategories[index];
                      final isSelected = _selectedSub == sub;
                      
                      String displayTitle = sub;
                      if (widget.categoryId == 'all') {
                        if (sub == 'cleaning') {
                          displayTitle = 'Cleaning';
                        } else if (sub == 'plumbing') {
                          displayTitle = 'Plumbing';
                        } else if (sub == 'electrician') {
                          displayTitle = 'Electrician';
                        } else if (sub == 'appliances') {
                          displayTitle = 'Appliances';
                        } else if (sub == 'carpentry') {
                          displayTitle = 'Carpentry';
                        } else if (sub == 'All') {
                          displayTitle = 'All Services';
                        }
                      }

                      return GestureDetector(
                        onTap: () {
                          AppHaptics.selectionClick();
                          setState(() {
                            _selectedSub = sub;
                          });
                        },
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected 
                                ? (isDark ? Colors.white : AppColors.secondary) 
                                : (isDark ? AppColors.surfaceDark : Colors.white),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected 
                                  ? (isDark ? Colors.white : AppColors.secondary) 
                                  : (isDark ? AppColors.borderDark : AppColors.borderLight),
                            ),
                          ),
                          child: Text(
                            displayTitle,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected 
                                  ? (isDark ? AppColors.secondary : Colors.white) 
                                  : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Service Packages list
              Expanded(
                child: packages.isEmpty
                    ? Center(
                        child: Text(
                          'No services available under this section',
                          style: AppTextStyles.bodyMedium(isDark),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 90),
                        itemCount: packages.length,
                        itemBuilder: (context, index) {
                          final pkg = packages[index];
                          final isInCart = cart.containsKey(pkg.id);
                          final cartItem = cart[pkg.id];
                          final quantity = cartItem?.quantity ?? 0;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.surfaceDark : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.02),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                              border: isDark 
                                  ? Border.all(color: AppColors.borderDark)
                                  : Border.all(color: AppColors.borderLight),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Left details panel
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        pkg.title,
                                        style: AppTextStyles.headingSmall(isDark).copyWith(fontSize: 15),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Colors.green.shade50,
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Row(
                                              children: [
                                                const Icon(Icons.star, color: Colors.green, size: 10),
                                                const SizedBox(width: 2),
                                                Text(
                                                  '${pkg.rating}',
                                                  style: const TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.bold),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            '(${pkg.reviewsCount} reviews)',
                                            style: AppTextStyles.bodySmall(isDark).copyWith(fontSize: 10),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Text(
                                            '₹${pkg.price.toInt()}',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: isDark ? Colors.white : AppColors.secondary,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            '₹${pkg.originalPrice.toInt()}',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: AppColors.textSecondaryLight,
                                              decoration: TextDecoration.lineThrough,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            '${((pkg.originalPrice - pkg.price) / pkg.originalPrice * 100).toInt()}% OFF',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: AppColors.primary,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          const Icon(Icons.alarm, size: 12, color: AppColors.textSecondaryLight),
                                          const SizedBox(width: 4),
                                          Text(
                                            pkg.durationText,
                                            style: AppTextStyles.bodySmall(isDark).copyWith(fontWeight: FontWeight.w600),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      // Bullet points description
                                      ...pkg.bulletPoints.map((bullet) => Padding(
                                            padding: const EdgeInsets.only(bottom: 4),
                                            child: Row(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                const Padding(
                                                  padding: EdgeInsets.only(top: 4.0, right: 6.0),
                                                  child: Icon(Icons.circle, size: 4, color: AppColors.textSecondaryLight),
                                                ),
                                                Expanded(
                                                  child: Text(
                                                    bullet,
                                                    style: AppTextStyles.bodySmall(isDark).copyWith(fontSize: 11),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          )),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                
                                // Right image & Add/Minus panel
                                Column(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.network(
                                        pkg.imageUrl,
                                        width: 100,
                                        height: 100,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    
                                    // ADD / Quantity Selector Button
                                    SizedBox(
                                      width: 88,
                                      height: 36,
                                      child: isInCart
                                          ? Container(
                                              decoration: BoxDecoration(
                                                color: AppColors.primary,
                                                borderRadius: BorderRadius.circular(18),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: AppColors.primary.withOpacity(0.2),
                                                    blurRadius: 4,
                                                  ),
                                                ],
                                              ),
                                              child: Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  GestureDetector(
                                                    onTap: () {
                                                      AppHaptics.lightTap();
                                                      ref.read(cartProvider.notifier).removeItem(pkg.id);
                                                    },
                                                    child: const Padding(
                                                      padding: EdgeInsets.symmetric(horizontal: 10.0),
                                                      child: Icon(Icons.remove, color: Colors.white, size: 16),
                                                    ),
                                                  ),
                                                  Text(
                                                    '$quantity',
                                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                                  ),
                                                  GestureDetector(
                                                    onTap: () {
                                                      AppHaptics.lightTap();
                                                      ref.read(cartProvider.notifier).addItem(pkg.id, pkg.title, pkg.price);
                                                    },
                                                    child: const Padding(
                                                      padding: EdgeInsets.symmetric(horizontal: 10.0),
                                                      child: Icon(Icons.add, color: Colors.white, size: 16),
                                                    ),
                                                  ),
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
                                                side: const BorderSide(color: AppColors.primary, width: 1.5),
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                                                elevation: 0,
                                                padding: EdgeInsets.zero,
                                              ),
                                              child: Text(
                                                'ADD',
                                                style: AppTextStyles.badgeText.copyWith(
                                                  color: AppColors.primary,
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ).animate(delay: (50 * index).ms).fadeIn().slideY(begin: 0.05, end: 0);
                        },
                      ),
              ),
            ],
          ),

          // Floating Cart Summary bottom popup card
          if (totalItems > 0)
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: GestureDetector(
                onTap: () {
                  AppHaptics.heavyTap();
                  context.push('/checkout');
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    gradient: AppColors.plusGradient,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.shopping_bag_outlined, color: Colors.white, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '₹${totalAmount.toInt()}',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              Text(
                                '$totalItems Item(s) Added',
                                style: const TextStyle(color: Colors.white70, fontSize: 11),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Row(
                        children: const [
                          Text(
                            'View Cart',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          SizedBox(width: 4),
                          Icon(Icons.chevron_right, color: Colors.white, size: 18),
                        ],
                      ),
                    ],
                  ),
                ),
              ).animate().slideY(begin: 1.0, end: 0.0, duration: 250.ms, curve: Curves.easeOutQuad),
            ),
        ],
      ),
    );
  }
}
