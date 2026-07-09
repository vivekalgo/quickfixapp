import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/haptics.dart';
import '../../../../core/widgets/glass_container.dart';
import '../../../home/presentation/providers/home_providers.dart';
import '../../../home/data/models/home_models.dart';

class WishlistScreen extends ConsumerStatefulWidget {
  const WishlistScreen({super.key});

  @override
  ConsumerState<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends ConsumerState<WishlistScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Local copy of shop database for lookup
  final List<Shop> _allShops = const [
    Shop(
      id: '1',
      name: 'QuickFix Solutions',
      categories: ['Plumbing', 'Electrical'],
      rating: 4.6,
      distanceKm: 1.2,
      deliveryTimeMins: 15,
      priceRange: '₹₹',
      imagePath: 'https://images.unsplash.com/photo-1621905251189-08b45d6a269e?w=500&auto=format&fit=crop&q=60',
    ),
    Shop(
      id: '2',
      name: 'HomeFix Services',
      categories: ['Cleaning', 'Appliances'],
      rating: 4.4,
      distanceKm: 1.8,
      deliveryTimeMins: 20,
      priceRange: '₹',
      imagePath: 'https://images.unsplash.com/photo-1527515637462-cff94eecc1ac?w=500&auto=format&fit=crop&q=60',
    ),
    Shop(
      id: '3',
      name: 'FixIt Pro',
      categories: ['Carpentry', 'Painting'],
      rating: 4.7,
      distanceKm: 0.9,
      deliveryTimeMins: 10,
      priceRange: '₹₹',
      imagePath: 'https://images.unsplash.com/photo-1534081333815-ae5019106622?w=500&auto=format&fit=crop&q=60',
    ),
  ];

  // Local copy of professional database for lookup
  final List<Professional> _allProfessionals = const [
    Professional(
      id: 'p1',
      name: 'Rohan Sharma',
      specialty: 'Expert Electrician',
      rating: 4.9,
      reviewsCount: 320,
      avatarUrl: 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150',
    ),
    Professional(
      id: 'p2',
      name: 'Suresh Kumar',
      specialty: 'Master Plumber',
      rating: 4.8,
      reviewsCount: 240,
      avatarUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150',
    ),
  ];

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

    // Filter down to favorited items
    final favShops = _allShops.where((shop) => wishlist.contains(shop.id)).toList();
    final favExperts = _allProfessionals.where((prof) => wishlist.contains(prof.id)).toList();

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
          unselectedLabelColor: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
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
          _buildShopsTab(favShops, isDark),
          _buildExpertsTab(favExperts, isDark),
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
        subtitle: 'Save nearby service hubs and repair stations for quick access.',
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
            border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: InkWell(
            onTap: () {
              AppHaptics.lightTap();
              // Navigate to category screen matching the first category of the shop
              final category = shop.categories.first.toLowerCase();
              context.push('/category/$category');
            },
            borderRadius: BorderRadius.circular(16),
            child: Row(
              children: [
                // Shop Image
                ClipRRect(
                  borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
                  child: Image.network(
                    shop.imagePath,
                    width: 110,
                    height: 110,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 14),
                // Details
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 4.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          shop.name,
                          style: AppTextStyles.headingSmall(isDark).copyWith(fontSize: 15),
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
                            const Icon(Icons.star, color: Colors.amber, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              '${shop.rating} ★',
                              style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : AppColors.secondary, fontSize: 12),
                            ),
                            const SizedBox(width: 12),
                            const Icon(Icons.location_on_outlined, color: AppColors.textSecondaryLight, size: 13),
                            const SizedBox(width: 2),
                            Text(
                              '${shop.distanceKm} km',
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
                    ref.read(wishlistProvider.notifier).toggleFavourite(shop.id);
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
        subtitle: 'Save premium handymen and specialists to request them on-demand.',
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
            border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: InkWell(
            onTap: () {
              AppHaptics.lightTap();
              final category = prof.specialty.toLowerCase().contains('electrician') ? 'electrician' : 'plumbing';
              context.push('/category/$category');
            },
            borderRadius: BorderRadius.circular(16),
            child: Row(
              children: [
                const SizedBox(width: 14),
                // Avatar
                CircleAvatar(
                  radius: 28,
                  backgroundImage: NetworkImage(prof.avatarUrl),
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
                          style: AppTextStyles.headingSmall(isDark).copyWith(fontSize: 15),
                        ),
                        Text(
                          prof.specialty,
                          style: AppTextStyles.bodySmall(isDark),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.star, color: Colors.amber, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              '${prof.rating} (${prof.reviewsCount} reviews)',
                              style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : AppColors.secondary, fontSize: 12),
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
                    ref.read(wishlistProvider.notifier).toggleFavourite(prof.id);
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

  Widget _buildEmptyState(bool isDark, {required IconData icon, required String title, required String subtitle}) {
    return Center(
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
                color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1),
                width: 1.5,
              ),
              child: Center(
                child: Icon(
                  icon,
                  size: 44,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: AppTextStyles.headingMedium(isDark).copyWith(fontSize: 18),
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
                ref.read(currentNavIndexProvider.notifier).state = 0; // Home tab
                context.go('/home');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Explore Services', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
