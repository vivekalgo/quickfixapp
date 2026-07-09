import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../providers/bookings_provider.dart';

class BookingDetailScreen extends ConsumerStatefulWidget {
  final String bookingId;

  const BookingDetailScreen({super.key, required this.bookingId});

  @override
  ConsumerState<BookingDetailScreen> createState() => _BookingDetailScreenState();
}

class _BookingDetailScreenState extends ConsumerState<BookingDetailScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(bookingsProvider.notifier).fetchBookingDetails(widget.bookingId);
    });
  }

  Future<void> _makeCall(String phoneNumber) async {
    final Uri url = Uri.parse('tel:$phoneNumber');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  Future<void> _launchMaps(double lat, double lng) async {
    final Uri url = Uri.parse('google.navigation:q=$lat,$lng');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      // Fallback web url
      final Uri webUrl = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
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

    if (state.isLoading && booking == null) {
      return Scaffold(
        backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
        appBar: AppBar(title: const Text('Order Details')),
        body: const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    if (booking == null) {
      return Scaffold(
        backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
        appBar: AppBar(title: const Text('Order Details')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Booking not found', style: AppTextStyles.headingMedium(isDark)),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => ref.read(bookingsProvider.notifier).fetchBookingDetails(widget.bookingId),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final nextStatus = _getNextStatus(booking.status);
    final actionLabel = _getStatusActionButtonLabel(booking.status);

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(booking.id),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status Summary Box
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
              ),
              child: Row(
                children: [
                  Icon(
                    _getStatusIcon(booking.status),
                    color: _getStatusColor(booking.status),
                    size: 32,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('CURRENT STATUS', style: TextStyle(fontSize: 10, color: Colors.white54)),
                        const SizedBox(height: 2),
                        Text(
                          booking.status.toUpperCase().replaceAll('_', ' '),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: _getStatusColor(booking.status),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Stepper timeline indicator
            _buildStatusStepper(booking.status),
            const SizedBox(height: 24),

            // Customer details panel (Revealed only for accepted/navigating/etc)
            Text(
              'CUSTOMER CONTACT DETAILS',
              style: AppTextStyles.headingSmall(isDark).copyWith(
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                fontSize: 11,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 10),
            if (booking.isDetailsMasked)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                ),
                child: Row(
                  children: [
                    Icon(Icons.lock_rounded, color: Colors.white.withOpacity(0.3), size: 36),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Contact Info Restricted',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Accept the booking to reveal customer name, verified phone number, exact address, and maps navigation support.',
                            style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11.5, height: 1.4),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          booking.customerName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Row(
                          children: [
                            IconButton(
                              onPressed: () => _makeCall(booking.customerPhone),
                              icon: const Icon(Icons.phone, color: AppColors.success),
                              style: IconButton.styleFrom(
                                backgroundColor: AppColors.success.withOpacity(0.15),
                                shape: const CircleBorder(),
                              ),
                            ),
                            if (booking.customerLat != null && booking.customerLng != null) ...[
                              const SizedBox(width: 8),
                              IconButton(
                                onPressed: () => _launchMaps(booking.customerLat!, booking.customerLng!),
                                icon: const Icon(Icons.navigation_rounded, color: AppColors.primary),
                                style: IconButton.styleFrom(
                                  backgroundColor: AppColors.primary.withOpacity(0.15),
                                  shape: const CircleBorder(),
                                ),
                              ),
                            ]
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      booking.customerPhone,
                      style: TextStyle(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight, fontSize: 14),
                    ),
                    const Divider(height: 24, color: Colors.white12),
                    
                    const Text('VERIFIED ADDRESS', style: TextStyle(fontSize: 10, color: Colors.white54)),
                    const SizedBox(height: 4),
                    Text(
                      booking.customerAddress,
                      style: const TextStyle(fontSize: 13, height: 1.4, fontWeight: FontWeight.w500),
                    ),
                    if (booking.customerLat != null && booking.customerLng != null) ...[
                      const SizedBox(height: 12),
                      InkWell(
                        onTap: () => _launchMaps(booking.customerLat!, booking.customerLng!),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.primary.withOpacity(0.4)),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.map_rounded, color: AppColors.primary, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                'Open Google Maps Turn-By-Turn',
                                style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ]
                  ],
                ),
              ),
            const SizedBox(height: 24),

            // Job Details
            Text(
              'ORDER BILL SUMMARY',
              style: AppTextStyles.headingSmall(isDark).copyWith(
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                fontSize: 11,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSummaryRow('Job Category', booking.title, false),
                  _buildSummaryRow('Scheduled Date', DateFormatter.formatShortDate(booking.date), false),
                  _buildSummaryRow('Preferred Slot', booking.slot, false),
                  _buildSummaryRow('Est. Duration', booking.estDuration, false),
                  if (booking.specialInstructions.isNotEmpty)
                    _buildSummaryRow('Instructions', booking.specialInstructions, false),
                  const Divider(height: 24, color: Colors.white12),
                  _buildSummaryRow('Visiting Charges', CurrencyFormatter.format(booking.visitingCharges), false),
                  _buildSummaryRow('Booking Amount', CurrencyFormatter.format(booking.amount), false),
                  _buildSummaryRow('Estimated Earnings', CurrencyFormatter.format(booking.estEarnings), true),
                ],
              ),
            ),
            const SizedBox(height: 36),

            // Action Status Stepper Button
            if (nextStatus.isNotEmpty && actionLabel.isNotEmpty) ...[
              ElevatedButton(
                onPressed: state.isLoading
                    ? null
                    : () async {
                        final success = await ref
                            .read(bookingsProvider.notifier)
                            .updateStatus(booking.id, nextStatus);
                        if (success && nextStatus == 'navigating' && booking.customerLat != null) {
                          // Launch Google Maps navigation automatically
                          _launchMaps(booking.customerLat!, booking.customerLng!);
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 4,
                ),
                child: state.isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Text(actionLabel, style: AppTextStyles.buttonText.copyWith(fontSize: 15)),
              ),
              const SizedBox(height: 12),
            ],
            
            // Reject Button (Only if Accepted and not yet navigating/started)
            if (booking.status == 'accepted') ...[
              OutlinedButton(
                onPressed: state.isLoading
                    ? null
                    : () => ref.read(bookingsProvider.notifier).updateStatus(booking.id, 'cancelled'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.danger,
                  side: const BorderSide(color: AppColors.danger),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Cancel Job Request', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, bool highlight) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: Colors.white54)),
          Text(
            value,
            style: TextStyle(
              fontSize: highlight ? 14 : 13,
              fontWeight: highlight ? FontWeight.bold : FontWeight.w500,
              color: highlight ? AppColors.success : Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.hourglass_top_rounded;
      case 'accepted':
        return Icons.handshake_rounded;
      case 'navigating':
        return Icons.directions_car_rounded;
      case 'arrived':
        return Icons.pin_drop_rounded;
      case 'work_started':
        return Icons.build_rounded;
      case 'work_completed':
        return Icons.done_outline_rounded;
      case 'payment_completed':
        return Icons.payments_rounded;
      case 'closed':
        return Icons.task_alt_rounded;
      default:
        return Icons.info_outline_rounded;
    }
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

  Widget _buildStatusStepper(String currentStatus) {
    final stages = [
      {'key': 'accepted', 'label': 'Accepted'},
      {'key': 'navigating', 'label': 'Travel'},
      {'key': 'arrived', 'label': 'Arrived'},
      {'key': 'work_started', 'label': 'Working'},
      {'key': 'work_completed', 'label': 'Complete'},
      {'key': 'closed', 'label': 'Closed'},
    ];

    int currentIndex = stages.indexWhere((s) => s['key'] == currentStatus);
    if (currentStatus == 'pending') currentIndex = -1;
    if (currentStatus == 'payment_completed') currentIndex = 4; // Map to complete stage

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(stages.length, (index) {
          final isPast = index < currentIndex;
          final isCurrent = index == currentIndex;
          
          return Expanded(
            child: Row(
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isPast 
                            ? AppColors.primary 
                            : (isCurrent ? AppColors.primary : Colors.white12),
                        border: Border.all(
                          color: isCurrent ? Colors.white : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      child: Center(
                        child: isPast
                            ? const Icon(Icons.done, size: 14, color: Colors.white)
                            : Text(
                                '${index + 1}',
                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      stages[index]['label']!,
                      style: TextStyle(
                        fontSize: 8.5,
                        fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                        color: isCurrent ? Colors.white : Colors.white54,
                      ),
                    ),
                  ],
                ),
                if (index < stages.length - 1)
                  Expanded(
                    child: Container(
                      height: 2,
                      color: index < currentIndex ? AppColors.primary : Colors.white12,
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }
}
