import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:quickfix/features/home/models/home_models.dart';
import 'package:quickfix/features/home/repositories/home_repository.dart';
import 'package:quickfix/features/home/repositories/home_repository_impl.dart';
import 'package:quickfix/core/services/hive_service.dart';
import 'package:hive/hive.dart';
import 'package:dio/dio.dart';

import 'package:quickfix/core/providers/network_providers.dart';
import 'package:quickfix/features/home/services/home_remote_data_source.dart';

// Remote Data Source Provider
final homeRemoteDataSourceProvider = Provider<HomeRemoteDataSource>((ref) {
  final client = ref.watch(dioClientProvider);
  return HomeRemoteDataSource(client);
});

// Repository Provider
final homeRepositoryProvider = Provider<HomeRepository>((ref) {
  final remote = ref.watch(homeRemoteDataSourceProvider);
  return HomeRepositoryImpl(remote);
});

// Categories Provider
final categoriesProvider = FutureProvider<List<ServiceCategory>>((ref) async {
  final repository = ref.watch(homeRepositoryProvider);
  final list = await repository.getCategories();
  final normalized = list
      .where((category) => category.id.trim().isNotEmpty && category.name.trim().isNotEmpty)
      .toList();

  return normalized;
});

// Selected Nearby Shop Filter Tag Provider
final selectedNearbyFilterProvider = StateProvider<String>((ref) => 'All');

// Nearby Shops Provider (reactive to filters & location)
final nearbyShopsProvider = FutureProvider<List<Shop>>((ref) async {
  final repository = ref.watch(homeRepositoryProvider);
  final activeFilter = ref.watch(selectedNearbyFilterProvider);
  final location = ref.watch(currentAddressProvider);
  
  return repository.getNearbyShops(
    filter: activeFilter, 
    lat: location.latitude, 
    lng: location.longitude,
  );
});

// Top Rated Professionals Provider
final topProfessionalsProvider = FutureProvider<List<Professional>>((ref) async {
  final repository = ref.watch(homeRepositoryProvider);
  return repository.getTopProfessionals();
});

// Promo Banners Provider
final bannersProvider = FutureProvider<List<PromoBanner>>((ref) async {
  final repository = ref.watch(homeRepositoryProvider);
  return repository.getBanners();
});

// Promotions Provider
final promotionsProvider = FutureProvider<List<Promotion>>((ref) async {
  final repository = ref.watch(homeRepositoryProvider);
  return repository.getPromotions();
});

// Special Cards Provider
final specialCardsProvider = FutureProvider<List<SpecialCard>>((ref) async {
  final repository = ref.watch(homeRepositoryProvider);
  return repository.getSpecialCards();
});

// Homepage Layout Provider
final homepageLayoutProvider = FutureProvider<List<CmsSection>>((ref) async {
  final repository = ref.watch(homeRepositoryProvider);
  return repository.getHomepageLayout();
});

// Custom Homepage Sections Provider
final customSectionsProvider = FutureProvider<List<CustomSection>>((ref) async {
  final repository = ref.watch(homeRepositoryProvider);
  return repository.getCustomSections();
});

// Cart Shop ID Tracker Provider
final cartShopIdProvider = StateProvider<String?>((ref) => null);

// Customer Reviews Provider
final customerReviewsProvider = FutureProvider<List<Review>>((ref) async {
  final repository = ref.watch(homeRepositoryProvider);
  return repository.getCustomerReviews();
});

// Active Navigation Bar Index
final currentNavIndexProvider = StateProvider<int>((ref) => 0);

// Location Provider
class LocationNotifier extends StateNotifier<UserLocation> {
  LocationNotifier() : super(_getInitialLocation()) {
    fetchCurrentLocationAutomatically();
  }

  static UserLocation _getInitialLocation() {
    final cached = HiveService.getActiveLocation();
    if (cached != null) {
      return UserLocation.fromJson(cached);
    }
    final address = HiveService.getSavedAddress();
    if (address.isNotEmpty) {
      return UserLocation(address: address, latitude: 0.0, longitude: 0.0);
    }
    return const UserLocation(
      address: 'Detecting Location...',
      latitude: 0.0,
      longitude: 0.0,
    );
  }

  void updateLocation(String address, double lat, double lng) {
    if (state.address == address && state.latitude != 0.0 && state.longitude != 0.0 && lat != 0.0 && lng != 0.0) {
      final double distance = Geolocator.distanceBetween(
        state.latitude,
        state.longitude,
        lat,
        lng,
      );
      if (distance < 100.0) {
        return; // Ignore small coordinate drift to avoid redundant API queries
      }
    }
    state = UserLocation(address: address, latitude: lat, longitude: lng);
    HiveService.saveAddress(address, lat: lat, lng: lng);
  }

