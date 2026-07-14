import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:quickfix/shared/themes/app_colors.dart';
import 'package:quickfix/shared/themes/app_text_styles.dart';
import 'package:quickfix/shared/utils/haptics.dart';
import 'package:quickfix/features/home/providers/home_providers.dart';
import 'package:quickfix/features/booking/providers/cart_provider.dart';
import 'package:quickfix/features/booking/widgets/checkout_offers_sheet.dart';
import 'package:quickfix/features/booking/screens/booking_receipt_screen.dart';

class BookingConfirmationScreen extends ConsumerWidget {
  final Map<String, dynamic>? extraData;
  const BookingConfirmationScreen({super.key, this.extraData});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(isDarkModeProvider);
    
    // Extract data from extraData if available, otherwise fallback to providers/hardcoded
    final String bookingId = extraData?['bookingId']?.toString() ?? 'QF-8947265';
    
    final double? extraAmount = (extraData?['amount'] as num?)?.toDouble();
    final double finalPaidAmount;
    if (extraAmount != null) {
      finalPaidAmount = extraAmount;
    } else {
      final totalAmount = ref.watch(cartTotalAmountProvider);
      final coupon = ref.watch(appliedCouponProvider);
      double discount = 0.0;
      if (coupon == 'QUICK20') {
        discount = totalAmount * 0.20;
      } else if (coupon == 'FIRST15') {
        discount = totalAmount * 0.15;
      }
      finalPaidAmount = totalAmount - discount + (totalAmount > 0 ? 49.0 : 0.0);
    }

    final DateTime selectedDate;
    if (extraData?['date'] != null) {
      DateTime? parsed;
      try {
        parsed = DateTime.parse(extraData!['date'].toString());
      } catch (_) {}
      selectedDate = parsed ?? ref.watch(selectedDateProvider);
    } else {
      selectedDate = ref.watch(selectedDateProvider);
    }

    final String selectedSlot;
    if (extraData?['slot'] != null) {
      selectedSlot = extraData!['slot'].toString();
    } else {
      selectedSlot = ref.watch(selectedSlotProvider);
    }

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              
              // 1. Success checkmark bouncing animation
              Container(
                width: 90,
                height: 90,
                decoration: const BoxDecoration(
                  color: AppColors.success,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 56,
                ),
              ).animate()
               .scale(duration: 500.ms, curve: Curves.elasticOut)
               .then()
               .shake(duration: 400.ms),

              const SizedBox(height: 24),
              
              Text(
                'Booking Confirmed!',
                style: AppTextStyles.headingLarge(isDark).copyWith(fontSize: 26),
              ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1, end: 0),
              
              const SizedBox(height: 8),
              
              Text(
                'Your service expert will arrive on schedule.',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium(isDark),
              ).animate().fadeIn(delay: 350.ms),

              const SizedBox(height: 36),

              // 2. Summary receipt card details
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDark : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? AppColors.borderDark : AppColors.borderLight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildDetailsRow('Booking ID', '#$bookingId', isDark),
                    const Divider(height: 24),
                    _buildDetailsRow(
                      'Date & Time', 
                      '${DateFormat('dd MMM yyyy').format(selectedDate)}\n$selectedSlot', 
                      isDark,
                      isMultiLine: true,
                    ),
                    const Divider(height: 24),
                    _buildDetailsRow('Paid Amount', '₹${finalPaidAmount.toInt()}', isDark, isHighlighted: true),
                  ],
                ),
              ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.05, end: 0),

              const Spacer(),

              // 3. Actions Panel
              Column(
                children: [
                  ElevatedButton(
                    onPressed: () {
                      AppHaptics.heavyTap();
                      // Clear Cart
                      ref.read(cartProvider.notifier).clearCart();
                      context.push('/tracking/$bookingId');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Track Booking', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () {
                      AppHaptics.lightTap();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => BookingReceiptScreen(
                            bookingId: bookingId,
                            bookingData: {
                              'amount': finalPaidAmount,
                              'date': DateFormat('dd MMM yyyy').format(selectedDate),
                              'slot': selectedSlot,
                            },
                          ),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      side: const BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.receipt_long_outlined, color: AppColors.primary, size: 18),
                    label: const Text(
                      'View Payment Receipt',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.primary),
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () {
                      AppHaptics.lightTap();
                      // Clear Cart
                      ref.read(cartProvider.notifier).clearCart();
                      context.go('/home');
                    },
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      side: BorderSide(color: isDark ? Colors.white38 : AppColors.secondary),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      'Back to Home', 
                      style: TextStyle(
                        fontWeight: FontWeight.bold, 
                        fontSize: 16,
                        color: isDark ? Colors.white : AppColors.secondary,
                      ),
                    ),
                  ),
                ],
              ).animate().fadeIn(delay: 600.ms),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailsRow(String label, String value, bool isDark, {bool isHighlighted = false, bool isMultiLine = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: isMultiLine ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: AppTextStyles.bodyMedium(isDark),
        ),
        Text(
          value,
          textAlign: TextAlign.right,
          style: AppTextStyles.bodyMedium(isDark).copyWith(
            fontWeight: FontWeight.bold,
            color: isHighlighted 
                ? AppColors.primary 
                : (isDark ? Colors.white : AppColors.secondary),
          ),
        ),
      ],
    );
  }
}
