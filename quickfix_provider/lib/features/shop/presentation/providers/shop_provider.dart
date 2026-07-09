import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/network_providers.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class ShopManagementState {
  final bool isLoading;
  final String? errorMessage;
  final bool isSuccess;

  ShopManagementState({
    this.isLoading = false,
    this.errorMessage,
    this.isSuccess = false,
  });

  ShopManagementState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool? isSuccess,
  }) {
    return ShopManagementState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }
}

class ShopManagementNotifier extends StateNotifier<ShopManagementState> {
  final Ref _ref;

  ShopManagementNotifier(this._ref) : super(ShopManagementState());

  Future<bool> updateOperationalHours({
    required Map<String, dynamic> workingHours,
    required List<String> holidays,
    required double serviceRadius,
    required double visitingCharges,
    required bool emergencyAvailable,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null, isSuccess: false);
    try {
      final success = await _ref.read(authProvider.notifier).updateShopDetails(
        workingHours: workingHours,
        holidays: holidays,
        serviceRadius: serviceRadius,
        visitingCharges: visitingCharges,
        emergencyAvailable: emergencyAvailable,
      );

      if (success) {
        state = ShopManagementState(isSuccess: true);
        return true;
      }
      state = state.copyWith(isLoading: false, errorMessage: 'Failed to update shop parameters.');
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> toggleService(String serviceId, bool isEnabled) async {
    final shop = _ref.read(authProvider).shop;
    if (shop == null) return false;

    state = state.copyWith(isLoading: true, errorMessage: null, isSuccess: false);
    try {
      final dio = _ref.read(dioClientProvider);
      
      // Update local catalog list
      final servicesList = List<Map<String, dynamic>>.from(
        shop.toJson()['services'] as List? ?? []
      );
      
      // Find and update status / pricing if needed, or remove/add
      // For this toggle: we can keep a status flag, or if disabled, set originalPrice to -1.
      // Let's assume we toggle it by updating bulletPoints or we can just filter it.
      // Wait, let's allow updating the services array directly:
      final updatedList = servicesList.map((s) {
        if (s['id'] == serviceId) {
          s['isEnabled'] = isEnabled;
        }
        return s;
      }).toList();

      final response = await dio.post(
        ApiEndpoints.updateServices,
        data: {'services': updatedList},
      );

      if (response.data != null && response.data['success'] == true) {
        await _ref.read(authProvider.notifier).refreshProfile();
        state = ShopManagementState(isSuccess: true);
        return true;
      }
      state = state.copyWith(isLoading: false, errorMessage: 'Failed to toggle service.');
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> updateServicePrice(String serviceId, double newPrice) async {
    final shop = _ref.read(authProvider).shop;
    if (shop == null) return false;

    state = state.copyWith(isLoading: true, errorMessage: null, isSuccess: false);
    try {
      final dio = _ref.read(dioClientProvider);
      final servicesList = List<Map<String, dynamic>>.from(
        shop.toJson()['services'] as List? ?? []
      );
      
      final updatedList = servicesList.map((s) {
        if (s['id'] == serviceId) {
          s['price'] = newPrice;
        }
        return s;
      }).toList();

      final response = await dio.post(
        ApiEndpoints.updateServices,
        data: {'services': updatedList},
      );

      if (response.data != null && response.data['success'] == true) {
        await _ref.read(authProvider.notifier).refreshProfile();
        state = ShopManagementState(isSuccess: true);
        return true;
      }
      state = state.copyWith(isLoading: false, errorMessage: 'Failed to update service price.');
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> addCustomService({
    required String title,
    required double price,
    required String durationText,
    required List<String> bulletPoints,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null, isSuccess: false);
    try {
      final dio = _ref.read(dioClientProvider);
      final response = await dio.post(
        ApiEndpoints.updateServices,
        data: {
          'customService': {
            'title': title,
            'price': price,
            'durationText': durationText,
            'bulletPoints': bulletPoints,
          }
        },
      );

      if (response.data != null && response.data['success'] == true) {
        await _ref.read(authProvider.notifier).refreshProfile();
        state = ShopManagementState(isSuccess: true);
        return true;
      }
      state = state.copyWith(isLoading: false, errorMessage: 'Failed to add custom service.');
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }
}

final shopManagementProvider = StateNotifierProvider<ShopManagementNotifier, ShopManagementState>((ref) {
  return ShopManagementNotifier(ref);
});