  void updateAddress(String newAddress) {
    updateLocation(newAddress, state.latitude, state.longitude);
  }

  Future<String?> _reverseGeocode(double lat, double lng) async {
    try {
      final dio = Dio();
      dio.options.headers['User-Agent'] = 'QuickFixApp/1.0';
      final response = await dio.get(
        'https://nominatim.openstreetmap.org/reverse',
        queryParameters: {
          'lat': lat,
          'lon': lng,
          'format': 'json',
          'addressdetails': 1,
        },
      );
      if (response.statusCode == 200 && response.data != null) {
        return response.data['display_name'] as String?;
      }
    } catch (e) {
      // Ignore reverse geocoding failures and fall back to coordinates.
    }
    return null;
  }

  Future<void> updateAddressFromCoordinates(double lat, double lng) async {
    final realAddress = await _reverseGeocode(lat, lng);
    if (realAddress != null && realAddress.trim().isNotEmpty) {
      updateLocation(realAddress, lat, lng);
    } else {
      updateLocation("Latitude: ${lat.toStringAsFixed(4)}, Longitude: ${lng.toStringAsFixed(4)}", lat, lng);
    }
  }

  Future<void> fetchCurrentLocationAutomatically() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.always || permission == LocationPermission.whileInUse) {
        // Try last known location first for instant update
        final lastKnown = await Geolocator.getLastKnownPosition();
        if (lastKnown != null) {
          await updateAddressFromCoordinates(lastKnown.latitude, lastKnown.longitude);
        }

        // Fetch current position with fallback to balanced/low accuracy to avoid hanging
        Position? position;
        try {
          position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.medium,
            timeLimit: const Duration(seconds: 5),
          );
        } catch (_) {
          try {
            position = await Geolocator.getCurrentPosition(
              desiredAccuracy: LocationAccuracy.low,
              timeLimit: const Duration(seconds: 4),
            );
          } catch (_) {
            if (lastKnown == null) {
              position = await Geolocator.getLastKnownPosition();
            }
          }
        }

        if (position != null) {
          await updateAddressFromCoordinates(position.latitude, position.longitude);
        }
      }
    } catch (e) {
      // Fail silently
    }
  }

  Future<bool> fetchGPSLocation({bool requestPermission = true}) async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return false;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied && requestPermission) {
        permission = await Geolocator.requestPermission();
      }
      
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        return false;
      }

      // Try last known location first for speed
      final lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null) {
        updateAddressFromCoordinates(lastKnown.latitude, lastKnown.longitude);
      }

      Position? position;
      try {
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium,
          timeLimit: const Duration(seconds: 8),
        );
      } catch (_) {
        try {
          position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.low,
            timeLimit: const Duration(seconds: 5),
          );
        } catch (_) {
          position = lastKnown ?? await Geolocator.getLastKnownPosition();
        }
      }

      if (position != null) {
        await updateAddressFromCoordinates(position.latitude, position.longitude);
        return true;
      }
      
      return lastKnown != null;
    } catch (e) {
      return false;
    }
  }
}

String getShortAddress(String address) {
  if (address.isEmpty) return 'Select Location';
  if (address.startsWith('Latitude:')) {
    return 'Current Location';
  }
  final parts = address.split(',');
  if (parts.isEmpty) return address;
  
  final first = parts[0].trim();
  if (first.length <= 4 || 
      RegExp(r'^\d+$').hasMatch(first) || 
      first.toLowerCase().startsWith('flat') || 
      first.toLowerCase().startsWith('shop') || 
      first.toLowerCase().startsWith('house') || 
      first.toLowerCase().startsWith('plot') || 
      first.toLowerCase().startsWith('block') || 
      first.toLowerCase().startsWith('no.')) {
    if (parts.length > 1) {
      final second = parts[1].trim();
      return '$first, $second';
    }
  }
  return first;
}

final currentAddressProvider = StateNotifierProvider<LocationNotifier, UserLocation>((ref) {
  return LocationNotifier();
});

// Theme Mode Provider (Light/Dark)
class ThemeModeNotifier extends StateNotifier<bool> {
  ThemeModeNotifier() : super(HiveService.isDarkMode());

  void toggleTheme() {
    state = !state;
    HiveService.setDarkMode(state);
  }
}

