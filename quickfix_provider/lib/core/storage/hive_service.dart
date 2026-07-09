import 'dart:convert';
import 'package:hive/hive.dart';

class HiveService {
  static const String _tokenKey = 'auth_token';
  static const String _shopKey = 'shop_profile';
  static const String _themeModeKey = 'is_dark_mode';

  static Box get _box => Hive.box('provider_settings');

  // Token
  static Future<void> saveAuthToken(String token) async {
    await _box.put(_tokenKey, token);
  }

  static String? getAuthToken() {
    return _box.get(_tokenKey) as String?;
  }

  static Future<void> clearAuthToken() async {
    await _box.delete(_tokenKey);
  }

  // Shop Profile
  static Future<void> saveShopProfile(Map<String, dynamic> shop) async {
    await _box.put(_shopKey, jsonEncode(shop));
  }

  static Map<String, dynamic>? getShopProfile() {
    final data = _box.get(_shopKey) as String?;
    if (data == null) return null;
    try {
      return jsonDecode(data) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  static Future<void> clearShopProfile() async {
    await _box.delete(_shopKey);
  }

  // Theme Mode
  static Future<void> saveDarkMode(bool isDark) async {
    await _box.put(_themeModeKey, isDark);
  }

  static bool isDarkMode() {
    return _box.get(_themeModeKey, defaultValue: true) as bool;
  }

  // Complete logout
  static Future<void> clearSession() async {
    await clearAuthToken();
    await clearShopProfile();
  }
}
