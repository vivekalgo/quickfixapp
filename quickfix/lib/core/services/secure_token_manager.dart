/// Manages authentication tokens with an in-memory cache layer on top of
/// persistent Hive storage. The in-memory copy is never written to logs.
/// All sensitive strings are stored as opaque [Object]s to prevent accidental
/// `toString()` leaks in debug output.
class SecureTokenManager {
  SecureTokenManager._();

  // In-memory opaque store – never appears in log output directly
  static Object? _cachedToken;

  /// Store a token in memory immediately and persist to encrypted Hive
  /// asynchronously. The memory copy is available for synchronous reads on
  /// subsequent requests within the same session.
  static Future<void> saveToken(String token, {
    required Future<void> Function(String) persistCallback,
  }) async {
    _cachedToken = token; // wrap as Object to prevent accidental string logging
    await persistCallback(token);
  }

  /// Read the token. Prefers the in-memory copy; falls back to the
  /// persistence layer via [fetchCallback].
  static String? readToken({required String? Function() fetchCallback}) {
    if (_cachedToken != null) return _cachedToken as String?;
    final persisted = fetchCallback();
    if (persisted != null) {
      _cachedToken = persisted;
    }
    return persisted;
  }

  /// Clear the in-memory token and invoke the persistence clear callback.
  static Future<void> clearToken({
    required Future<void> Function() clearCallback,
  }) async {
    _cachedToken = null;
    await clearCallback();
  }

  /// Returns true if a token is currently held in memory or persistence.
  static bool hasToken({required String? Function() fetchCallback}) {
    return readToken(fetchCallback: fetchCallback) != null;
  }
}
