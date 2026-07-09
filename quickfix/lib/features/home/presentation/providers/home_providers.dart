import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../../data/models/home_models.dart';
import '../../domain/repositories/home_repository.dart';
import '../../data/repositories/home_repository_impl.dart';
import '../../../../core/database/hive_service.dart';
import 'package:dio/dio.dart';

import '../../../../core/network/network_providers.dart';
import '../../data/sources/home_remote_data_source.dart';

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

  final baseCategories = normalized.isEmpty
      ? const [
          ServiceCategory(
            id: 'cleaning',
            name: 'Cleaning',
            icon: Icons.cleaning_services_outlined,
            backgroundColor: Color(0xFFEEF2FF),
            iconColor: Color(0xFF4F46E5),
          ),
          ServiceCategory(
            id: 'plumbing',
            name: 'Plumbing',
            icon: Icons.plumbing_outlined,
            backgroundColor: Color(0xFFECFDF5),
            iconColor: Color(0xFF059669),
          ),
          ServiceCategory(
            id: 'electrician',
            name: 'Electrician',
            icon: Icons.bolt_outlined,
            backgroundColor: Color(0xFFFFFBEB),
            iconColor: Color(0xFFD97706),
          ),
          ServiceCategory(
            id: 'appliances',
            name: 'Appliances Repair',
            icon: Icons.local_laundry_service_outlined,
            backgroundColor: Color(0xFFF5F3FF),
            iconColor: Color(0xFF7C3AED),
          ),
          ServiceCategory(
            id: 'carpentry',
            name: 'Carpentry',
            icon: Icons.carpenter_outlined,
            backgroundColor: Color(0xFFFFF7ED),
            iconColor: Color(0xFFEA580C),
          ),
        ]
      : normalized;

  final hasMore = baseCategories.any((c) => c.id == 'more');
  if (hasMore) {
    return baseCategories;
  }

  return [
    ...baseCategories,
    const ServiceCategory(
      id: 'more',
      name: 'More',
      icon: Icons.grid_view_outlined,
      backgroundColor: Color(0xFFF1F5F9),
      iconColor: Color(0xFF475569),
    ),
  ];
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
      return UserLocation(address: address, latitude: 26.4912, longitude: 80.3156);
    }
    return const UserLocation(
      address: '113, Swaroop Nagar, Kanpur, Uttar Pradesh - 208002',
      latitude: 26.4912,
      longitude: 80.3156,
    );
  }

  void updateLocation(String address, double lat, double lng) {
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
        final data = response.data;
        final address = data['address'] as Map<String, dynamic>?;
        if (address != null) {
          final road = address['road'] ?? address['suburb'] ?? address['neighbourhood'] ?? address['amenity'] ?? '';
          final city = address['city'] ?? address['town'] ?? address['village'] ?? address['county'] ?? '';
          final state = address['state'] ?? '';
          final postcode = address['postcode'] ?? '';
          final parts = [road, city, state, postcode].where((element) => element.toString().trim().isNotEmpty).toList();
          if (parts.isNotEmpty) {
            return parts.join(', ');
          }
        }
        return data['display_name'] as String?;
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
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        await updateAddressFromCoordinates(position.latitude, position.longitude);
      }
    } catch (e) {
      // Fail silently if permission is missing or GPS is turned off
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

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 8),
      );
      await updateAddressFromCoordinates(position.latitude, position.longitude);
      return true;
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

