import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/haptics.dart';
import '../../presentation/providers/home_providers.dart';
import '../../data/models/home_models.dart';

class ShopsListScreen extends ConsumerStatefulWidget {
  const ShopsListScreen({super.key});

  @override
  ConsumerState<ShopsListScreen> createState() => _ShopsListScreenState();
}

class _ShopsListScreenState extends ConsumerState<ShopsListScreen> {
  List<Shop>? _allShops;
  List<Shop>? _filteredShops;
  bool _isLoading = true;
  String _searchQuery = '';
  
  bool _filterTopRated = false;
  bool _filterFastDelivery = false;
  bool _filterAffordable = false;

  @override
  void initState() {
    super.initState();
    _fetchShops();
  }

  Future<void> _fetchShops() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final activeLocation = ref.read(currentAddressProvider);
      final repo = ref.read(homeRepositoryProvider);
      final shops = await repo.getNearbyShops(lat: activeLocation.latitude, lng: activeLocation.longitude);
      
      // Sort shops by distance ascending
      shops.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));

      if (mounted) {
        setState(() {
          _allShops = shops;
          _isLoading = false;
          _applyFilters();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _allShops = [];
          _filteredShops = [];
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load shops: $e')),
        );
      }
    }
  }

  void _applyFilters() {
    if (_allShops == null) return;

    List<Shop> temp = List.from(_allShops!);

    // 1. Search Query Filter
    if (_searchQuery.trim().isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      temp = temp.where((s) {
        return s.name.toLowerCase().contains(query) ||
            s.categories.any((c) => c.toLowerCase().contains(query));
      }).toList();
    }

    // 2. Top Rated Filter (rating >= 4.5)
    if (_filterTopRated) {
      temp = temp.where((s) => s.rating >= 4.5).toList();
    }

    // 3. Fast Delivery Filter (<= 15 mins)
    if (_filterFastDelivery) {
      temp = temp.where((s) => s.deliveryTimeMins <= 15).toList();
    }

    // 4. Affordable Filter (₹ or ₹₹)
    if (_filterAffordable) {
      temp = temp.where((s) => s.priceRange == '₹' || s.priceRange == '₹₹').toList();
    }

    setState(() {
      _filteredShops = temp;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(isDarkModeProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Nearby Service Shops', style: AppTextStyles.headingMedium(isDark)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            AppHaptics.lightTap();
            context.pop();
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              AppHaptics.mediumTap();
              _fetchShops();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. Search Box
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: TextField(
              onChanged: (val) {
                setState(() {
                  _searchQuery = val;
                  _applyFilters();
                });
              },
              decoration: InputDecoration(
                hintText: 'Search shops or services...',
                prefixIcon: const Icon(Icons.search, color: AppColors.textSecondaryLight),
                filled: true,
                fillColor: isDark ? AppColors.surfaceDark : Colors.grey.shade100,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                ),
              ),
            ),
          ),

          // 2. Interactive Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
            child: Row(
              children: [
                _buildFilterChip(
                  label: '⭐ Top Rated (4.5+)',
                  isActive: _filterTopRated,
                  onTap: () {
                    AppHaptics.selectionClick();
                    setState(() {
                      _filterTopRated = !_filterTopRated;
                      _applyFilters();
                    });
                  },
                  isDark: isDark,
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: '⚡ Fast Delivery',
                  isActive: _filterFastDelivery,
                  onTap: () {
                    AppHaptics.selectionClick();
                    setState(() {
                      _filterFastDelivery = !_filterFastDelivery;
                      _applyFilters();
                    });
                  },
                  isDark: isDark,
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: '💸 Affordable',
                  isActive: _filterAffordable,
                  onTap: () {
                    AppHaptics.selectionClick();
                    setState(() {
                      _filterAffordable = !_filterAffordable;
                      _applyFilters();
                    });
                  },
                  isDark: isDark,
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // 3. Shop Directory List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : (_filteredShops == null || _filteredShops!.isEmpty)
                    ? _buildEmptyState(isDark)
                    : ListView.builder(
                        padding: const EdgeInsets.all(16.0),
                        physics: const BouncingScrollPhysics(),
                        itemCount: _filteredShops!.length,
                        itemBuilder: (context, index) {
                          final shop = _filteredShops![index];
                          final isFav = ref.watch(wishlistProvider).contains(shop.id);

                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.surfaceDark : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.03),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                              border: Border.all(
                                color: isDark ? AppColors.borderDark : AppColors.borderLight,
                              ),
                            ),
                            child: InkWell(
                              onTap: () {
                                AppHaptics.mediumTap();
                                final catId = shop.categories.isNotEmpty 
                                    ? shop.categories.first.toLowerCase().split(' ')[0] 
                                    : 'cleaning';
                                String finalCat = 'cleaning';
                                if (catId.contains('plumb')) {
                                  finalCat = 'plumbing';
                                } else if (catId.contains('elect') || catId.contains('light')) {
                                  finalCat = 'electrician';
                                } else if (catId.contains('appl') || catId.contains('repair')) {
                                  finalCat = 'appliances';
                                } else if (catId.contains('carp')) {
                                  finalCat = 'carpentry';
                                }
                                context.push('/category/$finalCat');
                              },
                              borderRadius: BorderRadius.circular(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Shop Image Header
                                  Stack(
                                    children: [
                                      ClipRRect(
                                        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                                        child: Image.network(
                                          shop.imagePath,
                                          height: 150,
                                          width: double.infinity,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                      // Star Rating Badge
                                      Positioned(
                                        top: 12,
                                        right: 12,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: AppColors.success,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(Icons.star, color: Colors.white, size: 12),
                                              const SizedBox(width: 4),
                                              Text(
                                                '${shop.rating}',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      // Wishlist Heart Icon
                                      Positioned(
                                        top: 12,
                                        left: 12,
                                        child: GestureDetector(
                                          onTap: () {
                                            AppHaptics.mediumTap();
                                            ref.read(wishlistProvider.notifier).toggleFavourite(shop.id);
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  isFav
                                                      ? 'Removed ${shop.name} from Wishlist'
                                                      : 'Added ${shop.name} to Wishlist',
                                                ),
                                                duration: const Duration(seconds: 1),
                                                behavior: SnackBarBehavior.floating,
                                              ),
                                            );
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.all(6),
                                            decoration: BoxDecoration(
                                              color: Colors.black.withOpacity(0.4),
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(
                                              isFav ? Icons.favorite : Icons.favorite_border,
                                              color: Colors.redAccent,
                                              size: 18,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  
                                  // Details Section
                                  Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          shop.name,
                                          style: AppTextStyles.headingSmall(isDark).copyWith(fontSize: 16),
                                        ),
                                        const SizedBox(height: 6),
                                        // Category Tags
                                        Wrap(
                                          spacing: 6,
                                          runSpacing: 4,
                                          children: shop.categories.map((c) => Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: isDark ? Colors.white.withOpacity(0.08) : Colors.grey.shade100,
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              c,
                                              style: TextStyle(
                                                fontSize: 10.5,
                                                color: isDark ? Colors.white70 : AppColors.textSecondaryLight,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          )).toList(),
                                        ),
                                        const SizedBox(height: 12),
                                        const Divider(height: 1, thickness: 0.5),
                                        const SizedBox(height: 12),
                                        // Dynamic Distance & Delivery Info Row
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Row(
                                              children: [
                                                const Icon(Icons.location_on_outlined, size: 16, color: AppColors.primary),
                                                const SizedBox(width: 4),
                                                Text(
                                                  '${shop.distanceKm.toStringAsFixed(1)} km away',
                                                  style: AppTextStyles.bodySmall(isDark).copyWith(fontWeight: FontWeight.bold),
                                                ),
                                              ],
                                            ),
                                            Row(
                                              children: [
                                                const Icon(Icons.alarm, size: 16, color: AppColors.textSecondaryLight),
                                                const SizedBox(width: 4),
                                                Text(
                                                  '${shop.deliveryTimeMins} mins',
                                                  style: AppTextStyles.bodySmall(isDark),
                                                ),
                                              ],
                                            ),
                                            Text(
                                              shop.priceRange,
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.bold,
                                                color: isDark ? Colors.white70 : AppColors.secondary,
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
                          ).animate(delay: (50 * index).ms).fadeIn().slideY(begin: 0.05, end: 0);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isActive,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive 
              ? (isDark ? Colors.white : AppColors.secondary) 
              : (isDark ? AppColors.surfaceDark : Colors.white),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive 
                ? (isDark ? Colors.white : AppColors.secondary) 
                : (isDark ? AppColors.borderDark : AppColors.borderLight),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            color: isActive 
                ? (isDark ? AppColors.secondary : Colors.white) 
                : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.storefront_outlined, size: 64, color: isDark ? Colors.white24 : Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'No matching shops nearby',
            style: AppTextStyles.headingSmall(isDark),
          ),
          const SizedBox(height: 6),
          Text(
            'Try adjusting your filter options or search query.',
            style: AppTextStyles.bodySmall(isDark),
          ),
        ],
      ),
    );
  }
}
