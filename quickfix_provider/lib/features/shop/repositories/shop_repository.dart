abstract class ShopRepository {
  Future<bool> updateServices(Map<String, dynamic> data);
  Future<String?> uploadServiceImage(String base64Image, String mimeType);
}
