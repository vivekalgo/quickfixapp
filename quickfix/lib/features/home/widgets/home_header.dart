import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:quickfix/shared/themes/app_colors.dart';
import 'package:quickfix/shared/themes/app_text_styles.dart';
import 'package:quickfix/shared/themes/app_shadows.dart';
import 'package:quickfix/shared/utils/haptics.dart';
import 'package:quickfix/features/auth/providers/auth_providers.dart';
import 'package:quickfix/features/home/providers/home_providers.dart';

// Helper to get short address format
String getShortAddress(String address) {
  if (address.isEmpty) return 'Select Location';
  final parts = address.split(',');
  if (parts.isEmpty) return address;
  return parts.first.trim();
}

// ─────────────────────────────────────────────────────────────────────────────
// TOP ROW: Avatar | QuickFix Logo | Theme Toggle + Notifications
// ─────────────────────────────────────────────────────────────────────────────
class HomeHeaderRow extends ConsumerWidget {
  const HomeHeaderRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(isDarkModeProvider);
    final unreadCount = ref.watch(unreadNotificationsCountProvider);
    final avatarUrl = ref.watch(authProvider).user?['avatarUrl']?.toString() ?? '';
    final finalAvatar = avatarUrl.isNotEmpty
        ? avatarUrl
        : 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // ── User Avatar ────────────────────────────────────────────────────
        GestureDetector(
          onTap: () {
            AppHaptics.lightTap();
            context.push('/profile');
          },
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF4E36), Color(0xFFFF8A78)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(2),
                child: CircleAvatar(
                  radius: 20,
                  backgroundImage: NetworkImage(finalAvatar),
                  backgroundColor: AppColors.surfaceDark,
                ),
              ),
              // Online indicator dot
              Positioned(
                right: 1,
                bottom: 1,
                child: Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark ? AppColors.backgroundDark : Colors.white,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(width: 10),

        // ── Brand Name ─────────────────────────────────────────────────────
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'QuickFix',
                style: AppTextStyles.headingMedium(isDark).copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                  letterSpacing: -0.5,
                ),
              ),
              Text(
                'Fix Fast, Live Easy',
                style: AppTextStyles.bodySmall(isDark).copyWith(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.3,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
              ),
            ],
          ),
        ),

        // ── Action Icons ───────────────────────────────────────────────────
        Row(
          children: [
            _IconButton(
              icon: isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
              isDark: isDark,
              onTap: () {
                AppHaptics.mediumTap();
                ref.read(isDarkModeProvider.notifier).toggleTheme();
              },
            ),
            const SizedBox(width: 2),
            _NotificationIconButton(
              isDark: isDark,
              unreadCount: unreadCount,
              onTap: () {
                AppHaptics.lightTap();
                context.push('/notifications');
              },
            ),
          ],
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ADDRESS ROW: Location icon | Address text | Locate Me CTA
// ─────────────────────────────────────────────────────────────────────────────
class HomeAddressRow extends ConsumerWidget {
  const HomeAddressRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(isDarkModeProvider);
    final currentAddress = ref.watch(currentAddressProvider).address;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.borderDark : const Color(0xFFEFF2F5),
          width: 1,
        ),
        boxShadow: isDark ? [] : AppShadows.chip,
      ),
      child: Row(
        children: [
          // Location icon with subtle primary tint bg
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.location_on_rounded,
              color: AppColors.primary,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          // Address text
          Expanded(
            child: InkWell(
              onTap: () {
                AppHaptics.lightTap();
                context.push('/location-selector');
              },
              borderRadius: BorderRadius.circular(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Delivering to',
                        style: AppTextStyles.bodySmall(isDark).copyWith(
                          fontSize: 10.5,
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 14,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                    ],
                  ),
                  const SizedBox(height: 1),
                  Text(
                    currentAddress.isEmpty
                        ? 'Select your location'
                        : currentAddress,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodyMedium(isDark).copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: isDark ? Colors.white : AppColors.textPrimaryLight,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Locate Me CTA
          GestureDetector(
            onTap: () async {
              AppHaptics.mediumTap();
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Row(
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(width: 12),
                      Text('Determining GPS location...'),
                    ],
                  ),
                  duration: Duration(seconds: 4),
                  behavior: SnackBarBehavior.floating,
                ),
              );

              bool success = await ref
                  .read(currentAddressProvider.notifier)
                  .fetchGPSLocation(requestPermission: true);
              if (context.mounted) {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? 'GPS Location updated successfully!'
                          : 'Failed to fetch GPS location. Please select manually.',
                    ),
                    backgroundColor:
                        success ? AppColors.success : AppColors.error,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(20),
                boxShadow: AppShadows.primaryButton,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.my_location, color: Colors.white, size: 13),
                  const SizedBox(width: 5),
                  Text(
                    'Locate',
                    style: AppTextStyles.badgeText.copyWith(fontSize: 11),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SEARCH BAR: Full-width prominent search bar navigating to /search
// ─────────────────────────────────────────────────────────────────────────────
class HomeSearchBarRow extends ConsumerWidget {
  const HomeSearchBarRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(isDarkModeProvider);

    return GestureDetector(
      onTap: () {
        AppHaptics.lightTap();
        context.push('/search');
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? AppColors.borderDark : const Color(0xFFE5E9EF),
            width: 1,
          ),
          boxShadow: isDark
              ? []
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Row(
          children: [
            Icon(
              Icons.search_rounded,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
              size: 21,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Search services, shops...',
                style: AppTextStyles.bodyMedium(isDark).copyWith(
                  fontWeight: FontWeight.w400,
                  fontSize: 13.5,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : const Color(0xFF9CA3AF),
                ),
              ),
            ),
            // Mic icon — navigates to search (same action)
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.tune_rounded,
                color: AppColors.primary,
                size: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PINNED HEADER: Shows when scrolled past threshold
// ─────────────────────────────────────────────────────────────────────────────
class HomePinnedHeader extends ConsumerWidget {
  const HomePinnedHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(isDarkModeProvider);
    final currentAddress = ref.watch(currentAddressProvider).address;
    final unreadCount = ref.watch(unreadNotificationsCountProvider);
    final avatarUrl =
        ref.watch(authProvider).user?['avatarUrl']?.toString() ?? '';
    final finalAvatar = avatarUrl.isNotEmpty
        ? avatarUrl
        : 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.backgroundDark : Colors.white,
        boxShadow: AppShadows.header,
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          // Location
          Expanded(
            child: InkWell(
              onTap: () {
                AppHaptics.lightTap();
                context.push('/location-selector');
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.location_on_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                getShortAddress(currentAddress),
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: isDark
                                      ? Colors.white
                                      : AppColors.secondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              size: 16,
                              color: AppColors.primary,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Icons
          _IconButton(
            icon: Icons.search_rounded,
            isDark: isDark,
            onTap: () {
              AppHaptics.lightTap();
              context.push('/search');
            },
          ),
          _IconButton(
            icon: isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
            isDark: isDark,
            onTap: () {
              AppHaptics.mediumTap();
              ref.read(isDarkModeProvider.notifier).toggleTheme();
            },
          ),
          _NotificationIconButton(
            isDark: isDark,
            unreadCount: unreadCount,
            onTap: () {
              AppHaptics.lightTap();
              context.push('/notifications');
            },
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: () {
              AppHaptics.lightTap();
              context.push('/profile');
            },
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primary, width: 1.5),
              ),
              child: CircleAvatar(
                radius: 15,
                backgroundImage: NetworkImage(finalAvatar),
                backgroundColor: AppColors.surfaceDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// INTERNAL HELPERS
// ─────────────────────────────────────────────────────────────────────────────

class _IconButton extends StatelessWidget {
  final IconData icon;
  final bool isDark;
  final VoidCallback onTap;

  const _IconButton({
    required this.icon,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
        child: Icon(
          icon,
          color: isDark ? Colors.white70 : AppColors.secondary,
          size: 22,
        ),
      ),
    );
  }
}

class _NotificationIconButton extends StatelessWidget {
  final bool isDark;
  final int unreadCount;
  final VoidCallback onTap;

  const _NotificationIconButton({
    required this.isDark,
    required this.unreadCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(
              Icons.notifications_none_rounded,
              size: 24,
              color: isDark ? Colors.white70 : AppColors.secondary,
            ),
            if (unreadCount > 0)
              Positioned(
                right: -2,
                top: -1,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                  child: Text(
                    unreadCount > 9 ? '9+' : '$unreadCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 7.5,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
