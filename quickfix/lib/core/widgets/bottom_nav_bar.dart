import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quickfix/core/theme/app_colors.dart';
import 'package:quickfix/features/home/presentation/controllers/home_providers.dart';
import 'package:quickfix/core/utils/haptics.dart';

class CustomBottomNavBar extends ConsumerWidget {
  const CustomBottomNavBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16, left: 16, right: 16),
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          Container(
            height: 72,
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark.withValues(alpha: 0.9) : Colors.white.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
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
                    const SizedBox(width: 58), // Spacer for FAB
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
            ),
          ),
          Positioned(
            top: -24,
            child: GestureDetector(
              onTap: () {
                AppHaptics.heavyTap();
                context.push('/booking-quick');
              },
              child: Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: AppColors.primaryAccent,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryAccent.withValues(alpha: 0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(Icons.add, color: Colors.white, size: 28),
              ),
            ),
          ),
        ],
      ),
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
    const activeColor = AppColors.primaryAccent;
    final inactiveColor = isDark ? Colors.white54 : AppColors.textSecondaryLight;

    return GestureDetector(
      onTap: () {
        AppHaptics.lightTap();
        ref.read(currentNavIndexProvider.notifier).state = index;
        context.go(route);
      },
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 60,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              color: isSelected ? activeColor : inactiveColor,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: isSelected
                  ? GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: activeColor,
                    )
                  : GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                      color: inactiveColor,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
