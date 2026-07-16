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

  /// Razorpay key credential managed via compile-time environment variable flags.
  /// Hardcoded fallbacks are removed for production security.
  static const String razorpayKey = String.fromEnvironment(
    'RAZORPAY_KEY',
    defaultValue: '',
  );

  /// Returns true if running in production mode
  static bool get isProduction => env.toLowerCase() == 'production';
}
