import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';

// 1. Active Shop Provider (holds logged-in partner data)
class ActiveShopNotifier extends StateNotifier<Map<String, dynamic>?> {
  ActiveShopNotifier() : super(null);

  void setShop(Map<String, dynamic> shop) {
    state = shop;
  }

  void logout() {
    state = null;
  }

  Future<void> toggleOnlineStatus() async {
    if (state == null) return;
    final currentStatus = state!['isOnline'] ?? false;
    final updatedShop = Map<String, dynamic>.from(state!);
    updatedShop['isOnline'] = !currentStatus;

    try {
      final dio = DioClient().dio;
      final res = await dio.post('/shops/update', data: updatedShop);
      if (res.statusCode == 200 && res.data['success'] == true) {
        state = res.data['shop'];
      }
    } catch (e) {
      // Fallback update locally if offline
      state = updatedShop;
    }
  }

  Future<void> updateTimings(String timings) async {
    if (state == null) return;
    final updatedShop = Map<String, dynamic>.from(state!);
    updatedShop['timings'] = timings;

    try {
      final dio = DioClient().dio;
      final res = await dio.post('/shops/update', data: updatedShop);
      if (res.statusCode == 200 && res.data['success'] == true) {
        state = res.data['shop'];
      }
    } catch (e) {
      state = updatedShop;
    }
  }

  Future<void> updateServicePrice(String serviceId, double price) async {
    if (state == null) return;
    final updatedShop = Map<String, dynamic>.from(state!);
    final List services = List.from(updatedShop['services'] ?? []);
    
    for (int i = 0; i < services.length; i++) {
      if (services[i]['id'] == serviceId) {
        services[i]['price'] = price;
        break;
      }
    }
    updatedShop['services'] = services;

    try {
      final dio = DioClient().dio;
      final res = await dio.post('/shops/update', data: updatedShop);
      if (res.statusCode == 200 && res.data['success'] == true) {
        state = res.data['shop'];
      }
    } catch (e) {
      state = updatedShop;
    }
  }

  Future<void> addPortfolioImage(String imageUrl) async {
    if (state == null) return;
    final updatedShop = Map<String, dynamic>.from(state!);
    final List portfolio = List.from(updatedShop['portfolioImages'] ?? []);
    portfolio.add(imageUrl);
    updatedShop['portfolioImages'] = portfolio;

    try {
      final dio = DioClient().dio;
      final res = await dio.post('/shops/update', data: updatedShop);
      if (res.statusCode == 200 && res.data['success'] == true) {
        state = res.data['shop'];
      }
    } catch (e) {
      state = updatedShop;
    }
  }
}

final activeShopProvider = StateNotifierProvider<ActiveShopNotifier, Map<String, dynamic>?>((ref) {
  return ActiveShopNotifier();
});

// 2. Stream Provider to fetch and poll bookings from backend
final providerBookingsProvider = FutureProvider<List<dynamic>>((ref) async {
  final shop = ref.watch(activeShopProvider);
  if (shop == null) return [];
  
  try {
    final dio = DioClient().dio;
    final res = await dio.get('/bookings', queryParameters: {'shopId': shop['id']});
    return res.data as List;
  } catch (e) {
    return [];
  }
});
