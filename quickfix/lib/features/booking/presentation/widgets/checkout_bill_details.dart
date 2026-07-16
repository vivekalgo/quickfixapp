import 'package:flutter/material.dart';
import 'package:quickfix/core/theme/app_colors.dart';

class CheckoutBillDetails extends StatelessWidget {
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

  BoxDecoration _buildBoxDecoration() {
    return BoxDecoration(
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
        width: 1,
      ),
    );
  }

  Widget _buildBillRow(
    String label,
    String value, {
    bool isGreen = false,
    bool isBold = false,
  }) {
    final style = TextStyle(
      fontSize: isBold ? 16 : 13,
      fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
      color: isGreen
          ? AppColors.success
          : (isDark
                ? (isBold ? Colors.white : Colors.white70)
                : AppColors.secondary),
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(child: Text(label, style: style)),
        const SizedBox(width: 8),
        Text(value, style: style),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _buildBoxDecoration(),
      child: Column(
        children: [
          if (calcData == null) ...[
            if (hasInspectionService) ...[
              _buildBillRow(
                'Inspection Service',
                'Price after inspection',
              ),
              const SizedBox(height: 8),
              _buildBillRow(
                'Visiting Charges',
                isFreeInspection
                    ? 'FREE'
                    : '₹${inspectionVisitingCharges.toInt()}',
                isGreen: isFreeInspection,
              ),
            ] else ...[
              _buildBillRow(
                'Items Total',
                '₹${baseAmount.toInt()}',
              ),
              if (discount > 0) ...[
                const SizedBox(height: 8),
                _buildBillRow(
                  'Coupon Discount',
                  '- ₹${discount.toInt()}',
                  isGreen: true,
                ),
              ],
              const SizedBox(height: 8),
              _buildBillRow(
                'Convenience & Safety Fee',
                '₹${convenienceFee.toInt()}',
              ),
            ],
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12.0),
              child: Divider(),
            ),
            _buildBillRow(
              'Grand Total',
              '₹${finalAmount.toInt()}',
              isBold: true,
            ),
          ] else ...[
            ...(calcData!['billDetails'] as List<dynamic>).map((row) {
              final label = row['label']?.toString() ?? '';
              final val = row['value']?.toString() ?? '';
              final isGreen = row['isGreen'] == true;

              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: _buildBillRow(
                  label,
                  val,
                  isGreen: isGreen,
                ),
              );
            }),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12.0),
              child: Divider(),
            ),
            _buildBillRow(
              'Grand Total',
              '₹${(calcData!['grandTotal'] as num).toInt()}',
              isBold: true,
            ),
          ],
        ],
      ),
    );
  }
}
