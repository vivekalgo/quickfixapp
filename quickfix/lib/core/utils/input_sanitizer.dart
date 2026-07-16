/// Client-side input sanitization and validation helpers.
/// Centralizes all input checking so business logic never receives raw,
/// unvalidated user input.
class InputSanitizer {
  InputSanitizer._();

  // ── Phone Number ──────────────────────────────────────────────────────────
  static final RegExp _phoneRegExp = RegExp(r'^\d{10}$');

  /// Returns true if [phone] is exactly 10 digits.
  static bool isValidPhone(String phone) => _phoneRegExp.hasMatch(phone.trim());

  // ── OTP ───────────────────────────────────────────────────────────────────
  static final RegExp _otpRegExp = RegExp(r'^\d{6}$');

  /// Returns true if [otp] is exactly 6 digits.
  static bool isValidOtp(String otp) => _otpRegExp.hasMatch(otp.trim());

  // ── Name ──────────────────────────────────────────────────────────────────
  /// Returns true if [name] is non-empty and ≤ 100 characters.
  static bool isValidName(String name) {
    final trimmed = name.trim();
    return trimmed.isNotEmpty && trimmed.length <= 100;
  }

  // ── Email ─────────────────────────────────────────────────────────────────
  static final RegExp _emailRegExp = RegExp(
    r'^[\w\-\.+]+@([\w\-]+\.)+[\w\-]{2,}$',
    caseSensitive: false,
  );

  /// Returns true if [email] is a valid email address.
  static bool isValidEmail(String email) => _emailRegExp.hasMatch(email.trim());

  // ── Referral Code ─────────────────────────────────────────────────────────
  static final RegExp _referralRegExp = RegExp(r'^[A-Za-z0-9]{4,12}$');

  /// Returns true if [code] is an alphanumeric string of 4–12 characters.
  static bool isValidReferralCode(String code) =>
      _referralRegExp.hasMatch(code.trim());

  // ── General String Sanitization ───────────────────────────────────────────

  /// Trims and strips HTML/script tags to prevent XSS-like injection in text.
  static String sanitize(String input) {
    return input
        .trim()
        .replaceAll(RegExp(r'<[^>]*>'), '') // strip HTML tags
        .replaceAll(
          RegExp(r'[\x00-\x08\x0B-\x0C\x0E-\x1F]'),
          '',
        ); // strip control chars
  }

  /// Strips all characters except digits.
  static String digitsOnly(String input) =>
      input.replaceAll(RegExp(r'[^\d]'), '');

  /// Truncates [input] to [maxLength] characters.
  static String truncate(String input, int maxLength) {
    final s = input.trim();
    return s.length <= maxLength ? s : s.substring(0, maxLength);
  }
}
