import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quickfix/core/theme/app_colors.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:quickfix/features/booking/presentation/controllers/booking_providers.dart';

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
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: Text('Receipt', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined, size: 22),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.download_outlined, size: 22),
            onPressed: () {},
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

  Widget _buildFullReceipt(BuildContext context, Map<String, dynamic> ledger, bool isDark) {

    final gateway = (ledger['gatewayCharges'] as num?)?.toDouble() ?? 0.0;
    final payMethod = ledger['paymentMethod']?.toString() ?? 'cash';
    final serviceTitle = ledger['serviceTitle']?.toString() ?? 'Service';
    final createdAt = ledger['createdAt'] != null ? DateTime.tryParse(ledger['createdAt'].toString()) : null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
              boxShadow: isDark ? [] : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.flash_on_rounded, color: AppColors.primaryAccent, size: 32),
                          const SizedBox(width: 8),
                          Text('QuickFix', style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.w900, color: isDark ? Colors.white : AppColors.primary)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('RECEIPT', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 2, color: AppColors.textSecondaryLight)),
                      const SizedBox(height: 24),
                      Text(serviceTitle, style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w600, color: isDark ? Colors.white : AppColors.primary), textAlign: TextAlign.center),
                      if (createdAt != null) ...[
                        const SizedBox(height: 4),
                        Text(DateFormat('dd MMM yyyy, hh:mm a').format(createdAt.toLocal()), style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondaryLight)),
                      ],
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      _receiptRow('Booking ID', '#', isDark, mono: true),
                      _receiptRow('Payment Method', _methodLabel(payMethod), isDark),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: _DashedDivider(),
                      ),
                      _receiptRow('Service Amount', '₹', isDark),
                      if (gateway > 0)
                        _receiptRow('Gateway Charges', '+ ₹', isDark, valueColor: Colors.orange),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: _DashedDivider(),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Total Paid', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w700, color: isDark ? Colors.white : AppColors.primary)),
                          Text('₹', style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w800, color: isDark ? Colors.white : AppColors.primary)),
                        ],
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05, end: 0),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.download_rounded),
                  label: Text('Download', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.share_rounded),
                  label: Text('Share', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildBasicReceipt(BuildContext context, bool isDark) {
    final amount = (bookingData?['amount'] as num?)?.toDouble();
    final date = bookingData?['date']?.toString();
    final slot = bookingData?['slot']?.toString();
    final title = bookingData?['title']?.toString() ?? 'Service Booking';
    final payMethod = bookingData?['paymentMethod']?.toString() ?? 'Cash';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
              boxShadow: isDark ? [] : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.flash_on_rounded, color: AppColors.primaryAccent, size: 32),
                          const SizedBox(width: 8),
                          Text('QuickFix', style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.w900, color: isDark ? Colors.white : AppColors.primary)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('RECEIPT', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 2, color: AppColors.textSecondaryLight)),
                      const SizedBox(height: 24),
                      Text(title, style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w600, color: isDark ? Colors.white : AppColors.primary), textAlign: TextAlign.center),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      _receiptRow('Booking ID', '#', isDark, mono: true),
                      if (date != null) _receiptRow('Date', date, isDark),
                      if (slot != null) _receiptRow('Time Slot', slot, isDark),
                      _receiptRow('Payment Method', _methodLabel(payMethod), isDark),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: _DashedDivider(),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Total Paid', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w700, color: isDark ? Colors.white : AppColors.primary)),
                          Text(amount != null ? '₹' : 'See Details', style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w800, color: isDark ? Colors.white : AppColors.primary)),
                        ],
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05, end: 0),
        ],
      ),
    );
  }

  Widget _receiptRow(String label, String value, bool isDark, {bool mono = false, Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.inter(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight, fontSize: 14)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: valueColor ?? (isDark ? Colors.white : AppColors.primary),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _methodLabel(String method) {
    if (method.toLowerCase().contains('cash')) return 'Cash';
    if (method.toLowerCase().contains('online')) return 'Online Payment';
    return method;
  }
}

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
              color: AppColors.borderLight,
            ),
          ),
        );
      },
    );
  }
}
