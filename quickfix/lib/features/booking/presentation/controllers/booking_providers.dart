import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quickfix/core/network/network_providers.dart';
import 'package:quickfix/features/booking/datasources/booking_remote_data_source.dart';
import 'package:quickfix/features/booking/repositories/booking_repository.dart';
import 'package:quickfix/features/booking/repositories/booking_repository_impl.dart';
import 'package:quickfix/features/booking/presentation/controllers/cart_provider.dart';
import 'package:quickfix/features/home/presentation/controllers/home_providers.dart';

final bookingRemoteDataSourceProvider = Provider<BookingRemoteDataSource>((ref) {
  final client = ref.watch(dioClientProvider);
  return BookingRemoteDataSource(client);
});

final bookingRepositoryProvider = Provider<BookingRepository>((ref) {
  final remote = ref.watch(bookingRemoteDataSourceProvider);
  return BookingRepositoryImpl(remote);
});

final selectedDateProvider = StateProvider<DateTime>(
  (ref) => DateTime.now().add(const Duration(days: 1)),
);

final selectedSlotProvider = StateProvider<String>(
  (ref) => '09:00 AM - 11:00 AM',
);

final selectedAddressIndexProvider = StateProvider<int>((ref) => 0);
final appliedCouponProvider = StateProvider<String?>((ref) => null);
final appliedCouponDiscountProvider = StateProvider<double>((ref) => 0.0);
final selectedPaymentMethodProvider = StateProvider<String>(
  (ref) => 'Razorpay',
);

final checkoutCalculationProvider = FutureProvider<Map<String, dynamic>?>((
  ref,
) async {
  final cart = ref.watch(cartProvider);
  final couponCode = ref.watch(appliedCouponProvider);
  final shopId = ref.watch(cartShopIdProvider);

  if (shopId == null || cart.isEmpty) {
    return null;
  }

  final itemsList = cart.values
      .map((item) => {'id': item.id, 'quantity': item.quantity})
      .toList();

  try {
    final repository = ref.watch(bookingRepositoryProvider);
    final data = await repository.calculateCheckout({
      'shopId': shopId,
      'items': itemsList,
      'couponCode': couponCode,
    });
    
    if (data['success'] == true) {
      final double discount =
          (data['couponDiscount'] as num?)?.toDouble() ?? 0.0;
      
      // Use microtask to avoid updating provider state during build phase
      Future.microtask(() {
        ref.read(appliedCouponDiscountProvider.notifier).state = discount;
      });
      return data;
    }
  } catch (e) {
    // Fail silently
  }
  return null;
});

final activeOffersProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  try {
    final repository = ref.watch(bookingRepositoryProvider);
    final offers = await repository.getOffers();
    return offers
        .where((o) => o['isActive'] == true)
        .toList();
  } catch (_) {
    return [];
  }
});

final bookingReceiptProvider =
    FutureProvider.family<Map<String, dynamic>?, String>((
      ref,
      bookingId,
    ) async {
      try {
        final repository = ref.watch(bookingRepositoryProvider);
        final data = await repository.getBookingLedger(bookingId);
        if (data['ledger'] != null) {
          return data['ledger'] as Map<String, dynamic>;
        }
        return null;
      } catch (e) {
        return null;
      }
    });
