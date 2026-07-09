import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/haptics.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../features/home/presentation/providers/home_providers.dart';

final _notificationsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  try {
    final res = await DioClient().get('/notifications');
    final data = res.data as List;
    return data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  } catch (e) {
    return [];
  }
});

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  final Set<String> _readIds = {};

  IconData _iconForColor(String iconColor) {
    switch (iconColor) {
      case 'success':   return Icons.check_circle_outlined;
      case 'info':      return Icons.account_balance_wallet_outlined;
      case 'warning':   return Icons.warning_amber_outlined;
      case 'error':     return Icons.error_outline;
      default:          return Icons.notifications_active_outlined;
    }
  }

  Color _colorForTag(String iconColor, bool isDark) {
    switch (iconColor) {
      case 'success':  return AppColors.success;
      case 'info':     return AppColors.info;
      case 'warning':  return AppColors.warning;
      case 'error':    return AppColors.error;
      case 'primary':  return AppColors.primary;
      default:         return AppColors.accent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(isDarkModeProvider);
    final notificationsAsync = ref.watch(_notificationsProvider);

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
        elevation: 0,
        title: Text('Notifications', style: AppTextStyles.headingMedium(isDark)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            AppHaptics.lightTap();
            if (context.canPop()) context.pop();
            else { ref.read(currentNavIndexProvider.notifier).state = 0; context.go('/home'); }
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            onPressed: () {
              AppHaptics.lightTap();
              ref.invalidate(_notificationsProvider);
            },
          ),
        ],
      ),
      body: notificationsAsync.when(
        loading: () => _buildSkeleton(isDark),
        error: (err, _) => _buildError(isDark),
        data: (notifications) {
          if (notifications.isEmpty) {
            return Center(
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.notifications_off_outlined, size: 70, color: AppColors.textSecondaryLight),
                const SizedBox(height: 16),
                Text('No notifications yet', style: AppTextStyles.headingSmall(isDark)),
                const SizedBox(height: 6),
                Text('We\'ll notify you about bookings,\noffers, and updates here.', textAlign: TextAlign.center, style: AppTextStyles.bodySmall(isDark)),
              ]),
            );
          }

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async => ref.invalidate(_notificationsProvider),
            child: ListView.builder(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final item = notifications[index];
                final id = item['id']?.toString() ?? index.toString();
                final isRead = _readIds.contains(id);
                final iconColor = item['iconColor']?.toString() ?? 'primary';
                final color = _colorForTag(iconColor, isDark);
                final icon = _iconForColor(iconColor);

                return GestureDetector(
                  onTap: () => setState(() => _readIds.add(id)),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isRead
                          ? (isDark ? AppColors.surfaceDark : Colors.white)
                          : (isDark ? AppColors.surfaceDark.withOpacity(0.8) : color.withOpacity(0.04)),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isRead
                            ? (isDark ? AppColors.borderDark : AppColors.borderLight)
                            : color.withOpacity(0.25),
                      ),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 4))],
                    ),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
                        child: Icon(icon, color: color, size: 20),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(children: [
                            Expanded(child: Text(item['title']?.toString() ?? '', style: AppTextStyles.headingSmall(isDark).copyWith(fontSize: 14))),
                            if (!isRead)
                              Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle)),
                          ]),
                          const SizedBox(height: 4),
                          Text(item['body']?.toString() ?? '', style: AppTextStyles.bodySmall(isDark).copyWith(color: isDark ? Colors.white60 : AppColors.textSecondaryLight)),
                          const SizedBox(height: 8),
                          Text(item['time']?.toString() ?? 'Just now', style: AppTextStyles.bodySmall(isDark).copyWith(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
                        ]),
                      ),
                    ]),
                  ).animate(delay: (50 * index).ms).fadeIn().slideY(begin: 0.05, end: 0),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildSkeleton(bool isDark) {
    final base = isDark ? AppColors.surfaceDark : Colors.grey.shade200;
    final highlight = isDark ? AppColors.borderDark : Colors.grey.shade100;
    return Shimmer.fromColors(
      baseColor: base,
      highlightColor: highlight,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 5,
        itemBuilder: (_, __) => Container(
          height: 88,
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }

  Widget _buildError(bool isDark) {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Icon(Icons.cloud_off_rounded, size: 64, color: AppColors.textSecondaryLight),
      const SizedBox(height: 16),
      Text('Could not load notifications', style: AppTextStyles.headingSmall(isDark)),
      const SizedBox(height: 12),
      ElevatedButton(
        onPressed: () => ref.invalidate(_notificationsProvider),
        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
        child: const Text('Retry', style: TextStyle(color: Colors.white)),
      ),
    ]));
  }
}
