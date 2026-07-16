import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quickfix_provider/core/theme/app_colors.dart';
import 'package:quickfix_provider/features/bookings/models/booking_model.dart';
import 'package:quickfix_provider/features/bookings/presentation/controllers/bookings_provider.dart';

class QuotationDialog extends ConsumerStatefulWidget {
  final BookingModel booking;

  const QuotationDialog({super.key, required this.booking});

  @override
  ConsumerState<QuotationDialog> createState() => _QuotationDialogState();
}

class _QuotationDialogState extends ConsumerState<QuotationDialog> {
  late final TextEditingController labourController;
  late final TextEditingController sparesController;
  late final TextEditingController materialsController;
  late final TextEditingController visitingController;
  late final TextEditingController discountController;
  late final TextEditingController gstController;

  @override
  void initState() {
    super.initState();
    labourController = TextEditingController(
      text: widget.booking.quotation?['labourCharge']?.toString() ?? '0',
    );
    sparesController = TextEditingController(
      text: widget.booking.quotation?['spareParts']?.toString() ?? '0',
    );
    materialsController = TextEditingController(
      text: widget.booking.quotation?['additionalMaterials']?.toString() ?? '0',
    );
    visitingController = TextEditingController(
      text: widget.booking.visitingCharges.toStringAsFixed(0),
    );
    discountController = TextEditingController(
      text: widget.booking.quotation?['discount']?.toString() ?? '0',
    );
    gstController = TextEditingController(text: '18');
  }

  @override
  void dispose() {
    labourController.dispose();
    sparesController.dispose();
    materialsController.dispose();
    visitingController.dispose();
    discountController.dispose();
    gstController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
      title: Text(
        widget.booking.quotation != null
            ? 'Edit Quotation'
            : 'Create Quotation',
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: labourController,
              decoration: const InputDecoration(
                labelText: 'Labour Charges (₹)',
              ),
              keyboardType: TextInputType.number,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: sparesController,
              decoration: const InputDecoration(
                labelText: 'Spare Parts Charges (₹)',
              ),
              keyboardType: TextInputType.number,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: materialsController,
              decoration: const InputDecoration(
                labelText: 'Additional Materials (₹)',
              ),
              keyboardType: TextInputType.number,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: visitingController,
              decoration: const InputDecoration(
                labelText: 'Visiting Charges (₹)',
              ),
              keyboardType: TextInputType.number,
              enabled: false,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: discountController,
              decoration: const InputDecoration(labelText: 'Discount (₹)'),
              keyboardType: TextInputType.number,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: gstController,
              decoration: const InputDecoration(labelText: 'GST (%)'),
              keyboardType: TextInputType.number,
              onChanged: (_) => setState(() {}),
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total Amount:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  '₹ ${totalAmount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.success,
                    fontSize: 16,
                  ),
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
            final success = await ref
                .read(bookingsProvider.notifier)
                .uploadQuotation(
                  bookingId: widget.booking.id,
                  labourCharge: lC,
                  spareParts: sP,
                  additionalMaterials: aM,
                  visitingCharges: vC,
                  discount: disc,
                  gst: gstPct,
                );

            if (success && context.mounted) {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Quotation uploaded successfully!'),
                  backgroundColor: AppColors.success,
                ),
              );
            }
          },
          child: const Text('Submit'),
        ),
      ],
    );
  }
}
