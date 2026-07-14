import 'package:hive_flutter/hive_flutter.dart';
import 'dart:convert';

class HiveService {
  static const String _settingsBox = 'app_settings';
  static const String _cacheBox = 'app_cache';

  static List<int> _getEncryptionKey() {
    // Dynamically derive the 32-byte key from obfuscated segments to prevent static string extraction.
    final part1 = base64.decode('UXVpY2tGaXhBcHBT'); // "QuickFixAppS" in base64
    final part2 = base64.decode('ZWN1cmVMb2NhbFM='); // "ecureLocalS" in base64
    final part3 = base64.decode('dG9yYWdlU2FsdDIwMjY='); // "torageSalt2026" in base64
    
    final decoded = [...part1, ...part2, ...part3];
    final key = List<int>.filled(32, 0);
    for (int i = 0; i < decoded.length && i < 32; i++) {
      key[i] = decoded[i];
    }
    return key;
  }

  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(_settingsBox);
    await Hive.openBox('local_notifications');
    await Hive.openBox(
      _cacheBox,
      encryptionCipher: HiveAesCipher(_getEncryptionKey()),
    );
  }

  // Theme Setting
  static bool isDarkMode() {
    final box = Hive.box(_settingsBox);
    return box.get('is_dark_mode', defaultValue: false) as bool;
  }

  static Future<void> setDarkMode(bool isDark) async {
    final box = Hive.box(_settingsBox);
    await box.put('is_dark_mode', isDark);
  }

  // Onboarding Setting
  static bool isOnboardingComplete() {
    final box = Hive.box(_settingsBox);
    return box.get('onboarding_complete', defaultValue: false) as bool;
  }

  static Future<void> setOnboardingComplete() async {
    final box = Hive.box(_settingsBox);
    await box.put('onboarding_complete', true);
  }

  // Initial permission flow setting
  static bool isInitialPermissionFlowComplete() {
    final box = Hive.box(_settingsBox);
    return box.get('initial_permission_flow_complete', defaultValue: false) as bool;
  }

  static Future<void> setInitialPermissionFlowComplete() async {
    final box = Hive.box(_settingsBox);
    await box.put('initial_permission_flow_complete', true);
  }

  // Authentication Cache
  static String? getAuthToken() {
    final box = Hive.box(_cacheBox);
    return box.get('auth_token') as String?;
  }

  static Future<void> saveAuthToken(String token) async {
    final box = Hive.box(_cacheBox);
    await box.put('auth_token', token);
  }

  static Future<void> clearAuthToken() async {
    final box = Hive.box(_cacheBox);
    await box.delete('auth_token');
  }

  // Profile Cache
  static Map<String, dynamic>? getCachedProfile() {
    final box = Hive.box(_cacheBox);
    final data = box.get('cached_profile');
    if (data == null) return null;
    return Map<String, dynamic>.from(data as Map);
  }

  static Future<void> saveCachedProfile(Map<String, dynamic> profile) async {
    final box = Hive.box(_cacheBox);
    await box.put('cached_profile', profile);
  }

  static Future<void> clearCachedProfile() async {
    final box = Hive.box(_cacheBox);
    await box.delete('cached_profile');
  }

  // Address Cache
  static Map<String, dynamic>? getActiveLocation() {
    final box = Hive.box(_cacheBox);
    final data = box.get('active_location');
    if (data == null) return null;
    try {
      if (data is String) {
        return jsonDecode(data) as Map<String, dynamic>;
      }
      return Map<String, dynamic>.from(data as Map);
    } catch (_) {
      return null;
    }
  }

  static Future<void> saveActiveLocation(String address, double lat, double lng) async {
    final box = Hive.box(_cacheBox);
    final loc = {'address': address, 'latitude': lat, 'longitude': lng};
    await box.put('active_location', loc);
    await box.put('saved_address', address);
  }

  static String getSavedAddress() {
    final box = Hive.box(_cacheBox);
    return box.get('saved_address', defaultValue: '') as String;
  }

  static Future<void> saveAddress(String address, {double lat = 0.0, double lng = 0.0}) async {
    final box = Hive.box(_cacheBox);
    final savedAddresses = getSavedAddresses();
    
    final newLoc = {'address': address, 'latitude': lat, 'longitude': lng};
    final jsonStr = jsonEncode(newLoc);

    final filtered = savedAddresses.where((item) {
      if (item.trim().isEmpty) return false;
      if (item.startsWith('{')) {
        try {
          final parsed = jsonDecode(item) as Map<String, dynamic>;
          return parsed['address'] != address;
        } catch (_) {
          return true;
        }
      }
      return item != address;
    }).toList();

    final updated = [jsonStr, ...filtered].take(5).toList();
    await box.put('saved_addresses', updated);
    await box.put('saved_address', address);
    await box.put('active_location', newLoc);
  }

  static List<String> getSavedAddresses() {
    final box = Hive.box(_cacheBox);
    final list = box.get('saved_addresses', defaultValue: <String>[]) as List;
    return list.map((e) => e.toString()).toList();
  }

  // Search History Cache
  static List<String> getSearchHistory() {
    final box = Hive.box(_cacheBox);
    final history = box.get('search_history', defaultValue: <String>[]) as List;
    return history.map((e) => e.toString()).toList();
  }

  static Future<void> addSearchQuery(String query) async {
    if (query.trim().isEmpty) return;
    final box = Hive.box(_cacheBox);
    final history = getSearchHistory();
    history.remove(query);
    history.insert(0, query);
    if (history.length > 10) history.removeLast();
    await box.put('search_history', history);
  }

  static Future<void> clearSearchHistory() async {
    final box = Hive.box(_cacheBox);
    await box.put('search_history', <String>[]);
  }

  // Wishlist / Favourites Cache
  static List<String> getFavouriteProviderIds() {
    final box = Hive.box(_cacheBox);
    final list = box.get('favourite_providers', defaultValue: <String>[]) as List;
    return list.map((e) => e.toString()).toList();
  }

  static Future<void> toggleFavouriteProvider(String providerId) async {
    final box = Hive.box(_cacheBox);
    final list = getFavouriteProviderIds();
    if (list.contains(providerId)) {
      list.remove(providerId);
    } else {
      list.add(providerId);
    }
    await box.put('favourite_providers', list);
  }

  // Read Notifications Cache
  static List<String> getReadNotificationIds() {
    final box = Hive.box(_cacheBox);
    final list = box.get('read_notifications', defaultValue: <String>[]) as List;
    return list.map((e) => e.toString()).toList();
  }

  static Future<void> markNotificationAsRead(String notificationId) async {
    final box = Hive.box(_cacheBox);
    final list = getReadNotificationIds();
    if (!list.contains(notificationId)) {
      list.add(notificationId);
      await box.put('read_notifications', list);
    }
  }
}
