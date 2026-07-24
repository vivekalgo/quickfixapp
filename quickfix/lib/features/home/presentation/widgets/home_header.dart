import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quickfix/core/theme/app_colors.dart';
import 'package:quickfix/core/utils/haptics.dart';
import 'package:quickfix/features/auth/presentation/controllers/auth_providers.dart';
import 'package:quickfix/features/home/presentation/controllers/home_providers.dart';
import 'package:quickfix/features/notifications/presentation/controllers/notifications_provider.dart';

// Helper to get short address format
String getShortAddress(String address) {
  if (address.isEmpty) return 'Select Location';
  final parts = address.split(',');
  if (parts.isEmpty) return address;
  return parts.first.trim();
}

String _getGreeting() {
  final hour = DateTime.now().hour;
  if (hour < 12) return 'Good morning';
  if (hour < 17) return 'Good afternoon';
  return 'Good evening';
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
    final user = ref.watch(authProvider).user;
    final avatarUrl = user?['avatarUrl']?.toString() ?? '';
    final displayName = user?['name']?.toString() ?? '';
    final firstName = displayName.isNotEmpty
        ? displayName.split(' ').first
        : 'there';
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
                  border: Border.all(
                    color: AppColors.primaryAccent,
                    width: 2.5,
                  ),
                ),
                padding: const EdgeInsets.all(2),
                child: CircleAvatar(
                  radius: 21,
                  backgroundImage: NetworkImage(finalAvatar),
                  backgroundColor: AppColors.surfaceDark,
                ),
              ),
              // Online indicator dot
              Positioned(
                right: 1,
                bottom: 1,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark ? AppColors.backgroundDark : Colors.white,
                      width: 2,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(width: 12),

        // ── Greeting + Brand ───────────────────────────────────────────────
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${_getGreeting()}, $firstName 👋',
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                  letterSpacing: 0.1,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                'QuickFix',
                style: GoogleFonts.outfit(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.8,
                  height: 1.1,
                  color: isDark ? Colors.white : AppColors.primary,
                ),
              ),
            ],
          ),
        ),

        // ── Action Icons ───────────────────────────────────────────────────
        Row(
          children: [
            // Dark mode toggle
            GestureDetector(
              onTap: () {
                AppHaptics.mediumTap();
                ref.read(isDarkModeProvider.notifier).toggleTheme();
              },
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.surfaceDark
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isDark
                        ? AppColors.borderDark
                        : const Color(0xFFE2E8F0),
                    width: 1,
                  ),
                ),
                child: Icon(
                  isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                  color: isDark
                      ? const Color(0xFFFFB800)
                      : AppColors.textSecondaryLight,
                  size: 18,
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Notifications
            GestureDetector(
              onTap: () {
                AppHaptics.lightTap();
                context.push('/notifications');
              },
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.surfaceDark
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isDark
                            ? AppColors.borderDark
                            : const Color(0xFFE2E8F0),
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      Icons.notifications_outlined,
                      size: 18,
                      color: isDark
                          ? Colors.white70
                          : AppColors.textPrimaryLight,
                    ),
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      right: -2,
                      top: -2,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          color: AppColors.primaryAccent,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 15,
                          minHeight: 15,
                        ),
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

    return GestureDetector(
      onTap: () {
        AppHaptics.lightTap();
        context.push('/location-selector');
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppColors.borderDark : const Color(0xFFE8ECF0),
            width: 1,
          ),
          boxShadow: isDark
              ? []
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 3),
                  ),
                ],
        ),
        child: Row(
          children: [
            // Location icon
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppColors.primaryAccent.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.location_on_rounded,
                color: AppColors.primaryAccent,
                size: 17,
              ),
            ),
            const SizedBox(width: 10),
            // Address text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Delivering to',
                        style: GoogleFonts.inter(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w500,
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
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w700,
                      fontSize: 13.5,
                      letterSpacing: -0.2,
                      color: isDark ? Colors.white : AppColors.textPrimaryLight,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            // Locate Me pill
            GestureDetector(
              onTap: () async {
                AppHaptics.mediumTap();
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Row(
                      children: [
                        SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: 10),
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
                      backgroundColor: success
                          ? AppColors.success
                          : AppColors.error,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.my_location_rounded,
                      color: Colors.white,
                      size: 12,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'Locate',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
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
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0),
            width: 1,
          ),
          boxShadow: isDark
              ? []
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 16,
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
                  : const Color(0xFF94A3B8),
              size: 22,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                "Search services, e.g. 'AC Repair', 'Plumber'...",
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w400,
                  fontSize: 13.5,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : const Color(0xFFA0ABBB),
                ),
              ),
            ),
            // Divider
            Container(
              height: 22,
              width: 1,
              color: isDark
                  ? AppColors.borderDark
                  : const Color(0xFFE2E8F0),
            ),
            const SizedBox(width: 10),
            // Filter icon
            const Icon(
              Icons.tune_rounded,
              color: AppColors.primaryAccent,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PINNED HEADER: Shows when scrolled past threshold — glassmorphism blur bar
// ─────────────────────────────────────────────────────────────────────────────
class HomePinnedHeader extends ConsumerWidget {
  const HomePinnedHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(isDarkModeProvider);
    final currentAddress = ref.watch(currentAddressProvider).address;
    final unreadCount = ref.watch(unreadNotificationsCountProvider);
    final avatarUrl = ref.watch(
      authProvider.select((state) => state.user?['avatarUrl']?.toString() ?? ''),
    );
    final finalAvatar = avatarUrl.isNotEmpty
        ? avatarUrl
        : 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150';

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          decoration: BoxDecoration(
            color: (isDark ? AppColors.backgroundDark : Colors.white)
                .withValues(alpha: 0.88),
            border: Border(
              bottom: BorderSide(
                color: isDark
                    ? AppColors.borderDark
                    : const Color(0xFFE8ECF0),
                width: 0.8,
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
                  borderRadius: BorderRadius.circular(8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.location_on_rounded,
                        color: AppColors.primaryAccent,
                        size: 18,
                      ),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          getShortAddress(currentAddress),
                          style: GoogleFonts.outfit(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
                            color: isDark ? Colors.white : AppColors.primary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 16,
                        color: AppColors.primaryAccent,
                      ),
                    ],
                  ),
                ),
              ),
              // Search icon
              _PinnedIconButton(
                icon: Icons.search_rounded,
                isDark: isDark,
                onTap: () {
                  AppHaptics.lightTap();
                  context.push('/search');
                },
              ),
              // Dark mode toggle
              _PinnedIconButton(
                icon: isDark
                    ? Icons.light_mode_rounded
                    : Icons.dark_mode_rounded,
                isDark: isDark,
                onTap: () {
                  AppHaptics.mediumTap();
                  ref.read(isDarkModeProvider.notifier).toggleTheme();
                },
              ),
              // Notifications
              _PinnedNotificationButton(
                isDark: isDark,
                unreadCount: unreadCount,
                onTap: () {
                  AppHaptics.lightTap();
                  context.push('/notifications');
                },
              ),
              const SizedBox(width: 4),
              // Avatar
              GestureDetector(
                onTap: () {
                  AppHaptics.lightTap();
                  context.push('/profile');
                },
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.primaryAccent,
                      width: 2,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 14,
                    backgroundImage: NetworkImage(finalAvatar),
                    backgroundColor: AppColors.surfaceDark,
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

// ─────────────────────────────────────────────────────────────────────────────
// INTERNAL HELPERS
// ─────────────────────────────────────────────────────────────────────────────

class _PinnedIconButton extends StatelessWidget {
  final IconData icon;
  final bool isDark;
  final VoidCallback onTap;

  const _PinnedIconButton({
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
          color: isDark ? Colors.white70 : AppColors.primary,
          size: 21,
        ),
      ),
    );
  }
}

class _PinnedNotificationButton extends StatelessWidget {
  final bool isDark;
  final int unreadCount;
  final VoidCallback onTap;

  const _PinnedNotificationButton({
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
              Icons.notifications_outlined,
              size: 22,
              color: isDark ? Colors.white70 : AppColors.primary,
            ),
            if (unreadCount > 0)
              Positioned(
                right: -2,
                top: -1,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    color: AppColors.primaryAccent,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 14,
                    minHeight: 14,
                  ),
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
