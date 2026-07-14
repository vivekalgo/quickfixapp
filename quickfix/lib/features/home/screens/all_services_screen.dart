import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:quickfix/shared/themes/app_colors.dart';
import 'package:quickfix/shared/themes/app_text_styles.dart';
import 'package:quickfix/shared/widgets/shimmer_loading.dart';
import 'package:quickfix/shared/widgets/error_widgets.dart';
import 'package:quickfix/shared/utils/haptics.dart';
import 'package:quickfix/features/home/models/home_models.dart';
import 'package:quickfix/features/home/providers/home_providers.dart';
import 'package:quickfix/core/providers/connectivity_provider.dart';
import 'package:quickfix/core/network/error_handler.dart';

class AllServicesScreen extends ConsumerWidget {
  const AllServicesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(isDarkModeProvider);
    final categoriesAsync = ref.watch(categoriesProvider);

    // Auto-retry on internet reconnection if previously failed
    ref.listen<AsyncValue<bool>>(connectivityProvider, (previous, next) {
      if (next.value == true && previous?.value == false && categoriesAsync.hasError) {
        ref.invalidate(categoriesProvider);
      }
    });

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
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          await ref.refresh(categoriesProvider.future);
        },
        child: categoriesAsync.when(
          data: (categories) {
            if (categories.isEmpty) {
              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Container(
                  height: MediaQuery.of(context).size.height - kToolbarHeight - MediaQuery.of(context).padding.top - 50,
                  alignment: Alignment.center,
                  child: const EmptyStateWidget(
                    title: 'No services available',
                    message: 'Check back later for available services.',
                    icon: Icons.grid_view_outlined,
                  ),
                ),
              );
            }

            return GridView.builder(
              padding: const EdgeInsets.all(16),
              physics: const AlwaysScrollableScrollPhysics(),
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
                                ? cat.iconColor.withValues(alpha: 0.15)
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
          error: (e, s) => SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Container(
              height: MediaQuery.of(context).size.height - kToolbarHeight - MediaQuery.of(context).padding.top - 50,
              alignment: Alignment.center,
              child: CommonErrorWidget(
                message: ErrorHandler.handle(e, s).message,
                onRetry: () => ref.invalidate(categoriesProvider),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
