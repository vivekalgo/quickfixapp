import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:quickfix/core/theme/app_colors.dart';
import 'package:quickfix/core/theme/app_text_styles.dart';
import 'package:quickfix/core/utils/haptics.dart';
import 'package:quickfix/features/home/models/home_models.dart';
import 'package:quickfix/features/home/presentation/controllers/home_providers.dart';
import 'package:quickfix/features/home/presentation/widgets/shop_details_header.dart';
import 'package:quickfix/features/home/presentation/widgets/shop_service_item.dart';
import 'package:quickfix/features/booking/presentation/controllers/cart_provider.dart';
import 'package:quickfix/core/widgets/error_widgets.dart';
import 'package:quickfix/core/network/connectivity_provider.dart';
import 'package:quickfix/core/network/error_handler.dart';

class ShopDetailsScreen extends ConsumerStatefulWidget {
  final String shopId;
  final Shop? initialShop;

  const ShopDetailsScreen({super.key, required this.shopId, this.initialShop});

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
          _errorMessage = ErrorHandler.handle(e).message;
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Replace Cart Items?',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Your cart contains services from another shop. Do you want to clear your cart and add services from ${_shop!.name} instead?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text(
                'Cancel',
                style: TextStyle(color: AppColors.textSecondaryLight),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                ref.read(cartProvider.notifier).clearCart();
                ref.read(cartShopIdProvider.notifier).state = _shop!.id;
                ref
                    .read(cartProvider.notifier)
                    .addItem(
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
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              child: const Text(
                'Replace Items',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      ref.read(cartShopIdProvider.notifier).state = _shop!.id;
      ref
          .read(cartProvider.notifier)
          .addItem(
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
      if (next.value == true &&
          previous?.value == false &&
          (_errorMessage.isNotEmpty || _shop == null)) {
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
            height:
                MediaQuery.of(context).size.height -
                kToolbarHeight -
                MediaQuery.of(context).padding.top -
                50,
            alignment: Alignment.center,
            child: CommonErrorWidget(
              message: _errorMessage.isNotEmpty
                  ? _errorMessage
                  : 'Shop details could not be found.',
              onRetry: _fetchShopDetails,
            ),
          ),
        );
      }

      final shop = _shop!;
      final displayedServices = shop.services
          .where((s) => s.isEnabled != false && s.isAvailable != false)
          .toList();
      final imageToUse = shop.imagePath.isNotEmpty
          ? shop.imagePath
          : 'https://images.unsplash.com/photo-1581578731548-c64695cc6952?w=500';

      return Stack(
        children: [
          CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              // Cover Image Header with Back Button
              SliverAppBar(
                expandedHeight: 220,
                pinned: true,
                stretch: true,
                backgroundColor: isDark
                    ? AppColors.backgroundDark
                    : Colors.white,
                leading: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: CircleAvatar(
                    backgroundColor: isDark
                        ? Colors.black54
                        : Colors.white.withValues(alpha: 0.9),
                    child: IconButton(
                      icon: Icon(
                        Icons.arrow_back,
                        color: isDark ? Colors.white : AppColors.secondary,
                        size: 20,
                      ),
                      onPressed: () {
                        AppHaptics.lightTap();
                        context.pop();
                      },
                    ),
                  ),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  stretchModes: const [StretchMode.zoomBackground],
                  background: Image.network(imageToUse, fit: BoxFit.cover),
                ),
              ),

              // Shop Details Header Card
              SliverToBoxAdapter(
                child: ShopDetailsHeader(
                  shop: shop,
                  isDark: isDark,
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
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final service = displayedServices[index];
                        final quantity = cart[service.id]?.quantity ?? 0;
                        final isInCart = quantity > 0;

                        return ShopServiceItem(
                          service: service,
                          quantity: quantity,
                          isInCart: isInCart,
                          isDark: isDark,
                          onAddToCart: () => _handleAddToCart(service),
                          onRemoveFromCart: () => _handleRemoveFromCart(service),
                        );
                      }, childCount: displayedServices.length),
                    ),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),

          // Floating Cart summary card
          if (totalItems > 0)
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child:
                  GestureDetector(
                    onTap: () {
                      AppHaptics.heavyTap();
                      context.push('/checkout');
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
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
                                child: const Icon(
                                  Icons.shopping_bag_outlined,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '₹${totalAmount.toInt()}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    '$totalItems Item(s) Added',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const Row(
                            children: [
                              Text(
                                'View Cart',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              SizedBox(width: 4),
                              Icon(
                                Icons.chevron_right,
                                color: Colors.white,
                                size: 18,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ).animate().slideY(
                    begin: 1.0,
                    end: 0.0,
                    duration: 250.ms,
                    curve: Curves.easeOutQuad,
                  ),
            ),
        ],
      );
    }

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
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


}
