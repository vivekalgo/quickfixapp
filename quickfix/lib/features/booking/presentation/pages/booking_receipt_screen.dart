import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quickfix/core/theme/app_colors.dart';
import 'package:quickfix/core/theme/app_text_styles.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:quickfix/features/booking/presentation/controllers/booking_providers.dart';

// ─── Screen ──────────────────────────────────────────────────────────────────

class BookingReceiptScreen extends ConsumerWidget {
  final String bookingId;
  final Map<String, dynamic>? bookingData;

  const BookingReceiptScreen({
    super.key,
    required this.bookingId,
    this.bookingData,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final receiptAsync = ref.watch(bookingReceiptProvider(bookingId));

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Payment Receipt'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.copy_outlined, size: 20),
            tooltip: 'Copy Booking ID',
            onPressed: () {
              Clipboard.setData(ClipboardData(text: bookingId));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Booking ID copied!'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
        ],
      ),
      body: receiptAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => _buildBasicReceipt(context, isDark),
        data: (ledger) => ledger != null
            ? _buildFullReceipt(context, ledger, isDark)
            : _buildBasicReceipt(context, isDark),
      ),
    );
  }

  // ─── Full Receipt (from ledger API) ────────────────────────────────────────

  Widget _buildFullReceipt(
    BuildContext context,
    Map<String, dynamic> ledger,
    bool isDark,
  ) {
    final gross = (ledger['grossAmount'] as num?)?.toDouble() ?? 0.0;
    final commission = (ledger['commissionAmount'] as num?)?.toDouble() ?? 0.0;
    final commRate = (ledger['commissionRate'] as num?)?.toDouble() ?? 20.0;
    final gateway = (ledger['gatewayCharges'] as num?)?.toDouble() ?? 0.0;
    final payMethod = ledger['paymentMethod']?.toString() ?? 'cash';
    final payStatus = ledger['paymentStatus']?.toString() ?? 'pending';
    final serviceTitle = ledger['serviceTitle']?.toString() ?? 'Service';
    final providerName = ledger['providerName']?.toString() ?? '—';
    final createdAt = ledger['createdAt'] != null
        ? DateTime.tryParse(ledger['createdAt'].toString())
        : null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Receipt card
          Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: AppColors.plusGradient,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.receipt_long,
                        color: Colors.white,
                        size: 36,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'PAYMENT RECEIPT',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        serviceTitle,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (createdAt != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          DateFormat(
                            'dd MMM yyyy, hh:mm a',
                          ).format(createdAt.toLocal()),
                          style: const TextStyle(
                            color: Colors.white60,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Receipt body
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      _receiptRow(
                        'Booking ID',
                        '#$bookingId',
                        isDark,
                        mono: true,
                      ),
                      _receiptRow('Service Provider', providerName, isDark),
                      _receiptRow(
                        'Payment Method',
                        _methodLabel(payMethod),
                        isDark,
                      ),
                      _receiptRow(
                        'Status',
                        _statusLabel(payStatus),
                        isDark,
                        statusColor: _statusColor(payStatus),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: _DashedDivider(),
                      ),

                      // Pricing breakdown
                      _receiptRow(
                        'Service Amount',
                        '₹${gross.toStringAsFixed(2)}',
                        isDark,
                      ),
                      if (gateway > 0)
                        _receiptRow(
                          'Gateway Charges',
                          '+ ₹${gateway.toStringAsFixed(2)}',
                          isDark,
                          valueColor: Colors.orange,
                        ),

                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: _DashedDivider(),
                      ),

                      // Total
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total Paid',
                            style: AppTextStyles.headingSmall(
                              isDark,
                            ).copyWith(fontSize: 15),
                          ),
                          Text(
                            '₹${gross.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                              fontFamily: 'Outfit',
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Platform transparency note
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.15),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.info_outline,
                              color: AppColors.primary,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'QuickFix collects ${commRate.toStringAsFixed(0)}% (₹${commission.toStringAsFixed(2)}) as platform commission. Your service provider receives the rest.',
                                style: TextStyle(
                                  color: isDark
                                      ? Colors.white60
                                      : AppColors.textSecondaryLight,
                                  fontSize: 11,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Footer stamp
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.03)
                        : Colors.grey.shade50,
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(20),
                    ),
                    border: Border(
                      top: BorderSide(
                        color: isDark
                            ? AppColors.borderDark
                            : AppColors.borderLight,
                      ),
                    ),
                  ),
                  child: const Center(
                    child: Text(
                      '⚡ QuickFix — Powering Your Home Services',
                      style: TextStyle(color: Colors.grey, fontSize: 11),
                    ),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05, end: 0),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // ─── Basic Receipt (fallback) ───────────────────────────────────────────────

  Widget _buildBasicReceipt(BuildContext context, bool isDark) {
    final amount = (bookingData?['amount'] as num?)?.toDouble();
    final date = bookingData?['date']?.toString();
    final slot = bookingData?['slot']?.toString();
    final title = bookingData?['title']?.toString() ?? 'Service Booking';
    final payMethod = bookingData?['paymentMethod']?.toString() ?? 'Cash';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppColors.plusGradient,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              child: Column(
                children: [
                  const Icon(Icons.receipt_long, color: Colors.white, size: 36),
                  const SizedBox(height: 8),
                  const Text(
                    'BOOKING RECEIPT',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _receiptRow('Booking ID', '#$bookingId', isDark, mono: true),
                  if (date != null) _receiptRow('Date', date, isDark),
                  if (slot != null) _receiptRow('Time Slot', slot, isDark),
                  _receiptRow('Payment Method', payMethod, isDark),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: _DashedDivider(),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Amount Paid',
                        style: AppTextStyles.headingSmall(isDark),
                      ),
                      Text(
                        amount != null
                            ? '₹${amount.toStringAsFixed(2)}'
                            : 'See Booking Details',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.03)
                    : Colors.grey.shade50,
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(20),
                ),
                border: Border(
                  top: BorderSide(
                    color: isDark
                        ? AppColors.borderDark
                        : AppColors.borderLight,
                  ),
                ),
              ),
              child: const Center(
                child: Text(
                  '⚡ QuickFix — Powering Your Home Services',
                  style: TextStyle(color: Colors.grey, fontSize: 11),
                ),
              ),
            ),
          ],
        ),
      ).animate().fadeIn(duration: 400.ms),
    );
  }

  // ─── Helpers ───────────────────────────────────────────────────────────────

  Widget _receiptRow(
    String label,
    String value,
    bool isDark, {
    bool mono = false,
    Color? valueColor,
    Color? statusColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isDark ? Colors.white54 : Colors.grey.shade600,
              fontSize: 13,
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color:
                    statusColor ??
                    valueColor ??
                    (isDark ? Colors.white : AppColors.secondary),
                fontFamily: mono ? 'monospace' : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _methodLabel(String method) {
    const map = {
      'cash': '💵 Cash on Service',
      'online': '💳 Online Payment',
      'wallet': '👛 Wallet',
      'upi': '📱 UPI',
      'card': '💳 Card',
      'netbanking': '🏦 Net Banking',
    };
    return map[method] ?? method.toUpperCase();
  }

  String _statusLabel(String status) {
    const map = {
      'cash_pending': 'Cash — Pending Completion',
      'cash_collected': '✅ Cash Collected',
      'paid': '✅ Payment Confirmed',
      'settlement_pending': '✅ Paid — Processing',
      'settled': '✅ Completed',
      'pending': 'Pending',
      'failed': '❌ Failed',
    };
    return map[status] ?? status.toUpperCase();
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'paid':
      case 'cash_collected':
      case 'settled':
      case 'settlement_pending':
        return AppColors.success;
      case 'cash_pending':
      case 'pending':
        return Colors.orange;
      case 'failed':
        return Colors.red;
      default:
        return AppColors.primary;
    }
  }
}

// ─── Dashed Divider ────────────────────────────────────────────────────────

class _DashedDivider extends StatelessWidget {
  const _DashedDivider();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const dashWidth = 6.0;
        const dashGap = 4.0;
        final count = (constraints.maxWidth / (dashWidth + dashGap)).floor();
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(
            count,
            (_) => Container(
              width: dashWidth,
              height: 1,
              color: Colors.grey.withValues(alpha: 0.4),
            ),
          ),
        );
      },
    );
  }
}
