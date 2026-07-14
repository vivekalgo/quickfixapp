import 'package:quickfix/features/home/models/home_models.dart';
import 'package:quickfix/features/home/repositories/home_repository.dart';
import 'package:quickfix/features/home/services/home_remote_data_source.dart';

class HomeRepositoryImpl implements HomeRepository {
  final HomeRemoteDataSource _remoteDataSource;

  HomeRepositoryImpl(this._remoteDataSource);

  @override
  Future<List<ServiceCategory>> getCategories() async {
    return await _remoteDataSource.getCategories();
  }

  @override
  Future<List<Shop>> getNearbyShops({String? filter, double? lat, double? lng}) async {
    return await _remoteDataSource.getNearbyShops(filter: filter, lat: lat, lng: lng);
  }

  @override
  Future<List<Professional>> getTopProfessionals() async {
    return await _remoteDataSource.getTopProfessionals();
  }

  @override
  Future<List<Review>> getCustomerReviews() async {
    return await _remoteDataSource.getCustomerReviews();
  }

  @override
  Future<List<Shop>> searchShops({required String query, double? lat, double? lng}) async {
    return await _remoteDataSource.searchShops(query: query, lat: lat, lng: lng);
  }

  @override
  Future<List<PromoBanner>> getBanners() async {
    return await _remoteDataSource.getBanners();
  }

  @override
  Future<List<Promotion>> getPromotions() async {
    return await _remoteDataSource.getPromotions();
  }

  @override
  Future<List<SpecialCard>> getSpecialCards() async {
    return await _remoteDataSource.getSpecialCards();
  }

  @override
  Future<List<CmsSection>> getHomepageLayout() async {
    return await _remoteDataSource.getHomepageLayout();
  }

  @override
  Future<List<CustomSection>> getCustomSections() async {
    return await _remoteDataSource.getCustomSections();
  }
}
