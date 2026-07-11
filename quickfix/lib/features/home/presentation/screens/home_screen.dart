import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/shimmer_loading.dart';
import '../../../../core/utils/haptics.dart';
import '../../data/models/home_models.dart';
import '../providers/home_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../../core/network/network_providers.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with WidgetsBindingObserver {
  final PageController _bannerController = PageController();
  final ScrollController _scrollController = ScrollController();
  int _currentBannerIndex = 0;
  bool _showPinnedHeader = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scrollController.addListener(_scrollListener);
    
    // Fetch location dynamically on app startup
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(currentAddressProvider.notifier).fetchGPSLocation(requestPermission: true);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _bannerController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Trigger background location update on app resume
      ref.read(currentAddressProvider.notifier).fetchGPSLocation(requestPermission: false);
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
    final currentAddress = ref.watch(currentAddressProvider).address;
    final bannersAsync = ref.watch(bannersProvider);
    final layoutAsync = ref.watch(homepageLayoutProvider);
    
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(categoriesProvider);
                ref.invalidate(nearbyShopsProvider);
                ref.invalidate(topProfessionalsProvider);
                ref.invalidate(customerReviewsProvider);
                ref.invalidate(bannersProvider);
                ref.invalidate(promotionsProvider);
                ref.invalidate(specialCardsProvider);
                ref.invalidate(homepageLayoutProvider);
                ref.invalidate(notificationsProvider);
              },
              color: AppColors.primary,
              child: CustomScrollView(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // 1. Original Large Header Row
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeaderRow(context, ref, isDark),
                          const SizedBox(height: 16),
                          _buildAddressRow(context, ref, currentAddress, isDark),
                          const SizedBox(height: 16),
                          _buildSearchBarRow(context, isDark),
                        ],
                      ),
                    ),
                  ),

                  ...layoutAsync.when(
                    data: (sections) => sections.map((sec) => _buildDynamicSection(sec, isDark)).toList(),
                    loading: () => [
                      const SliverToBoxAdapter(
                        child: Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 40),
                            child: CircularProgressIndicator(),
                          ),
                        ),
                      ),
                    ],
                    error: (err, stack) => [
                      // Fallback static layout (equivalent to current layout)
                      SliverToBoxAdapter(
                        child: bannersAsync.when(
                          data: (banners) => _buildBannerCarousel(banners, isDark),
                          loading: () => const Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 24),
                              child: CircularProgressIndicator(),
                            ),
                          ),
                          error: (e, s) => const SizedBox.shrink(),
                        ),
                      ),
                      SliverToBoxAdapter(child: _buildCategoriesSection(isDark)),
                      SliverToBoxAdapter(child: _buildFestiveOfferBanner(isDark)),
                      SliverToBoxAdapter(child: _buildNearbyShopsSection(isDark)),
                      SliverToBoxAdapter(child: _buildQuickFixPlusBanner(isDark)),
                      SliverToBoxAdapter(child: _buildTrustBadges(isDark)),
                      SliverToBoxAdapter(child: _buildOfferPromoSection(isDark)),
                      SliverToBoxAdapter(child: _buildHowItWorksSection(isDark)),
                      SliverToBoxAdapter(child: _buildSpecialForYou(isDark)),
                      SliverToBoxAdapter(child: _buildTopProfessionalsBanner(isDark)),
                      SliverToBoxAdapter(child: _buildCustomerReviews(isDark)),
                      SliverToBoxAdapter(child: _buildBrandLogos(isDark)),
                      SliverToBoxAdapter(child: _buildNeedHelpCard(isDark)),
                    ],
                  ),

                  const SliverToBoxAdapter(
                    child: SizedBox(height: 24),
                  ),
                ],
          ),
        ),
        // 2. Animated Pinned Compact Header Row
        AnimatedPositioned(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          top: _showPinnedHeader ? 0 : -80,
          left: 0,
          right: 0,
          child: _buildPinnedHeader(context, currentAddress, isDark),
        ),
      ],
    ),
  ),
);
}

  // --- WIDGET BUILDERS ---

  Widget _buildAddressDropdown(BuildContext context, WidgetRef ref, String currentAddress, bool isDark) {
    return InkWell(
      onTap: () {
        AppHaptics.lightTap();
        context.push('/location-selector');
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.location_on,
            color: AppColors.primary,
            size: 22,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      getShortAddress(currentAddress),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppColors.secondary,
                      ),
                    ),
                    const Icon(
                      Icons.keyboard_arrow_down,
                      size: 16,
                      color: AppColors.primary,
                    ),
                  ],
                ),
                Text(
                  currentAddress,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    color: isDark ? Colors.white60 : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchIcon(BuildContext context, bool isDark) {
    return GestureDetector(
      onTap: () {
        AppHaptics.lightTap();
        context.push('/search');
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Icon(
          Icons.search,
          color: isDark ? Colors.white : AppColors.secondary,
          size: 24,
        ),
      ),
    );
  }

  Widget _buildThemeToggle(WidgetRef ref, bool isDark) {
    return GestureDetector(
      onTap: () {
        AppHaptics.mediumTap();
        ref.read(isDarkModeProvider.notifier).toggleTheme();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Icon(
          isDark ? Icons.light_mode : Icons.dark_mode,
          color: isDark ? Colors.white : AppColors.secondary,
          size: 22,
        ),
      ),
    );
  }

  Widget _buildNotificationBell(BuildContext context, bool isDark) {
    final unreadCount = ref.watch(unreadNotificationsCountProvider);

    return GestureDetector(
      onTap: () {
        AppHaptics.lightTap();
        context.push('/notifications');
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(
              Icons.notifications_none_outlined,
              size: 26,
              color: isDark ? Colors.white : AppColors.secondary,
            ),
            if (unreadCount > 0)
              Positioned(
                right: 2,
                top: 10,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 14,
                    minHeight: 14,
                  ),
                  child: Text(
                    '$unreadCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileAvatar(BuildContext context, bool isDark) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final rawAvatarUrl = user?['avatarUrl']?.toString() ?? '';
    final avatarUrl = rawAvatarUrl.isNotEmpty ? rawAvatarUrl : 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150';

    return GestureDetector(
      onTap: () {
        AppHaptics.lightTap();
        context.push('/profile');
      },
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.primary, width: 1.5),
        ),
        child: CircleAvatar(
          radius: 16,
          backgroundImage: NetworkImage(avatarUrl),
        ),
      ),
    );
  }

  Widget _buildBannerCarousel(List<PromoBanner> banners, bool isDark) {
    if (banners.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        SizedBox(
          height: 200,
          child: PageView.builder(
            controller: _bannerController,
            onPageChanged: (index) {
              setState(() {
                _currentBannerIndex = index;
              });
            },
            itemCount: banners.length,
            itemBuilder: (context, index) {
              final banner = banners[index];
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  gradient: AppColors.plusGradient,
                  borderRadius: BorderRadius.circular(16),
                  image: DecorationImage(
                    image: NetworkImage(banner.imageUrl),
                    fit: BoxFit.cover,
                    colorFilter: ColorFilter.mode(
                      Colors.black.withOpacity(0.55),
                      BlendMode.srcOver,
                    ),
                  ),
                ),
                child: Stack(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Limited Time Offer',
                            style: AppTextStyles.bodySmall(true).copyWith(
                              color: AppColors.accent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            banner.title,
                            style: AppTextStyles.headingMedium(true).copyWith(
                              height: 1.2,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.white60, width: 1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'Use Code: ${banner.code}',
                                  style: AppTextStyles.badgeText.copyWith(color: Colors.white),
                                ),
                              ),
                              const SizedBox(width: 12),
                              ElevatedButton(
                                onPressed: () {
                                  AppHaptics.heavyTap();
                                  context.push('/category/all');
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Text('Book Now', style: AppTextStyles.badgeText.copyWith(fontSize: 12)),
                                    const Icon(Icons.chevron_right, size: 14),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      right: 16,
                      top: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.4),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: Text(
                          banner.percent,
                          style: AppTextStyles.badgeText.copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ).animate(onPlay: (controller) => controller.repeat()).shimmer(
                          duration: 1500.ms,
                          color: Colors.white.withOpacity(0.3),
                        ),
                  ],
                ),
              );
            },
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(banners.length, (index) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: _currentBannerIndex == index ? 16 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: _currentBannerIndex == index 
                    ? AppColors.primary 
                    : (isDark ? AppColors.borderDark : AppColors.borderLight),
                borderRadius: BorderRadius.circular(3),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildCategoriesSection(bool isDark) {
    final categoriesAsync = ref.watch(categoriesProvider);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'All Services',
                style: AppTextStyles.headingMedium(isDark),
              ),
              TextButton(
                onPressed: () {
                  AppHaptics.lightTap();
                  context.push('/category/all');
                },
                child: Row(
                  children: [
                    Text(
                      'View All',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Icon(Icons.chevron_right, size: 16, color: AppColors.primary),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          categoriesAsync.when(
            data: (categories) {
              final List<ServiceCategory> displayedCategories;
              if (categories.length > 5) {
                displayedCategories = categories.take(5).toList()
                  ..add(
                    const ServiceCategory(
                      id: 'more',
                      name: 'More',
                      icon: Icons.more_horiz,
                      backgroundColor: Color(0xFFF3F4F6),
                      iconColor: Color(0xFF4B5563),
                    ),
                  );
              } else {
                displayedCategories = categories;
              }

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 1.0,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: displayedCategories.length,
                itemBuilder: (context, index) {
                  final cat = displayedCategories[index];
                  return GestureDetector(
                    onTap: () {
                      AppHaptics.mediumTap();
                      if (cat.id == 'more') {
                        context.push('/category/all');
                      } else {
                        context.push('/category/${cat.id}');
                      }
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.surfaceDark : cat.backgroundColor,
                        borderRadius: BorderRadius.circular(16),
                        border: isDark 
                            ? Border.all(color: AppColors.borderDark)
                            : null,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isDark ? cat.iconColor.withOpacity(0.15) : Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: cat.iconUrl == null || cat.iconUrl!.trim().isEmpty
                                ? Icon(
                                    cat.icon,
                                    color: cat.iconColor,
                                    size: 26,
                                  )
                                : (cat.iconUrl!.trim().toLowerCase().contains('.svg') ||
                                        cat.iconUrl!.trim().toLowerCase().contains('format=svg'))
                                    ? SvgPicture.network(
                                        cat.iconUrl!.trim().startsWith('http://')
                                            ? cat.iconUrl!.trim().replaceFirst('http://', 'https://')
                                            : cat.iconUrl!.trim(),
                                        width: 26,
                                        height: 26,
                                        fit: BoxFit.contain,
                                        placeholderBuilder: (context) => Icon(
                                          cat.icon,
                                          color: cat.iconColor,
                                          size: 26,
                                        ),
                                      )
                                    : ClipRRect(
                                        borderRadius: BorderRadius.circular(13),
                                        child: Image.network(
                                          cat.iconUrl!.trim().startsWith('http://')
                                              ? cat.iconUrl!.trim().replaceFirst('http://', 'https://')
                                              : cat.iconUrl!.trim(),
                                          width: 26,
                                          height: 26,
                                          fit: BoxFit.contain,
                                          errorBuilder: (context, error, stackTrace) => Icon(
                                            cat.icon,
                                            color: cat.iconColor,
                                            size: 26,
                                          ),
                                        ),
                                      ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            cat.name,
                            textAlign: TextAlign.center,
                            style: AppTextStyles.bodySmall(isDark).copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: isDark ? Colors.white : AppColors.textPrimaryLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
            loading: () => GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 1.0,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: 6,
              itemBuilder: (context, index) => const ShimmerLoading(width: 80, height: 80, borderRadius: 16),
            ),
            error: (e, s) => Center(child: Text('Error loading categories: $e')),
          ),
        ],
      ),
    );
  }

  Widget _buildFestiveOfferBanner(bool isDark) {
    final promosAsync = ref.watch(promotionsProvider);
    return promosAsync.when(
      data: (promos) {
        if (promos.isEmpty) return const SizedBox.shrink();
        
        return Column(
          children: promos.map((promo) {
            Color bgColor = const Color(0xFFFFF1F0);
            Color txtColor = AppColors.primary;
            Color btnColor = AppColors.primary;
            Color btnTxtColor = Colors.white;

            try {
              if (promo.backgroundColor.isNotEmpty) {
                bgColor = Color(int.parse(promo.backgroundColor.replaceAll('#', '0xFF')));
              }
              if (promo.textColor.isNotEmpty) {
                txtColor = Color(int.parse(promo.textColor.replaceAll('#', '0xFF')));
              }
              if (promo.buttonColor.isNotEmpty) {
                btnColor = Color(int.parse(promo.buttonColor.replaceAll('#', '0xFF')));
              }
              if (promo.buttonTextColor.isNotEmpty) {
                btnTxtColor = Color(int.parse(promo.buttonTextColor.replaceAll('#', '0xFF')));
              }
            } catch (e) {
              // Safe fallback
            }

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: txtColor.withOpacity(0.15)),
                ),
                child: Row(
                  children: [
                    if (promo.bannerImage.isNotEmpty) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          promo.bannerImage,
                          width: 44,
                          height: 44,
                          fit: BoxFit.cover,
                          errorBuilder: (c, o, s) => Container(
                            padding: const EdgeInsets.all(10),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.card_giftcard, color: txtColor, size: 24),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ] else ...[
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.card_giftcard,
                          color: txtColor,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            promo.title,
                            style: AppTextStyles.bodySmall(false).copyWith(
                              fontWeight: FontWeight.bold,
                              color: txtColor,
                            ),
                          ),
                          Text(
                            promo.subtitle,
                            style: AppTextStyles.headingSmall(false).copyWith(
                              color: isDark ? Colors.white : AppColors.secondary,
                            ),
                          ),
                          if (promo.description.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              promo.description,
                              style: AppTextStyles.bodySmall(false).copyWith(
                                color: isDark ? Colors.white70 : AppColors.textSecondaryLight,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        AppHaptics.heavyTap();
                        handleCtaAction(context, promo.ctaButtonAction, promo.ctaButtonActionValue);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: btnColor,
                        foregroundColor: btnTxtColor,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(
                            promo.ctaButtonText.isNotEmpty ? promo.ctaButtonText : 'Grab Now',
                            style: AppTextStyles.badgeText.copyWith(fontSize: 12, color: btnTxtColor),
                          ),
                          Icon(Icons.chevron_right, size: 14, color: btnTxtColor),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (e, s) => const SizedBox.shrink(),
    );
  }

  Widget _buildDynamicSection(CmsSection sec, bool isDark) {
    switch (sec.type) {
      case 'banner_carousel':
        final bannersAsync = ref.watch(bannersProvider);
        return SliverToBoxAdapter(
          child: bannersAsync.when(
            data: (banners) => _buildBannerCarousel(banners, isDark),
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
        return SliverToBoxAdapter(child: _buildCategoriesSection(isDark));
      case 'home_promotions':
        return SliverToBoxAdapter(child: _buildFestiveOfferBanner(isDark));
      case 'nearby_shops':
        return SliverToBoxAdapter(child: _buildNearbyShopsSection(isDark));
      case 'quickfix_plus':
        return SliverToBoxAdapter(child: _buildQuickFixPlusBanner(isDark));
      case 'trust_badges':
        return SliverToBoxAdapter(child: _buildTrustBadges(isDark));
      case 'referral_offers':
        return SliverToBoxAdapter(child: _buildOfferPromoSection(isDark));
      case 'how_it_works':
        return SliverToBoxAdapter(child: _buildHowItWorksSection(isDark));
      case 'special_for_you':
        return SliverToBoxAdapter(child: _buildSpecialForYou(isDark));
      case 'top_experts':
        return SliverToBoxAdapter(child: _buildTopProfessionalsBanner(isDark));
      case 'customer_reviews':
        return SliverToBoxAdapter(child: _buildCustomerReviews(isDark, sec.settings));
      case 'brand_logos':
        return SliverToBoxAdapter(child: _buildBrandLogos(isDark));
      case 'support_card':
        return SliverToBoxAdapter(child: _buildNeedHelpCard(isDark));
      case 'custom_section':
        return SliverToBoxAdapter(child: _buildCustomSection(sec, isDark));
      default:
        return SliverToBoxAdapter(child: _buildGenericCmsSection(sec, isDark));
    }
  }

  Widget _buildGenericCmsSection(CmsSection sec, bool isDark) {
    // Elegant fallback card for future unknown sections
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              sec.title,
              style: AppTextStyles.headingMedium(isDark),
            ),
            const SizedBox(height: 8),
            Text(
              sec.settings['description']?.toString() ?? 'Dynamic content section.',
              style: AppTextStyles.bodySmall(isDark),
            ),
            if (sec.settings['buttonText'] != null) ...[
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () {
                  handleCtaAction(
                    context, 
                    sec.settings['ctaAction']?.toString() ?? 'No Action', 
                    sec.settings['ctaActionValue']?.toString() ?? ''
                  );
                },
                child: Text(sec.settings['buttonText'].toString()),
              )
            ]
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
        // Urban-style Banner (if provided)
        if (data.bannerImageUrl.isNotEmpty)
          GestureDetector(
            onTap: () {
              AppHaptics.mediumTap();
              handleCtaAction(context, data.bannerActionType, data.bannerActionValue);
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              height: 180,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 8,
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
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: isDark ? AppColors.surfaceDark : Colors.grey[200],
                        child: const Icon(Icons.broken_image, size: 40),
                      ),
                    ),
                    // Elegant dark gradient overlay for text readability
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withOpacity(0.1),
                            Colors.black.withOpacity(0.65),
                          ],
                        ),
                      ),
                    ),
                    // Badge Text (top left)
                    if (data.bannerBadgeText.isNotEmpty)
                      Positioned(
                        top: 14,
                        left: 14,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A9E3F), // Sleek Green Badge
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            data.bannerBadgeText,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    // Content (bottom left)
                    Positioned(
                      bottom: 14,
                      left: 14,
                      right: 14,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            data.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              shadows: [
                                Shadow(
                                  blurRadius: 4.0,
                                  color: Colors.black45,
                                  offset: Offset(0.0, 1.5),
                                ),
                              ],
                            ),
                          ),
                          if (data.subtitle.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              data.subtitle,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.85),
                                fontSize: 12,
                                shadows: const [
                                  Shadow(
                                    blurRadius: 3.0,
                                    color: Colors.black45,
                                    offset: Offset(0.0, 1.0),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Explore now',
                              style: TextStyle(
                                color: Colors.black87,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

        // Service Cards Row
        if (data.serviceItems.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 12.0, bottom: 6.0),
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
                      handleCtaAction(context, data.seeAllActionType, data.seeAllActionValue);
                    },
                    child: Text(
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
                    margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            width: 130,
                            height: 90,
                            color: isDark ? AppColors.surfaceDark : Colors.grey[200],
                            child: item.imageUrl.isNotEmpty
                                ? Image.network(
                                    item.imageUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => const Icon(
                                      Icons.broken_image,
                                      color: Colors.grey,
                                    ),
                                  )
                                : const Icon(Icons.category, color: Colors.grey),
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
                            color: isDark ? Colors.white : AppColors.textPrimaryLight,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(Icons.star, size: 12, color: Color(0xFFFFB300)),
                            const SizedBox(width: 2),
                            Text(
                              item.rating.toStringAsFixed(1),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white70 : AppColors.textPrimaryLight.withOpacity(0.8),
                              ),
                            ),
                            if (item.reviewsCount.isNotEmpty) ...[
                              const SizedBox(width: 4),
                              Text(
                                '(${item.reviewsCount})',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: isDark ? Colors.white54 : Colors.grey[600],
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


  void handleCtaAction(BuildContext context, String action, String value) {
    if (action == 'Open Category') {
      context.push('/category/$value');
    } else if (action == 'Open Specific Service') {
      context.push('/service/$value');
    } else if (action == 'Open Shop') {
      context.push('/shop/$value');
    } else if (action == 'Open Internal Screen') {
      final String path = value.startsWith('/') ? value : '/$value';
      context.push(path);
    } else if (action == 'Open External URL') {
      try {
        final Uri uri = Uri.parse(value);
        launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (e) {
        // Safe fail
      }
    }
  }

  Widget _buildNearbyShopsSection(bool isDark) {
    final shopsAsync = ref.watch(nearbyShopsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Nearby Top Shops',
                style: AppTextStyles.headingMedium(isDark),
              ),
              TextButton(
                onPressed: () {
                  AppHaptics.lightTap();
                  context.push('/shops');
                },
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                ),
                child: Row(
                  children: [
                    Text(
                      'View All',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const Icon(Icons.chevron_right, size: 16, color: AppColors.primary),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 4),

        // Horizontally scrolling shops list or coming soon card
        shopsAsync.when(
          data: (shops) {
            if (shops.isEmpty) {
              return _buildComingSoonCard(context, isDark);
            }
            return SizedBox(
              height: 258,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: shops.length,
                itemBuilder: (context, index) {
                  final shop = shops[index];
                  return GestureDetector(
                    onTap: () {
                      AppHaptics.mediumTap();
                      context.push('/shop/${shop.id}', extra: shop);
                    },
                    child: Container(
                      width: 260,
                      margin: const EdgeInsets.only(right: 16, bottom: 12),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.surfaceDark : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(isDark ? 0.25 : 0.04),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                        border: Border.all(
                          color: isDark ? AppColors.borderDark : AppColors.borderLight,
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Stack(
                            children: [
                              ClipRRect(
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                                child: Image.network(
                                  shop.imagePath,
                                  height: 130,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              // Gradient Overlay for readability
                              Positioned.fill(
                                child: Container(
                                  decoration: const BoxDecoration(
                                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                                    gradient: LinearGradient(
                                      colors: [Colors.black54, Colors.transparent],
                                      begin: Alignment.bottomCenter,
                                      end: Alignment.topCenter,
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 12,
                                right: 12,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 4,
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.star_rounded, color: Color(0xFFFFB800), size: 14),
                                      const SizedBox(width: 3),
                                      Text(
                                        shop.rating.toStringAsFixed(1),
                                        style: const TextStyle(
                                          color: AppColors.secondary,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      if (shop.reviewsCount > 0) ...[
                                        const SizedBox(width: 3),
                                        Text(
                                          '(${shop.reviewsCount})',
                                          style: TextStyle(
                                            color: AppColors.textSecondaryLight,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 12,
                                left: 12,
                                child: GestureDetector(
                                  onTap: () {
                                    AppHaptics.mediumTap();
                                    ref.read(wishlistProvider.notifier).toggleFavourite(shop.id);
                                    final isNowFav = ref.read(wishlistProvider.notifier).isFavourite(shop.id);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          isNowFav
                                              ? 'Added ${shop.name} to Wishlist'
                                              : 'Removed ${shop.name} from Wishlist',
                                        ),
                                        duration: const Duration(seconds: 1),
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.35),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      ref.watch(wishlistProvider).contains(shop.id)
                                          ? Icons.favorite
                                          : Icons.favorite_border,
                                      color: ref.watch(wishlistProvider).contains(shop.id)
                                          ? Colors.red
                                          : Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  shop.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyles.headingSmall(isDark).copyWith(fontSize: 14),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  shop.categories.join(', '),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyles.bodySmall(isDark).copyWith(fontSize: 11),
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.access_time_filled_rounded, size: 14, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                                        const SizedBox(width: 4),
                                        Text(
                                          shop.estimatedTimeDisplay,
                                          style: AppTextStyles.bodySmall(isDark).copyWith(fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        Icon(Icons.near_me_rounded, size: 14, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${shop.distanceKm} km',
                                          style: AppTextStyles.bodySmall(isDark).copyWith(fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      shop.priceRange,
                                      style: TextStyle(
                                        color: isDark ? Colors.white70 : AppColors.secondary,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 13,
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
                  );
                },
              ),
            );
          },
          loading: () => SizedBox(
            height: 258,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: 3,
              itemBuilder: (context, index) => const Padding(
                padding: EdgeInsets.only(right: 16),
                child: ShimmerLoading(width: 260, height: 220, borderRadius: 16),
              ),
            ),
          ),
          error: (e, s) => Center(child: Text('Error: $e')),
        ),
      ],
    );
  }

  Widget _buildQuickFixPlusBanner(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: AppColors.plusGradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.amber.withOpacity(0.3), width: 1),
              ),
              child: const Icon(
                Icons.stars,
                color: AppColors.accent,
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'QuickFix Plus',
                    style: AppTextStyles.headingSmall(true).copyWith(
                      color: AppColors.accent,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Free Delivery • Priority Booking • Exclusive Offers',
                    style: AppTextStyles.bodySmall(true).copyWith(
                      color: Colors.white70,
                    ),
                  ),
                  Text(
                    'And much more!',
                    style: AppTextStyles.bodySmall(true).copyWith(
                      color: Colors.white54,
                    ),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: () {
                AppHaptics.heavyTap();
                context.push('/wallet');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              child: Row(
                children: [
                  Text('Join Now', style: AppTextStyles.badgeText.copyWith(fontSize: 12)),
                  const Icon(Icons.chevron_right, size: 14),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrustBadges(bool isDark) {
    final List<Map<String, dynamic>> badges = [
      {
        'title': 'Genuine\nProfessionals',
        'icon': Icons.verified_user_outlined,
        'color': AppColors.success,
      },
      {
        'title': 'Background\nVerified',
        'icon': Icons.security_outlined,
        'color': AppColors.catAppliancesIcon,
      },
      {
        'title': 'Upfront\nPricing',
        'icon': Icons.monetization_on_outlined,
        'color': AppColors.accent,
      },
      {
        'title': 'On-time\nService',
        'icon': Icons.alarm_outlined,
        'color': AppColors.info,
      },
      {
        'title': '24x7\nSupport',
        'icon': Icons.headset_mic_outlined,
        'color': AppColors.error,
      },
    ];

    return SizedBox(
      height: 110,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: badges.length,
        itemBuilder: (context, index) {
          final b = badges[index];
          return Container(
            width: 100,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(b['icon'], color: b['color'], size: 24),
                const SizedBox(height: 8),
                Text(
                  b['title'],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textPrimaryLight,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildOfferPromoSection(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
      child: Row(
        children: [
          // Referral Card
          Expanded(
            child: Container(
              height: 150,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFECFDF5), Color(0xFFD1FAE5)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.green.withOpacity(0.15)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Refer & Earn',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green.shade800),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Get ₹100\nfor every friend',
                        style: AppTextStyles.headingSmall(false).copyWith(
                          color: AppColors.secondary,
                          fontWeight: FontWeight.bold,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                  ElevatedButton(
                    onPressed: () {
                      AppHaptics.heavyTap();
                      context.push('/profile');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      minimumSize: const Size(80, 32),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Refer Now', style: AppTextStyles.badgeText.copyWith(fontSize: 11)),
                        const Icon(Icons.chevron_right, size: 12),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          // First Booking Card
          Expanded(
            child: Container(
              height: 150,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFEEF2FF), Color(0xFFE0E7FF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.blue.withOpacity(0.15)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Flat 15% OFF',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blue.shade800),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'On First App\nBooking',
                        style: AppTextStyles.headingSmall(false).copyWith(
                          color: AppColors.secondary,
                          fontWeight: FontWeight.bold,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                  ElevatedButton(
                    onPressed: () {
                      AppHaptics.heavyTap();
                      context.push('/category/all');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      minimumSize: const Size(80, 32),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Book Now', style: AppTextStyles.badgeText.copyWith(fontSize: 11)),
                        const Icon(Icons.chevron_right, size: 12),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHowItWorksSection(bool isDark) {
    final List<Map<String, dynamic>> steps = [
      {
        'num': '1',
        'title': 'Search',
        'desc': 'Choose the service you need',
        'icon': Icons.search_outlined,
        'color': AppColors.success,
      },
      {
        'num': '2',
        'title': 'Choose',
        'desc': 'Select from top rated professionals',
        'icon': Icons.thumb_up_alt_outlined,
        'color': AppColors.accent,
      },
      {
        'num': '3',
        'title': 'Book',
        'desc': 'Pick a time slot & confirm booking',
        'icon': Icons.calendar_month_outlined,
        'color': AppColors.info,
      },
      {
        'num': '4',
        'title': 'Relax',
        'desc': 'Professional arrives & gets it done',
        'icon': Icons.sentiment_satisfied_alt_outlined,
        'color': AppColors.primary,
      },
    ];

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How QuickFix Works?',
            style: AppTextStyles.headingMedium(isDark),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List.generate(steps.length, (index) {
              final step = steps[index];
              return Expanded(
                child: Column(
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: step['color'].withOpacity(0.08),
                            shape: BoxShape.circle,
                            border: Border.all(color: step['color'].withOpacity(0.3), width: 1.5),
                          ),
                          child: Icon(step['icon'], color: step['color'], size: 20),
                        ),
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: step['color'],
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              step['num'],
                              style: const TextStyle(fontSize: 8, color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      step['title'],
                      style: AppTextStyles.bodySmall(isDark).copyWith(
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppColors.textPrimaryLight,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      step['desc'],
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 9,
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecialForYou(bool isDark) {
    final cardsAsync = ref.watch(specialCardsProvider);

    return cardsAsync.when(
      data: (cards) {
        if (cards.isEmpty) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Special For You 🔥',
                style: AppTextStyles.headingMedium(isDark),
              ),
              const SizedBox(height: 12),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: cards.length,
                itemBuilder: (context, index) {
                  final item = cards[index];
                  
                  Color bgColor = isDark ? AppColors.surfaceDark : Colors.white;
                  try {
                    if (item.backgroundColor.isNotEmpty && !isDark) {
                      bgColor = Color(int.parse(item.backgroundColor.replaceAll('#', '0xFF')));
                    }
                  } catch (e) {
                    // Fallback
                  }

                  IconData iconData = Icons.star_outline;
                  if (item.icon == 'water_drop_outlined') iconData = Icons.water_drop_outlined;
                  else if (item.icon == 'flash_on_outlined') iconData = Icons.flash_on_outlined;
                  else if (item.icon == 'discount_outlined') iconData = Icons.discount_outlined;
                  else if (item.icon == 'cleaning_services_outlined') iconData = Icons.cleaning_services_outlined;
                  else if (item.icon == 'plumbing_outlined') iconData = Icons.plumbing_outlined;
                  else if (item.icon == 'bolt_outlined') iconData = Icons.bolt_outlined;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark ? AppColors.borderDark : AppColors.borderLight,
                      ),
                    ),
                    child: ListTile(
                      onTap: () {
                        AppHaptics.lightTap();
                        handleCtaAction(context, item.ctaAction, item.ctaActionValue);
                      },
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.08),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(iconData, color: AppColors.primary),
                      ),
                      title: Text(
                        item.title,
                        style: AppTextStyles.headingSmall(isDark),
                      ),
                      subtitle: Text(
                        item.subtitle.isNotEmpty ? item.subtitle : item.description,
                        style: AppTextStyles.bodySmall(isDark),
                      ),
                      trailing: const Icon(Icons.chevron_right, size: 20),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (e, s) => const SizedBox.shrink(),
    );
  }

  Widget _buildTopProfessionalsBanner(bool isDark) {
    final professionalsAsync = ref.watch(topProfessionalsProvider);
    final wishlist = ref.watch(wishlistProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Top Rated Experts',
                style: AppTextStyles.headingMedium(isDark),
              ),
              Row(
                children: const [
                  Icon(Icons.emoji_events_outlined, color: Colors.amber, size: 18),
                  SizedBox(width: 4),
                  Text(
                    'Best Rated',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.amber,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        
        SizedBox(
          height: 180,
          child: professionalsAsync.when(
            data: (professionals) {
              if (professionals.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Text(
                      'No experts active currently.',
                      style: TextStyle(color: Colors.grey.shade500),
                    ),
                  ),
                );
              }
              return ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: professionals.length,
                itemBuilder: (context, index) {
                  final prof = professionals[index];
                  final isFav = wishlist.contains(prof.id);
                  
                  return GestureDetector(
                    onTap: () {
                      AppHaptics.mediumTap();
                      if (prof.shopId.isNotEmpty) {
                        context.push('/shop/${prof.shopId}');
                      } else {
                        final spec = prof.specialty.toLowerCase();
                        String categoryId = 'plumbing';
                        if (spec.contains('electrician')) {
                          categoryId = 'electrician';
                        } else if (spec.contains('clean')) {
                          categoryId = 'cleaning';
                        } else if (spec.contains('plumb')) {
                          categoryId = 'plumbing';
                        } else if (spec.contains('appliance')) {
                          categoryId = 'appliances';
                        } else if (spec.contains('carpent')) {
                          categoryId = 'carpentry';
                        } else if (spec.contains('paint')) {
                          categoryId = 'painting';
                        } else if (spec.contains('pest')) {
                          categoryId = 'pestcontrol';
                        }
                        context.push('/category/$categoryId');
                      }
                    },
                    child: Container(
                      width: 220,
                      margin: const EdgeInsets.only(right: 16, bottom: 8),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.surfaceDark : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                        border: isDark 
                            ? Border.all(color: AppColors.borderDark)
                            : Border.all(color: AppColors.borderLight.withOpacity(0.6)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundImage: NetworkImage(prof.avatarUrl.isNotEmpty ? prof.avatarUrl : 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150'),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            prof.name,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: AppTextStyles.headingSmall(isDark).copyWith(fontSize: 14),
                                          ),
                                        ),
                                        if (prof.verifiedBadge) ...[
                                          const SizedBox(width: 4),
                                          const Icon(Icons.verified, color: Colors.blue, size: 14),
                                        ],
                                      ],
                                    ),
                                    Text(
                                      '${prof.specialty}${prof.experience.isNotEmpty ? " • ${prof.experience}" : ""}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTextStyles.bodySmall(isDark).copyWith(fontSize: 11),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.star, color: Colors.amber, size: 14),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${prof.rating} (${prof.reviewsCount} reviews)',
                                    style: AppTextStyles.bodySmall(isDark).copyWith(fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: prof.availability ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  prof.availability ? 'Online' : 'Offline',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: prof.availability ? Colors.green : Colors.red,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              IconButton(
                                icon: Icon(
                                  isFav ? Icons.favorite : Icons.favorite_border,
                                  color: Colors.redAccent,
                                  size: 20,
                                ),
                                onPressed: () {
                                  AppHaptics.mediumTap();
                                  ref.read(wishlistProvider.notifier).toggleFavourite(prof.id);
                                  final isNowFav = ref.read(wishlistProvider.notifier).isFavourite(prof.id);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        isNowFav
                                            ? 'Added ${prof.name} to Wishlist'
                                            : 'Removed ${prof.name} from Wishlist',
                                      ),
                                      duration: const Duration(seconds: 1),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                },
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  AppHaptics.heavyTap();
                                  if (prof.shopId.isNotEmpty) {
                                    context.push('/shop/${prof.shopId}');
                                  } else {
                                    final spec = prof.specialty.toLowerCase();
                                    String categoryId = 'plumbing';
                                    if (spec.contains('electrician')) {
                                      categoryId = 'electrician';
                                    } else if (spec.contains('clean')) {
                                      categoryId = 'cleaning';
                                    } else if (spec.contains('plumb')) {
                                      categoryId = 'plumbing';
                                    } else if (spec.contains('appliance')) {
                                      categoryId = 'appliances';
                                    } else if (spec.contains('carpent')) {
                                      categoryId = 'carpentry';
                                    } else if (spec.contains('paint')) {
                                      categoryId = 'painting';
                                    } else if (spec.contains('pest')) {
                                      categoryId = 'pestcontrol';
                                    }
                                    context.push('/category/$categoryId');
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  elevation: 0,
                                ),
                                child: const Text('Book', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
            loading: () => ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: 2,
              itemBuilder: (context, index) => const Padding(
                padding: EdgeInsets.only(right: 16),
                child: ShimmerLoading(width: 220, height: 160, borderRadius: 16),
              ),
            ),
            error: (e, s) => Center(child: Text('Error: $e')),
          ),
        ),
      ],
    );
  }

  Widget _buildCustomerReviews(bool isDark, [Map<String, dynamic>? settings]) {
    final reviewsAsync = ref.watch(customerReviewsProvider);
    final String layout = settings?['layout']?.toString() ?? 'slider';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'What Our Customers Say',
                style: AppTextStyles.headingMedium(isDark),
              ),
              const Text(
                'View All',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        reviewsAsync.when(
          data: (reviews) {
            if (reviews.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Column(
                    children: [
                      Icon(Icons.rate_review_outlined, color: Colors.grey.shade400, size: 44),
                      const SizedBox(height: 8),
                      Text('No reviews yet. Be the first to review!', style: TextStyle(color: Colors.grey.shade500)),
                    ],
                  ),
                ),
              );
            }

            if (layout == 'grid') {
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 1.15,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: reviews.length,
                itemBuilder: (context, index) => _buildReviewCard(reviews[index], isDark),
              );
            } else if (layout == 'list') {
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: reviews.length,
                itemBuilder: (context, index) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _buildReviewCard(reviews[index], isDark),
                ),
              );
            } else {
              return SizedBox(
                height: 175,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: reviews.length,
                  itemBuilder: (context, index) {
                    return SizedBox(
                      width: 280,
                      child: _buildReviewCard(reviews[index], isDark),
                    );
                  },
                ),
              );
            }
          },
          loading: () => ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: 2,
            itemBuilder: (context, index) => const Padding(
              padding: EdgeInsets.only(right: 16),
              child: ShimmerLoading(width: 280, height: 155, borderRadius: 16),
            ),
          ),
          error: (e, s) => Center(child: Text('Error: $e')),
        ),
      ],
    );
  }

  Widget _buildReviewCard(Review r, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(right: 16, bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
        border: isDark 
            ? Border.all(color: AppColors.borderDark)
            : Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundImage: NetworkImage(r.userAvatar.isNotEmpty ? r.userAvatar : 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150'),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            r.userName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.headingSmall(isDark).copyWith(fontSize: 13),
                          ),
                          Text(
                            '${r.serviceName}${r.providerName.isNotEmpty ? " • ${r.providerName}" : ""}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.bodySmall(isDark).copyWith(fontSize: 9),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    Text(
                      r.rating.toString(),
                      style: const TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.bold),
                    ),
                    const Icon(Icons.star, color: Colors.green, size: 10),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Text(
              r.comment,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodySmall(isDark).copyWith(fontSize: 11, fontStyle: FontStyle.italic),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                r.date.isNotEmpty ? r.date : 'Verified Booking',
                style: TextStyle(fontSize: 9, color: Colors.green.shade700, fontWeight: FontWeight.bold),
              ),
              if (r.verifiedBadge)
                const Icon(Icons.verified_user, color: Colors.green, size: 12),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBrandLogos(bool isDark) {
    final List<String> brands = ['DAIKIN', 'orient', 'HAVELLS', 'Crompton', 'hindware', 'PHILIPS'];

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Trusted by Leading Brands',
            style: AppTextStyles.headingSmall(isDark).copyWith(
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark.withOpacity(0.5) : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: List.generate(brands.length, (index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      brands[index],
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                        color: isDark ? Colors.white24 : Colors.black26,
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNeedHelpCard(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? AppColors.borderDark : Colors.transparent),
        ),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 30,
              backgroundImage: NetworkImage(
                'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=150',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Need Help?',
                    style: AppTextStyles.headingSmall(isDark),
                  ),
                  Text(
                    'Our support team is always here for you',
                    style: AppTextStyles.bodySmall(isDark),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '24x7 Support • Instant Response • 100% Satisfaction',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.amber : AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {
                          AppHaptics.mediumTap();
                          context.push('/support');
                        },
                        icon: const Icon(Icons.chat_bubble_outline, size: 14, color: Colors.white),
                        label: Text('Chat Now', style: AppTextStyles.badgeText.copyWith(fontSize: 11)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.secondary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: () {
                          AppHaptics.mediumTap();
                          // Simulating Call Action
                        },
                        icon: Icon(Icons.phone_outlined, size: 14, color: isDark ? Colors.white : AppColors.secondary),
                        label: Text(
                          'Call Us', 
                          style: AppTextStyles.badgeText.copyWith(
                            fontSize: 11, 
                            color: isDark ? Colors.white : AppColors.secondary,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: isDark ? Colors.white38 : AppColors.secondary),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
    );
  }

  // --- DIALOGS & BOTTOM SHEETS ---

  void _showAddressDialog(BuildContext context, WidgetRef ref, String currentAddress, bool isDark) {
    final textController = TextEditingController(text: currentAddress);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Change Address', style: AppTextStyles.headingSmall(isDark)),
        content: TextField(
          controller: textController,
          decoration: const InputDecoration(
            hintText: 'Enter new address details...',
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.primary)),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondaryLight)),
          ),
          ElevatedButton(
            onPressed: () {
              AppHaptics.heavyTap();
              ref.read(currentAddressProvider.notifier).updateAddress(textController.text);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildPinnedHeader(BuildContext context, String currentAddress, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.backgroundDark : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: _buildAddressDropdown(context, ref, currentAddress, isDark),
          ),
          const SizedBox(width: 8),
          _buildSearchIcon(context, isDark),
          _buildThemeToggle(ref, isDark),
          _buildNotificationBell(context, isDark),
          _buildProfileAvatar(context, isDark),
        ],
      ),
    );
  }

  Widget _buildHeaderRow(BuildContext context, WidgetRef ref, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Profile Avatar
        GestureDetector(
          onTap: () {
            AppHaptics.lightTap();
            context.push('/profile');
          },
          child: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primary, width: 1.5),
                ),
                child: CircleAvatar(
                  radius: 20,
                  backgroundImage: NetworkImage(
                    (ref.watch(authProvider).user?['avatarUrl']?.toString() ?? '').isNotEmpty
                        ? ref.watch(authProvider).user!['avatarUrl']!.toString()
                        : 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150',
                  ),
                ),
              ),
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ),
        
        // Brand Logo Text
        Column(
          children: [
            Text(
              'QuickFix',
              style: AppTextStyles.headingMedium(isDark).copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            Text(
              'Fix Fast, Live Easy',
              style: AppTextStyles.bodySmall(isDark).copyWith(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),

        // Dark Mode Toggle & Notifications Bell
        Row(
          children: [
            _buildThemeToggle(ref, isDark),
            _buildNotificationBell(context, isDark),
          ],
        ),
      ],
    );
  }

  Widget _buildAddressRow(BuildContext context, WidgetRef ref, String currentAddress, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: InkWell(
            onTap: () {
              AppHaptics.lightTap();
              context.push('/location-selector');
            },
            child: Row(
              children: [
                const Icon(
                  Icons.location_on,
                  color: AppColors.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Current Location',
                            style: AppTextStyles.bodySmall(isDark).copyWith(
                              fontWeight: FontWeight.bold,
                              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                            ),
                          ),
                          Icon(
                            Icons.keyboard_arrow_down,
                            size: 16,
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                          ),
                        ],
                      ),
                      Text(
                        currentAddress,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodyMedium(isDark).copyWith(
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : AppColors.textPrimaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Locate Me Button
        GestureDetector(
          onTap: () async {
            AppHaptics.mediumTap();
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Row(
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    ),
                    SizedBox(width: 12),
                    Text('Determining GPS location...'),
                  ],
                ),
                duration: Duration(seconds: 4),
                behavior: SnackBarBehavior.floating,
              ),
            );

            bool success = await ref.read(currentAddressProvider.notifier).fetchGPSLocation(requestPermission: true);
            if (context.mounted) {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('GPS Location updated successfully!'),
                    backgroundColor: AppColors.success,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Failed to fetch GPS location. Please select manually.'),
                    backgroundColor: AppColors.error,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : AppColors.secondary,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.my_location,
                  color: Colors.white,
                  size: 14,
                ),
                const SizedBox(width: 6),
                Text(
                  'Locate me',
                  style: AppTextStyles.badgeText.copyWith(fontSize: 11),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
  Widget _buildSearchBarRow(BuildContext context, bool isDark) {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () {
              AppHaptics.lightTap();
              context.push('/search');
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.search_rounded,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Search for services or shops...',
                    style: AppTextStyles.bodyMedium(isDark).copyWith(
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildComingSoonCard(BuildContext context, bool isDark) {
    final currentLoc = ref.watch(currentAddressProvider);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF1E1E2A), const Color(0xFF252535)]
              : [const Color(0xFFF0F4FF), const Color(0xFFE8F0FE)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? AppColors.borderDark
              : AppColors.primary.withOpacity(0.15),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Rocket illustration
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.primary, AppColors.secondary],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.35),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(Icons.rocket_launch_outlined, color: Colors.white, size: 38),
          ).animate().scale(delay: 100.ms, duration: 500.ms, curve: Curves.elasticOut),

          const SizedBox(height: 20),

          Text(
            'We\'re Coming Soon! 🚀',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppColors.secondary,
              letterSpacing: -0.3,
            ),
          ).animate().fadeIn(delay: 200.ms),

          const SizedBox(height: 8),

          Text(
            'QuickFix is expanding! We\'re onboarding trusted service partners near you. Be the first to know when we go live.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySmall(isDark).copyWith(
              fontSize: 12.5,
              height: 1.55,
            ),
          ).animate().fadeIn(delay: 300.ms),

          const SizedBox(height: 24),

          // Notify Me CTA
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _showNotifyMeDialog(context, isDark, currentLoc),
              icon: const Icon(Icons.notifications_active_outlined, size: 18),
              label: const Text('Notify Me When Available'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2, end: 0),
          ),

          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    AppHaptics.lightTap();
                    context.push('/location-selector');
                  },
                  icon: const Icon(Icons.edit_location_alt_outlined, size: 16),
                  label: const Text('Change Area', style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: isDark ? Colors.white70 : AppColors.secondary,
                    side: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    AppHaptics.lightTap();
                    // Fetch real GPS location
                    ref.read(currentAddressProvider.notifier).fetchGPSLocation(requestPermission: true);
                  },
                  icon: const Icon(Icons.my_location_outlined, size: 16),
                  label: const Text('Detect Location', style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ).animate().fadeIn(delay: 500.ms),
        ],
      ),
    );
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
                  'We\'ll notify you on WhatsApp the moment QuickFix goes live near ${currentLoc.address.split(',').first}.',
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
                  child: ElevatedButton(
                    onPressed: isSubmitting ? null : () async {
                      final phone = phoneController.text.trim();
                      if (phone.isEmpty || phone.length < 10) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please enter a valid phone number')),
                        );
                        return;
                      }
                      setDialogState(() => isSubmitting = true);
                      try {
                        final dioClient = ref.read(dioClientProvider);
                        await dioClient.post('/demand/submit', data: {
                          'phone': phone,
                          'address': currentLoc.address,
                          'latitude': currentLoc.latitude,
                          'longitude': currentLoc.longitude,
                        });
                        if (ctx.mounted) {
                          Navigator.of(ctx).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('✅ You\'re on the list! We\'ll notify you when we launch near you.'),
                              backgroundColor: AppColors.success,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      } catch (e) {
                        if (ctx.mounted) {
                          Navigator.of(ctx).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('✅ You\'re registered! We\'ll notify you when we launch.'),
                              backgroundColor: AppColors.success,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: isSubmitting
                        ? const SizedBox(
                            height: 18, width: 18,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Text('Notify Me', style: TextStyle(fontWeight: FontWeight.bold)),
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
