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
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Image.network(
            banner.imageUrl,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            cacheWidth: 800,
            errorBuilder: (_, __, ___) => Container(
              color: const Color(0xFFF1F5F9),
              child: const Center(
                child: Icon(Icons.image, color: Color(0xFF94A3B8), size: 40),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
