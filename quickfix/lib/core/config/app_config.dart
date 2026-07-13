class AppConfig {
  /// Razorpay key credential managed via compile-time environment variable flags
  static const String razorpayKey = String.fromEnvironment(
    'RAZORPAY_KEY',
    defaultValue: 'rzp_test_TBOQ0xGYrMCEEW',
  );
}
