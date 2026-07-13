import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:quickfix/shared/themes/app_colors.dart';
import 'package:quickfix/shared/themes/app_shadows.dart';
import 'package:quickfix/shared/utils/haptics.dart';
import 'package:quickfix/shared/widgets/shimmer_loading.dart';
import 'package:quickfix/shared/widgets/section_header.dart';
import 'package:quickfix/features/home/models/home_models.dart';
import 'package:quickfix/features/home/providers/home_providers.dart';
import 'package:quickfix/core/network/error_handler.dart';

class HomeCategoriesGrid extends ConsumerStatefulWidget {
  const HomeCategoriesGrid({super.key});

  @override
  ConsumerState<HomeCategoriesGrid> createState() => _HomeCategoriesGridState();
}

class _HomeCategoriesGridState extends ConsumerState<HomeCategoriesGrid> {
  // Track the tapped index for active state (resets after animation)
  int? _tappedIndex;

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(isDarkModeProvider);
    final categoriesAsync = ref.watch(categoriesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'All Services',
          isDark: isDark,
          onSeeAll: () {
            AppHaptics.lightTap();
            context.push('/category/all');
          },
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: categoriesAsync.when(
            data: (categories) {
              final List<ServiceCategory> displayedCategories;
              if (categories.length > 5) {
                displayedCategories = categories.take(5).toList()
                  ..add(
                    const ServiceCategory(
                      id: 'more',
                      name: 'More',
                      icon: Icons.more_horiz,
                      backgroundColor: Color(0xFFF1F5F9),
                      iconColor: Color(0xFF475569),
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
                  childAspectRatio: 0.88,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: displayedCategories.length,
                itemBuilder: (context, index) {
                  final cat = displayedCategories[index];
                  final isActive = _tappedIndex == index;

                  return GestureDetector(
                    onTap: () {
                      AppHaptics.mediumTap();
                      setState(() => _tappedIndex = index);
                      Future.delayed(const Duration(milliseconds: 300), () {
                        if (mounted) setState(() => _tappedIndex = null);
                      });
                      if (cat.id == 'more') {
                        context.push('/category/all');
                      } else {
                        context.push('/category/${cat.id}');
                      }
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOut,
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.surfaceDark
                            : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: isActive
                            ? Border.all(color: AppColors.primary, width: 1.8)
                            : isDark
                                ? Border.all(color: AppColors.borderDark, width: 1)
                                : Border.all(color: const Color(0xFFEFF2F5), width: 1),
                        boxShadow: isDark ? [] : AppShadows.card,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // ── Icon Container ─────────────────────────────
                          AnimatedScale(
                            scale: isActive ? 0.92 : 1.0,
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeInOut,
                            child: Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: isDark
                                    ? cat.iconColor.withValues(alpha: 0.15)
                                    : cat.backgroundColor,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Center(
                                child: _buildIcon(cat, isDark),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          // ── Label ──────────────────────────────────────
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Text(
                              cat.name,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                height: 1.25,
                                letterSpacing: -0.1,
                                color: isDark
                                    ? Colors.white
                                    : AppColors.textPrimaryLight,
                              ),
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
                childAspectRatio: 0.88,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: 6,
              itemBuilder: (context, index) => const ShimmerLoading(
                width: double.infinity,
                height: 100,
                borderRadius: 14,
              ),
            ),
            error: (e, s) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text(
                  ErrorHandler.handle(e, s).message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
      ],
    );
  }

  Widget _buildIcon(ServiceCategory cat, bool isDark) {
    if (cat.iconUrl == null || cat.iconUrl!.trim().isEmpty) {
      return Icon(cat.icon, color: cat.iconColor, size: 30);
    }

    final url = cat.iconUrl!.trim().startsWith('http://')
        ? cat.iconUrl!.trim().replaceFirst('http://', 'https://')
        : cat.iconUrl!.trim();

    final isSvg = url.toLowerCase().contains('.svg') ||
        url.toLowerCase().contains('format=svg');

    const double imageSize = 46.0;

    if (isSvg) {
      return SvgPicture.network(
        url,
        width: imageSize,
        height: imageSize,
        fit: BoxFit.contain,
        placeholderBuilder: (_) =>
            Icon(cat.icon, color: cat.iconColor, size: 30),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Image.network(
        url,
        width: imageSize,
        height: imageSize,
        fit: BoxFit.contain,
        cacheWidth: 120,
        errorBuilder: (_, __, ___) =>
            Icon(cat.icon, color: cat.iconColor, size: 30),
      ),
    );
  }
}
