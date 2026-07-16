/// Validates API responses at the boundary before they are consumed by
/// repositories or UI layers. Prevents null crashes from unexpected server payloads.
class ApiResponseValidator {
  /// Validates that [data] is a non-null Map and contains all [requiredKeys].
  /// Returns a typed [Map<String, dynamic>] or throws a descriptive [FormatException].
  static Map<String, dynamic> requireMap(
    dynamic data, {
    List<String> requiredKeys = const [],
    String context = 'API Response',
  }) {
    if (data == null) {
      throw FormatException('$context: Response body is null.');
    }
    if (data is! Map) {
      throw FormatException('$context: Expected Map, got ${data.runtimeType}.');
    }
    final map = Map<String, dynamic>.from(data);
    for (final key in requiredKeys) {
      if (!map.containsKey(key)) {
        throw FormatException(
          '$context: Missing required field "$key" in response.',
        );
      }
    }
    return map;
  }

  /// Validates that [data] is a non-null List.
  /// Returns a typed [List<dynamic>] or throws a descriptive [FormatException].
  static List<dynamic> requireList(
    dynamic data, {
    String context = 'API Response',
  }) {
    if (data == null) {
      throw FormatException('$context: Response body is null.');
    }
    if (data is! List) {
      throw FormatException(
        '$context: Expected List, got ${data.runtimeType}.',
      );
    }
    return data;
  }

  /// Safely extracts a String from [map] at [key].
  /// Returns [defaultValue] if key is missing or value is null/non-String.
  static String getString(
    Map<String, dynamic> map,
    String key, {
    String defaultValue = '',
  }) {
    final value = map[key];
    if (value == null) return defaultValue;
    return value.toString();
  }

  /// Safely extracts a nullable String from [map] at [key].
  static String? getStringOrNull(Map<String, dynamic> map, String key) {
    final value = map[key];
    if (value == null) return null;
    return value.toString();
  }

  /// Safely extracts a num from [map] at [key].
  static num getNum(
    Map<String, dynamic> map,
    String key, {
    num defaultValue = 0,
  }) {
    final value = map[key];
    if (value == null) return defaultValue;
    if (value is num) return value;
    return num.tryParse(value.toString()) ?? defaultValue;
  }

  /// Safely extracts a double from [map] at [key].
  static double getDouble(
    Map<String, dynamic> map,
    String key, {
    double defaultValue = 0.0,
  }) => getNum(map, key, defaultValue: defaultValue).toDouble();

  /// Safely extracts an int from [map] at [key].
  static int getInt(
    Map<String, dynamic> map,
    String key, {
    int defaultValue = 0,
  }) => getNum(map, key, defaultValue: defaultValue).toInt();

  /// Safely extracts a bool from [map] at [key].
  static bool getBool(
    Map<String, dynamic> map,
    String key, {
    bool defaultValue = false,
  }) {
    final value = map[key];
    if (value == null) return defaultValue;
    if (value is bool) return value;
    if (value is int) return value != 0;
    return value.toString().toLowerCase() == 'true';
  }

  /// Safely extracts a nested Map from [map] at [key].
  static Map<String, dynamic>? getMap(Map<String, dynamic> map, String key) {
    final value = map[key];
    if (value == null) return null;
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }

  /// Safely extracts a List from [map] at [key].
  static List<dynamic> getList(Map<String, dynamic> map, String key) {
    final value = map[key];
    if (value == null) return [];
    if (value is List) return value;
    return [];
  }
}
