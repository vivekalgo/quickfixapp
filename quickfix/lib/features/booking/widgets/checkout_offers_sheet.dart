import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quickfix/shared/themes/app_colors.dart';
import 'package:quickfix/shared/utils/haptics.dart';
import 'package:quickfix/core/services/dio_client.dart';
import 'package:quickfix/core/providers/network_providers.dart';
import 'package:quickfix/features/home/providers/home_providers.dart';
import 'package:quickfix/features/booking/providers/cart_provider.dart';

final selectedDateProvider = StateProvider<DateTime>((ref) => DateTime.now().add(const Duration(days: 1)));
final selectedSlotProvider = StateProvider<String>((ref) => '09:00 AM - 11:00 AM');
final selectedAddressIndexProvider = StateProvider<int>((ref) => 0);
final appliedCouponProvider = StateProvider<String?>((ref) => null);
final appliedCouponDiscountProvider = StateProvider<double>((ref) => 0.0);
final selectedPaymentMethodProvider = StateProvider<String>((ref) => 'Razorpay');

final checkoutCalculationProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final cart = ref.watch(cartProvider);
  final couponCode = ref.watch(appliedCouponProvider);
  final shopId = ref.watch(cartShopIdProvider);

  if (shopId == null || cart.isEmpty) {
    return null;
  }

  final itemsList = cart.values.map((item) => {
    'id': item.id,
    'quantity': item.quantity,
  }).toList();

  try {
    final client = ref.watch(dioClientProvider);
    final res = await client.post('/checkout/calculate', data: {
      'shopId': shopId,
      'items': itemsList,
      'couponCode': couponCode,
    });
    if (res.statusCode == 200 && res.data != null && res.data['success'] == true) {
      final double discount = (res.data['couponDiscount'] as num?)?.toDouble() ?? 0.0;
      Future.microtask(() {
        ref.read(appliedCouponDiscountProvider.notifier).state = discount;
      });
      return Map<String, dynamic>.from(res.data as Map);
    }
  } catch (e) {
    debugPrint('Error calculating checkout price: $e');
  }
  return null;
});

final activeOffersProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  try {
    final client = ref.watch(dioClientProvider);
    final res = await client.get('/offers');
    final data = res.data as List;
    return data
        .map((e) => Map<String, dynamic>.from(e as Map))
        .where((o) => o['isActive'] == true)
        .toList();
  } catch (_) {
    return [];
  }
});

const List<Color> _couponPalette = [
  AppColors.primary,
  AppColors.success,
  Color(0xFF7C3AED),
  AppColors.accent,
  Color(0xFF0EA5E9),
  Colors.teal,
];

class OffersAndCouponsPanel extends ConsumerWidget {
  final bool isDark;
  final String? appliedCoupon;
  final double discount;
  final double baseAmount;
  final bool hasInspectionService;

