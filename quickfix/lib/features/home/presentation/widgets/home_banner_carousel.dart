import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quickfix/core/theme/app_colors.dart';
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
      viewportFraction: 0.94,
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
        // ── Banner Pages ───────────────────────────────────────────────────
        SizedBox(
          height: 228,
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

        // ── Premium Pill Indicators ────────────────────────────────────────
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(widget.banners.length, (index) {
            final isActive = _currentBannerIndex == index;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeInOutCubic,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: isActive ? 28 : 7,
              height: 7,
              decoration: BoxDecoration(
                color: isActive
                    ? AppColors.primaryAccent
                    : (isDark
                        ? AppColors.borderDark
                        : const Color(0xFFCBD5E1)),
                borderRadius: BorderRadius.circular(4),
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
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.10),
              blurRadius: 20,
              spreadRadius: 0,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // ── Background Image ──────────────────────────────────────────
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
                      Icons.image_outlined,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : const Color(0xFF94A3B8),
                      size: 40,
                    ),
                  ),
                ),
              ),

              // ── Rich Gradient Overlay ─────────────────────────────────────
              if (!showFullWidthImage)
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withValues(alpha: 0.78),
                        Colors.black.withValues(alpha: 0.48),
                        Colors.black.withValues(alpha: 0.08),
                      ],
                      begin: Alignment.bottomLeft,
                      end: Alignment.topRight,
                      stops: const [0.0, 0.50, 1.0],
                    ),
                  ),
                ),

              // ── Text overlay ──────────────────────────────────────────────
              if (!showFullWidthImage)
                Positioned(
                  left: 20,
                  top: 18,
                  right: 20,
                  bottom: 18,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Top row: badge + discount
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primaryAccent.withValues(alpha: 0.85),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'LIMITED TIME',
                              style: GoogleFonts.inter(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                        ],
                      ),

                      // Center: subtitle + title
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (banner.code.isNotEmpty)
                            Text(
                              'USE CODE: ${banner.code}',
                              style: GoogleFonts.inter(
                                color: Colors.white.withValues(alpha: 0.80),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                          if (banner.code.isNotEmpty) const SizedBox(height: 4),
                          if (banner.title.isNotEmpty)
                            Text(
                              banner.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                height: 1.15,
                                letterSpacing: -0.6,
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withValues(alpha: 0.5),
                                    blurRadius: 10,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),

                      // Bottom: Book Now CTA
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Book Now',
                              style: GoogleFonts.outfit(
                                color: AppColors.primary,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.2,
                              ),
                            ),
                            const SizedBox(width: 5),
                            const Icon(
                              Icons.arrow_forward_rounded,
                              size: 14,
                              color: AppColors.primary,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

              // ── Discount badge — top right corner ─────────────────────────
              if (!showFullWidthImage && banner.percent.isNotEmpty)
                Positioned(
                  top: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 13,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFB800),
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFFB800).withValues(alpha: 0.40),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Text(
                      banner.percent,
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.3,
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
