import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quickfix_provider/core/theme/app_colors.dart';
import 'package:quickfix_provider/core/utils/currency_formatter.dart';
import 'package:quickfix_provider/core/utils/date_formatter.dart';
import 'package:quickfix_provider/features/bookings/presentation/controllers/bookings_provider.dart';
import 'package:quickfix_provider/features/bookings/presentation/pages/booking_detail_screen.dart';
import 'package:quickfix_provider/core/widgets/error_widgets.dart';
import 'package:quickfix_provider/core/network/connectivity_provider.dart';

class BookingsScreen extends ConsumerWidget {
  const BookingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(bookingsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Auto-retry on internet reconnection if previously failed
    ref.listen<AsyncValue<bool>>(connectivityProvider, (previous, next) {
      if (next.value == true &&
          previous?.value == false &&
          state.errorMessage != null) {
        ref.read(bookingsProvider.notifier).fetchBookings();
      }
    });

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: isDark
            ? AppColors.backgroundDark
            : AppColors.backgroundLight,
        appBar: AppBar(
          title: const Text('My Booking Orders'),
          centerTitle: true,
          bottom: const TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelColor: AppColors.primary,
            unselectedLabelColor: Colors.white54,
            indicatorColor: AppColors.primary,
            tabs: [
              Tab(text: 'Ongoing'),
              Tab(text: 'New Request'),
              Tab(text: 'Completed'),
              Tab(text: 'Cancelled'),
            ],
          ),
        ),
        body: state.errorMessage != null
            ? RefreshIndicator(
                color: AppColors.primary,
                onRefresh: () async {
                  await ref.read(bookingsProvider.notifier).fetchBookings();
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Container(
                    height:
                        MediaQuery.of(context).size.height -
                        kToolbarHeight -
                        MediaQuery.of(context).padding.top -
                        50,
                    alignment: Alignment.center,
                    child: CommonErrorWidget(
                      message: state.errorMessage!,
                      onRetry: () =>
                          ref.read(bookingsProvider.notifier).fetchBookings(),
                    ),
                  ),
                ),
              )
            : state.isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              )
            : TabBarView(
                children: [
                  _buildBookingsList(
                    context,
                    ref,
                    state.bookings
                        .where(
                          (b) => [
                            'accepted',
                            'navigating',
                            'arrived',
                            'work_started',
                          ].contains(b.status),
                        )
                        .toList(),
                    isDark,
                    'No ongoing bookings. Go to "New Request" to accept some!',
                  ),
                  _buildBookingsList(
                    context,
                    ref,
                    state.bookings.where((b) => b.status == 'pending').toList(),
                    isDark,
                    'No new booking requests at the moment.',
                  ),
                  _buildBookingsList(
                    context,
                    ref,
                    state.bookings
                        .where(
                          (b) => [
                            'completed',
                            'payment_completed',
                            'closed',
                          ].contains(b.status),
                        )
                        .toList(),
                    isDark,
                    'No completed orders yet.',
                  ),
                  _buildBookingsList(
                    context,
                    ref,
                    state.bookings
                        .where(
                          (b) => ['cancelled', 'rejected'].contains(b.status),
                        )
                        .toList(),
                    isDark,
                    'No cancelled orders.',
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildBookingsList(
    BuildContext context,
    WidgetRef ref,
    List<dynamic> list,
    bool isDark,
    String emptyLabel,
  ) {
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async {
        await ref.read(bookingsProvider.notifier).fetchBookings(silent: true);
      },
      child: list.isEmpty
          ? SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Container(
                height: MediaQuery.of(context).size.height - 250,
                alignment: Alignment.center,
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.assignment_late_rounded,
                        size: 48,
                        color: Colors.white.withValues(alpha: 0.2),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        emptyLabel,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.4),
                          fontSize: 13.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          : ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: list.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final booking = list[index];
                return InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            BookingDetailScreen(bookingId: booking.id),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.surfaceDark
                          : AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark
                            ? AppColors.borderDark
                            : AppColors.borderLight,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              booking.id,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: AppColors.primary,
                              ),
                            ),
                            Text(
                              booking.status.toUpperCase().replaceAll('_', ' '),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                                color: _getStatusColor(booking.status),
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 20, color: Colors.white10),
                        Text(
                          booking.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.calendar_today,
                                  size: 14,
                                  color: Colors.white54,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  DateFormatter.formatShortDate(booking.date),
                                  style: const TextStyle(
                                    color: Colors.white54,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                const Icon(
                                  Icons.access_time,
                                  size: 14,
                                  color: Colors.white54,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  booking.slot,
                                  style: const TextStyle(
                                    color: Colors.white54,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              booking.approxAddress,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.5),
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              CurrencyFormatter.format(booking.amount),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return AppColors.warning;
      case 'accepted':
        return AppColors.info;
      case 'navigating':
        return Colors.blue;
      case 'arrived':
        return Colors.deepPurpleAccent;
      case 'work_started':
        return Colors.orangeAccent;
      case 'work_completed':
        return Colors.teal;
      case 'payment_completed':
      case 'closed':
        return AppColors.success;
      default:
        return AppColors.danger;
    }
  }
}
