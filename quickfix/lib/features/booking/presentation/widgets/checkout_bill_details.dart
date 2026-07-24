import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quickfix/core/theme/app_colors.dart';

class CheckoutBillDetails extends StatefulWidget {
  final bool isDark;
  final Map<String, dynamic>? calcData;
  final double baseAmount;
  final double discount;
  final double finalAmount;
  final bool hasInspectionService;
  final bool isFreeInspection;
  final double inspectionVisitingCharges;
  final double convenienceFee;

  const CheckoutBillDetails({
    super.key,
    required this.isDark,
    required this.calcData,
    required this.baseAmount,
    required this.discount,
    required this.finalAmount,
    required this.hasInspectionService,
    required this.isFreeInspection,
    required this.inspectionVisitingCharges,
    required this.convenienceFee,
  });

  @override
  State<CheckoutBillDetails> createState() => _CheckoutBillDetailsState();
}

class _CheckoutBillDetailsState extends State<CheckoutBillDetails> {

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: widget.isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: widget.isDark ? [] : [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: widget.isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: true,

          title: Text(
            'Bill Details',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: widget.isDark ? Colors.white : AppColors.primary,
            ),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                children: [
                  if (widget.calcData == null) ...[
                    if (widget.hasInspectionService) ...[
                      _buildLineItem('Inspection Service', 'Price after inspection'),
                      const SizedBox(height: 12),
                      _buildLineItem(
                        'Visiting Charges',
                        widget.isFreeInspection ? 'FREE' : '₹${widget.inspectionVisitingCharges.toInt()}',
                        isGreen: widget.isFreeInspection,
                      ),
                    ] else ...[
                      _buildLineItem('Items Total', '₹${widget.baseAmount.toInt()}'),
                      if (widget.discount > 0) ...[
                        const SizedBox(height: 12),
                        _buildLineItem('Coupon Discount', '- ₹${widget.discount.toInt()}', isGreen: true),
                      ],
                      const SizedBox(height: 12),
                      _buildLineItem('Convenience & Safety Fee', '₹${widget.convenienceFee.toInt()}'),
                    ],
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16.0),
                      child: Divider(),
                    ),
                    _buildTotalRow('₹${widget.finalAmount.toInt()}'),
                  ] else ...[
                    ...(widget.calcData!['billDetails'] as List<dynamic>).map((row) {
                      final label = row['label']?.toString() ?? '';
                      final val = row['value']?.toString() ?? '';
                      final isGreen = row['isGreen'] == true;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: _buildLineItem(label, val, isGreen: isGreen),
                      );
                    }),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16.0),
                      child: Divider(),
                    ),
                    _buildTotalRow('₹${(widget.calcData!['grandTotal'] as num).toInt()}'),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLineItem(String label, String value, {bool isGreen = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: widget.isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            ),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isGreen ? AppColors.success : (widget.isDark ? Colors.white : AppColors.primary),
          ),
        ),
      ],
    );
  }

  Widget _buildTotalRow(String total) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Total to Pay',
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: widget.isDark ? Colors.white : AppColors.primary,
          ),
        ),
        Text(
          total,
          style: GoogleFonts.outfit(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: widget.isDark ? Colors.white : AppColors.primary,
          ),
        ),
      ],
    );
  }
}
