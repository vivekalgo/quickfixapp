import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:dio/dio.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/haptics.dart';
import '../../presentation/providers/home_providers.dart';
import '../../data/models/home_models.dart';
import '../../../../core/network/dio_client.dart';

class CategoryScreen extends ConsumerStatefulWidget {
  final String categoryId;
  const CategoryScreen({super.key, required this.categoryId});

  @override
  ConsumerState<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends ConsumerState<CategoryScreen> {
  List<Shop>? _shops;
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchCategoryShops();
  }

  Future<void> _fetchCategoryShops() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final activeLocation = ref.read(currentAddressProvider);
      final repo = ref.read(homeRepositoryProvider);
      
      // Dynamic query based on selected category, latitude and longitude
      final shops = await repo.searchShops(
        query: widget.categoryId,
        lat: activeLocation.latitude,
        lng: activeLocation.longitude,
      );

      // Filter to keep only active shops
      if (mounted) {
        setState(() {
          _shops = shops;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load services near you: $e';
        });
      }
    }
  }

  String _getCategoryTitle() {
    switch (widget.categoryId.toLowerCase()) {
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
        return '${widget.categoryId[0].toUpperCase()}${widget.categoryId.substring(1)} Services';
    }
  }

  void _showNotifyMeDialog(BuildContext context, bool isDark, UserLocation currentLoc) {
    final phoneController = TextEditingController();
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.notifications_active, color: AppColors.primary, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Get Notified',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : AppColors.secondary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'We\'ll notify you on WhatsApp the moment QuickFix launches ${_getCategoryTitle()} near your location.',
                  style: AppTextStyles.bodySmall(isDark).copyWith(fontSize: 12.5, height: 1.5),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    hintText: 'Enter your phone number',
                    prefixIcon: const Icon(Icons.phone, color: AppColors.primary),
                    filled: true,
                    fillColor: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade100,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: isSubmitting
                        ? null
                        : () async {
                            final phone = phoneController.text.trim();
                            if (phone.length < 10) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Please enter a valid phone number.')),
                              );
                              return;
                            }
                            setDialogState(() {
                              isSubmitting = true;
                            });

                            try {
                              await DioClient().post('/demand/submit', data: {
                                'phone': phone,
                                'address': currentLoc.address,
                                'latitude': currentLoc.latitude,
                                'longitude': currentLoc.longitude,
                              });

                              if (context.mounted) {
                                Navigator.pop(ctx);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text('Thank you! We have registered your area demand.'),
                                    backgroundColor: AppColors.success,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Failed to submit demand: $e')),
                                );
                              }
                            } finally {
                              setDialogState(() {
                                isSubmitting = false;
                              });
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: isSubmitting
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Submit Demand', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildComingSoonScreen(BuildContext context, bool isDark) {
    final currentLoc = ref.watch(currentAddressProvider);
    return Center(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2E2E3A) : const Color(0xFFFFF1F0),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.red.withOpacity(0.15), width: 1.5),
              ),
              child: const Icon(
                Icons.construction,
                color: AppColors.primary,
                size: 56,
              ),
            ).animate().scale(duration: 500.ms, curve: Curves.elasticOut),
            const SizedBox(height: 28),
            Text(
              '🚧 We\'re Coming Soon!',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppColors.secondary,
              ),
            ).animate().fadeIn(delay: 200.ms),
            const SizedBox(height: 12),
            Text(
              'Sorry, QuickFix currently doesn\'t provide ${_getCategoryTitle()} in your area.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium(isDark).copyWith(
                height: 1.5,
              ),
            ).animate().fadeIn(delay: 350.ms),
            const SizedBox(height: 8),
            Text(
              'We\'re expanding rapidly and will be launching services here soon.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall(isDark).copyWith(
                height: 1.4,
              ),
            ).animate().fadeIn(delay: 450.ms),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () => _showNotifyMeDialog(context, isDark, currentLoc),
                icon: const Icon(Icons.notifications_active_outlined, color: Colors.white),
                label: const Text('Notify Me When Available', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ).animate().fadeIn(delay: 550.ms),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      AppHaptics.lightTap();
                      context.push('/location-selector');
                    },
                    icon: const Icon(Icons.edit_location_alt_outlined),
                    label: const Text('Change Address'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: isDark ? Colors.white : AppColors.secondary,
                      side: BorderSide(color: isDark ? Colors.white38 : AppColors.borderLight),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      AppHaptics.mediumTap();
                      _fetchCategoryShops();
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Refresh'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ).animate().fadeIn(delay: 650.ms),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(isDarkModeProvider);

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
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              AppHaptics.mediumTap();
              _fetchCategoryShops();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                      const SizedBox(height: 16),
                      Text(_errorMessage, style: TextStyle(color: isDark ? Colors.white70 : AppColors.secondary)),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _fetchCategoryShops,
                        child: const Text('Retry'),
                      )
                    ],
                  ),
                )
              : (_shops == null || _shops!.isEmpty)
                  ? _buildComingSoonScreen(context, isDark)
                  : ListView.builder(
                      padding: const EdgeInsets.all(16.0),
                      physics: const BouncingScrollPhysics(),
                      itemCount: _shops!.length,
                      itemBuilder: (context, index) {
                        final shop = _shops![index];
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
                              // Route to Shop Details
                              context.push('/shop/${shop.id}', extra: shop);
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
                                        height: 160,
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
    );
  }
}
