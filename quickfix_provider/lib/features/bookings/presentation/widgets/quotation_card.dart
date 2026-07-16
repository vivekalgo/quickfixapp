import 'package:flutter/material.dart';
import 'package:quickfix_provider/core/theme/app_colors.dart';
import 'package:quickfix_provider/core/utils/currency_formatter.dart';
import 'package:quickfix_provider/features/bookings/models/booking_model.dart';
import 'package:quickfix_provider/features/bookings/presentation/widgets/quotation_dialog.dart';

class QuotationCard extends StatelessWidget {
  final BookingModel booking;
  final bool isDark;

  const QuotationCard({
    super.key,
    required this.booking,
    required this.isDark,
  });

  void _showQuotationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => QuotationDialog(booking: booking),
    );
  }

  Widget _buildSummaryRow(String label, String value, bool highlight) {
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

  @override
  Widget build(BuildContext context) {
    if (booking.pricingType != 'inspection') return const SizedBox.shrink();

    final quote = booking.quotation;
    final hasQuote = quote != null && (quote['totalAmount'] as num? ?? 0.0) > 0;

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.surfaceDark
            : (hasQuote
                  ? Colors.white
                  : Colors.amber.shade50.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: isDark
              ? AppColors.borderDark
              : (hasQuote ? AppColors.borderLight : Colors.amber.shade300),
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
            _buildSummaryRow(
              'Labour Charges',
              CurrencyFormatter.format(
                (quote['labourCharge'] as num?)?.toDouble() ?? 0.0,
              ),
              false,
            ),
            _buildSummaryRow(
              'Spare Parts',
              CurrencyFormatter.format(
                (quote['spareParts'] as num?)?.toDouble() ?? 0.0,
              ),
              false,
            ),
            _buildSummaryRow(
              'Materials',
              CurrencyFormatter.format(
                (quote['additionalMaterials'] as num?)?.toDouble() ?? 0.0,
              ),
              false,
            ),
            _buildSummaryRow(
              'Visiting Charges',
              CurrencyFormatter.format(
                (quote['visitingCharges'] as num?)?.toDouble() ?? 0.0,
              ),
              false,
            ),
            _buildSummaryRow(
              'Discount',
              '- ${CurrencyFormatter.format((quote['discount'] as num?)?.toDouble() ?? 0.0)}',
              false,
            ),
            _buildSummaryRow(
              'GST Amount',
              CurrencyFormatter.format(
                (quote['gst'] as num?)?.toDouble() ?? 0.0,
              ),
              false,
            ),
            Divider(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
            ),
            _buildSummaryRow(
              'Total Amount',
              CurrencyFormatter.format(
                (quote['totalAmount'] as num?)?.toDouble() ?? 0.0,
              ),
              true,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Quotation Status:',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
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
            if (quote['status'] == 'pending' ||
                quote['status'] == 'modified' ||
                booking.status == 'arrived') ...[
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () => _showQuotationDialog(context),
                icon: const Icon(Icons.edit, size: 16),
                label: const Text('Edit Quotation'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ] else ...[
            Text(
              'This service requires a home inspection. Please inspect the issue and submit a quotation for the customer\'s approval before starting work.',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white70 : Colors.black87,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            if (booking.status == 'arrived')
              ElevatedButton.icon(
                onPressed: () => _showQuotationDialog(context),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Create & Send Quotation'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              )
            else
              Row(
                children: [
                  const Icon(
                    Icons.lightbulb_outline,
                    size: 16,
                    color: Colors.amber,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Arrive at the location to submit the quotation.',
                      style: TextStyle(
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                        color: isDark ? Colors.white54 : Colors.black54,
                      ),
                    ),
                  ),
                ],
              ),
          ],

          // Quotation History
          if (booking.quotationHistory != null &&
              booking.quotationHistory!.isNotEmpty) ...[
            const Divider(height: 24, color: Colors.white12),
            Theme(
              data: Theme.of(
                context,
              ).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                title: const Text(
                  'Quotation Revisions',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                childrenPadding: EdgeInsets.zero,
                tilePadding: EdgeInsets.zero,
                children: booking.quotationHistory!.map((q) {
                  final idx = booking.quotationHistory!.indexOf(q) + 1;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Revision #$idx',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Labour: ₹${q['labourCharge'] ?? 0}, Spares: ₹${q['spareParts'] ?? 0}, Materials: ₹${q['additionalMaterials'] ?? 0}, Discount: -₹${q['discount'] ?? 0}, GST: ₹${q['gst'] ?? 0}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.white60,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Total: ₹${q['totalAmount'] ?? 0} (${(q['status']?.toString() ?? 'REVISED').toUpperCase()})',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                            color: Colors.white70,
                          ),
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
