import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/currency_formatter.dart';
import 'package:quickfix_provider/features/auth/presentation/providers/auth_provider.dart';
import 'package:quickfix_provider/features/bookings/presentation/providers/bookings_provider.dart';
import 'package:quickfix_provider/features/dashboard/presentation/providers/dashboard_provider.dart';
import 'package:quickfix_provider/features/bookings/presentation/screens/booking_detail_screen.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final dashboardState = ref.watch(dashboardProvider);
    final bookingsState = ref.watch(bookingsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Filter pending requests for this shop
    final pendingRequests = bookingsState.bookings
        .where((b) => b.status == 'pending')
        .toList();

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await ref.read(dashboardProvider.notifier).fetchStats();
            await ref.read(bookingsProvider.notifier).fetchBookings(silent: true);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Profile Info & Online Toggle
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome back,',
                          style: AppTextStyles.bodyMedium(isDark),
                        ),
                        Text(
                          authState.shop?.ownerName ?? 'Service Partner',
                          style: AppTextStyles.headingMedium(isDark).copyWith(fontSize: 20),
                        ),
                        Text(
                          authState.shop?.shopDisplayId ?? '',
                          style: AppTextStyles.bodySmall(isDark).copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Text(
                          dashboardState.stats.isOnline ? 'ONLINE' : 'OFFLINE',
                          style: TextStyle(
                            color: dashboardState.stats.isOnline ? AppColors.success : AppColors.danger,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Switch(
                          value: dashboardState.stats.isOnline,
                          activeColor: AppColors.success,
                          inactiveThumbColor: AppColors.danger,
                          inactiveTrackColor: AppColors.danger.withOpacity(0.2),
                          onChanged: (val) {
                            ref.read(dashboardProvider.notifier).toggleOnlineStatus(val);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Revenue Wallet Banner Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: AppColors.plusGradient,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'TODAY\'S REVENUE',
                        style: AppTextStyles.badgeText.copyWith(
                          color: Colors.white.withOpacity(0.7),
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        CurrencyFormatter.format(dashboardState.stats.revenue),
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontFamily: 'Outfit',
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Wallet Balance',
                                style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                CurrencyFormatter.format(dashboardState.stats.walletBalance),
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'Rating',
                                style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  const Icon(Icons.star_rounded, color: Colors.amber, size: 18),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${dashboardState.stats.rating} (${dashboardState.stats.reviewsCount} reviews)',
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Performance Metrics Grid
                Text(
                  'PERFORMANCE METRICS',
                  style: AppTextStyles.headingSmall(isDark).copyWith(
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 12),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.6,
                  children: [
                    _buildStatCard('Today\'s Orders', dashboardState.stats.todayOrders.toString(), Icons.today, Colors.blue, isDark),
                    _buildStatCard('Pending Requests', dashboardState.stats.pendingOrders.toString(), Icons.hourglass_empty_rounded, Colors.orange, isDark),
                    _buildStatCard('Accepted Jobs', dashboardState.stats.acceptedOrders.toString(), Icons.assignment_turned_in_rounded, Colors.green, isDark),
                    _buildStatCard('Completed Jobs', dashboardState.stats.completedOrders.toString(), Icons.done_all_rounded, Colors.teal, isDark),
                  ],
                ),
                const SizedBox(height: 28),

                // Live Booking Requests (Protected Customer Privacy Flow)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'LIVE BOOKING REQUESTS',
                      style: AppTextStyles.headingSmall(isDark).copyWith(
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${pendingRequests.length} New',
                        style: const TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                if (pendingRequests.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.wifi_off_rounded, size: 48, color: Colors.white.withOpacity(0.3)),
                        const SizedBox(height: 12),
                        const Text(
                          'No active requests in your area',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Ensure your switch is ONLINE to start receiving nearby hyperlocal bookings instantly.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12),
                        ),
                      ],
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: pendingRequests.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final booking = pendingRequests[index];
                      return _buildRequestCard(context, ref, booking, isDark);
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.25 : 0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white60 : AppColors.textSecondaryLight,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Icon(icon, color: color, size: 20),
            ],
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppColors.secondary,
              fontFamily: 'Inter',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestCard(BuildContext context, WidgetRef ref, dynamic booking, bool isDark) {
    final labelStyle = TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.5,
      color: isDark ? Colors.white60 : AppColors.textSecondaryLight,
    );
    final valueStyle = TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 13,
      color: isDark ? Colors.white : AppColors.secondary,
    );

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.25 : 0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                booking.id,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primary),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'PENDING ACCEPTANCE',
                  style: TextStyle(color: AppColors.warning, fontSize: 9, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            child: Divider(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
              height: 1,
            ),
          ),
          
          // Job details (Privacy-safe)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('SERVICE', style: labelStyle),
                  const SizedBox(height: 3),
                  Text(booking.title, style: valueStyle),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('EST. EARNINGS', style: labelStyle),
                  const SizedBox(height: 3),
                  Text(
                    CurrencyFormatter.format(booking.estEarnings),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.success),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('LOCATION AREA', style: labelStyle),
                  const SizedBox(height: 3),
                  Text(booking.approxAddress, style: valueStyle),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('DURATION', style: labelStyle),
                  const SizedBox(height: 3),
                  Text(booking.estDuration, style: valueStyle),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('VISITING CHARGES', style: labelStyle),
                  const SizedBox(height: 3),
                  Text(
                    CurrencyFormatter.format(booking.visitingCharges),
                    style: valueStyle,
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('TIME SLOT', style: labelStyle),
                  const SizedBox(height: 3),
                  Text(booking.slot, style: valueStyle),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    // Reject job (Cancel)
                    ref.read(bookingsProvider.notifier).updateStatus(booking.id, 'cancelled');
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.danger,
                    side: const BorderSide(color: AppColors.danger, width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Reject', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    // Accept Job
                    final success = await ref.read(bookingsProvider.notifier).updateStatus(booking.id, 'accepted');
                    if (success && context.mounted) {
                      // Navigate to details screen which reveals customer info
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => BookingDetailScreen(bookingId: booking.id),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: const Text('Accept Booking', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
