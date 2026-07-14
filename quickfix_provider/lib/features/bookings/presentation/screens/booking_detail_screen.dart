import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../data/models/booking_model.dart';
import '../providers/bookings_provider.dart';
import 'package:quickfix_provider/core/widgets/error_widgets.dart';
import 'package:quickfix_provider/core/network/connectivity_provider.dart';

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

    // Auto-retry on internet reconnection if previously failed
    ref.listen<AsyncValue<bool>>(connectivityProvider, (previous, next) {
      if (next.value == true && previous?.value == false && state.errorMessage != null) {
        ref.read(bookingsProvider.notifier).fetchBookingDetails(widget.bookingId);
      }
    });

    Widget buildBody() {
      if (state.isLoading && booking == null) {
        return const Center(child: CircularProgressIndicator(color: AppColors.primary));
      }

      if (state.errorMessage != null && booking == null) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Container(
            height: MediaQuery.of(context).size.height - kToolbarHeight - MediaQuery.of(context).padding.top - 50,
            alignment: Alignment.center,
            child: CommonErrorWidget(
              message: state.errorMessage!,
              onRetry: () => ref.read(bookingsProvider.notifier).fetchBookingDetails(widget.bookingId),
            ),
          ),
        );
      }

      if (booking == null) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Container(
            height: MediaQuery.of(context).size.height - kToolbarHeight - MediaQuery.of(context).padding.top - 50,
            alignment: Alignment.center,
            child: CommonErrorWidget(
              message: 'Booking details not found.',
              onRetry: () => ref.read(bookingsProvider.notifier).fetchBookingDetails(widget.bookingId),
            ),
          ),
        );
      }

      final nextStatus = _getNextStatus(booking.status);
      final actionLabel = _getStatusActionButtonLabel(booking.status);

      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status Summary Box
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
                        Text(
                          'CURRENT STATUS',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                            color: isDark ? Colors.white60 : AppColors.textSecondaryLight,
                          ),
                        ),
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
                  color: isDark ? AppColors.surfaceDark : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                  border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.lock_rounded,
                      color: isDark ? Colors.white.withValues(alpha: 0.3) : Colors.black.withValues(alpha: 0.2),
                      size: 36,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Contact Info Restricted',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: isDark ? Colors.white : AppColors.secondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Accept the booking to reveal customer name, verified phone number, exact address, and maps navigation support.',
                            style: TextStyle(
                              color: isDark ? Colors.white70 : AppColors.textSecondaryLight,
                              fontSize: 11.5,
                              height: 1.4,
                            ),
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
                  color: isDark ? AppColors.surfaceDark : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
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
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: isDark ? Colors.white : AppColors.secondary,
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              onPressed: () => _makeCall(booking.customerPhone),
                              icon: const Icon(Icons.phone, color: AppColors.success),
                              style: IconButton.styleFrom(
                                backgroundColor: AppColors.success.withValues(alpha: 0.15),
                                shape: const CircleBorder(),
                              ),
                            ),
                            if (booking.customerLat != null && booking.customerLng != null) ...[
                              const SizedBox(width: 8),
                              IconButton(
                                onPressed: () => _launchMaps(booking.customerLat!, booking.customerLng!),
                                icon: const Icon(Icons.navigation_rounded, color: AppColors.primary),
                                style: IconButton.styleFrom(
                                  backgroundColor: AppColors.primary.withValues(alpha: 0.15),
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
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12.0),
                      child: Divider(color: isDark ? AppColors.borderDark : AppColors.borderLight, height: 1),
                    ),
                    
                    Text(
                      'VERIFIED ADDRESS',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                        color: isDark ? Colors.white60 : AppColors.textSecondaryLight,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      booking.customerAddress,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.4,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white : AppColors.secondary,
                      ),
                    ),
                    if (booking.customerLat != null && booking.customerLng != null) ...[
                      const SizedBox(height: 12),
                      InkWell(
                        onTap: () => _launchMaps(booking.customerLat!, booking.customerLng!),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.map_rounded, color: AppColors.primary, size: 18),
                              SizedBox(width: 8),
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
                color: isDark ? AppColors.surfaceDark : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
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
                  Divider(height: 24, color: isDark ? AppColors.borderDark : AppColors.borderLight),
                  _buildSummaryRow('Visiting Charges', CurrencyFormatter.format(booking.visitingCharges), false),
                  _buildSummaryRow('Booking Amount', CurrencyFormatter.format(booking.amount), false),
                  _buildSummaryRow('Estimated Earnings', CurrencyFormatter.format(booking.estEarnings), true),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Quotation Form / Details
            _buildQuotationCard(booking, isDark),
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
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Action Status Stepper Button
            if (nextStatus.isNotEmpty && actionLabel.isNotEmpty && !(booking.pricingType == 'inspection' && (booking.status == 'arrived' || booking.status == 'quote_sent'))) ...[
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
      );
    }

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(booking?.id ?? 'Order Details'),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          await ref.read(bookingsProvider.notifier).fetchBookingDetails(widget.bookingId);
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
              color: highlight ? AppColors.success : (isDark ? Colors.white : AppColors.secondary),
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
      case 'quote_sent':
        return Icons.pending_actions_rounded;
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
      case 'quote_sent':
        return Colors.orangeAccent;
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

    final isDark = Theme.of(context).brightness == Brightness.dark;
    int currentIndex = stages.indexWhere((s) => s['key'] == currentStatus);
    if (currentStatus == 'pending') currentIndex = -1;
    if (currentStatus == 'quote_sent') currentIndex = 2; // Map to arrived stage
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
                            : (isCurrent ? AppColors.primary : (isDark ? Colors.white12 : Colors.grey.shade200)),
                        border: Border.all(
                          color: isCurrent ? (isDark ? Colors.white : AppColors.secondary) : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      child: Center(
                        child: isPast
                            ? const Icon(Icons.done, size: 14, color: Colors.white)
                            : Text(
                                '${index + 1}',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: isCurrent ? Colors.white : (isDark ? Colors.white70 : AppColors.textSecondaryLight),
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      stages[index]['label']!,
                      style: TextStyle(
                        fontSize: 8.5,
                        fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                        color: isCurrent 
                            ? (isDark ? Colors.white : AppColors.secondary) 
                            : (isDark ? Colors.white54 : AppColors.textSecondaryLight),
                      ),
                    ),
                  ],
                ),
                if (index < stages.length - 1)
                  Expanded(
                    child: Container(
                      height: 2,
                      color: index < currentIndex ? AppColors.primary : (isDark ? Colors.white12 : Colors.grey.shade200),
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  void _showQuotationDialog(BookingModel booking) {
    final labourController = TextEditingController(text: booking.quotation?['labourCharge']?.toString() ?? '0');
    final sparesController = TextEditingController(text: booking.quotation?['spareParts']?.toString() ?? '0');
    final materialsController = TextEditingController(text: booking.quotation?['additionalMaterials']?.toString() ?? '0');
    final visitingController = TextEditingController(text: booking.visitingCharges.toStringAsFixed(0));
    final discountController = TextEditingController(text: booking.quotation?['discount']?.toString() ?? '0');
    final gstController = TextEditingController(text: '18');

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final lC = double.tryParse(labourController.text) ?? 0.0;
          final sP = double.tryParse(sparesController.text) ?? 0.0;
          final aM = double.tryParse(materialsController.text) ?? 0.0;
          final vC = double.tryParse(visitingController.text) ?? 0.0;
          final disc = double.tryParse(discountController.text) ?? 0.0;
          final gstPct = double.tryParse(gstController.text) ?? 0.0;

          final subtotal = lC + sP + aM + vC - disc;
          final gstAmt = subtotal * (gstPct / 100);
          final totalAmount = subtotal + gstAmt;

          return AlertDialog(
            title: Text(booking.quotation != null ? 'Edit Quotation' : 'Create Quotation'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: labourController,
                    decoration: const InputDecoration(labelText: 'Labour Charges (₹)'),
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setDialogState(() {}),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: sparesController,
                    decoration: const InputDecoration(labelText: 'Spare Parts Charges (₹)'),
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setDialogState(() {}),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: materialsController,
                    decoration: const InputDecoration(labelText: 'Additional Materials (₹)'),
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setDialogState(() {}),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: visitingController,
                    decoration: const InputDecoration(labelText: 'Visiting Charges (₹)'),
                    keyboardType: TextInputType.number,
                    enabled: false,
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: discountController,
                    decoration: const InputDecoration(labelText: 'Discount (₹)'),
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setDialogState(() {}),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: gstController,
                    decoration: const InputDecoration(labelText: 'GST (%)'),
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setDialogState(() {}),
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Amount:', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(
                        '₹ ${totalAmount.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.success, fontSize: 16),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final success = await ref.read(bookingsProvider.notifier).uploadQuotation(
                    bookingId: booking.id,
                    labourCharge: lC,
                    spareParts: sP,
                    additionalMaterials: aM,
                    visitingCharges: vC,
                    discount: disc,
                    gst: gstPct,
                  );

                  if (success && mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Quotation uploaded successfully!'), backgroundColor: AppColors.success),
                    );
                  }
                },
                child: const Text('Submit'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildQuotationCard(BookingModel booking, bool isDark) {
    if (booking.pricingType != 'inspection') return const SizedBox.shrink();

    final quote = booking.quotation;
    final hasQuote = quote != null && (quote['totalAmount'] as num? ?? 0.0) > 0;

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : (hasQuote ? Colors.white : Colors.amber.shade50.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: isDark ? AppColors.borderDark : (hasQuote ? AppColors.borderLight : Colors.amber.shade300),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                hasQuote ? Icons.receipt_long : Icons.warning_amber_rounded,
                color: hasQuote ? AppColors.primary : Colors.amber.shade700,
              ),
              const SizedBox(width: 8),
              Text(
                hasQuote ? 'Quotation Details' : 'Quotation Required',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: isDark ? Colors.white : AppColors.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (hasQuote) ...[
            _buildSummaryRow('Labour Charges', CurrencyFormatter.format((quote['labourCharge'] as num?)?.toDouble() ?? 0.0), false),
            _buildSummaryRow('Spare Parts', CurrencyFormatter.format((quote['spareParts'] as num?)?.toDouble() ?? 0.0), false),
            _buildSummaryRow('Materials', CurrencyFormatter.format((quote['additionalMaterials'] as num?)?.toDouble() ?? 0.0), false),
            _buildSummaryRow('Visiting Charges', CurrencyFormatter.format((quote['visitingCharges'] as num?)?.toDouble() ?? 0.0), false),
            _buildSummaryRow('Discount', '- ${CurrencyFormatter.format((quote['discount'] as num?)?.toDouble() ?? 0.0)}', false),
            _buildSummaryRow('GST Amount', CurrencyFormatter.format((quote['gst'] as num?)?.toDouble() ?? 0.0), false),
            Divider(color: isDark ? AppColors.borderDark : AppColors.borderLight),
            _buildSummaryRow(
              'Total Amount',
              CurrencyFormatter.format((quote['totalAmount'] as num?)?.toDouble() ?? 0.0),
              true,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Quotation Status:',
                  style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : Colors.black54),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: quote['status'] == 'accepted'
                        ? Colors.green.withValues(alpha: 0.2)
                        : quote['status'] == 'rejected'
                            ? Colors.red.withValues(alpha: 0.2)
                            : Colors.orange.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    (quote['status']?.toString() ?? 'PENDING').toUpperCase(),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                      color: quote['status'] == 'accepted'
                          ? Colors.green
                          : quote['status'] == 'rejected'
                              ? Colors.red
                              : Colors.orange,
                    ),
                  ),
                ),
              ],
            ),
            if (quote['status'] == 'pending' || quote['status'] == 'modified' || booking.status == 'arrived') ...[
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () => _showQuotationDialog(booking),
                icon: const Icon(Icons.edit, size: 16),
                label: const Text('Edit Quotation'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ] else ...[
            Text(
              'This service requires a home inspection. Please inspect the issue and submit a quotation for the customer\'s approval before starting work.',
              style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : Colors.black87, height: 1.4),
            ),
            const SizedBox(height: 12),
            if (booking.status == 'arrived')
              ElevatedButton.icon(
                onPressed: () => _showQuotationDialog(booking),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Create & Send Quotation'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              )
            else
              Row(
                children: [
                  const Icon(Icons.lightbulb_outline, size: 16, color: Colors.amber),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Arrive at the location to submit the quotation.',
                      style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: isDark ? Colors.white54 : Colors.black54),
                    ),
                  ),
                ],
              ),
          ],

          // Quotation History
          if (booking.quotationHistory != null && booking.quotationHistory!.isNotEmpty) ...[
            const Divider(height: 24, color: Colors.white12),
            Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                title: const Text('Quotation Revisions', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                childrenPadding: EdgeInsets.zero,
                tilePadding: EdgeInsets.zero,
                children: booking.quotationHistory!.map((q) {
                  final idx = booking.quotationHistory!.indexOf(q) + 1;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Revision #$idx', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                        const SizedBox(height: 4),
                        Text(
                          'Labour: ₹${q['labourCharge'] ?? 0}, Spares: ₹${q['spareParts'] ?? 0}, Materials: ₹${q['additionalMaterials'] ?? 0}, Discount: -₹${q['discount'] ?? 0}, GST: ₹${q['gst'] ?? 0}',
                          style: const TextStyle(fontSize: 11, color: Colors.white60),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Total: ₹${q['totalAmount'] ?? 0} (${(q['status']?.toString() ?? 'REVISED').toUpperCase()})', 
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.white70)
                        ),
                        const Divider(height: 16, color: Colors.white12),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
