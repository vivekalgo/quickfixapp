abstract class AuthRepository {
  Future<void> requestOtp(String phone);
  Future<String> verifyCode(String phone, String code, {String? firebaseToken});
  Future<Map<String, dynamic>> fetchUserProfile();
  Future<Map<String, dynamic>> updateUserProfile(
    Map<String, dynamic> updateData,
  );
  Future<Map<String, dynamic>> addMoneyToWallet(double amount);
  Future<String> uploadAvatar(String base64Image, String mimeType);
  Future<Map<String, dynamic>> getReferralInfo();
  Future<void> applyReferralCode(String code);
  Future<void> deleteAccount();
}
