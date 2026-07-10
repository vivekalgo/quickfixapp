import '../../data/models/home_models.dart';

abstract class HomeRepository {
  Future<List<ServiceCategory>> getCategories();
  Future<List<Shop>> getNearbyShops({String? filter, double? lat, double? lng});
  Future<List<Professional>> getTopProfessionals();
  Future<List<Review>> getCustomerReviews();
  Future<List<Shop>> searchShops({required String query, double? lat, double? lng});
  Future<List<PromoBanner>> getBanners();
  Future<List<Promotion>> getPromotions();
  Future<List<SpecialCard>> getSpecialCards();
  Future<List<CmsSection>> getHomepageLayout();
}
