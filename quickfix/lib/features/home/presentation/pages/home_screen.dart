import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
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
        return const SliverToBoxAdapter(child: SizedBox.shrink());
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.12),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Stack(
                    children: [
                      // Banner Image
                      AspectRatio(
                        aspectRatio: 1.85,
                        child: Image.network(
                          data.bannerImageUrl,
                          fit: BoxFit.cover,
                          cacheWidth: 800,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                            color: isDark
                                ? AppColors.surfaceDark
                                : Colors.grey[200],
                            child: const Icon(
                              Icons.broken_image_rounded,
                              size: 40,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ),
                      // Multi-stop Vignette Overlay
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0.35),
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.80),
                              ],
                              stops: const [0.0, 0.40, 1.0],
                            ),
                          ),
                        ),
                      ),
                      // Top Badge
                      if (data.bannerBadgeText.isNotEmpty)
                        Positioned(
                          top: 14,
                          left: 14,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF10B981), Color(0xFF059669)],
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF10B981).withValues(alpha: 0.4),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.star_rounded,
                                  size: 12,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  data.bannerBadgeText.toUpperCase(),
                                  style: GoogleFonts.outfit(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.6,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      // Banner Content Text
                      Positioned(
                        bottom: 16,
                        left: 16,
                        right: 16,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (data.title.isNotEmpty)
                                    Text(
                                      data.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.outfit(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -0.3,
                                        shadows: [
                                          Shadow(
                                            blurRadius: 6.0,
                                            color: Colors.black.withValues(alpha: 0.6),
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                    ),
                                  if (data.subtitle.isNotEmpty) ...[
                                    const SizedBox(height: 3),
                                    Text(
                                      data.subtitle,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.inter(
                                        color: Colors.white.withValues(alpha: 0.9),
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w500,
                                        height: 1.25,
                                        shadows: [
                                          Shadow(
                                            blurRadius: 4.0,
                                            color: Colors.black.withValues(alpha: 0.6),
                                            offset: const Offset(0, 1),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            if (data.bannerButtonText.isNotEmpty) ...[
                              const SizedBox(width: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 9,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.25),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      data.bannerButtonText,
                                      style: GoogleFonts.outfit(
                                        color: Colors.black,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(
                                      Icons.arrow_forward_rounded,
                                      size: 13,
                                      color: Colors.black,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
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
              top: 14.0,
              bottom: 8.0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (data.title.isNotEmpty)
                        Text(
                          data.title,
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                            color: isDark ? Colors.white : AppColors.primary,
                          ),
                        ),
                      if (data.subtitle.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          data.subtitle,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (data.seeAllActionType != 'No Action')
                  GestureDetector(
                    onTap: () {
                      AppHaptics.lightTap();
                      handleCtaAction(
                        context,
                        data.seeAllActionType,
                        data.seeAllActionValue,
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          Text(
                            'See all',
                            style: GoogleFonts.outfit(
                              color: AppColors.primary,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 2),
                          const Icon(
                            Icons.chevron_right_rounded,
                            size: 16,
                            color: AppColors.primary,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(
            height: 195,
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
                    width: 145,
                    margin: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceDark : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark
                            ? AppColors.borderDark
                            : const Color(0xFFF1F5F9),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Stack(
                              children: [
                                Container(
                                  width: double.infinity,
                                  height: 95,
                                  color: isDark
                                      ? const Color(0xFF1E293B)
                                      : const Color(0xFFF8FAFC),
                                  child: item.imageUrl.isNotEmpty
                                      ? Image.network(
                                          item.imageUrl,
                                          fit: BoxFit.cover,
                                          cacheWidth: 350,
                                          errorBuilder:
                                              (context, error, stackTrace) =>
                                                  const Icon(
                                            Icons.image_not_supported_outlined,
                                            color: Colors.grey,
                                            size: 24,
                                          ),
                                        )
                                      : const Icon(
                                          Icons.category_outlined,
                                          color: Colors.grey,
                                          size: 24,
                                        ),
                                ),
                                if (item.startingPrice.isNotEmpty)
                                  Positioned(
                                    bottom: 6,
                                    right: 6,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 7,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withValues(alpha: 0.75),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        item.startingPrice,
                                        style: GoogleFonts.outfit(
                                          color: Colors.white,
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            item.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? Colors.white
                                  : AppColors.textPrimaryLight,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 5,
                                  vertical: 1.5,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF8E1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.star_rounded,
                                      size: 11,
                                      color: Color(0xFFFFB300),
                                    ),
                                    const SizedBox(width: 2),
                                    Text(
                                      item.rating.toStringAsFixed(1),
                                      style: GoogleFonts.inter(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w800,
                                        color: const Color(0xFFB78103),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (item.reviewsCount.isNotEmpty) ...[
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    '(${item.reviewsCount})',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.inter(
                                      fontSize: 10,
                                      color: isDark
                                          ? AppColors.textSecondaryDark
                                          : Colors.grey[600],
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
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
