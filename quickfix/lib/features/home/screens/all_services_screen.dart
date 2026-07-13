import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:quickfix/shared/themes/app_colors.dart';
import 'package:quickfix/shared/themes/app_text_styles.dart';
import 'package:quickfix/shared/widgets/shimmer_loading.dart';
import 'package:quickfix/shared/utils/haptics.dart';
import 'package:quickfix/features/home/models/home_models.dart';
import 'package:quickfix/features/home/providers/home_providers.dart';

class AllServicesScreen extends ConsumerWidget {
  const AllServicesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(isDarkModeProvider);
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDark ? Colors.white : AppColors.secondary,
          ),
          onPressed: () {
            AppHaptics.lightTap();
            context.pop();
          },
        ),
        title: Text('All Services', style: AppTextStyles.headingMedium(isDark)),
        actions: [
          IconButton(
            icon: Icon(
              Icons.refresh,
              color: isDark ? Colors.white70 : AppColors.secondary,
            ),
            onPressed: () {
              AppHaptics.mediumTap();
              ref.invalidate(categoriesProvider);
            },
          ),
        ],
      ),
      body: categoriesAsync.when(
        data: (categories) {
          if (categories.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.grid_view_outlined,
                    size: 64,
                    color: isDark ? Colors.white30 : Colors.grey.shade300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No services available',
                    style: AppTextStyles.headingSmall(isDark).copyWith(
                      color: isDark ? Colors.white54 : AppColors.textSecondaryLight,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Check back later for available services.',
                    style: AppTextStyles.bodySmall(isDark),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            physics: const BouncingScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 1.0,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final ServiceCategory cat = categories[index];
              return GestureDetector(
                onTap: () {
                  AppHaptics.mediumTap();
                  // Same navigation as Home Screen category tap — preserves full booking flow
                  context.push('/category/${cat.id}');
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
                        padding: cat.iconUrl == null || cat.iconUrl!.trim().isEmpty
                            ? const EdgeInsets.all(10)
                            : const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: isDark
                              ? cat.iconColor.withOpacity(0.15)
                              : (cat.iconUrl == null || cat.iconUrl!.trim().isEmpty
                                  ? Colors.white
                                  : Colors.transparent),
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
                                    width: 38,
                                    height: 38,
                                    fit: BoxFit.contain,
                                    placeholderBuilder: (context) => Icon(
                                      cat.icon,
                                      color: cat.iconColor,
                                      size: 26,
                                    ),
                                  )
                                : ClipRRect(
                                    borderRadius: BorderRadius.circular(19),
                                    child: Image.network(
                                      cat.iconUrl!.trim().startsWith('http://')
                                          ? cat.iconUrl!.trim().replaceFirst('http://', 'https://')
                                          : cat.iconUrl!.trim(),
                                      width: 38,
                                      height: 38,
                                      fit: BoxFit.contain,
                                      cacheWidth: 100,
                                      errorBuilder: (context, error, stackTrace) => Icon(
                                        cat.icon,
                                        color: cat.iconColor,
                                        size: 26,
                                      ),
                                    ),
                                  ),
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Text(
                          cat.name,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bodySmall(isDark).copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: isDark ? Colors.white : AppColors.textPrimaryLight,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ).animate(delay: (40 * index).ms).fadeIn(duration: 250.ms).slideY(begin: 0.05, end: 0);
            },
          );
        },
        loading: () => GridView.builder(
          padding: const EdgeInsets.all(16),
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 1.0,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: 9,
          itemBuilder: (context, index) =>
              const ShimmerLoading(width: 80, height: 80, borderRadius: 16),
        ),
        error: (e, s) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: 16),
              Text(
                'Failed to load services',
                style: AppTextStyles.headingSmall(isDark),
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: () => ref.invalidate(categoriesProvider),
                icon: const Icon(Icons.refresh, color: Colors.white),
                label: const Text('Retry', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
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
