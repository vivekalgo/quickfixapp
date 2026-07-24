import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quickfix/core/theme/app_colors.dart';
import 'package:quickfix/core/utils/haptics.dart';
import 'package:quickfix/features/home/presentation/controllers/home_providers.dart';
import 'package:quickfix/features/booking/presentation/controllers/cart_provider.dart';
import 'package:quickfix/features/booking/presentation/controllers/booking_providers.dart';

class BookingConfirmationScreen extends ConsumerWidget {
  final Map<String, dynamic>? extraData;
  const BookingConfirmationScreen({super.key, this.extraData});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(isDarkModeProvider);

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
      try { parsed = DateTime.parse(extraData!['date'].toString()); } catch (_) {}
      selectedDate = parsed ?? ref.watch(selectedDateProvider);
    } else {
      selectedDate = ref.watch(selectedDateProvider);
    }

    final String selectedSlot = extraData?['slot']?.toString() ?? ref.watch(selectedSlotProvider);

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppColors.primaryAccent.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.primaryAccent,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryAccent.withValues(alpha: 0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.check_rounded, color: Colors.white, size: 48),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Booking Confirmed!',
                style: GoogleFonts.outfit(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : AppColors.primary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Your service expert will arrive on schedule.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                ),
              ),
              const SizedBox(height: 48),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDark : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isDark ? AppColors.borderDark : AppColors.borderLight,
                  ),
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
                    _buildDetailsRow('Booking ID', '#$bookingId', isDark),
                    const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider()),
                    _buildDetailsRow(
                      'Date & Time',
                      '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}\n$selectedSlot',
                      isDark,
                      isMultiLine: true,
                    ),
                    const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider()),
                    _buildDetailsRow(
                      'Paid Amount',
                      '₹${finalPaidAmount.toInt()}',
                      isDark,
                      isHighlighted: true,
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Column(
                children: [
                  ElevatedButton(
                    onPressed: () {
                      AppHaptics.heavyTap();
                      ref.read(cartProvider.notifier).clearCart();
                      context.push('/tracking/$bookingId');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryAccent,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Track Order',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton(
                    onPressed: () {
                      AppHaptics.lightTap();
                      ref.read(cartProvider.notifier).clearCart();
                      context.go('/home');
                    },
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 56),
                      side: BorderSide(
                        color: isDark ? AppColors.borderDark : AppColors.borderLight,
                        width: 2,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      'Back to Home',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                        color: isDark ? Colors.white : AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
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
        Text(label, style: GoogleFonts.inter(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight, fontSize: 14)),
        Text(
          value,
          textAlign: TextAlign.right,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            fontSize: isHighlighted ? 18 : 14,
            color: isHighlighted
                ? AppColors.primaryAccent
                : (isDark ? Colors.white : AppColors.primary),
          ),
        ),
      ],
    );
  }
}
