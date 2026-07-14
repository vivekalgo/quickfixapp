import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:quickfix/shared/themes/app_colors.dart';
import 'package:quickfix/shared/themes/app_text_styles.dart';
import 'package:quickfix/shared/utils/haptics.dart';
import 'package:quickfix/features/home/models/home_models.dart';
import 'package:quickfix/features/home/providers/home_providers.dart';
import 'package:quickfix/features/booking/providers/cart_provider.dart';
import 'package:quickfix/shared/widgets/error_widgets.dart';
import 'package:quickfix/core/providers/connectivity_provider.dart';

class ShopDetailsScreen extends ConsumerStatefulWidget {
  final String shopId;
  final Shop? initialShop;

  const ShopDetailsScreen({
    super.key,
    required this.shopId,
    this.initialShop,
  });

  @override
  ConsumerState<ShopDetailsScreen> createState() => _ShopDetailsScreenState();
}

class _ShopDetailsScreenState extends ConsumerState<ShopDetailsScreen> {
  Shop? _shop;
  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    if (widget.initialShop != null) {
      _shop = widget.initialShop;
    } else {
      _fetchShopDetails();
    }
  }

  Future<void> _fetchShopDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final activeLocation = ref.read(currentAddressProvider);
      final repo = ref.read(homeRepositoryProvider);
      final shops = await repo.getNearbyShops(
        lat: activeLocation.latitude,
        lng: activeLocation.longitude,
      );

      final found = shops.firstWhere(
        (s) => s.id == widget.shopId,
        orElse: () => throw Exception('Shop details not found.'),
      );

      if (mounted) {
        setState(() {
          _shop = found;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load shop details: $e';
        });
      }
    }
  }

  void _handleAddToCart(ShopService service) {
    AppHaptics.heavyTap();
    final activeShopId = ref.read(cartShopIdProvider);

    if (activeShopId != null && activeShopId != _shop!.id) {
      // Prompt user to clear cart from different shop
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Replace Cart Items?', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Text(
            'Your cart contains services from another shop. Do you want to clear your cart and add services from ${_shop!.name} instead?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondaryLight)),
            ),
            ElevatedButton(
              onPressed: () {
                ref.read(cartProvider.notifier).clearCart();
                ref.read(cartShopIdProvider.notifier).state = _shop!.id;
                ref.read(cartProvider.notifier).addItem(
                      service.id,
                      service.title,
                      service.price,
                      pricingType: service.pricingType,
                      isFreeInspection: service.isFreeInspection,
                      visitingCharges: service.visitingCharges,
                      minPrice: service.minPrice,
                      maxPrice: service.maxPrice,
                    );
                Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text('Replace Items', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    } else {
      ref.read(cartShopIdProvider.notifier).state = _shop!.id;
      ref.read(cartProvider.notifier).addItem(
            service.id,
            service.title,
            service.price,
            pricingType: service.pricingType,
            isFreeInspection: service.isFreeInspection,
            visitingCharges: service.visitingCharges,
            minPrice: service.minPrice,
            maxPrice: service.maxPrice,
          );
    }
  }

  void _handleRemoveFromCart(ShopService service) {
    AppHaptics.lightTap();
    ref.read(cartProvider.notifier).removeItem(service.id);
    
    // If cart becomes empty, reset shop id tracker
    final cart = ref.read(cartProvider);
    if (cart.isEmpty) {
      ref.read(cartShopIdProvider.notifier).state = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(isDarkModeProvider);
    final cart = ref.watch(cartProvider);
    final totalItems = ref.watch(cartTotalItemsProvider);
    final totalAmount = ref.watch(cartTotalAmountProvider);

    // Auto-retry on internet reconnection if previously failed
    ref.listen<AsyncValue<bool>>(connectivityProvider, (previous, next) {
      if (next.value == true && previous?.value == false && (_errorMessage.isNotEmpty || _shop == null)) {
        _fetchShopDetails();
      }
    });

    Widget buildBody() {
      if (_isLoading) {
        return const Center(child: CircularProgressIndicator());
      }

      if (_errorMessage.isNotEmpty || _shop == null) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Container(
            height: MediaQuery.of(context).size.height - kToolbarHeight - MediaQuery.of(context).padding.top - 50,
            alignment: Alignment.center,
            child: CommonErrorWidget(
              message: _errorMessage.isNotEmpty ? _errorMessage : 'Shop details could not be found.',
              onRetry: _fetchShopDetails,
            ),
          ),
        );
      }

      final shop = _shop!;
      final displayedServices = shop.services.where((s) => s.isEnabled != false && s.isAvailable != false).toList();
      final imageToUse = shop.imagePath.isNotEmpty
          ? shop.imagePath
          : 'https://images.unsplash.com/photo-1581578731548-c64695cc6952?w=500';

      return Stack(
        children: [
          CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            slivers: [
              // Cover Image Header with Back Button
              SliverAppBar(
                expandedHeight: 220,
                pinned: true,
                stretch: true,
                backgroundColor: isDark ? AppColors.backgroundDark : Colors.white,
                leading: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: CircleAvatar(
                    backgroundColor: isDark ? Colors.black54 : Colors.white.withValues(alpha: 0.9),
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
                  background: Image.network(
                    imageToUse,
                    fit: BoxFit.cover,
                  ),
                ),
              ),

              // Shop Details Header Card
              SliverToBoxAdapter(
                child: Padding(
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
                                  children: shop.categories.map((c) => Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      c,
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: isDark ? Colors.white70 : AppColors.textSecondaryLight,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  )).toList(),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.success.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.star_rounded, color: Color(0xFFFFB300), size: 16),
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
                                      color: isDark ? Colors.white70 : AppColors.textSecondaryLight,
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
                          _buildMetaColumn(Icons.access_time_outlined, 'Timings', shop.timings, isDark),
                          _buildMetaColumn(Icons.location_on_outlined, 'Distance', '${shop.distanceKm.toStringAsFixed(1)} km', isDark),
                          _buildMetaColumn(Icons.payments_outlined, 'Visiting Charge', '₹${shop.visitingCharges.toInt()}', isDark),
                        ],
                      ),

                      const SizedBox(height: 12),
                      const Divider(),
                      const SizedBox(height: 16),

                      // About Shop / Address
                      Text('About Shop & Location', style: AppTextStyles.headingSmall(isDark)),
                      const SizedBox(height: 8),
                      Text(
                        shop.address.isNotEmpty ? shop.address : 'No address specified.',
                        style: AppTextStyles.bodyMedium(isDark),
                      ),
                      if (shop.phone.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.phone_outlined, size: 16, color: AppColors.primary),
                            const SizedBox(width: 8),
                            Text(
                              shop.phone,
                              style: AppTextStyles.bodySmall(isDark).copyWith(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                      if (shop.technicians.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Technicians available: ${shop.technicians.join(', ')}',
                          style: AppTextStyles.bodySmall(isDark).copyWith(fontStyle: FontStyle.italic),
                        ),
                      ],

                      // Portfolio / Gallery
                      if (shop.portfolioImages.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        Text('Work Gallery', style: AppTextStyles.headingSmall(isDark)),
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
                      Text('Available Services', style: AppTextStyles.headingSmall(isDark)),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),

              // Shop Services dynamic listings
              displayedServices.isEmpty
                  ? SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40.0),
                        child: Center(
                          child: Text(
                            'No services published by this shop yet.',
                            style: AppTextStyles.bodyMedium(isDark),
                          ),
                        ),
                      ),
                    )
                  : SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final service = displayedServices[index];
                          final quantity = cart[service.id]?.quantity ?? 0;
                          final isInCart = quantity > 0;

                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.surfaceDark : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                                  blurRadius: 16,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                              border: Border.all(
                                color: isDark ? AppColors.borderDark : AppColors.borderLight,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        service.title,
                                        style: AppTextStyles.headingSmall(isDark).copyWith(fontSize: 15),
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          if (service.pricingType == 'fixed')
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: Colors.green.withValues(alpha: 0.1),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: const Text(
                                                'Fixed Price',
                                                style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold),
                                              ),
                                            )
                                          else if (service.pricingType == 'starting')
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: Colors.amber.withValues(alpha: 0.1),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: const Text(
                                                'Starts From',
                                                style: TextStyle(color: Colors.amber, fontSize: 10, fontWeight: FontWeight.bold),
                                              ),
                                            )
                                          else if (service.pricingType == 'range')
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: Colors.blue.withValues(alpha: 0.1),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: const Text(
                                                'Price Range',
                                                style: TextStyle(color: Colors.blue, fontSize: 10, fontWeight: FontWeight.bold),
                                              ),
                                            )
                                          else if (service.pricingType == 'inspection')
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: Colors.orange.withValues(alpha: 0.1),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: const Text(
                                                'Quote Required',
                                                style: TextStyle(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.bold),
                                              ),
                                            ),
                                           if (service.isFreeInspection) ...[
                                             const SizedBox(width: 6),
                                             Container(
                                               padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                               decoration: BoxDecoration(
                                                 color: Colors.green.withValues(alpha: 0.15),
                                                 borderRadius: BorderRadius.circular(6),
                                                 border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                                               ),
                                               child: const Text(
                                                 'FREE INSPECTION',
                                                 style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold),
                                               ),
                                             ),
                                           ],
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          Text(
                                            service.pricingType == 'inspection'
                                                ? 'Quote Required'
                                                : service.pricingType == 'starting'
                                                    ? 'Starts from ₹${service.price.toInt()}'
                                                    : service.pricingType == 'range'
                                                        ? '₹${service.minPrice.toInt()} - ₹${service.maxPrice.toInt()}'
                                                        : '₹${service.price.toInt()}',
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold,
                                              color: isDark ? Colors.white : AppColors.secondary,
                                            ),
                                          ),
                                          if (service.pricingType == 'fixed' && service.originalPrice > service.price) ...[
                                            const SizedBox(width: 8),
                                            Text(
                                              '₹${service.originalPrice.toInt()}',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: AppColors.textSecondaryLight,
                                                decoration: TextDecoration.lineThrough,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              '${((service.originalPrice - service.price) / service.originalPrice * 100).toInt()}% OFF',
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: AppColors.primary,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          const Icon(Icons.timer_outlined, size: 12, color: AppColors.textSecondaryLight),
                                          const SizedBox(width: 4),
                                          Text(
                                            service.durationText,
                                            style: AppTextStyles.bodySmall(isDark).copyWith(fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                      if (service.bulletPoints.isNotEmpty) ...[
                                        const SizedBox(height: 10),
                                        ...service.bulletPoints.map((bullet) => Padding(
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
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  children: [
                                    if (service.imageUrl.isNotEmpty)
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Image.network(
                                          service.imageUrl,
                                          width: 88,
                                          height: 88,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    const SizedBox(height: 8),
                                    SizedBox(
                                      width: 80,
                                      height: 32,
                                      child: isInCart
                                          ? Container(
                                              decoration: BoxDecoration(
                                                color: AppColors.primary,
                                                borderRadius: BorderRadius.circular(12),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: AppColors.primary.withValues(alpha: 0.2),
                                                    blurRadius: 4,
                                                    offset: const Offset(0, 2),
                                                  ),
                                                ],
                                              ),
                                              child: Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  GestureDetector(
                                                    onTap: () => _handleRemoveFromCart(service),
                                                    child: const Padding(
                                                      padding: EdgeInsets.symmetric(horizontal: 8.0),
                                                      child: Icon(Icons.remove, color: Colors.white, size: 14),
                                                    ),
                                                  ),
                                                  Text(
                                                    '$quantity',
                                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                                                  ),
                                                  GestureDetector(
                                                    onTap: () => _handleAddToCart(service),
                                                    child: const Padding(
                                                      padding: EdgeInsets.symmetric(horizontal: 8.0),
                                                      child: Icon(Icons.add, color: Colors.white, size: 14),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            )
                                          : OutlinedButton(
                                              onPressed: () => _handleAddToCart(service),
                                              style: OutlinedButton.styleFrom(
                                                foregroundColor: AppColors.primary,
                                                backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
                                                side: const BorderSide(color: AppColors.primary, width: 1.5),
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                                padding: EdgeInsets.zero,
                                                elevation: 2,
                                                shadowColor: Colors.black.withValues(alpha: 0.05),
                                              ),
                                              child: const Text('ADD', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                            ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ).animate().fadeIn().slideY(begin: 0.05, end: 0);
                        },
                        childCount: displayedServices.length,
                      ),
                    ),
              const SliverToBoxAdapter(
                child: SizedBox(height: 100),
              ),
            ],
          ),

          // Floating Cart summary card
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
                        color: Colors.black.withValues(alpha: 0.15),
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
                              color: Colors.white.withValues(alpha: 0.1),
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
                      const Row(
                        children: [
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
      );
    }

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: (_isLoading || _errorMessage.isNotEmpty || _shop == null)
          ? AppBar(title: const Text('Shop Details'))
          : null,
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _fetchShopDetails,
        child: buildBody(),
      ),
    );
  }

  Widget _buildMetaColumn(IconData icon, String label, String value, bool isDark) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(fontSize: 10, color: isDark ? Colors.white60 : AppColors.textSecondaryLight),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.secondary),
        ),
      ],
    );
  }
}
