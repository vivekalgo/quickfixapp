import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:quickfix/core/theme/app_colors.dart';
import 'package:quickfix/core/theme/app_shadows.dart';
import 'package:quickfix/core/utils/haptics.dart';
import 'package:quickfix/features/home/models/home_models.dart';
import 'package:quickfix/features/home/presentation/controllers/home_providers.dart';

class HomeBannerCarousel extends ConsumerStatefulWidget {
  final List<PromoBanner> banners;

  const HomeBannerCarousel({super.key, required this.banners});

  @override
  ConsumerState<HomeBannerCarousel> createState() => _HomeBannerCarouselState();
}

class _HomeBannerCarouselState extends ConsumerState<HomeBannerCarousel> {
  late final PageController _bannerController;
  int _currentBannerIndex = 0;
  Timer? _autoPlayTimer;

  @override
  void initState() {
    super.initState();
    final bannersCount = widget.banners.length;
    final initialPage = bannersCount > 1 ? bannersCount * 1000 : 0;
    _bannerController = PageController(
      viewportFraction: 0.92,
      initialPage: initialPage,
    );
    _currentBannerIndex = 0;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _startAutoPlay();
      }
    });
  }

  @override
  void didUpdateWidget(covariant HomeBannerCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.banners.length != oldWidget.banners.length) {
      _stopAutoPlay();
      _currentBannerIndex = 0;
      if (_bannerController.hasClients && widget.banners.isNotEmpty) {
        final bannersCount = widget.banners.length;
        final initialPage = bannersCount > 1 ? bannersCount * 1000 : 0;
        _bannerController.jumpToPage(initialPage);
      }
      _startAutoPlay();
    }
  }

  @override
  void dispose() {
    _stopAutoPlay();
    _bannerController.dispose();
    super.dispose();
  }

  void _startAutoPlay() {
    _stopAutoPlay();
    if (widget.banners.length <= 1) return;
    _autoPlayTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_bannerController.hasClients) {
        final nextPage = _bannerController.page!.round() + 1;
        _bannerController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOutCubic,
        );
      }
    });
  }

  void _stopAutoPlay() {
    _autoPlayTimer?.cancel();
    _autoPlayTimer = null;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.banners.isEmpty) return const SizedBox.shrink();
    final isDark = ref.watch(isDarkModeProvider);

    return Column(
      children: [
        // ── Banner Pages ─────────────────────────────────────────────────
        SizedBox(
          height: 162,
          child: RepaintBoundary(
            child: NotificationListener<ScrollNotification>(
              onNotification: (notification) {
                if (notification is ScrollStartNotification) {
                  if (notification.dragDetails != null) {
                    _stopAutoPlay();
                  }
                } else if (notification is ScrollEndNotification) {
                  _startAutoPlay();
                }
                return false;
              },
              child: PageView.builder(
                controller: _bannerController,
                onPageChanged: (i) {
                  if (widget.banners.isNotEmpty) {
                    setState(() {
                      _currentBannerIndex = i % widget.banners.length;
                    });
                  }
                },
                itemCount: widget.banners.length <= 1
                    ? widget.banners.length
                    : 100000,
                itemBuilder: (context, index) {
                  if (widget.banners.isEmpty) return const SizedBox.shrink();
                  final actualIndex = index % widget.banners.length;
                  final banner = widget.banners[actualIndex];
                  return _BannerCard(
                    banner: banner,
                    onTap: () {
                      AppHaptics.heavyTap();
                      context.push('/category/all');
                    },
                  );
                },
              ),
            ),
          ),
        ),

        // ── Page Indicators ──────────────────────────────────────────────
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(widget.banners.length, (index) {
            final isActive = _currentBannerIndex == index;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeInOut,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: isActive ? 20 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: isActive
                    ? AppColors.primary
                    : (isDark ? AppColors.borderDark : const Color(0xFFD1D5DB)),
                borderRadius: BorderRadius.circular(3),
              ),
            );
          }),
        ),
        const SizedBox(height: 4),
      ],
    );
  }
}

class _BannerCard extends StatelessWidget {
  final PromoBanner banner;
  final VoidCallback onTap;

  const _BannerCard({required this.banner, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final bool showFullWidthImage =
        banner.title.isEmpty && banner.code.isEmpty && banner.percent.isEmpty;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          boxShadow: AppShadows.elevated,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // ── Background Image: covers the entire card ──────────────
              Image.network(
                banner.imageUrl,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                cacheWidth: 800,
                errorBuilder: (_, __, ___) => Container(
                  color: isDark
                      ? AppColors.surfaceDark
                      : const Color(0xFFF1F5F9),
                  child: Center(
                    child: Icon(
                      Icons.image,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : const Color(0xFF94A3B8),
                      size: 40,
                    ),
                  ),
                ),
              ),

              // ── Gradient Overlay for Text Readability ────────────────
              // (Only shown if we have text overlays, to make white text readable over any image)
              if (!showFullWidthImage)
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withValues(alpha: 0.55),
                        Colors.black.withValues(alpha: 0.15),
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                  ),
                ),

              // ── Text overlay on the left ──────────────────────────────
              if (!showFullWidthImage)
                Positioned(
                  left: 16,
                  top: 14,
                  right: MediaQuery.of(context).size.width * 0.92 * 0.38,
                  bottom: 14,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // "Limited Time Offer" pill badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Limited Time Offer',
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                            letterSpacing: 0.1,
                          ),
                        ),
                      ),

                      // Main Title
                      if (banner.title.isNotEmpty)
                        Text(
                          banner.title,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            height: 1.22,
                            letterSpacing: -0.3,
                            shadows: [
                              Shadow(
                                color: Color(0x66000000),
                                blurRadius: 4,
                                offset: Offset(0, 1),
                              ),
                            ],
                          ),
                        ),

                      // Code + Book Now row
                      Row(
                        children: [
                          // Use Code: pill (only if not empty)
                          if (banner.code.isNotEmpty)
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.75),
                                    width: 1,
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'Use Code: ${banner.code}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.2,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          if (banner.code.isNotEmpty) const SizedBox(width: 7),
                          // Book Now CTA
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Book Now',
                                  style: TextStyle(
                                    color: AppColors.primary,
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Icon(
                                  Icons.chevron_right_rounded,
                                  size: 12,
                                  color: AppColors.primary,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

              // ── Discount badge — top right corner ─────────────────────
              if (!showFullWidthImage && banner.percent.isNotEmpty)
                Positioned(
                  top: 12,
                  right: 14,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      banner.percent,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