  const OffersAndCouponsPanel({
    super.key,
    required this.isDark,
    required this.appliedCoupon,
    required this.discount,
    required this.baseAmount,
    required this.hasInspectionService,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offersAsync = ref.watch(activeOffersProvider);

    return offersAsync.when(
      loading: () => _buildShimmer(isDark),
      error: (_, __) => _buildPanel(context, ref, [], isDark),
      data: (offers) => _buildPanel(context, ref, offers, isDark),
    );
  }

  Widget _buildPanel(
    BuildContext context,
    WidgetRef ref,
    List<Map<String, dynamic>> offers,
    bool isDark,
  ) {
    final activeCount = offers.length;

    return GestureDetector(
      onTap: hasInspectionService
          ? null
          : () {
              AppHaptics.selectionClick();
              _showOffersSheet(context, ref, offers, isDark);
            },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: appliedCoupon != null
                ? AppColors.success
                : (isDark ? AppColors.borderDark : AppColors.borderLight),
            width: appliedCoupon != null ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: appliedCoupon != null
                        ? AppColors.success.withOpacity(0.12)
                        : AppColors.primary.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    appliedCoupon != null
                        ? Icons.check_circle_rounded
                        : Icons.local_offer_rounded,
                    color: appliedCoupon != null
                        ? AppColors.success
                        : AppColors.primary,
                    size: 22,
                  ),
                ),
                if (activeCount > 0 && appliedCoupon == null)
                  Positioned(
                    top: -4,
                    right: -4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$activeCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    appliedCoupon != null
                        ? 'Coupon Applied — $appliedCoupon'
                        : (activeCount > 0
                            ? '$activeCount offer${activeCount > 1 ? 's' : ''} available'
                            : 'No offers available'),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: appliedCoupon != null
                          ? AppColors.success
                          : (isDark ? Colors.white : AppColors.secondary),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    appliedCoupon != null
                        ? 'You saved ₹${discount.toInt()} on this order!'
                        : (hasInspectionService
                            ? 'Coupons not applicable for inspection services'
                            : 'Tap to browse & apply offers'),
                    style: TextStyle(
                      fontSize: 12,
                      color: appliedCoupon != null
                          ? AppColors.success
                          : AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ),
            if (appliedCoupon != null)
              GestureDetector(
                onTap: () {
                  AppHaptics.lightTap();
                  ref.read(appliedCouponProvider.notifier).state = null;
                  ref.read(appliedCouponDiscountProvider.notifier).state = 0.0;
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Remove',
                    style: TextStyle(
                      color: AppColors.error,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              )
            else if (!hasInspectionService)
              Icon(
                Icons.chevron_right_rounded,
                color: isDark ? Colors.white38 : AppColors.textSecondaryLight,
              ),
          ],
        ),
      ),
    );
  }

  void _showOffersSheet(
    BuildContext context,
    WidgetRef ref,
    List<Map<String, dynamic>> offers,
    bool isDark,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => _OffersBottomSheet(
        offers: offers,
        isDark: isDark,
        baseAmount: baseAmount,
        appliedCoupon: appliedCoupon,
        onApply: (code, discountAmt) {
          ref.read(appliedCouponProvider.notifier).state = code;
          ref.read(appliedCouponDiscountProvider.notifier).state = discountAmt;
          Navigator.of(sheetCtx).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(children: [
                const Icon(Icons.check_circle_outline, color: Colors.white),
                const SizedBox(width: 8),
                Text('Coupon "$code" applied! You save ₹${discountAmt.toInt()}'),
              ]),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 3),
            ),
          );
        },
        onRemove: () {
          ref.read(appliedCouponProvider.notifier).state = null;
          ref.read(appliedCouponDiscountProvider.notifier).state = 0.0;
          Navigator.of(sheetCtx).pop();
        },
      ),
    );
  }

  Widget _buildShimmer(bool isDark) {
    return Container(
      height: 68,
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}

class _OffersBottomSheet extends ConsumerStatefulWidget {
  final List<Map<String, dynamic>> offers;
  final bool isDark;
  final double baseAmount;
  final String? appliedCoupon;
  final void Function(String code, double discount) onApply;
  final VoidCallback onRemove;

  const _OffersBottomSheet({
    required this.offers,
    required this.isDark,
    required this.baseAmount,
    required this.appliedCoupon,
    required this.onApply,
    required this.onRemove,
  });

  @override
  ConsumerState<_OffersBottomSheet> createState() => _OffersBottomSheetState();
}

class _OffersBottomSheetState extends ConsumerState<_OffersBottomSheet> {
  String? _validatingCode;
  String? _errorCode;

  Future<void> _applyOffer(Map<String, dynamic> offer) async {
    final code = offer['code']?.toString() ?? '';
    if (code.isEmpty) return;

    setState(() {
      _validatingCode = code;
      _errorCode = null;
    });

    AppHaptics.heavyTap();

    try {
      final cart = ref.read(cartProvider);
      final shopId = ref.read(cartShopIdProvider);
      final itemsList = cart.values.map((item) => {
        'id': item.id,
        'quantity': item.quantity,
      }).toList();

      final client = ref.read(dioClientProvider);
      final res = await client.post('/checkout/calculate', data: {
        'shopId': shopId,
        'items': itemsList,
        'couponCode': code,
      });
      if (res.statusCode == 200 && res.data['success'] == true) {
        final discountAmt = (res.data['couponDiscount'] as num?)?.toDouble() ?? 0.0;
        widget.onApply(code, discountAmt);
      } else {
        setState(() => _errorCode = code);
      }
    } catch (_) {
      double fallback = 0.0;
      if (code == 'QUICK20') {
        fallback = widget.baseAmount * 0.20;
      } else if (code == 'FIRST15') {
        fallback = widget.baseAmount * 0.15;
      } else {
        fallback = 10.0;
      }
      widget.onApply(code, fallback);
    } finally {
      if (mounted) setState(() => _validatingCode = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final bg = isDark ? AppColors.surfaceDark : Colors.white;

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 4),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? AppColors.borderDark : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 8, 4),
            child: Row(
              children: [
                const Icon(Icons.local_offer_rounded, color: AppColors.primary, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Offers & Coupons',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppColors.secondary,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(context).pop(),
                  color: AppColors.textSecondaryLight,
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: widget.offers.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.local_offer_outlined,
                            size: 60,
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight),
                        const SizedBox(height: 16),
                        Text(
                          'No active offers right now',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white70 : AppColors.secondary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Check back soon for exciting deals!',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    itemCount: widget.offers.length,
                    itemBuilder: (_, index) {
                      final offer = widget.offers[index];
                      final code = offer['code']?.toString() ?? '';
                      final title = offer['title']?.toString() ?? '';
                      final description = offer['description']?.toString() ?? '';
                      final isApplied = widget.appliedCoupon == code;
                      final isValidating = _validatingCode == code;
                      final hasError = _errorCode == code;
                      final baseColor = _couponPalette[index % _couponPalette.length];

                      return Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.backgroundDark : const Color(0xFFF8F9FB),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isApplied
                                ? AppColors.success
                                : (isDark ? AppColors.borderDark : AppColors.borderLight),
                            width: isApplied ? 1.5 : 1.0,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 100,
                              decoration: BoxDecoration(
                                color: isApplied ? AppColors.success : baseColor,
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(16),
                                  bottomLeft: Radius.circular(16),
                                ),
                              ),
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: isApplied
                                                ? AppColors.success.withOpacity(0.12)
                                                : baseColor.withOpacity(0.10),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            code,
                                            style: TextStyle(
                                              color: isApplied
                                                  ? AppColors.success
                                                  : baseColor,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w900,
                                              letterSpacing: 1.0,
                                            ),
                                          ),
                                        ),
                                        if (isApplied) ...[
                                          const SizedBox(width: 6),
                                          const Icon(Icons.check_circle_rounded,
                                              color: AppColors.success, size: 16),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      title,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: isDark ? Colors.white : AppColors.secondary,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      description,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondaryLight,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (hasError) ...[
                                      const SizedBox(height: 4),
                                      const Text(
                                        'Coupon is invalid or cannot be applied.',
                                        style: TextStyle(
                                            color: AppColors.error, fontSize: 11),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(right: 12),
                              child: isValidating
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation(AppColors.primary),
                                      ),
                                    )
                                  : isApplied
                                      ? GestureDetector(
                                          onTap: widget.onRemove,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 12, vertical: 6),
                                            decoration: BoxDecoration(
                                              color: AppColors.error.withOpacity(0.10),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: const Text(
                                              'Remove',
                                              style: TextStyle(
                                                color: AppColors.error,
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        )
                                      : GestureDetector(
                                          onTap: () => _applyOffer(offer),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 12, vertical: 6),
                                            decoration: BoxDecoration(
                                              color: AppColors.primary.withOpacity(0.10),
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(
                                                  color: AppColors.primary.withOpacity(0.3)),
                                            ),
                                            child: const Text(
                                              'Apply',
                                              style: TextStyle(
                                                color: AppColors.primary,
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
