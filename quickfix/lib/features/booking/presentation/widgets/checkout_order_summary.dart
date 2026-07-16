import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quickfix/core/theme/app_colors.dart';
import 'package:quickfix/core/theme/app_text_styles.dart';
import 'package:quickfix/core/utils/haptics.dart';
import 'package:quickfix/features/booking/presentation/controllers/cart_provider.dart';

class CheckoutOrderSummary extends ConsumerWidget {
  final bool isDark;
  final Map<String, CartItem> cart;

  const CheckoutOrderSummary({
    super.key,
    required this.isDark,
    required this.cart,
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _buildBoxDecoration(),
      child: Column(
        children: [
          ...cart.values.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: AppTextStyles.bodyMedium(
                            isDark,
                          ).copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            if (item.pricingType == 'inspection')
                              Text(
                                'Price after inspection',
                                style: AppTextStyles.bodySmall(
                                  isDark,
                                ).copyWith(fontStyle: FontStyle.italic),
                              )
                            else if (item.pricingType == 'starting')
                              Text(
                                'Starting from ₹${item.price.toInt()} x ${item.quantity}',
                                style: AppTextStyles.bodySmall(isDark),
                              )
                            else
                              Text(
                                '₹${item.price.toInt()} x ${item.quantity}',
                                style: AppTextStyles.bodySmall(isDark),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: item.pricingType == 'inspection'
                                ? Colors.orange.withValues(alpha: 0.1)
                                : item.pricingType == 'starting'
                                ? Colors.amber.withValues(alpha: 0.1)
                                : item.pricingType == 'range'
                                ? Colors.blue.withValues(alpha: 0.1)
                                : Colors.green.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            item.pricingType == 'inspection'
                                ? 'Quote Required'
                                : item.pricingType == 'starting'
                                ? 'Starts From'
                                : item.pricingType == 'range'
                                ? 'Price Range'
                                : 'Fixed Price',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: item.pricingType == 'inspection'
                                  ? Colors.orange
                                  : item.pricingType == 'starting'
                                  ? Colors.amber.shade700
                                  : item.pricingType == 'range'
                                  ? Colors.blue
                                  : Colors.green,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.remove_circle_outline,
                          color: AppColors.primary,
                          size: 20,
                        ),
                        onPressed: () {
                          AppHaptics.lightTap();
                          ref
                              .read(cartProvider.notifier)
                              .removeItem(item.id);
                        },
                      ),
                      Text(
                        '${item.quantity}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.add_circle_outline,
                          color: AppColors.primary,
                          size: 20,
                        ),
                        onPressed: () {
                          AppHaptics.lightTap();
                          ref
                              .read(cartProvider.notifier)
                              .addItem(item.id, item.title, item.price);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
