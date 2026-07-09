import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/haptics.dart';
import '../../../../features/home/presentation/providers/home_providers.dart';

import '../../../auth/presentation/providers/auth_providers.dart';

class WalletTransaction {
  final String title;
  final DateTime date;
  final double amount;
  final bool isCredit;

  const WalletTransaction({
    required this.title,
    required this.date,
    required this.amount,
    required this.isCredit,
  });
}

class WalletScreen extends ConsumerStatefulWidget {
  const WalletScreen({super.key});

  @override
  ConsumerState<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends ConsumerState<WalletScreen> {
  void _addMoney(double amt) {
    AppHaptics.heavyTap();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        Future(() async {
          try {
            await ref.read(authProvider.notifier).addMoney(amt);
            if (mounted) {
              AppHaptics.successNotification();
              Navigator.pop(context); // Close UPI dialog
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Successfully added ₹${amt.toInt()} to wallet!'),
                  backgroundColor: AppColors.success,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          } catch (e) {
            if (mounted) {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('UPI simulation failed: $e')),
              );
            }
          }
        });
        
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: ref.read(isDarkModeProvider) ? AppColors.surfaceDark : Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(28.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(AppColors.primary)),
                const SizedBox(height: 20),
                Text('Connecting to UPI Gateway...', style: AppTextStyles.bodyMedium(ref.read(isDarkModeProvider)).copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(isDarkModeProvider);
    final authState = ref.watch(authProvider);
    final user = authState.user;

    final balance = (user?['walletBalance'] ?? 0.0) as num;
    final transactionsList = user?['walletTransactions'] as List<dynamic>? ?? [];

    final transactions = transactionsList.map((item) {
      final title = item['title']?.toString() ?? 'Wallet Transaction';
      final amount = (item['amount'] ?? 0.0) as num;
      final isCredit = item['type'] == 'credit';
      final dateStr = item['date']?.toString();
      final date = dateStr != null ? DateTime.parse(dateStr) : DateTime.now();
      return WalletTransaction(
        title: title,
        date: date,
        amount: amount.toDouble(),
        isCredit: isCredit,
      );
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('QuickFix Wallet', style: AppTextStyles.headingMedium(isDark)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            AppHaptics.lightTap();
            if (context.canPop()) {
              context.pop();
            } else {
              ref.read(currentNavIndexProvider.notifier).state = 0;
              context.go('/home');
            }
          },
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Balance visual card layout
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: AppColors.plusGradient,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.secondary.withOpacity(0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'AVAILABLE BALANCE',
                    style: TextStyle(color: Colors.white60, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.0),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '₹${balance.toInt()}.00',
                    style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: const [
                      Icon(Icons.shield_outlined, color: AppColors.accent, size: 16),
                      SizedBox(width: 6),
                      Text(
                        '100% Secure Payments • Quick Refunds',
                        style: TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ),
            ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),

            const SizedBox(height: 28),

            // 2. Add money action section
            Text('Add Money to Wallet', style: AppTextStyles.headingSmall(isDark)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [500.0, 1000.0, 2000.0].map((amount) {
                return Expanded(
                  child: GestureDetector(
                    onTap: () => _addMoney(amount),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.surfaceDark : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                      ),
                      child: Center(
                        child: Text(
                          '+ ₹${amount.toInt()}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : AppColors.secondary,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 32),

            // 3. Transactions lists
            Text('Transaction History', style: AppTextStyles.headingSmall(isDark)),
            const SizedBox(height: 12),
            transactions.isEmpty
                ? Center(child: Text('No transaction logs found', style: AppTextStyles.bodyMedium(isDark)))
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: transactions.length,
                    itemBuilder: (context, index) {
                      final tx = transactions[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.surfaceDark : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: tx.isCredit ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    tx.isCredit ? Icons.arrow_upward : Icons.arrow_downward,
                                    color: tx.isCredit ? AppColors.success : AppColors.error,
                                    size: 16,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(tx.title, style: AppTextStyles.bodyMedium(isDark).copyWith(fontWeight: FontWeight.bold)),
                                    Text(DateFormat('dd MMM yyyy, hh:mm a').format(tx.date), style: AppTextStyles.bodySmall(isDark)),
                                  ],
                                ),
                              ],
                            ),
                            Text(
                               '${tx.isCredit ? "+" : "-"} ₹${tx.amount.toInt()}',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: tx.isCredit ? AppColors.success : AppColors.error,
                              ),
                            ),
                          ],
                        ),
                      ).animate(delay: (50 * index).ms).fadeIn().slideY(begin: 0.05, end: 0);
                    },
                  ),
          ],
        ),
      ),
    );
  }
}
