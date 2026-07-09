import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/haptics.dart';
import '../../../../features/home/presentation/providers/home_providers.dart';
import '../providers/cart_provider.dart';
import 'booking_checkout_screen.dart';

class BookingConfirmationScreen extends ConsumerWidget {
  const BookingConfirmationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(isDarkModeProvider);
    final totalAmount = ref.watch(cartTotalAmountProvider);
    
    final selectedDate = ref.watch(selectedDateProvider);
    final selectedSlot = ref.watch(selectedSlotProvider);

    final coupon = ref.watch(appliedCouponProvider);
    double discount = 0.0;
    if (coupon == 'QUICK20') {
      discount = totalAmount * 0.20;
    } else if (coupon == 'FIRST15') {
      discount = totalAmount * 0.15;
    }
    
    final finalPaidAmount = totalAmount - discount + (totalAmount > 0 ? 49.0 : 0.0);

    // Random Booking ID simulation
    const String bookingId = 'QF-8947265';

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
                      color: Colors.black.withOpacity(0.02),
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
