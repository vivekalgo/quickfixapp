import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:quickfix/shared/themes/app_colors.dart';
import 'package:quickfix/shared/themes/app_text_styles.dart';
import 'package:quickfix/shared/utils/haptics.dart';
import 'package:quickfix/features/home/providers/home_providers.dart';
import 'package:quickfix/features/booking/providers/cart_provider.dart';
import 'package:quickfix/core/providers/network_providers.dart';
import 'package:quickfix/features/auth/providers/auth_providers.dart';
import 'package:quickfix/features/booking/widgets/checkout_offers_sheet.dart';
import 'package:quickfix/core/network/error_handler.dart';
import 'package:quickfix/core/config/app_config.dart';

class BookingCheckoutScreen extends ConsumerStatefulWidget {
  const BookingCheckoutScreen({super.key});

  @override
  ConsumerState<BookingCheckoutScreen> createState() => _BookingCheckoutScreenState();
}

class _BookingCheckoutScreenState extends ConsumerState<BookingCheckoutScreen> {
  late Razorpay _razorpay;
  Map<String, dynamic>? _pendingBookingData;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    if (_pendingBookingData == null) return;
    _pendingBookingData!['paymentDetails'] = {
      'paymentId': response.paymentId,
      'signature': response.signature,
      'orderId': response.orderId,
    };
    _executeBookingRequest(_pendingBookingData!);
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    if (!mounted) return;
    setState(() {
      _isProcessing = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Payment failed: ${response.message ?? "User cancelled payment"} (Code: ${response.code})'),
        backgroundColor: AppColors.error,
      ),
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('External wallet chosen: ${response.walletName}')),
    );
  }

  void _executeBookingRequest(Map<String, dynamic> bookingData) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(AppColors.primary)),
      ),
    );

    try {
      final client = ref.read(dioClientProvider);
      final res = await client.post('/bookings', data: bookingData);

      if (!mounted) return;
      Navigator.pop(context); // Dismiss progress indicator

      if (res.statusCode == 200 && res.data['success'] == true) {
        ref.read(authProvider.notifier).checkSession();
        AppHaptics.successNotification();
        
        final bookingId = res.data['bookingId'] ?? (res.data['booking'] != null ? res.data['booking']['id'] : null);
        final amount = res.data['booking'] != null ? res.data['booking']['amount'] : null;
        final date = res.data['booking'] != null ? res.data['booking']['date'] : null;
        final slot = res.data['booking'] != null ? res.data['booking']['slot'] : null;
        
        ref.read(cartProvider.notifier).clearCart();
        
        context.push(
          '/confirmation',
          extra: {
            'bookingId': bookingId,
            'amount': amount,
            'date': date,
            'slot': slot,
          },
        );
      } else {
        throw Exception(res.data['error'] ?? 'Server booking rejection.');
      }
    } catch (e, s) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save booking order: ${ErrorHandler.handle(e, s).message}')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  void _showAddAddressDialog(BuildContext context, WidgetRef ref, Map<String, dynamic>? user) {
    final addressController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Add New Address', style: TextStyle(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: addressController,
          maxLines: 2,
          decoration: const InputDecoration(
            hintText: 'Enter complete address with house details & locality',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newAddress = addressController.text.trim();
              if (newAddress.isEmpty) return;
              Navigator.pop(context);

              try {
                final currentList = List<String>.from(user?['savedAddresses'] ?? []);
                currentList.add(newAddress);
                await ref.read(authProvider.notifier).updateProfile({
                  'savedAddresses': currentList,
                });
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Address added successfully')),
                  );
                }
              } catch (e, s) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to add address: ${ErrorHandler.handle(e, s).message}')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Save Address', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    ).then((_) => addressController.dispose());
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(isDarkModeProvider);
    final cart = ref.watch(cartProvider);
    final totalItems = ref.watch(cartTotalItemsProvider);
    final baseAmount = ref.watch(cartTotalAmountProvider);

    final selectedDate = ref.watch(selectedDateProvider);
    final selectedSlot = ref.watch(selectedSlotProvider);
    final selectedAddressIndex = ref.watch(selectedAddressIndexProvider);
    final appliedCoupon = ref.watch(appliedCouponProvider);
    final paymentMethod = ref.watch(selectedPaymentMethodProvider);

    final user = ref.watch(authProvider.select((state) => state.user));
    final currentAddress = ref.watch(currentAddressProvider.select((state) => state.address));

    final calcAsync = ref.watch(checkoutCalculationProvider);
    final calcData = calcAsync.value;

    final double finalAmount = calcData != null ? (calcData['grandTotal'] as num).toDouble() : 0.0;
    final double discount = calcData != null ? (calcData['couponDiscount'] as num).toDouble() : 0.0;

    final bool hasInspectionService = calcData != null ? (calcData['pricingType'] != 'fixed') : false;
    final bool isFreeInspection = calcData != null ? (calcData['isFreeInspection'] == true) : false;
    final double inspectionVisitingCharges = calcData != null ? (calcData['visitingCharge'] as num).toDouble() : 0.0;
    final double convenienceFee = calcData != null ? (calcData['convenienceFee'] as num).toDouble() : 0.0;

    final List<String> slots = [
      '09:00 AM - 11:00 AM',
      '12:00 PM - 02:00 PM',
      '03:00 PM - 05:00 PM',
      '06:00 PM - 08:00 PM',
    ];

    final savedAddresses = user?['savedAddresses'] as List<dynamic>? ?? [];
    final List<Map<String, String>> addresses = savedAddresses.map((addr) {
      final details = addr.toString();
      String type = 'Saved Address';
      if (details.toLowerCase().contains('office') || details.toLowerCase().contains('work')) {
        type = 'Office';
      } else if (details.toLowerCase().contains('swaroop') || details.toLowerCase().contains('home')) {
        type = 'Home';
      }
      return {
        'type': type,
        'details': details,
      };
    }).toList();

    final hasCurrentAddress = addresses.any((element) => element['details'] == currentAddress);
    if (!hasCurrentAddress && currentAddress.isNotEmpty) {
      addresses.insert(0, {
        'type': 'Current Selected Location',
        'details': currentAddress,
      });
    }

    if (addresses.isEmpty) {
      addresses.add({
        'type': 'No Address Found',
        'details': 'Please add or select a delivery address.',
      });
    }

    if (totalItems == 0) {
      return Scaffold(
        appBar: AppBar(title: const Text('Checkout')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.shopping_cart_outlined, size: 64, color: AppColors.textSecondaryLight),
              const SizedBox(height: 16),
              Text('Your cart is empty', style: AppTextStyles.headingMedium(isDark)),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => context.go('/home'),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                child: const Text('Go Home', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Booking Checkout', style: AppTextStyles.headingMedium(isDark)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            AppHaptics.lightTap();
            context.pop();
          },
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 8.0, bottom: 100.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(isDark, 'Order Summary'),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: _buildBoxDecoration(isDark),
              child: Column(
                children: [
                  ...cart.values.map((item) => Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item.title, style: AppTextStyles.bodyMedium(isDark).copyWith(fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      if (item.pricingType == 'inspection')
                                        Text('Price after inspection', style: AppTextStyles.bodySmall(isDark).copyWith(fontStyle: FontStyle.italic))
                                      else if (item.pricingType == 'starting')
                                        Text('Starting from ₹${item.price.toInt()} x ${item.quantity}', style: AppTextStyles.bodySmall(isDark))
                                      else
                                        Text('₹${item.price.toInt()} x ${item.quantity}', style: AppTextStyles.bodySmall(isDark)),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
                                  icon: const Icon(Icons.remove_circle_outline, color: AppColors.primary, size: 20),
                                  onPressed: () {
                                    AppHaptics.lightTap();
                                    ref.read(cartProvider.notifier).removeItem(item.id);
                                  },
                                ),
                                Text('${item.quantity}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                IconButton(
                                  icon: const Icon(Icons.add_circle_outline, color: AppColors.primary, size: 20),
                                  onPressed: () {
                                    AppHaptics.lightTap();
                                    ref.read(cartProvider.notifier).addItem(item.id, item.title, item.price);
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      )),
                ],
              ),
            ),

            const SizedBox(height: 20),

            _buildSectionHeader(isDark, 'Select Date'),
            SizedBox(
              height: 76,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: 7,
                itemBuilder: (context, index) {
                  final date = DateTime.now().add(Duration(days: index + 1));
                  final isSelected = selectedDate.day == date.day && selectedDate.month == date.month;
                  return GestureDetector(
                    onTap: () {
                      AppHaptics.selectionClick();
                      ref.read(selectedDateProvider.notifier).state = date;
                    },
                    child: Container(
                      width: 64,
                      margin: const EdgeInsets.only(right: 8, bottom: 4),
                      decoration: BoxDecoration(
                        color: isSelected 
                            ? (isDark ? Colors.white : AppColors.secondary) 
                            : (isDark ? AppColors.surfaceDark : Colors.white),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected 
                              ? (isDark ? Colors.white : AppColors.secondary) 
                              : (isDark ? AppColors.borderDark : AppColors.borderLight),
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            DateFormat('EEE').format(date).toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: isSelected 
                                  ? (isDark ? AppColors.secondary : Colors.white70) 
                                  : AppColors.textSecondaryLight,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat('d').format(date),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isSelected 
                                  ? (isDark ? AppColors.secondary : Colors.white) 
                                  : (isDark ? Colors.white : AppColors.secondary),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 20),

            _buildSectionHeader(isDark, 'Select Time Slot'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: slots.map((slot) {
                final isSelected = selectedSlot == slot;
                return GestureDetector(
                  onTap: () {
                    AppHaptics.selectionClick();
                    ref.read(selectedSlotProvider.notifier).state = slot;
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected 
                          ? AppColors.primary.withValues(alpha: 0.1) 
                          : (isDark ? AppColors.surfaceDark : Colors.white),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected ? AppColors.primary : (isDark ? AppColors.borderDark : AppColors.borderLight),
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      slot,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? AppColors.primary : (isDark ? Colors.white70 : AppColors.secondary),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: _buildSectionHeader(isDark, 'Service Address')),
                TextButton.icon(
                  onPressed: () {
                    AppHaptics.lightTap();
                    _showAddAddressDialog(context, ref, user);
                  },
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add New'),
                  style: TextButton.styleFrom(foregroundColor: AppColors.primary),
                ),
              ],
            ),
            ...List.generate(addresses.length, (index) {
              final addr = addresses[index];
              final isSelected = selectedAddressIndex == index;
              return GestureDetector(
                onTap: () {
                  AppHaptics.selectionClick();
                  ref.read(selectedAddressIndexProvider.notifier).state = index;
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceDark : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : (isDark ? AppColors.borderDark : AppColors.borderLight),
                      width: isSelected ? 1.5 : 1.0,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                        color: isSelected ? AppColors.primary : AppColors.textSecondaryLight,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              addr['type']!,
                              style: AppTextStyles.bodyMedium(isDark).copyWith(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              addr['details']!,
                              style: AppTextStyles.bodySmall(isDark),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),

            const SizedBox(height: 20),

            _buildSectionHeader(isDark, 'Offers & Coupons'),
            OffersAndCouponsPanel(
              isDark: isDark,
              appliedCoupon: appliedCoupon,
              discount: discount,
              baseAmount: baseAmount,
              hasInspectionService: hasInspectionService,
            ),

            const SizedBox(height: 20),

            _buildSectionHeader(isDark, 'Select Payment Method'),
            Column(
              children: ['Razorpay', 'Cash after Service'].map((method) {
                final isSelected = paymentMethod == method;
                return GestureDetector(
                  onTap: () {
                    AppHaptics.selectionClick();
                    ref.read(selectedPaymentMethodProvider.notifier).state = method;
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceDark : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? AppColors.primary : (isDark ? AppColors.borderDark : AppColors.borderLight),
                        width: isSelected ? 1.5 : 1.0,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              method == 'Razorpay' 
                                  ? Icons.payment_outlined 
                                  : Icons.monetization_on_outlined,
                              color: isSelected ? AppColors.primary : AppColors.textSecondaryLight,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              method,
                              style: AppTextStyles.bodyMedium(isDark).copyWith(
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                        Icon(
                          isSelected ? Icons.check_circle : Icons.circle_outlined,
                          color: isSelected ? AppColors.primary : AppColors.textSecondaryLight,
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 20),

            _buildSectionHeader(isDark, 'Bill Details'),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: _buildBoxDecoration(isDark),
              child: Column(
                children: [
                  if (calcData == null) ...[
                    if (hasInspectionService) ...[
                      _buildBillRow('Inspection Service', 'Price after inspection', isDark),
                      const SizedBox(height: 8),
                      _buildBillRow('Visiting Charges', isFreeInspection ? 'FREE' : '₹${inspectionVisitingCharges.toInt()}', isDark, isGreen: isFreeInspection),
                    ] else ...[
                      _buildBillRow('Items Total', '₹${baseAmount.toInt()}', isDark),
                      if (discount > 0) ...[
                        const SizedBox(height: 8),
                        _buildBillRow('Coupon Discount', '- ₹${discount.toInt()}', isDark, isGreen: true),
                      ],
                      const SizedBox(height: 8),
                      _buildBillRow('Convenience & Safety Fee', '₹${convenienceFee.toInt()}', isDark),
                    ],
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12.0),
                      child: Divider(),
                    ),
                    _buildBillRow('Grand Total', '₹${finalAmount.toInt()}', isDark, isBold: true),
                  ] else ...[
                    ... (calcData['billDetails'] as List<dynamic>).map((row) {
                      final label = row['label']?.toString() ?? '';
                      final val = row['value']?.toString() ?? '';
                      final isGreen = row['isGreen'] == true;
                      
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: _buildBillRow(label, val, isDark, isGreen: isGreen),
                      );
                    }),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12.0),
                      child: Divider(),
                    ),
                    _buildBillRow('Grand Total', '₹${(calcData['grandTotal'] as num).toInt()}', isDark, isBold: true),
                  ]
                ],
              ),
            ),
            if (calcData != null && calcData['redBannerText'] != null) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        calcData['redBannerText'].toString(),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.red.shade300 : Colors.red.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (calcData != null && calcData['pricingType'] != 'fixed') ...[
              const SizedBox(height: 20),
              _buildSectionHeader(isDark, 'Pricing Details'),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: _buildBoxDecoration(isDark),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (calcData['pricingType'] == 'starting') ...[
                      Text('Estimated Service Price', style: AppTextStyles.bodySmall(isDark)),
                      const SizedBox(height: 4),
                      Text(
                        calcData['estimatedPriceText'] ?? 'Starts From ₹0',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : AppColors.secondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Final amount will be decided after inspection.',
                        style: AppTextStyles.bodySmall(isDark).copyWith(fontStyle: FontStyle.italic),
                      ),
                    ] else if (calcData['pricingType'] == 'range') ...[
                      Text('Estimated Price Range', style: AppTextStyles.bodySmall(isDark)),
                      const SizedBox(height: 4),
                      Text(
                        calcData['estimatedPriceText'] ?? '₹0 - ₹0',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : AppColors.secondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Final repair cost will depend on the inspection.',
                        style: AppTextStyles.bodySmall(isDark).copyWith(fontStyle: FontStyle.italic),
                      ),
                    ] else if (calcData['pricingType'] == 'inspection') ...[
                      Text(
                        'Price will be shared after inspection.',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : AppColors.secondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          border: Border(
            top: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '₹${finalAmount.toInt()}',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppColors.secondary,
                    ),
                  ),
                  Text(
                    'To Pay',
                    style: AppTextStyles.bodySmall(isDark),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 180,
              height: 48,
              child: ElevatedButton(
                onPressed: _isProcessing ? null : () => _triggerPaymentGateway(context, finalAmount, isDark),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Place Order', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    SizedBox(width: 8),
                    Icon(Icons.lock, size: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(bool isDark, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0, top: 4.0),
      child: Text(
        title,
        style: AppTextStyles.headingSmall(isDark).copyWith(fontSize: 15),
      ),
    );
  }
  BoxDecoration _buildBoxDecoration(bool isDark) {
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

  Widget _buildBillRow(String label, String value, bool isDark, {bool isGreen = false, bool isBold = false}) {
    final style = TextStyle(
      fontSize: isBold ? 16 : 13,
      fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
      color: isGreen 
          ? AppColors.success 
          : (isDark ? (isBold ? Colors.white : Colors.white70) : AppColors.secondary),
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

  void _triggerPaymentGateway(BuildContext context, double amount, bool isDark) async {
    if (_isProcessing) return;
    setState(() {
      _isProcessing = true;
    });
    AppHaptics.heavyTap();
    
    final cart = ref.read(cartProvider);
    final itemsDesc = cart.values.map((item) => "${item.title} (x${item.quantity})").join(', ');
    final selectedDate = ref.read(selectedDateProvider);
    final selectedSlot = ref.read(selectedSlotProvider);
    final selectedAddressIndex = ref.read(selectedAddressIndexProvider);
    
    final authState = ref.read(authProvider);
    final user = authState.user;
    final currentAddress = ref.read(currentAddressProvider);
    
    final savedAddresses = user?['savedAddresses'] as List<dynamic>? ?? [];
    final List<Map<String, String>> addresses = savedAddresses.map((addr) {
      final details = addr.toString();
      String type = 'Saved Address';
      if (details.toLowerCase().contains('office') || details.toLowerCase().contains('work')) {
        type = 'Office';
      } else if (details.toLowerCase().contains('swaroop') || details.toLowerCase().contains('home')) {
        type = 'Home';
      }
      return {
        'type': type,
        'details': details,
      };
    }).toList();

    final hasCurrentAddress = addresses.any((element) => element['details'] == currentAddress.address);
    if (!hasCurrentAddress && currentAddress.address.isNotEmpty) {
      addresses.insert(0, {
        'type': 'Current Selected Location',
        'details': currentAddress.address,
      });
    }

    if (addresses.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add or select a delivery address before payment.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final paymentMethod = ref.read(selectedPaymentMethodProvider);
    final bool hasInspectionService = cart.values.any((item) => item.pricingType == 'inspection');
    final bool isFreeInspection = cart.values
        .where((item) => item.pricingType == 'inspection')
        .every((item) => item.isFreeInspection);

    String methodParam = 'Cash';
    if (amount > 0.0) {
      if (paymentMethod == 'Razorpay') {
        methodParam = 'Razorpay';
      }
    } else {
      methodParam = 'Cash';
    }

    final cartShopId = ref.read(cartShopIdProvider);

    final bookingData = {
      'amount': amount,
      'title': itemsDesc.isNotEmpty ? itemsDesc : 'Home Repair Service',
      'slot': selectedSlot,
      'date': selectedDate.toIso8601String(),
      'customerId': user?['id'] ?? user?['_id'] ?? 'cust-123',
      'customerName': user?['name'] ?? 'John Doe',
      'customerPhone': user?['phone'] ?? '9999888877',
      'customerAddress': addresses[selectedAddressIndex]['details'],
      'shopId': cartShopId ?? 'shop-1', 
      'paymentMethod': methodParam,
      'pricingType': hasInspectionService ? 'inspection' : (cart.values.any((item) => item.pricingType == 'starting') ? 'starting' : (cart.values.any((item) => item.pricingType == 'range') ? 'range' : 'fixed')),
      'isFreeInspection': isFreeInspection,
      'items': cart.values.map((item) => {
        'id': item.id,
        'quantity': item.quantity,
      }).toList(),
      'couponCode': ref.read(appliedCouponProvider),
    };

    if (methodParam == 'Razorpay' && amount > 0.0) {
      _pendingBookingData = bookingData;
      
      var options = {
        'key': AppConfig.razorpayKey, 
        'amount': (amount * 100).toInt(), 
        'name': 'QuickFix Services',
        'description': itemsDesc.isNotEmpty ? itemsDesc : 'Home Repair Service',
        'prefill': {
          'contact': user?['phone'] ?? '9999888877',
          'email': user?['email'] ?? 'customer@quickfix.com',
        },
        'external': {
          'wallets': ['paytm']
        }
      };

      try {
        _razorpay.open(options);
      } catch (e, s) {
        final resolved = ErrorHandler.handle(e, s);
        if (mounted) {
          setState(() {
            _isProcessing = false;
          });
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load Razorpay payment modal: ${resolved.message}')),
        );
      }
    } else {
      _executeBookingRequest(bookingData);
    }
  }
}
