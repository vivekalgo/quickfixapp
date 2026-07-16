import 'package:quickfix_provider/features/auth/models/shop_model.dart';

abstract class AuthRepository {
  Future<ShopModel?> login(String shopId, String password);
  Future<bool> changePassword(String oldPassword, String newPassword);
  Future<ShopModel?> updateShopDetails(Map<String, dynamic> data);
  Future<ShopModel?> getProfile();
  Future<String?> uploadShopBanner(String base64Image, String mimeType);
  Future<List<String>?> uploadPortfolioImage(String base64Image, String mimeType);
  Future<List<String>?> deletePortfolioImage(String imageUrl);
}
