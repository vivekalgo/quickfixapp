import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:quickfix_provider/core/theme/app_colors.dart';
import 'package:quickfix_provider/core/theme/app_text_styles.dart';
import 'package:quickfix_provider/core/utils/currency_formatter.dart';
import 'package:quickfix_provider/core/utils/date_formatter.dart';
import 'package:quickfix_provider/features/bookings/presentation/controllers/bookings_provider.dart';
import 'package:quickfix_provider/core/widgets/error_widgets.dart';
import 'package:quickfix_provider/core/network/connectivity_provider.dart';
import 'package:quickfix_provider/features/bookings/presentation/widgets/customer_info_card.dart';
import 'package:quickfix_provider/features/bookings/presentation/widgets/job_timeline_card.dart';
import 'package:quickfix_provider/features/bookings/presentation/widgets/booking_status_card.dart';
import 'package:quickfix_provider/features/bookings/presentation/widgets/quotation_card.dart';

class BookingDetailScreen extends ConsumerStatefulWidget {
  final String bookingId;

  const BookingDetailScreen({super.key, required this.bookingId});

  @override
  ConsumerState<BookingDetailScreen> createState() =>
      _BookingDetailScreenState();
}

class _BookingDetailScreenState extends ConsumerState<BookingDetailScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(bookingsProvider.notifier).fetchBookingDetails(widget.bookingId);
    });
  }

  Future<void> _launchMaps(double lat, double lng) async {
    final Uri url = Uri.parse('google.navigation:q=$lat,$lng');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      // Fallback web url
      final Uri webUrl = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
      );
      if (await canLaunchUrl(webUrl)) {
        await launchUrl(webUrl);
      }
    }
  }

  String _getNextStatus(String currentStatus) {
    switch (currentStatus) {
      case 'accepted':
        return 'navigating';
      case 'navigating':
        return 'arrived';
      case 'arrived':
        return 'work_started';
      case 'work_started':
        return 'work_completed';
      case 'work_completed':
        return 'payment_completed';
      case 'payment_completed':
        return 'closed';
      default:
        return '';
    }
  }

  String _getStatusActionButtonLabel(String currentStatus) {
    switch (currentStatus) {
      case 'accepted':
        return 'Start Travel / Navigate';
      case 'navigating':
        return 'I Have Arrived';
      case 'arrived':
        return 'Start Work';
      case 'work_started':
        return 'Mark Work Completed';
      case 'work_completed':
        return 'Confirm Payment Received';
      case 'payment_completed':
        return 'Close Booking Order';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(bookingsProvider);
    final booking = state.selectedBookingDetails;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Auto-retry on internet reconnection if previously failed
    ref.listen<AsyncValue<bool>>(connectivityProvider, (previous, next) {
      if (next.value == true &&
          previous?.value == false &&
          state.errorMessage != null) {
        ref
            .read(bookingsProvider.notifier)
            .fetchBookingDetails(widget.bookingId);
      }
    });

    Widget buildBody() {
      if (state.isLoading && booking == null) {
        return const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        );
      }

      if (state.errorMessage != null && booking == null) {
        return SingleChildScrollView(
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
              onRetry: () => ref
                  .read(bookingsProvider.notifier)
                  .fetchBookingDetails(widget.bookingId),
            ),
          ),
        );
      }

      if (booking == null) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Container(
            height:
                MediaQuery.of(context).size.height -
                kToolbarHeight -
                MediaQuery.of(context).padding.top -
                50,
            alignment: Alignment.center,
            child: CommonErrorWidget(
              message: 'Booking details not found.',
              onRetry: () => ref
                  .read(bookingsProvider.notifier)
                  .fetchBookingDetails(widget.bookingId),
            ),
          ),
        );
      }

      final nextStatus = _getNextStatus(booking.status);
      final actionLabel = _getStatusActionButtonLabel(booking.status);

      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status Summary Box
            BookingStatusCard(status: booking.status, isDark: isDark),
            const SizedBox(height: 20),

            // Stepper timeline indicator
            JobTimelineCard(
              currentStatus: booking.status,
              isDark: isDark,
            ),
            const SizedBox(height: 24),

            // Customer details panel
            Text(
              'CUSTOMER CONTACT DETAILS',
              style: AppTextStyles.headingSmall(isDark).copyWith(
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
                fontSize: 11,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 10),
            CustomerInfoCard(
              booking: booking,
              isDark: isDark,
            ),
            const SizedBox(height: 24),

            // Job Details
            Text(
              'ORDER BILL SUMMARY',
              style: AppTextStyles.headingSmall(isDark).copyWith(
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
                fontSize: 11,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
                border: Border.all(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSummaryRow('Job Category', booking.title, false),
                  _buildSummaryRow(
                    'Scheduled Date',
                    DateFormatter.formatShortDate(booking.date),
                    false,
                  ),
                  _buildSummaryRow('Preferred Slot', booking.slot, false),
                  _buildSummaryRow('Est. Duration', booking.estDuration, false),
                  if (booking.specialInstructions.isNotEmpty)
                    _buildSummaryRow(
                      'Instructions',
                      booking.specialInstructions,
                      false,
                    ),
                  Divider(
                    height: 24,
                    color: isDark
                        ? AppColors.borderDark
                        : AppColors.borderLight,
                  ),
                  _buildSummaryRow(
                    'Visiting Charges',
                    CurrencyFormatter.format(booking.visitingCharges),
                    false,
                  ),
                  _buildSummaryRow(
                    'Booking Amount',
                    CurrencyFormatter.format(booking.amount),
                    false,
                  ),
                  _buildSummaryRow(
                    'Estimated Earnings',
                    CurrencyFormatter.format(booking.estEarnings),
                    true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Quotation Form / Details
            QuotationCard(booking: booking, isDark: isDark),
            const SizedBox(height: 20),

            if (booking.status == 'quote_sent') ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.hourglass_empty, color: Colors.blue),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Awaiting customer approval. Once approved, the booking will transition to Working status.',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Action Status Stepper Button
            if (nextStatus.isNotEmpty &&
                actionLabel.isNotEmpty &&
                !(booking.pricingType == 'inspection' &&
                    (booking.status == 'arrived' ||
                        booking.status == 'quote_sent'))) ...[
              ElevatedButton(
                onPressed: state.isLoading
                    ? null
                    : () async {
                        final success = await ref
                            .read(bookingsProvider.notifier)
                            .updateStatus(booking.id, nextStatus);
                        if (success &&
                            nextStatus == 'navigating' &&
                            booking.customerLat != null) {
                          // Launch Google Maps navigation automatically
                          _launchMaps(
                            booking.customerLat!,
                            booking.customerLng!,
                          );
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                ),
                child: state.isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        actionLabel,
                        style: AppTextStyles.buttonText.copyWith(fontSize: 15),
                      ),
              ),
              const SizedBox(height: 12),
            ],

            // Reject Button (Only if Accepted and not yet navigating/started)
            if (booking.status == 'accepted') ...[
              OutlinedButton(
                onPressed: state.isLoading
                    ? null
                    : () => ref
                          .read(bookingsProvider.notifier)
                          .updateStatus(booking.id, 'cancelled'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.danger,
                  side: const BorderSide(color: AppColors.danger),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Cancel Job Request',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(booking?.id ?? 'Order Details'),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          await ref
              .read(bookingsProvider.notifier)
              .fetchBookingDetails(widget.bookingId);
        },
        child: buildBody(),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, bool highlight) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.white60 : AppColors.textSecondaryLight,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: highlight ? 14 : 13,
              fontWeight: highlight ? FontWeight.bold : FontWeight.w500,
              color: highlight
                  ? AppColors.success
                  : (isDark ? Colors.white : AppColors.secondary),
            ),
          ),
        ],
      ),
    );
  }
}
