import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quickfix_provider/core/theme/app_colors.dart';
import 'package:quickfix_provider/core/utils/currency_formatter.dart';
import 'package:quickfix_provider/features/shop/presentation/controllers/payments_provider.dart';

class WithdrawalDialog extends StatefulWidget {
  final double maxAmount;
  final WidgetRef ref;

  const WithdrawalDialog({super.key, required this.maxAmount, required this.ref});

  @override
  State<WithdrawalDialog> createState() => _WithdrawalDialogState();
}

class _WithdrawalDialogState extends State<WithdrawalDialog> {
  late final TextEditingController controller;
  final formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    controller = TextEditingController();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Request Payout Settlement'),
      content: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.3),
                ),
              ),
              child: const Text(
                'Funds will be transferred to your registered bank account/UPI ID within 24–48 hours after admin approval.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white70,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText:
                    'Amount (Max ${CurrencyFormatter.format(widget.maxAmount)})',
                prefixText: '₹ ',
                filled: true,
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) return 'Required';
                final numVal = double.tryParse(val);
                if (numVal == null) return 'Enter valid amount';
                if (numVal <= 0) return 'Must be greater than 0';
                if (numVal > widget.maxAmount) {
                  return 'Exceeds available wallet balance';
                }
                return null;
              },
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
            if (!formKey.currentState!.validate()) return;
            final success = await widget.ref
                .read(paymentsProvider.notifier)
                .requestSettlementWithdrawal(double.parse(controller.text));
            if (success && context.mounted) {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    '✅ Settlement request submitted! Admin will review and transfer within 24–48 hrs.',
                  ),
                  backgroundColor: AppColors.success,
                  duration: Duration(seconds: 4),
                ),
              );
            }
          },
          child: const Text('Confirm Settlement'),
        ),
      ],
    );
  }
}
