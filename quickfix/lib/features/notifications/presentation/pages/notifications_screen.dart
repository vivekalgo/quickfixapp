import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shimmer/shimmer.dart';
import 'package:intl/intl.dart';
import 'package:quickfix/core/theme/app_colors.dart';
import 'package:quickfix/core/theme/app_text_styles.dart';
import 'package:quickfix/core/utils/haptics.dart';
import 'package:quickfix/features/home/presentation/controllers/home_providers.dart';
import 'package:quickfix/features/notifications/presentation/controllers/notifications_provider.dart';
import 'package:quickfix/core/network/error_handler.dart';
import 'package:quickfix/core/widgets/error_widgets.dart';
import 'package:quickfix/core/network/connectivity_provider.dart';
import 'package:quickfix/core/services/notification_service.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  IconData _iconForColor(String iconColor) {
    switch (iconColor) {
      case 'success':
        return Icons.check_circle_outlined;
      case 'info':
        return Icons.account_balance_wallet_outlined;
      case 'warning':
        return Icons.warning_amber_outlined;
      case 'error':
        return Icons.error_outline;
      default:
        return Icons.notifications_active_outlined;
    }
  }

  Color _colorForTag(String iconColor, bool isDark) {
    switch (iconColor) {
      case 'success':
        return AppColors.success;
      case 'info':
        return AppColors.info;
      case 'warning':
        return AppColors.warning;
      case 'error':
        return AppColors.error;
      case 'primary':
        return AppColors.primary;
      default:
        return AppColors.accent;
    }
  }

  String _formatDate(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateToCheck = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (dateToCheck == today) {
      return 'Today';
    } else if (dateToCheck == yesterday) {
      return 'Yesterday';
    } else {
      return DateFormat('dd MMM yyyy').format(dateTime);
    }
  }

  String _formatTime(DateTime dateTime) {
    return DateFormat('hh:mm a').format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(isDarkModeProvider);
    final notificationsAsync = ref.watch(notificationsProvider);

    // Auto-retry on internet reconnection if previously failed
    ref.listen<AsyncValue<bool>>(connectivityProvider, (previous, next) {
      if (next.value == true &&
          previous?.value == false &&
          notificationsAsync.hasError) {
        ref.invalidate(notificationsProvider);
      }
    });

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          ref.read(currentNavIndexProvider.notifier).state = 0;
          context.go('/home');
        }
      },
      child: Scaffold(
        backgroundColor: isDark
            ? AppColors.backgroundDark
            : AppColors.backgroundLight,
        appBar: AppBar(
          backgroundColor: isDark
              ? AppColors.backgroundDark
              : AppColors.backgroundLight,
          elevation: 0,
          title: Text(
            'Notifications',
            style: AppTextStyles.headingMedium(isDark),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              AppHaptics.lightTap();
              ref.read(currentNavIndexProvider.notifier).state = 0;
              context.go('/home');
            },
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.done_all),
              tooltip: 'Mark all as read',
              onPressed: () {
                AppHaptics.lightTap();
                notificationsAsync.whenData((list) {
                  final ids = list
                      .map((e) => e['id']?.toString() ?? '')
                      .toList();
                  ref
                      .read(readNotificationsProvider.notifier)
                      .markAllAsRead(ids);
                });
              },
            ),
            IconButton(
              key: const ValueKey('clear_notifications'),
              icon: const Icon(Icons.delete_sweep_outlined),
              tooltip: 'Clear all',
              onPressed: () {
                AppHaptics.lightTap();
                ref.read(readNotificationsProvider.notifier).clearAll();
              },
            ),
            IconButton(
              icon: const Icon(Icons.refresh_outlined),
              tooltip: 'Sync alerts',
              onPressed: () {
                AppHaptics.lightTap();
                ref.invalidate(syncNotificationsProvider);
              },
            ),
          ],
        ),
        body: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async =>
              await ref.refresh(syncNotificationsProvider.future),
          child: notificationsAsync.when(
            loading: () => _buildSkeleton(isDark),
            error: (err, st) => SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Container(
                height:
                    MediaQuery.of(context).size.height -
                    kToolbarHeight -
                    MediaQuery.of(context).padding.top -
                    50,
                alignment: Alignment.center,
                child: CommonErrorWidget(
                  message: ErrorHandler.handle(err, st).message,
                  onRetry: () => ref.invalidate(syncNotificationsProvider),
                ),
              ),
            ),
            data: (notifications) {
              if (notifications.isEmpty) {
                return SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Container(
                    height:
                        MediaQuery.of(context).size.height -
                        kToolbarHeight -
                        MediaQuery.of(context).padding.top -
                        50,
                    alignment: Alignment.center,
                    child: const EmptyStateWidget(
                      title: 'No notifications yet',
                      message:
                          'We\'ll notify you about bookings, offers, and updates here.',
                      icon: Icons.notifications_off_outlined,
                    ),
                  ),
                );
              }

              return ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: const EdgeInsets.all(16),
                itemCount: notifications.length,
                itemBuilder: (context, index) {
                  final item = notifications[index];
                  final id = item['id']?.toString() ?? index.toString();
                  final isRead = item['isRead'] == true;
                  final iconColor = item['iconColor']?.toString() ?? 'primary';
                  final color = _colorForTag(iconColor, isDark);
                  final icon = _iconForColor(iconColor);

                  final timeVal = item['time']?.toString() ?? 'Just now';
                  String dateStr = 'Just now';
                  String timeStr = '';

                  final parsedDate = DateTime.tryParse(timeVal);
                  if (parsedDate != null) {
                    final localDate = parsedDate.toLocal();
                    dateStr = _formatDate(localDate);
                    timeStr = _formatTime(localDate);
                  } else {
                    if (timeVal.toLowerCase().contains('just now')) {
                      dateStr = 'Just now';
                    } else {
                      dateStr = timeVal;
                    }
                  }

                  return Dismissible(
                    key: Key(id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.only(right: 20),
                      alignment: Alignment.centerRight,
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.delete_outline,
                        color: AppColors.error,
                      ),
                    ),
                    onDismissed: (_) {
                      AppHaptics.lightTap();
                      ref
                          .read(readNotificationsProvider.notifier)
                          .deleteNotification(id);
                    },
                    child: GestureDetector(
                      onTap: () {
                        AppHaptics.lightTap();
                        ref
                            .read(readNotificationsProvider.notifier)
                            .markAsRead(id);
                        NotificationService.handleNotificationClick(item);
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: isRead
                              ? (isDark ? AppColors.surfaceDark : Colors.white)
                              : (isDark
                                    ? AppColors.surfaceDark.withValues(
                                        alpha: 0.95,
                                      )
                                    : Colors.white),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isRead
                                ? (isDark
                                      ? AppColors.borderDark
                                      : AppColors.borderLight)
                                : color.withValues(alpha: 0.35),
                            width: isRead ? 1 : 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: isRead
                                  ? Colors.black.withValues(alpha: 0.01)
                                  : color.withValues(alpha: 0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Stack(
                            children: [
                              if (!isRead)
                                Positioned(
                                  left: 0,
                                  top: 0,
                                  bottom: 0,
                                  width: 4,
                                  child: Container(color: color),
                                ),
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  16,
                                  16,
                                  12,
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: color.withValues(alpha: 0.08),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(icon, color: color, size: 20),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  item['title']?.toString() ??
                                                      '',
                                                  style:
                                                      AppTextStyles.headingSmall(
                                                        isDark,
                                                      ).copyWith(
                                                        fontSize: 14,
                                                        fontWeight: isRead
                                                            ? FontWeight.w600
                                                            : FontWeight.w700,
                                                        height: 1.2,
                                                      ),
                                                ),
                                              ),
                                              if (!isRead)
                                                Container(
                                                  margin: const EdgeInsets.only(
                                                    left: 8,
                                                    top: 4,
                                                  ),
                                                  width: 8,
                                                  height: 8,
                                                  decoration: BoxDecoration(
                                                    color: color,
                                                    shape: BoxShape.circle,
                                                  ),
                                                ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            item['body']?.toString() ?? '',
                                            style:
                                                AppTextStyles.bodySmall(
                                                  isDark,
                                                ).copyWith(
                                                  fontSize: 12,
                                                  color: isDark
                                                      ? Colors.white70
                                                      : AppColors
                                                            .textSecondaryLight,
                                                  height: 1.35,
                                                ),
                                          ),
                                          const SizedBox(height: 12),
                                          Divider(
                                            height: 1,
                                            thickness: 0.5,
                                            color: isDark
                                                ? Colors.white10
                                                : Colors.black.withValues(
                                                    alpha: 0.06,
                                                  ),
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    Icons
                                                        .calendar_today_outlined,
                                                    size: 11,
                                                    color: isDark
                                                        ? Colors.white38
                                                        : Colors.black38,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    dateStr,
                                                    style:
                                                        AppTextStyles.bodySmall(
                                                          isDark,
                                                        ).copyWith(
                                                          fontSize: 10,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                          color: isDark
                                                              ? Colors.white38
                                                              : Colors.black54,
                                                        ),
                                                  ),
                                                ],
                                              ),
                                              if (timeStr.isNotEmpty)
                                                Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Icon(
                                                      Icons.access_time_rounded,
                                                      size: 11,
                                                      color: isDark
                                                          ? Colors.white38
                                                          : Colors.black38,
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      timeStr,
                                                      style:
                                                          AppTextStyles.bodySmall(
                                                            isDark,
                                                          ).copyWith(
                                                            fontSize: 10,
                                                            fontWeight:
                                                                FontWeight.w500,
                                                            color: isDark
                                                                ? Colors.white38
                                                                : Colors
                                                                      .black54,
                                                          ),
                                                    ),
                                                  ],
                                                ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ).animate(delay: (50 * index).ms).fadeIn().slideY(begin: 0.05, end: 0);
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSkeleton(bool isDark) {
    final base = isDark ? AppColors.surfaceDark : Colors.grey.shade200;
    final highlight = isDark ? AppColors.borderDark : Colors.grey.shade100;
    return RepaintBoundary(
      child: Shimmer.fromColors(
        baseColor: base,
        highlightColor: highlight,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: 5,
          itemBuilder: (_, __) => Container(
            height: 88,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
    );
  }
}
