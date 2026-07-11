import 'package:flutter_riverpod/flutter_riverpod.dart';

class CartItem {
  final String id;
  final String title;
  final double price;
  final int quantity;
  final String pricingType;
  final bool isFreeInspection;
  final double visitingCharges;
  final double minPrice;
  final double maxPrice;

  const CartItem({
    required this.id,
    required this.title,
    required this.price,
    required this.quantity,
    this.pricingType = 'fixed',
    this.isFreeInspection = false,
    this.visitingCharges = 0.0,
    this.minPrice = 0.0,
    this.maxPrice = 0.0,
  });

  CartItem copyWith({int? quantity}) {
    return CartItem(
      id: id,
      title: title,
      price: price,
      quantity: quantity ?? this.quantity,
      pricingType: pricingType,
      isFreeInspection: isFreeInspection,
      visitingCharges: visitingCharges,
      minPrice: minPrice,
      maxPrice: maxPrice,
    );
  }
}

class CartNotifier extends StateNotifier<Map<String, CartItem>> {
  CartNotifier() : super({});

  void addItem(
    String id,
    String title,
    double price, {
    String pricingType = 'fixed',
    bool isFreeInspection = false,
    double visitingCharges = 0.0,
    double minPrice = 0.0,
    double maxPrice = 0.0,
  }) {
    if (state.containsKey(id)) {
      state = {
        ...state,
        id: state[id]!.copyWith(quantity: state[id]!.quantity + 1),
      };
    } else {
      state = {
        ...state,
        id: CartItem(
          id: id,
          title: title,
          price: price,
          quantity: 1,
          pricingType: pricingType,
          isFreeInspection: isFreeInspection,
          visitingCharges: visitingCharges,
          minPrice: minPrice,
          maxPrice: maxPrice,
        ),
      };
    }
  }

  void removeItem(String id) {
    if (!state.containsKey(id)) return;
    
    if (state[id]!.quantity > 1) {
      state = {
        ...state,
        id: state[id]!.copyWith(quantity: state[id]!.quantity - 1),
      };
    } else {
      final newState = Map<String, CartItem>.from(state);
      newState.remove(id);
      state = newState;
    }
  }

  void clearCart() {
    state = {};
  }
}

final cartProvider = StateNotifierProvider<CartNotifier, Map<String, CartItem>>((ref) {
  return CartNotifier();
});

final cartTotalItemsProvider = Provider<int>((ref) {
  final cart = ref.watch(cartProvider);
  return cart.values.fold(0, (sum, item) => sum + item.quantity);
});

final cartTotalAmountProvider = Provider<double>((ref) {
  final cart = ref.watch(cartProvider);
  return cart.values.fold(0.0, (sum, item) => sum + (item.price * item.quantity));
});
