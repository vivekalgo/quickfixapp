import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:quickfix/shared/themes/app_colors.dart';
import 'package:quickfix/features/home/providers/home_providers.dart';
import 'package:quickfix/shared/utils/haptics.dart';

class CustomBottomNavBar extends ConsumerWidget {
  const CustomBottomNavBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(currentNavIndexProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      alignment: Alignment.bottomCenter,
      clipBehavior: Clip.none,
      children: [
        // The bottom navigation bar background & tabs
        Container(
          height: 72,
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
            border: Border(
              top: BorderSide(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
                width: 0.8,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 12,
                offset: const Offset(0, -3),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                context: context,
                ref: ref,
                index: 0,
                icon: Icons.home_outlined,
                activeIcon: Icons.home,
                label: 'Home',
                route: '/home',
              ),
              _buildNavItem(
                context: context,
                ref: ref,
                index: 1,
                icon: Icons.assignment_outlined,
                activeIcon: Icons.assignment,
                label: 'Orders',
                route: '/orders',
              ),
              // Empty space for the floating action button
              const SizedBox(width: 60),
              _buildNavItem(
                context: context,
                ref: ref,
                index: 3,
                icon: Icons.favorite_border_outlined,
                activeIcon: Icons.favorite,
                label: 'Wishlist',
                route: '/wishlist',
              ),
              _buildNavItem(
                context: context,
                ref: ref,
                index: 4,
                icon: Icons.local_offer_outlined,
                activeIcon: Icons.local_offer,
                label: 'Offers',
                route: '/offers',
              ),
            ],
          ),
        ),
        
        // Floating "Book Now" Circle Button
        Positioned(
          top: -24,
          child: GestureDetector(
            onTap: () {
              AppHaptics.heavyTap();
              context.push('/booking-quick');
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.35),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                        spreadRadius: 1,
                      ),
                    ],
                    border: Border.all(
                      color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                      width: 4,
                    ),
                  ),
                  child: const Icon(
                    Icons.build,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Book Now',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: currentIndex == 2
                        ? AppColors.primary
                        : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required WidgetRef ref,
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required String route,
  }) {
    final currentIndex = ref.watch(currentNavIndexProvider);
    final isSelected = currentIndex == index;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: () {
        AppHaptics.lightTap();
        ref.read(currentNavIndexProvider.notifier).state = index;
        context.go(route);
      },
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: SizedBox(
        width: 60,
        height: 60,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedScale(
              scale: isSelected ? 1.12 : 1.0,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              child: Icon(
                isSelected ? activeIcon : icon,
                color: isSelected
                    ? AppColors.primary
                    : (isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight),
                size: 23,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight:
                    isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected
                    ? AppColors.primary
                    : (isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight),
              ),
            ),
            const SizedBox(height: 2),
            // Active indicator dot
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: isSelected ? 4 : 0,
              height: isSelected ? 4 : 0,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
