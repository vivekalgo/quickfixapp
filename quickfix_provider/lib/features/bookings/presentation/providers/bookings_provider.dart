import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:quickfix_provider/core/network/api_endpoints.dart';
import 'package:quickfix_provider/core/network/network_providers.dart';
import 'package:quickfix_provider/features/auth/presentation/providers/auth_provider.dart';
import 'package:quickfix_provider/features/dashboard/presentation/providers/dashboard_provider.dart';
import 'package:quickfix_provider/features/bookings/data/models/booking_model.dart';

class BookingsState {
  final bool isLoading;
  final String? errorMessage;
  final List<BookingModel> bookings;
  final BookingModel? selectedBookingDetails;

  BookingsState({
    this.isLoading = false,
    this.errorMessage,
    this.bookings = const [],
    this.selectedBookingDetails,
  });

  BookingsState copyWith({
    bool? isLoading,
    String? errorMessage,
    List<BookingModel>? bookings,
    BookingModel? selectedBookingDetails,
  }) {
    return BookingsState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      bookings: bookings ?? this.bookings,
      selectedBookingDetails: selectedBookingDetails ?? this.selectedBookingDetails,
    );
  }
}

class BookingsNotifier extends StateNotifier<BookingsState> {
  final Ref _ref;
  Timer? _refreshTimer;
  Timer? _trackingTimer;
  StreamSubscription<Position>? _positionSubscription;

  BookingsNotifier(this._ref) : super(BookingsState()) {
    fetchBookings();
    // Auto-refresh bookings every 30 seconds for live requests
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) => fetchBookings(silent: true));
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _trackingTimer?.cancel();
    _positionSubscription?.cancel();
    super.dispose();
  }

  Future<void> fetchBookings({bool silent = false}) async {
    final shop = _ref.read(authProvider).shop;
    if (shop == null) return;

    if (!silent) {
      state = state.copyWith(isLoading: true, errorMessage: null);
    }
    try {
      final dio = _ref.read(dioClientProvider);
      final response = await dio.get(
        ApiEndpoints.bookings,
        queryParameters: {'shopId': shop.id},
      );

      if (response.data is List) {
        final list = (response.data as List)
            .map((b) => BookingModel.fromJson(b as Map<String, dynamic>))
            .toList();
        state = state.copyWith(
          isLoading: false,
          bookings: list,
        );
      } else {
        state = state.copyWith(isLoading: false, errorMessage: 'Invalid bookings response format');
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> fetchBookingDetails(String bookingId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final dio = _ref.read(dioClientProvider);
      final response = await dio.get(ApiEndpoints.bookingDetails(bookingId));
      if (response.data != null) {
        state = state.copyWith(
          isLoading: false,
          selectedBookingDetails: BookingModel.fromJson(response.data as Map<String, dynamic>),
        );
      } else {
        state = state.copyWith(isLoading: false, errorMessage: 'Failed to load booking details');
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<bool> updateStatus(String bookingId, String status) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final dio = _ref.read(dioClientProvider);
      final shop = _ref.read(authProvider).shop;
      final response = await dio.post(
        ApiEndpoints.updateBookingStatus,
        data: {
          'id': bookingId,
          'status': status,
          'providerName': shop?.ownerName ?? 'Partner Service Agent',
        },
      );

      if (response.data != null && response.data['success'] == true) {
        // Refresh stats and listing
        await fetchBookings(silent: true);
        await _ref.read(dashboardProvider.notifier).fetchStats();
        
        // Update currently viewed detail if it is the same one
        if (state.selectedBookingDetails?.id == bookingId) {
          final updatedBooking = BookingModel.fromJson(response.data['booking'] as Map<String, dynamic>);
          state = state.copyWith(isLoading: false, selectedBookingDetails: updatedBooking);
        } else {
          state = state.copyWith(isLoading: false);
        }

        // Manage background tracking depending on new status
        if (status == 'navigating') {
          _startLocationTracking(bookingId);
        } else if (status == 'work_completed' || status == 'payment_completed' || status == 'cancelled' || status == 'closed') {
          _stopLocationTracking();
        }

        return true;
      }
      state = state.copyWith(isLoading: false, errorMessage: 'Failed to update status');
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  // Live Location Tracking during Navigation
  Future<void> _startLocationTracking(String bookingId) async {
    _stopLocationTracking(); // Clear any previous tracking
    
    try {
      // Request permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever || permission == LocationPermission.denied) {
        print('[Tracking]: Geolocator permission denied. Live location update skipped.');
        return;
      }

      // Start coordinates polling
      _positionSubscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10, // Update location every 10 meters
        ),
      ).listen((Position position) async {
        try {
          final dio = _ref.read(dioClientProvider);
          await dio.post(
            ApiEndpoints.updateLocation,
            data: {
              'latitude': position.latitude,
              'longitude': position.longitude,
            },
          );
          print('[Tracking]: Sent partner live coordinates: ${position.latitude}, ${position.longitude}');
        } catch (e) {
          print('[Tracking]: Failed to sync live position: $e');
        }
      });
    } catch (err) {
      print('[Tracking]: Error starting background stream: $err');
    }
  }

  void _stopLocationTracking() {
    _positionSubscription?.cancel();
    _positionSubscription = null;
    _trackingTimer?.cancel();
    _trackingTimer = null;
  }
}

final bookingsProvider = StateNotifierProvider<BookingsNotifier, BookingsState>((ref) {
  return BookingsNotifier(ref);
});
