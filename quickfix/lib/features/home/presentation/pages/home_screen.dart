import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quickfix/core/theme/app_colors.dart';
import 'package:quickfix/core/theme/app_text_styles.dart';
import 'package:quickfix/core/theme/app_shadows.dart';
import 'package:quickfix/core/utils/haptics.dart';
import 'package:quickfix/core/utils/cta_handler.dart';
import 'package:quickfix/core/widgets/shimmer_loading.dart';
import 'package:quickfix/features/home/models/home_models.dart';
import 'package:quickfix/features/home/presentation/controllers/home_providers.dart';
import 'package:quickfix/features/notifications/presentation/controllers/notifications_provider.dart';
import 'package:quickfix/features/home/presentation/widgets/home_header.dart';
import 'package:quickfix/features/home/presentation/widgets/home_banner_carousel.dart';
import 'package:quickfix/features/home/presentation/widgets/home_categories_grid.dart';
import 'package:quickfix/features/home/presentation/widgets/home_promo_banner.dart';
import 'package:quickfix/features/home/presentation/widgets/home_nearby_shops.dart';
import 'package:quickfix/features/home/presentation/widgets/home_professionals_section.dart';
import 'package:quickfix/features/home/presentation/widgets/home_special_offers.dart';
import 'package:quickfix/features/home/presentation/widgets/home_trust_and_guides.dart';
import 'package:quickfix/features/home/presentation/widgets/home_customer_reviews.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with WidgetsBindingObserver {
  final ScrollController _scrollController = ScrollController();
  bool _showPinnedHeader = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scrollController.addListener(_scrollListener);

    // Fetch location dynamically on app startup
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(currentAddressProvider.notifier)
          .fetchGPSLocation(requestPermission: true);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Trigger background location update on app resume
      ref
          .read(currentAddressProvider.notifier)
          .fetchGPSLocation(requestPermission: false);
    }
  }

  void _scrollListener() {
    if (_scrollController.offset > 120) {
      if (!_showPinnedHeader) {
        setState(() {
          _showPinnedHeader = true;
        });
      }
    } else {
      if (_showPinnedHeader) {
        setState(() {
          _showPinnedHeader = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(isDarkModeProvider);
    final bannersAsync = ref.watch(bannersProvider);
    final layoutAsync = ref.watch(homepageLayoutProvider);

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            RefreshIndicator(
              onRefresh: () async {
                await Future.wait([
                  ref.refresh(categoriesProvider.future),
                  ref.refresh(nearbyShopsProvider.future),
                  ref.refresh(topProfessionalsProvider.future),
                  ref.refresh(customerReviewsProvider.future),
                  ref.refresh(bannersProvider.future),
                  ref.refresh(promotionsProvider.future),
                  ref.refresh(specialCardsProvider.future),
                  ref.refresh(homepageLayoutProvider.future),
                  ref.refresh(notificationsProvider.future),
                ]);
              },
              color: AppColors.primary,
              child: CustomScrollView(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // Header Block
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          HomeHeaderRow(),
                          SizedBox(height: 12),
                          HomeAddressRow(),
                          SizedBox(height: 10),
                          HomeSearchBarRow(),
                          SizedBox(height: 4),
                        ],
                      ),
                    ),
                  ),

                  ...layoutAsync.when(
                    data: (sections) => sections
                        .map((sec) => _buildDynamicSection(sec, isDark))
                        .toList(),
                    loading: () => [
                      const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: Column(
                            children: [
                              ShimmerLoading(
                                width: double.infinity,
                                height: 168,
                                borderRadius: 18,
                              ),
                              SizedBox(height: 14),
                              ShimmerLoading(
                                width: double.infinity,
                                height: 120,
                                borderRadius: 14,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    error: (err, stack) => [
                      // Fallback static layout (equivalent to current layout)
                      SliverToBoxAdapter(
                        child: bannersAsync.when(
                          data: (banners) =>
                              HomeBannerCarousel(banners: banners),
                          loading: () => const Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 24),
                              child: CircularProgressIndicator(),
                            ),
                          ),
                          error: (e, s) => const SizedBox.shrink(),
                        ),
                      ),
                      const SliverToBoxAdapter(child: HomeCategoriesGrid()),
                      const SliverToBoxAdapter(child: HomeFestiveOfferBanner()),
                      const SliverToBoxAdapter(child: HomeNearbyShops()),
                      const SliverToBoxAdapter(child: HomeQuickFixPlusBanner()),
                      const SliverToBoxAdapter(child: HomeTrustBadges()),
                      const SliverToBoxAdapter(child: HomeOfferPromoSection()),
                      const SliverToBoxAdapter(child: HomeHowItWorksSection()),
                      const SliverToBoxAdapter(child: HomeSpecialForYou()),
                      const SliverToBoxAdapter(
                        child: HomeProfessionalsSection(),
                      ),
                      const SliverToBoxAdapter(child: HomeCustomerReviews()),
                      const SliverToBoxAdapter(child: HomeBrandLogos()),
                      const SliverToBoxAdapter(child: HomeNeedHelpCard()),
                    ],
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 24)),
                ],
              ),
            ),

            // Animated Pinned Compact Header Row
            AnimatedPositioned(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              top: _showPinnedHeader ? 0 : -80,
              left: 0,
              right: 0,
              child: const HomePinnedHeader(),
            ),
          ],
        ),
      ),
    );
  }

  // --- CMS DYNAMIC SECTIONS ROUTER ---

  Widget _buildDynamicSection(CmsSection sec, bool isDark) {
    switch (sec.type) {
      case 'banner_carousel':
        final bannersAsync = ref.watch(bannersProvider);
        return SliverToBoxAdapter(
          child: bannersAsync.when(
            data: (banners) =>
                RepaintBoundary(child: HomeBannerCarousel(banners: banners)),
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (e, s) => const SizedBox.shrink(),
          ),
        );
      case 'grid_categories':
        return const SliverToBoxAdapter(child: HomeCategoriesGrid());
      case 'home_promotions':
        return const SliverToBoxAdapter(child: HomeFestiveOfferBanner());
      case 'nearby_shops':
        return const SliverToBoxAdapter(
          child: RepaintBoundary(child: HomeNearbyShops()),
        );
      case 'quickfix_plus':
        return const SliverToBoxAdapter(child: HomeQuickFixPlusBanner());
      case 'trust_badges':
        return const SliverToBoxAdapter(child: HomeTrustBadges());
      case 'referral_offers':
        return const SliverToBoxAdapter(child: HomeOfferPromoSection());
      case 'how_it_works':
        return const SliverToBoxAdapter(child: HomeHowItWorksSection());
      case 'special_for_you':
        return const SliverToBoxAdapter(child: HomeSpecialForYou());
      case 'top_experts':
        return const SliverToBoxAdapter(
          child: RepaintBoundary(child: HomeProfessionalsSection()),
        );
      case 'customer_reviews':
        return SliverToBoxAdapter(
          child: RepaintBoundary(
            child: HomeCustomerReviews(settings: sec.settings),
          ),
        );
      case 'brand_logos':
        return const SliverToBoxAdapter(child: HomeBrandLogos());
      case 'support_card':
        return const SliverToBoxAdapter(child: HomeNeedHelpCard());
      case 'custom_section':
        return SliverToBoxAdapter(
          child: RepaintBoundary(child: _buildCustomSection(sec, isDark)),
        );
      default:
        return SliverToBoxAdapter(child: _buildGenericCmsSection(sec, isDark));
    }
  }

  Widget _buildGenericCmsSection(CmsSection sec, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isDark ? [] : AppShadows.card,
          border: isDark
              ? Border.all(color: AppColors.borderDark)
              : Border.all(color: AppColors.borderLight),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(sec.title, style: AppTextStyles.headingMedium(isDark)),
            const SizedBox(height: 8),
            Text(
              sec.settings['description']?.toString() ??
                  'Dynamic content section.',
              style: AppTextStyles.bodySmall(isDark),
            ),
            if (sec.settings['buttonText'] != null) ...[
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () {
                  handleCtaAction(
                    context,
                    sec.settings['ctaAction']?.toString() ?? 'No Action',
                    sec.settings['ctaActionValue']?.toString() ?? '',
                  );
                },
                child: Text(sec.settings['buttonText'].toString()),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCustomSection(CmsSection sec, bool isDark) {
    final customSectionsAsync = ref.watch(customSectionsProvider);

    return customSectionsAsync.when(
      data: (customSections) {
        final data = customSections.where((cs) => cs.id == sec.id).firstOrNull;
        if (data == null) return const SizedBox.shrink();
        return _buildCustomSectionContent(data, isDark);
      },
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 16.0),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, s) => const SizedBox.shrink(),
    );
  }

  Widget _buildCustomSectionContent(CustomSection data, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (data.bannerImageUrl.isNotEmpty)
          GestureDetector(
            onTap: () {
              AppHaptics.mediumTap();
              handleCtaAction(
                context,
                data.bannerActionType,
                data.bannerActionValue,
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: AspectRatio(
                aspectRatio: 1.0,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(
                          data.bannerImageUrl,
                          fit: BoxFit.cover,
                          cacheWidth: 800,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                                color: isDark
                                    ? AppColors.surfaceDark
                                    : Colors.grey[200],
                                child: const Icon(Icons.broken_image, size: 40),
                              ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0.25),
                                Colors.black.withValues(alpha: 0.05),
                                Colors.black.withValues(alpha: 0.55),
                              ],
                              stops: const [0.0, 0.45, 1.0],
                            ),
                          ),
                        ),
                        if (data.bannerBadgeText.isNotEmpty)
                          Positioned(
                            top: 16,
                            left: 16,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0F793E),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                data.bannerBadgeText,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ),
                          ),
                        Positioned(
                          top: 68,
                          left: 16,
                          right: 16,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                data.title.toUpperCase(),
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 3.5,
                                  shadows: [
                                    Shadow(
                                      blurRadius: 4.0,
                                      color: Colors.black.withValues(
                                        alpha: 0.45,
                                      ),
                                      offset: const Offset(0.0, 1.5),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                data.subtitle,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 32,
                                  fontWeight: FontWeight.w900,
                                  height: 1.15,
                                  letterSpacing: -0.5,
                                  shadows: [
                                    Shadow(
                                      blurRadius: 6.0,
                                      color: Colors.black.withValues(
                                        alpha: 0.55,
                                      ),
                                      offset: const Offset(0.0, 2.0),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Positioned(
                          bottom: 18,
                          left: 18,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 22,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.15),
                                  blurRadius: 6,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: const Text(
                              'Explore now',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.1,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

        if (data.serviceItems.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(
              left: 16.0,
              right: 16.0,
              top: 12.0,
              bottom: 6.0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.title,
                      style: AppTextStyles.headingMedium(isDark),
                    ),
                    if (data.subtitle.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        data.subtitle,
                        style: AppTextStyles.bodySmall(isDark),
                      ),
                    ],
                  ],
                ),
                if (data.seeAllActionType != 'No Action')
                  TextButton(
                    onPressed: () {
                      AppHaptics.lightTap();
                      handleCtaAction(
                        context,
                        data.seeAllActionType,
                        data.seeAllActionValue,
                      );
                    },
                    child: const Text(
                      'See all',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(
            height: 175,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: data.serviceItems.length,
              itemBuilder: (context, index) {
                final item = data.serviceItems[index];
                return GestureDetector(
                  onTap: () {
                    AppHaptics.mediumTap();
                    handleCtaAction(context, item.actionType, item.actionValue);
                  },
                  child: Container(
                    width: 130,
                    margin: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 4,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            width: 130,
                            height: 90,
                            color: isDark
                                ? AppColors.surfaceDark
                                : Colors.grey[200],
                            child: item.imageUrl.isNotEmpty
                                ? Image.network(
                                    item.imageUrl,
                                    fit: BoxFit.cover,
                                    cacheWidth: 300,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            const Icon(
                                              Icons.broken_image,
                                              color: Colors.grey,
                                            ),
                                  )
                                : const Icon(
                                    Icons.category,
                                    color: Colors.grey,
                                  ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? Colors.white
                                : AppColors.textPrimaryLight,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(
                              Icons.star,
                              size: 12,
                              color: Color(0xFFFFB300),
                            ),
                            const SizedBox(width: 2),
                            Text(
                              item.rating.toStringAsFixed(1),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? Colors.white70
                                    : AppColors.textPrimaryLight.withValues(
                                        alpha: 0.8,
                                      ),
                              ),
                            ),
                            if (item.reviewsCount.isNotEmpty) ...[
                              const SizedBox(width: 4),
                              Text(
                                '(${item.reviewsCount})',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: isDark
                                      ? Colors.white54
                                      : Colors.grey[600],
                                ),
                              ),
                            ],
                          ],
                        ),
                        if (item.startingPrice.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            'Starts ${item.startingPrice}',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: isDark ? Colors.white54 : Colors.grey[600],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}
