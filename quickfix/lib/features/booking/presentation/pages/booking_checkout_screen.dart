import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quickfix/core/theme/app_colors.dart';
import 'package:quickfix/core/utils/haptics.dart';
import 'package:quickfix/features/home/presentation/controllers/home_providers.dart';
import 'package:quickfix/features/booking/presentation/controllers/cart_provider.dart';
import 'package:quickfix/features/booking/presentation/controllers/booking_providers.dart';
import 'package:quickfix/features/auth/presentation/controllers/auth_providers.dart';
import 'package:quickfix/features/booking/presentation/widgets/checkout_offers_sheet.dart';

import 'package:quickfix/features/booking/presentation/widgets/checkout_bill_details.dart';


class BookingCheckoutScreen extends ConsumerStatefulWidget {
  const BookingCheckoutScreen({super.key});

  @override
  ConsumerState<BookingCheckoutScreen> createState() => _BookingCheckoutScreenState();
}

class _BookingCheckoutScreenState extends ConsumerState<BookingCheckoutScreen> {
  late Razorpay _razorpay;
  Map<String, dynamic>? _pendingBookingData;
  bool _isProcessing = false;
  int _currentStep = 0;

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
    setState(() => _isProcessing = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Payment failed: '),
        backgroundColor: AppColors.error,
      ),
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('External wallet chosen: ')),
    );
  }

  void _executeBookingRequest(Map<String, dynamic> bookingData) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );
    try {
      final repository = ref.read(bookingRepositoryProvider);
      final resData = await repository.createBooking(bookingData);
      if (!mounted) return;
      Navigator.pop(context);

      if (resData['success'] == true) {
        ref.read(authProvider.notifier).checkSession();
        AppHaptics.successNotification();
        final bookingId = resData['bookingId'] ?? (resData['booking'] != null ? resData['booking']['id'] : null);
        final amount = resData['booking'] != null ? resData['booking']['amount'] : null;
        final date = resData['booking'] != null ? resData['booking']['date'] : null;
        final slot = resData['booking'] != null ? resData['booking']['slot'] : null;

        ref.read(cartProvider.notifier).clearCart();
        context.push('/confirmation', extra: {'bookingId': bookingId, 'amount': amount, 'date': date, 'slot': slot});
      } else {
        throw Exception(resData['error'] ?? 'Server booking rejection.');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to save booking order: ')));
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _triggerPaymentGateway(BuildContext context, double finalAmount, bool isDark) {
    setState(() => _isProcessing = true);
    final user = ref.read(authProvider).user;
    final phone = user?['phone'] ?? '9999999999';
    final email = user?['email'] ?? 'test@test.com';

    final cart = ref.read(cartProvider);
    final selectedDate = ref.read(selectedDateProvider);
    final selectedSlot = ref.read(selectedSlotProvider);
    final appliedCoupon = ref.read(appliedCouponProvider);
    final currentAddress = ref.read(currentAddressProvider.select((state) => state.address));
    final paymentMethod = ref.read(selectedPaymentMethodProvider);
    final shopId = ref.read(cartShopIdProvider);
    


    final bookingData = {
      'userId': user?['id'] ?? 'guest',
      'customerId': user?['id'] ?? 'guest',
      'customerName': user?['name'] ?? 'John Doe',
      'customerPhone': phone,
      'customerAddress': currentAddress,
      'shopId': shopId,
      'title': ' Service(s) Booked',
      'slot': selectedSlot,
      'date': DateFormat('yyyy-MM-dd').format(selectedDate),
      'amount': finalAmount,
      'paymentMethod': paymentMethod,
      'couponCode': appliedCoupon,
      'items': cart.values.map((e) => {'id': e.id, 'quantity': e.quantity, 'price': e.price, 'title': e.title}).toList(),
      'type': 'booking',
    };

    if (paymentMethod == 'Razorpay') {
      _pendingBookingData = bookingData;
      final options = {
        'key': 'rzp_test_YourKeyHere',
        'amount': (finalAmount * 100).toInt(),
        'name': 'QuickFix',
        'description': 'Service Booking',
        'prefill': {'contact': phone, 'email': email},
      };
      try {
        _razorpay.open(options);
      } catch (e) {
        setState(() => _isProcessing = false);
      }
    } else {
      _executeBookingRequest(bookingData);
    }
  }

  void _showAddAddressDialog(BuildContext context, WidgetRef ref, Map<String, dynamic>? user) {
    final addressController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Add New Address', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
        content: TextField(
          controller: addressController,
          maxLines: 2,
          decoration: InputDecoration(
            hintText: 'Enter complete address with house details & locality',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel', style: GoogleFonts.outfit())),
          ElevatedButton(
            onPressed: () async {
              final newAddress = addressController.text.trim();
              if (newAddress.isEmpty) return;
              Navigator.pop(context);
              try {
                final currentList = List<String>.from(user?['savedAddresses'] ?? []);
                currentList.add(newAddress);
                await ref.read(authProvider.notifier).updateProfile({'savedAddresses': currentList});
              } catch (e) {
                // Ignore error
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryAccent),
            child: Text('Save Address', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Row(
        children: [
          _buildStepNode(0, 'Date/Time', isDark),
          _buildStepLine(isDark),
          _buildStepNode(1, 'Address', isDark),
          _buildStepLine(isDark),
          _buildStepNode(2, 'Payment', isDark),
        ],
      ),
    );
  }

  Widget _buildStepNode(int index, String title, bool isDark) {
    final isActive = _currentStep >= index;
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive ? AppColors.primaryAccent : (isDark ? AppColors.surfaceDark : Colors.grey.shade200),
              border: Border.all(
                color: isActive ? AppColors.primaryAccent : (isDark ? AppColors.borderDark : AppColors.borderLight),
                width: 2,
              ),
            ),
            child: Center(
              child: isActive && _currentStep > index
                  ? const Icon(Icons.check, color: Colors.white, size: 16)
                  : Text('', style: GoogleFonts.outfit(color: isActive ? Colors.white : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight), fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(height: 8),
          Text(title, style: GoogleFonts.inter(fontSize: 12, fontWeight: isActive ? FontWeight.w600 : FontWeight.w400, color: isActive ? (isDark ? Colors.white : AppColors.primary) : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight))),
        ],
      ),
    );
  }

  Widget _buildStepLine(bool isDark) {
    return Container(
      width: 40,
      height: 2,
      color: isDark ? AppColors.borderDark : AppColors.borderLight,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(isDarkModeProvider);
    final totalItems = ref.watch(cartTotalItemsProvider);
    final baseAmount = ref.watch(cartTotalAmountProvider);

    final selectedDate = ref.watch(selectedDateProvider);
    final selectedSlot = ref.watch(selectedSlotProvider);
    final selectedAddressIndex = ref.watch(selectedAddressIndexProvider);
    final appliedCoupon = ref.watch(appliedCouponProvider);
    final paymentMethod = ref.watch(selectedPaymentMethodProvider);

    final user = ref.watch(authProvider).user;
    final currentAddress = ref.watch(currentAddressProvider).address;

    final calcAsync = ref.watch(checkoutCalculationProvider);
    final calcData = calcAsync.value;

    final double finalAmount = calcData != null ? (calcData['grandTotal'] as num).toDouble() : 0.0;
    final double discount = calcData != null ? (calcData['couponDiscount'] as num).toDouble() : 0.0;
    final bool hasInspectionService = calcData != null ? (calcData['pricingType'] != 'fixed') : false;
    final bool isFreeInspection = calcData != null ? (calcData['isFreeInspection'] == true) : false;
    final double inspectionVisitingCharges = calcData != null ? (calcData['visitingCharge'] as num).toDouble() : 0.0;
    final double convenienceFee = calcData != null ? (calcData['convenienceFee'] as num).toDouble() : 0.0;

    final List<String> slots = ['09:00 AM - 11:00 AM', '12:00 PM - 02:00 PM', '03:00 PM - 05:00 PM', '06:00 PM - 08:00 PM'];

    final savedAddresses = user?['savedAddresses'] as List<dynamic>? ?? [];
    final List<Map<String, String>> addresses = savedAddresses.map((addr) {
      final details = addr.toString();
      String type = 'Saved Address';
      if (details.toLowerCase().contains('office') || details.toLowerCase().contains('work')) {
        type = 'Office';
      } else if (details.toLowerCase().contains('swaroop') || details.toLowerCase().contains('home')) {
        type = 'Home';
      }
      return {'type': type, 'details': details};
    }).toList();

    final hasCurrentAddress = addresses.any((element) => element['details'] == currentAddress);
    if (!hasCurrentAddress && currentAddress.isNotEmpty) {
      addresses.insert(0, {'type': 'Current Selected Location', 'details': currentAddress});
    }

    if (addresses.isEmpty) {
      addresses.add({'type': 'No Address Found', 'details': 'Please add or select a delivery address.'});
    }

    if (totalItems == 0) {
      return Scaffold(
        backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
        appBar: AppBar(title: Text('Checkout', style: GoogleFonts.outfit())),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.shopping_cart_outlined, size: 64, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
              const SizedBox(height: 16),
              Text('Your cart is empty', style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w700, color: isDark ? Colors.white : AppColors.primary)),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.go('/home'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryAccent,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: Text('Go Home', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16)),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: Text('Checkout', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(left: 20.0, right: 20.0, top: 8.0, bottom: 120.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStepIndicator(isDark),
            
            Text('Date & Time', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w700, color: isDark ? Colors.white : AppColors.primary)),
            const SizedBox(height: 16),
            SizedBox(
              height: 80,
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
                      width: 72,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primaryAccent : (isDark ? AppColors.surfaceDark : Colors.white),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? AppColors.primaryAccent : (isDark ? AppColors.borderDark : AppColors.borderLight),
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            DateFormat('EEE').format(date).toUpperCase(),
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isSelected ? Colors.white : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat('d').format(date),
                            style: GoogleFonts.outfit(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: isSelected ? Colors.white : (isDark ? Colors.white : AppColors.primary),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 2.5,
              children: slots.map((slot) {
                final isSelected = selectedSlot == slot;
                return GestureDetector(
                  onTap: () {
                    AppHaptics.selectionClick();
                    ref.read(selectedSlotProvider.notifier).state = slot;
                    setState(() => _currentStep = 1);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primaryAccent.withValues(alpha: 0.1) : (isDark ? AppColors.surfaceDark : Colors.white),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? AppColors.primaryAccent : (isDark ? AppColors.borderDark : AppColors.borderLight),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        slot,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected ? AppColors.primaryAccent : (isDark ? Colors.white70 : AppColors.primary),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Address', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w700, color: isDark ? Colors.white : AppColors.primary)),
                TextButton.icon(
                  onPressed: () {
                    AppHaptics.lightTap();
                    _showAddAddressDialog(context, ref, user);
                  },
                  icon: const Icon(Icons.edit_location_alt_outlined, size: 18),
                  label: Text('Add New', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...List.generate(addresses.length, (index) {
              final addr = addresses[index];
              final isSelected = selectedAddressIndex == index;
              return GestureDetector(
                onTap: () {
                  AppHaptics.selectionClick();
                  ref.read(selectedAddressIndexProvider.notifier).state = index;
                  setState(() => _currentStep = 2);
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceDark : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? AppColors.primaryAccent : (isDark ? AppColors.borderDark : AppColors.borderLight),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isSelected ? Icons.check_circle_rounded : Icons.circle_outlined,
                        color: isSelected ? AppColors.primaryAccent : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                        size: 24,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              addr['type']!,
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white : AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              addr['details']!,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.edit_outlined, size: 20, color: AppColors.textSecondaryLight),
                    ],
                  ),
                ),
              );
            }),

            const SizedBox(height: 24),
            Text('Offers & Coupons', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w700, color: isDark ? Colors.white : AppColors.primary)),
            const SizedBox(height: 16),
            OffersAndCouponsPanel(
              isDark: isDark,
              appliedCoupon: appliedCoupon,
              discount: discount,
              baseAmount: baseAmount,
              hasInspectionService: hasInspectionService,
            ),

            const SizedBox(height: 32),
            Text('Payment Method', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w700, color: isDark ? Colors.white : AppColors.primary)),
            const SizedBox(height: 16),
            Column(
              children: ['Razorpay', 'Cash after Service'].map((method) {
                final isSelected = paymentMethod == method;
                return GestureDetector(
                  onTap: () {
                    AppHaptics.selectionClick();
                    ref.read(selectedPaymentMethodProvider.notifier).state = method;
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceDark : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? AppColors.primaryAccent : (isDark ? AppColors.borderDark : AppColors.borderLight),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          method == 'Razorpay' ? Icons.credit_card_rounded : Icons.payments_rounded,
                          color: isSelected ? AppColors.primaryAccent : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            method,
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : AppColors.primary,
                            ),
                          ),
                        ),
                        Icon(
                          isSelected ? Icons.check_circle_rounded : Icons.circle_outlined,
                          color: isSelected ? AppColors.primaryAccent : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                          size: 24,
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 32),
            CheckoutBillDetails(
              isDark: isDark,
              calcData: calcData,
              baseAmount: baseAmount,
              discount: discount,
              finalAmount: finalAmount,
              hasInspectionService: hasInspectionService,
              isFreeInspection: isFreeInspection,
              inspectionVisitingCharges: inspectionVisitingCharges,
              convenienceFee: convenienceFee,
            ),
          ],
        ),
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Total Price', style: GoogleFonts.inter(fontSize: 13, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
                  Text(
                    '₹',
                    style: GoogleFonts.outfit(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 200,
              height: 56,
              child: ElevatedButton(
                onPressed: _isProcessing ? null : () => _triggerPaymentGateway(context, finalAmount, isDark),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryAccent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: Text(
                  'Confirm Booking',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
