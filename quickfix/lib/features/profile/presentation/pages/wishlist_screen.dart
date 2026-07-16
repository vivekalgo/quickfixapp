import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:quickfix/core/theme/app_colors.dart';
import 'package:quickfix/core/theme/app_text_styles.dart';
import 'package:quickfix/core/utils/haptics.dart';
import 'package:quickfix/core/widgets/glass_container.dart';
import 'package:quickfix/features/home/presentation/controllers/home_providers.dart';
import 'package:quickfix/features/home/models/home_models.dart';
import 'package:quickfix/core/widgets/error_widgets.dart';
import 'package:quickfix/core/network/connectivity_provider.dart';
import 'package:quickfix/core/network/error_handler.dart';

class WishlistScreen extends ConsumerStatefulWidget {
  const WishlistScreen({super.key});

  @override
  ConsumerState<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends ConsumerState<WishlistScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(isDarkModeProvider);
    final wishlist = ref.watch(wishlistProvider);

    final shopsAsync = ref.watch(nearbyShopsProvider);
    final expertsAsync = ref.watch(topProfessionalsProvider);

    // Auto-retry on internet reconnection if previously failed
    ref.listen<AsyncValue<bool>>(connectivityProvider, (previous, next) {
      if (next.value == true && previous?.value == false) {
        if (shopsAsync.hasError) ref.invalidate(nearbyShopsProvider);
        if (expertsAsync.hasError) ref.invalidate(topProfessionalsProvider);
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text('My Wishlist', style: AppTextStyles.headingMedium(isDark)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            AppHaptics.lightTap();
            if (context.canPop()) {
              context.pop();
            } else {
              ref.read(currentNavIndexProvider.notifier).state = 0;
              context.go('/home');
            }
          },
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: isDark
              ? AppColors.textSecondaryDark
              : AppColors.textSecondaryLight,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'Shops & Centers'),
            Tab(text: 'Service Experts'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Shops Tab
          RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async {
              ref.invalidate(nearbyShopsProvider);
              await ref.read(nearbyShopsProvider.future);
            },
            child: shopsAsync.when(
              data: (allShops) {
                final favShops = allShops
                    .where((shop) => wishlist.contains(shop.id))
                    .toList();
                return _buildShopsTab(favShops, isDark);
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Container(
                  height: MediaQuery.of(context).size.height - 200,
                  alignment: Alignment.center,
                  child: CommonErrorWidget(
                    message: ErrorHandler.handle(err, stack).message,
                    onRetry: () => ref.invalidate(nearbyShopsProvider),
                  ),
                ),
              ),
            ),
          ),

          // Experts Tab
          RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async {
              ref.invalidate(topProfessionalsProvider);
              await ref.read(topProfessionalsProvider.future);
            },
            child: expertsAsync.when(
              data: (allExperts) {
                final favExperts = allExperts
                    .where((prof) => wishlist.contains(prof.id))
                    .toList();
                return _buildExpertsTab(favExperts, isDark);
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Container(
                  height: MediaQuery.of(context).size.height - 200,
                  alignment: Alignment.center,
                  child: CommonErrorWidget(
                    message: ErrorHandler.handle(err, stack).message,
                    onRetry: () => ref.invalidate(topProfessionalsProvider),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShopsTab(List<Shop> shops, bool isDark) {
    if (shops.isEmpty) {
      return _buildEmptyState(
        isDark,
        icon: Icons.storefront_outlined,
        title: 'No Favorite Shops Yet',
        subtitle:
            'Save nearby service hubs and repair stations for quick access.',
      );
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: shops.length,
      itemBuilder: (context, index) {
        final shop = shops[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: InkWell(
            onTap: () {
              AppHaptics.lightTap();
              context.push('/shop/${shop.id}', extra: shop);
            },
            borderRadius: BorderRadius.circular(16),
            child: Row(
              children: [
                // Shop Image
                ClipRRect(
                  borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(16),
                  ),
                  child: Image.network(
                    shop.imagePath,
                    width: 110,
                    height: 110,
                    fit: BoxFit.cover,
                    cacheWidth: 330,
                  ),
                ),
                const SizedBox(width: 14),
                // Details
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 12.0,
                      horizontal: 4.0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          shop.name,
                          style: AppTextStyles.headingSmall(
                            isDark,
                          ).copyWith(fontSize: 15),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          shop.categories.join(', '),
                          style: AppTextStyles.bodySmall(isDark),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              color: Color(0xFFFFB300),
                              size: 15,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              shop.rating.toStringAsFixed(1),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? Colors.white70
                                    : AppColors.secondary,
                                fontSize: 12,
                              ),
                            ),
                            if (shop.reviewsCount > 0) ...[
                              const SizedBox(width: 3),
                              Text(
                                '(${shop.reviewsCount})',
                                style: TextStyle(
                                  color: isDark
                                      ? Colors.white54
                                      : Colors.grey[600],
                                  fontSize: 10,
                                ),
                              ),
                            ],
                            const SizedBox(width: 12),
                            const Icon(
                              Icons.location_on_outlined,
                              color: AppColors.textSecondaryLight,
                              size: 13,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              '${shop.distanceKm.toStringAsFixed(1)} km',
                              style: AppTextStyles.bodySmall(isDark),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                // Heart icon
                IconButton(
                  icon: const Icon(Icons.favorite, color: Colors.redAccent),
                  onPressed: () {
                    AppHaptics.mediumTap();
                    ref
                        .read(wishlistProvider.notifier)
                        .toggleFavourite(shop.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Removed ${shop.name} from Wishlist'),
                        duration: const Duration(seconds: 1),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
                const SizedBox(width: 8),
              ],
            ),
          ),
        ).animate(delay: (50 * index).ms).fadeIn().slideY(begin: 0.05, end: 0);
      },
    );
  }

  Widget _buildExpertsTab(List<Professional> experts, bool isDark) {
    if (experts.isEmpty) {
      return _buildEmptyState(
        isDark,
        icon: Icons.person_pin_outlined,
        title: 'No Favorite Experts Yet',
        subtitle:
            'Save premium handymen and specialists to request them on-demand.',
      );
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: experts.length,
      itemBuilder: (context, index) {
        final prof = experts[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: InkWell(
            onTap: () {
              AppHaptics.lightTap();
              final category =
                  prof.specialty.toLowerCase().contains('electrician')
                  ? 'electrician'
                  : 'plumbing';
              context.push('/category/$category');
            },
            borderRadius: BorderRadius.circular(16),
            child: Row(
              children: [
                const SizedBox(width: 14),
                // Avatar
                CircleAvatar(
                  radius: 28,
                  backgroundImage: ResizeImage(
                    NetworkImage(prof.avatarUrl),
                    width: 150,
                  ),
                ),
                const SizedBox(width: 14),
                // Details
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          prof.name,
                          style: AppTextStyles.headingSmall(
                            isDark,
                          ).copyWith(fontSize: 15),
                        ),
                        Text(
                          prof.specialty,
                          style: AppTextStyles.bodySmall(isDark),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(
                              Icons.star,
                              color: Colors.amber,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${prof.rating} (${prof.reviewsCount} reviews)',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? Colors.white70
                                    : AppColors.secondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                // Heart icon
                IconButton(
                  icon: const Icon(Icons.favorite, color: Colors.redAccent),
                  onPressed: () {
                    AppHaptics.mediumTap();
                    ref
                        .read(wishlistProvider.notifier)
                        .toggleFavourite(prof.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Removed ${prof.name} from Wishlist'),
                        duration: const Duration(seconds: 1),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
                const SizedBox(width: 8),
              ],
            ),
          ),
        ).animate(delay: (50 * index).ms).fadeIn().slideY(begin: 0.05, end: 0);
      },
    );
  }

  Widget _buildEmptyState(
    bool isDark, {
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: SizedBox(
        height: MediaQuery.of(context).size.height - 250,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Glassmorphism Placeholder
                GlassContainer(
                  width: 100,
                  height: 100,
                  borderRadius: BorderRadius.circular(50),
                  blur: 8,
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.black.withValues(alpha: 0.1),
                    width: 1.5,
                  ),
                  child: Center(
                    child: Icon(icon, size: 44, color: AppColors.primary),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  title,
                  style: AppTextStyles.headingMedium(
                    isDark,
                  ).copyWith(fontSize: 18),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  style: AppTextStyles.bodyMedium(isDark),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () {
                    AppHaptics.heavyTap();
                    ref.read(currentNavIndexProvider.notifier).state =
                        0; // Home tab
                    context.go('/home');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Explore Services',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
