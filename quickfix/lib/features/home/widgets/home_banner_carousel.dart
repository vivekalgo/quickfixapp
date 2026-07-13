import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:quickfix/shared/themes/app_colors.dart';
import 'package:quickfix/shared/themes/app_shadows.dart';
import 'package:quickfix/shared/utils/haptics.dart';
import 'package:quickfix/features/home/models/home_models.dart';
import 'package:quickfix/features/home/providers/home_providers.dart';

class HomeBannerCarousel extends ConsumerStatefulWidget {
  final List<PromoBanner> banners;

  const HomeBannerCarousel({
    super.key,
    required this.banners,
  });

  @override
  ConsumerState<HomeBannerCarousel> createState() =>
      _HomeBannerCarouselState();
}

class _HomeBannerCarouselState extends ConsumerState<HomeBannerCarousel> {
  late final PageController _bannerController;
  int _currentBannerIndex = 0;

  @override
  void initState() {
    super.initState();
    _bannerController = PageController(viewportFraction: 0.92);
  }

  @override
  void dispose() {
    _bannerController.dispose();
    super.dispose();
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
            child: PageView.builder(
              controller: _bannerController,
              onPageChanged: (i) => setState(() => _currentBannerIndex = i),
              itemCount: widget.banners.length,
              itemBuilder: (context, index) {
                final banner = widget.banners[index];
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
                    : (isDark
                        ? AppColors.borderDark
                        : const Color(0xFFD1D5DB)),
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

// ─────────────────────────────────────────────────────────────────────────────
// Individual banner card — split layout matching reference image
// ─────────────────────────────────────────────────────────────────────────────
class _BannerCard extends StatelessWidget {
  final PromoBanner banner;
  final VoidCallback onTap;

  const _BannerCard({required this.banner, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          boxShadow: AppShadows.elevated,
          // Warm coral gradient — left lighter, right deeper
          gradient: const LinearGradient(
            colors: [Color(0xFFFF8E6E), Color(0xFFFF4E36)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Stack(
            children: [
              // ── Right side: product image ──────────────────────────────
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                // Image occupies right ~44% of card
                child: LayoutBuilder(
                  builder: (ctx, constraints) {
                    return SizedBox(
                      width: MediaQuery.of(context).size.width * 0.92 * 0.44,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          // Product image
                          Image.network(
                            banner.imageUrl,
                            fit: BoxFit.cover,
                            cacheWidth: 400,
                            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                          ),
                          // Left feather — blends image into gradient
                          Positioned(
                            left: 0,
                            top: 0,
                            bottom: 0,
                            child: Container(
                              width: 52,
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Color(0xFFFF4E36), Colors.transparent],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // ── Left side: text content ────────────────────────────────
              Positioned(
                left: 16,
                top: 14,
                right: MediaQuery.of(context).size.width * 0.92 * 0.40,
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

                    // Main title — from admin panel
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
                            color: Color(0x33000000),
                            blurRadius: 4,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                    ),

                    // Code + Book Now row
                    Row(
                      children: [
                        // Use Code: pill — from admin panel
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
                        const SizedBox(width: 7),
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
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                'Book Now',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const Icon(
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
                    style: TextStyle(
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