final isDarkModeProvider = StateNotifierProvider<ThemeModeNotifier, bool>((ref) {
  return ThemeModeNotifier();
});

class WishlistNotifier extends StateNotifier<List<String>> {
  WishlistNotifier() : super(HiveService.getFavouriteProviderIds());

  void toggleFavourite(String id) {
    HiveService.toggleFavouriteProvider(id);
    state = HiveService.getFavouriteProviderIds();
  }

  bool isFavourite(String id) {
    return state.contains(id);
  }
}

final wishlistProvider = StateNotifierProvider<WishlistNotifier, List<String>>((ref) {
  return WishlistNotifier();
});

// Global Notifications Providers
final notificationsProvider = StreamProvider<List<Map<String, dynamic>>>((ref) async* {
  final box = Hive.box('local_notifications');
  
  List<Map<String, dynamic>> getList() {
    final list = box.values
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
    list.sort((a, b) {
      final timeA = DateTime.tryParse(a['time'] ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
      final timeB = DateTime.tryParse(b['time'] ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
      return timeB.compareTo(timeA);
    });
    return list;
  }
  
  yield getList();
  
  await for (final _ in box.watch()) {
    yield getList();
  }
});

final syncNotificationsProvider = FutureProvider<void>((ref) async {
  try {
    final client = ref.read(dioClientProvider);
    final res = await client.get('/notifications');
    final data = res.data as List;
    final box = Hive.box('local_notifications');
    
    for (final item in data) {
      final map = Map<String, dynamic>.from(item as Map);
      final id = map['id']?.toString() ?? '';
      if (id.isNotEmpty && !box.containsKey(id)) {
        final localItem = {
          'id': id,
          'title': map['title'] ?? '',
          'body': map['body'] ?? '',
          'time': map['createdAt'] ?? map['time'] ?? DateTime.now().toIso8601String(),
          'isRead': false,
          'type': map['type'] ?? 'general',
          'bookingId': map['bookingId'] ?? '',
          'orderId': map['orderId'] ?? '',
          'deepLink': map['deepLink'] ?? '',
          'iconColor': map['iconColor'] ?? 'primary',
        };
        await box.put(id, localItem);
      }
    }
  } catch (_) {
    // Fail silently
  }
});

class ReadNotificationsNotifier extends StateNotifier<Set<String>> {
  ReadNotificationsNotifier() : super(HiveService.getReadNotificationIds().toSet()) {
    _syncWithLocalNotifications();
  }

  void _syncWithLocalNotifications() {
    try {
      final box = Hive.box('local_notifications');
      final readIds = box.values
          .map((e) => Map<String, dynamic>.from(e as Map))
          .where((item) => item['isRead'] == true)
          .map((item) => item['id']?.toString() ?? '')
          .where((id) => id.isNotEmpty)
          .toSet();
      state = readIds;
    } catch (_) {}
  }

  Future<void> markAsRead(String id) async {
    state = {...state, id};
    HiveService.markNotificationAsRead(id);
    
    try {
      final box = Hive.box('local_notifications');
      final item = box.get(id);
      if (item != null) {
        final updated = Map<String, dynamic>.from(item as Map);
        updated['isRead'] = true;
        await box.put(id, updated);
      }
    } catch (_) {}
  }

  Future<void> markAllAsRead(List<String> ids) async {
    state = {...state, ...ids};
    for (final id in ids) {
      HiveService.markNotificationAsRead(id);
    }
    
    try {
      final box = Hive.box('local_notifications');
      for (final id in ids) {
        final item = box.get(id);
        if (item != null) {
          final updated = Map<String, dynamic>.from(item as Map);
          updated['isRead'] = true;
          await box.put(id, updated);
        }
      }
    } catch (_) {}
  }

  Future<void> deleteNotification(String id) async {
    state = state.where((item) => item != id).toSet();
    try {
      final box = Hive.box('local_notifications');
      await box.delete(id);
    } catch (_) {}
  }

  Future<void> clearAll() async {
    state = {};
    try {
      final box = Hive.box('local_notifications');
      await box.clear();
    } catch (_) {}
  }
}

final readNotificationsProvider = StateNotifierProvider<ReadNotificationsNotifier, Set<String>>((ref) {
  return ReadNotificationsNotifier();
});

final unreadNotificationsCountProvider = Provider<int>((ref) {
  final notificationsAsync = ref.watch(notificationsProvider);
  return notificationsAsync.when(
    data: (list) {
      return list.where((item) => item['isRead'] != true).length;
    },
    loading: () => 0,
    error: (_, __) => 0,
  );
});

