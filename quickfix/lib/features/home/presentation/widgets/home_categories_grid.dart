import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quickfix/core/theme/app_colors.dart';
import 'package:quickfix/core/utils/haptics.dart';
import 'package:quickfix/core/widgets/shimmer_loading.dart';
import 'package:quickfix/core/widgets/section_header.dart';
import 'package:quickfix/features/home/models/home_models.dart';
import 'package:quickfix/features/home/presentation/controllers/home_providers.dart';
import 'package:quickfix/core/network/error_handler.dart';

class HomeCategoriesGrid extends ConsumerStatefulWidget {
  const HomeCategoriesGrid({super.key});

  @override
  ConsumerState<HomeCategoriesGrid> createState() => _HomeCategoriesGridState();
}

class _HomeCategoriesGridState extends ConsumerState<HomeCategoriesGrid> {
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
              if (categories.length > 7) {
                displayedCategories = categories.take(7).toList()
                  ..add(
                    const ServiceCategory(
                      id: 'more',
                      name: 'More',
                      icon: Icons.apps_rounded,
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
                  crossAxisCount: 4,
                  childAspectRatio: 0.82,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 12,
                ),
                itemCount: displayedCategories.length,
                itemBuilder: (context, index) {
                  final cat = displayedCategories[index];
                  final isActive = _tappedIndex == index;

                  return GestureDetector(
                    onTap: () {
                      AppHaptics.mediumTap();
                      setState(() => _tappedIndex = index);
                      Future.delayed(const Duration(milliseconds: 280), () {
                        if (mounted) setState(() => _tappedIndex = null);
                      });
                      if (cat.id == 'more') {
                        context.push('/category/all');
                      } else {
                        context.push('/category/${cat.id}');
                      }
                    },
                    child: AnimatedScale(
                      scale: isActive ? 0.93 : 1.0,
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeInOut,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // ── Icon Container ──────────────────────────────
                          Container(
                            width: double.infinity,
                            height: 62,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? cat.iconColor.withValues(alpha: 0.12)
                                  : cat.backgroundColor,
                              borderRadius: BorderRadius.circular(18),
                              border: isActive
                                  ? Border.all(
                                      color: AppColors.primaryAccent,
                                      width: 1.5,
                                    )
                                  : isDark
                                  ? Border.all(
                                      color: AppColors.borderDark,
                                      width: 1,
                                    )
                                  : Border.all(
                                      color: const Color(0xFFEEF2F7),
                                      width: 1,
                                    ),
                            ),
                            child: Center(
                              child: _buildIcon(cat, isDark),
                            ),
                          ),
                          const SizedBox(height: 7),
                          // ── Label ──────────────────────────────────────
                          Text(
                            cat.name,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              height: 1.2,
                              letterSpacing: -0.1,
                              color: isDark
                                  ? Colors.white
                                  : AppColors.textPrimaryLight,
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
                crossAxisCount: 4,
                childAspectRatio: 0.85,
                crossAxisSpacing: 10,
                mainAxisSpacing: 12,
              ),
              itemCount: 8,
              itemBuilder: (context, index) => const ShimmerLoading(
                width: double.infinity,
                height: 80,
                borderRadius: 18,
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
      return Icon(cat.icon, color: cat.iconColor, size: 26);
    }

    final url = cat.iconUrl!.trim().startsWith('http://')
        ? cat.iconUrl!.trim().replaceFirst('http://', 'https://')
        : cat.iconUrl!.trim();

    final isSvg =
        url.toLowerCase().contains('.svg') ||
        url.toLowerCase().contains('format=svg');

    const double imageSize = 40.0;

    if (isSvg) {
      return SvgPicture.network(
        url,
        width: imageSize,
        height: imageSize,
        fit: BoxFit.contain,
        placeholderBuilder: (_) =>
            Icon(cat.icon, color: cat.iconColor, size: 26),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        url,
        width: imageSize,
        height: imageSize,
        fit: BoxFit.contain,
        cacheWidth: 120,
        errorBuilder: (_, __, ___) =>
            Icon(cat.icon, color: cat.iconColor, size: 26),
      ),
    );
  }
}
