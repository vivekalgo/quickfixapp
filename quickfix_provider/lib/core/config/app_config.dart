class AppConfig {
  /// The environment name (development, staging, production)
  static const String env = String.fromEnvironment(
    'ENV',
    defaultValue: 'development',
  );

  /// Flag to enable operator DNS bypass (Jio / Airtel workaround)
  static const bool enableDnsBypass = bool.fromEnvironment(
    'ENABLE_DNS_BYPASS',
    defaultValue: true,
  );

  /// Returns true if running in production mode
  static bool get isProduction => env.toLowerCase() == 'production';
}
