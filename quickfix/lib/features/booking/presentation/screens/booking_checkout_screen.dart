import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/haptics.dart';
import '../../../../features/home/presentation/providers/home_providers.dart';
import '../providers/cart_provider.dart';
import '../../../../core/network/dio_client.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

// State providers for checkout selections
final selectedDateProvider = StateProvider<DateTime>((ref) => DateTime.now().add(const Duration(days: 1)));
final selectedSlotProvider = StateProvider<String>((ref) => '09:00 AM - 11:00 AM');
final selectedAddressIndexProvider = StateProvider<int>((ref) => 0);
final appliedCouponProvider = StateProvider<String?>((ref) => null);
final appliedCouponDiscountProvider = StateProvider<double>((ref) => 0.0);
final selectedPaymentMethodProvider = StateProvider<String>((ref) => 'Razorpay');

/// Fetches active offers from backend
final activeOffersProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  try {
    final res = await DioClient().get('/offers');
    final data = res.data as List;
    return data
        .map((e) => Map<String, dynamic>.from(e as Map))
        .where((o) => o['isActive'] == true)
        .toList();
  } catch (_) {
    return [];
  }
});

class BookingCheckoutScreen extends ConsumerStatefulWidget {
  const BookingCheckoutScreen({super.key});

  @override
  ConsumerState<BookingCheckoutScreen> createState() => _BookingCheckoutScreenState();
}

class _BookingCheckoutScreenState extends ConsumerState<BookingCheckoutScreen> {
  late Razorpay _razorpay;
  Map<String, dynamic>? _pendingBookingData;

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
    // Show loaders or progress dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(AppColors.primary)),
      ),
    );

    try {
      final res = await DioClient().post('/bookings', data: bookingData);

      if (!mounted) return;
      Navigator.pop(context); // Dismiss progress indicator

      if (res.statusCode == 200 && res.data['success'] == true) {
        ref.read(authProvider.notifier).checkSession();
        AppHaptics.successNotification();
        ref.read(cartProvider.notifier).clearCart();
        context.push('/confirmation');
      } else {
        throw Exception(res.data['error'] ?? 'Server booking rejection.');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save booking order: ${e.toString()}')),
      );
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
            hintText: 'Enter complete address with flat/house no, street, locality & pincode',
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
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to add address: $e')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Save Address', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
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

    final authState = ref.watch(authProvider);
    final user = authState.user;
    final currentAddress = ref.watch(currentAddressProvider).address;

    // Dynamic calculations
    final bool hasInspectionService = cart.values.any((item) => item.pricingType == 'inspection');
    final double inspectionVisitingCharges = cart.values
        .where((item) => item.pricingType == 'inspection')
        .fold(0.0, (maxVal, item) => item.visitingCharges > maxVal ? item.visitingCharges : maxVal);
    final bool isFreeInspection = cart.values
        .where((item) => item.pricingType == 'inspection')
        .every((item) => item.isFreeInspection);

    double discount = 0.0;
    if (!hasInspectionService) {
      discount = ref.watch(appliedCouponDiscountProvider);
    }

    final double convenienceFee = (baseAmount > 0 && !hasInspectionService) ? 49.0 : 0.0;
    final double finalAmount = hasInspectionService
        ? (isFreeInspection ? 0.0 : inspectionVisitingCharges)
        : (baseAmount - discount + convenienceFee);

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
            // 1. Order summary details card
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
                                  Text('₹${item.price.toInt()} x ${item.quantity}', style: AppTextStyles.bodySmall(isDark)),
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

            // 2. Date Slot Selection
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

            // 3. Time Slot Selection
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
                          ? AppColors.primary.withOpacity(0.1) 
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

            // 4. Address Selection
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

            // 5. Offers & Coupons Panel (real backend data)
            _buildSectionHeader(isDark, 'Offers & Coupons'),
            _OffersAndCouponsPanel(
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

            // 7. Payment Billing details
            _buildSectionHeader(isDark, 'Bill Details'),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: _buildBoxDecoration(isDark),
              child: Column(
                children: [
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
                ],
              ),
            ),
          ],
        ),
      ),

      // Bottom floating pay bar
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
                onPressed: () => _triggerPaymentGateway(context, finalAmount, isDark),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
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

  // Helper layouts
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
          color: Colors.black.withOpacity(isDark ? 0.25 : 0.04),
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

  // Razorpay payment gateway checkout trigger
  void _triggerPaymentGateway(BuildContext context, double amount, bool isDark) async {
    AppHaptics.heavyTap();
    
    // Compile items description from cart
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
      'pricingType': hasInspectionService ? 'inspection' : 'fixed',
      'isFreeInspection': isFreeInspection,
    };

    if (methodParam == 'Razorpay' && amount > 0.0) {
      _pendingBookingData = bookingData;
      
      var options = {
        'key': 'rzp_test_TBOQ0xGYrMCEEW', // Razorpay Test Key ID
        'amount': (amount * 100).toInt(), // in paisa
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
      } catch (e) {
        debugPrint('Razorpay checkout error: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load Razorpay payment modal: $e')),
        );
      }
    } else {
      _executeBookingRequest(bookingData);
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Offers & Coupons Panel — real backend-driven widget
// ─────────────────────────────────────────────────────────────────────────────
const List<Color> _couponPalette = [
  AppColors.primary,
  AppColors.success,
  Color(0xFF7C3AED),
  AppColors.accent,
  Color(0xFF0EA5E9),
  Colors.teal,
];

class _OffersAndCouponsPanel extends ConsumerWidget {
  final bool isDark;
  final String? appliedCoupon;
  final double discount;
  final double baseAmount;
  final bool hasInspectionService;

  const _OffersAndCouponsPanel({
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
            // Icon with optional active badge
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
            // Text content
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
            // Right arrow or Remove button
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

// ─────────────────────────────────────────────────────────────────────────────
// Modal Bottom Sheet for Offers
// ─────────────────────────────────────────────────────────────────────────────
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
      final res = await DioClient().post('/coupons/validate', data: {
        'code': code,
        'amount': widget.baseAmount,
      });
      if (res.statusCode == 200 && res.data['success'] == true) {
        final discountAmt = double.tryParse(res.data['discount'].toString()) ?? 0.0;
        widget.onApply(code, discountAmt);
      } else {
        setState(() => _errorCode = code);
      }
    } catch (_) {
      // Fallback: compute discount locally
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
          // Handle bar
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
          // Header row
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
          // List
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
                            // Colored left strip
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
                            // Main content
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
                            // Action button
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
