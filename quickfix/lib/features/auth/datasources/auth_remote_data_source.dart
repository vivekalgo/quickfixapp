import 'package:quickfix/core/network/dio_client.dart';
import 'package:quickfix/core/network/api_endpoints.dart';
import 'package:quickfix/core/network/api_response_validator.dart';

class AuthRemoteDataSource {
  final DioClient _client;

  AuthRemoteDataSource(this._client);

  Future<void> sendOtp(String phoneNumber) async {
    await _client.post(
      ApiEndpoints.sendOtp,
      data: {'phoneNumber': phoneNumber},
    );
  }

  Future<Map<String, dynamic>> verifyOtp(
    String phoneNumber,
    String code, {
    String? firebaseToken,
  }) async {
    final response = await _client.post(
      ApiEndpoints.verifyOtp,
      data: {
        'phoneNumber': phoneNumber,
        'code': code,
        if (firebaseToken != null) 'firebaseToken': firebaseToken,
      },
    );
    return ApiResponseValidator.requireMap(
      response.data,
      requiredKeys: ['token'],
      context: 'verifyOtp',
    );
  }

  Future<Map<String, dynamic>> getProfile() async {
    final response = await _client.get(ApiEndpoints.profile);
    return ApiResponseValidator.requireMap(
      response.data,
      context: 'getProfile',
    );
  }

  Future<Map<String, dynamic>> updateProfile(
    Map<String, dynamic> updateData,
  ) async {
    final response = await _client.post(
      '/auth/profile/update',
      data: updateData,
    );
    return ApiResponseValidator.requireMap(
      response.data,
      context: 'updateProfile',
    );
  }

  Future<Map<String, dynamic>> addMoney(double amount) async {
    final response = await _client.post(
      '/wallet/add-money',
      data: {'amount': amount},
    );
    return ApiResponseValidator.requireMap(response.data, context: 'addMoney');
  }

  /// Upload avatar as base64. Returns the stored avatarUrl.
  Future<String> uploadAvatar(String base64Image, String mimeType) async {
    final response = await _client.post(
      '/auth/profile/upload-avatar',
      data: {'base64Image': base64Image, 'mimeType': mimeType},
    );
    final data = ApiResponseValidator.requireMap(
      response.data,
      context: 'uploadAvatar',
    );
    return ApiResponseValidator.getString(data, 'avatarUrl');
  }

  /// Get referral code + stats for current user.
  Future<Map<String, dynamic>> getReferralInfo() async {
    final response = await _client.get('/auth/referral');
    return ApiResponseValidator.requireMap(
      response.data,
      context: 'getReferralInfo',
    );
  }

  /// Apply a friend's referral code (called once on first-time user).
  Future<void> applyReferralCode(String code) async {
    await _client.post('/auth/referral/apply', data: {'referralCode': code});
  }

  /// Soft-delete the current user's account.
  Future<void> deleteAccount() async {
    await _client.delete('/auth/account');
  }
}
