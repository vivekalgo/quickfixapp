import 'package:flutter/material.dart';
import '../../data/models/home_models.dart';
import '../../domain/repositories/home_repository.dart';
import '../sources/home_remote_data_source.dart';

class HomeRepositoryImpl implements HomeRepository {
  final HomeRemoteDataSource _remoteDataSource;

  HomeRepositoryImpl(this._remoteDataSource);

  @override
  Future<List<ServiceCategory>> getCategories() async {
    try {
      return await _remoteDataSource.getCategories();
    } catch (e) {
      return const [];
    }
  }

  @override
  Future<List<Shop>> getNearbyShops({String? filter, double? lat, double? lng}) async {
    try {
      return await _remoteDataSource.getNearbyShops(filter: filter, lat: lat, lng: lng);
    } catch (e) {
      return const [];
    }
  }

  @override
  Future<List<Professional>> getTopProfessionals() async {
    try {
      return await _remoteDataSource.getTopProfessionals();
    } catch (e) {
      return const [];
    }
  }

  @override
  Future<List<Review>> getCustomerReviews() async {
    try {
      return await _remoteDataSource.getCustomerReviews();
    } catch (e) {
      return const [];
    }
  }

  @override
  Future<List<Shop>> searchShops({required String query, double? lat, double? lng}) async {
    try {
      return await _remoteDataSource.searchShops(query: query, lat: lat, lng: lng);
    } catch (e) {
      return const [];
    }
  }

  @override
  Future<List<PromoBanner>> getBanners() async {
    try {
      return await _remoteDataSource.getBanners();
    } catch (e) {
      return const [];
    }
  }

  @override
  Future<List<Promotion>> getPromotions() async {
    try {
      return await _remoteDataSource.getPromotions();
    } catch (e) {
      return const [];
    }
  }

  @override
  Future<List<SpecialCard>> getSpecialCards() async {
    try {
      return await _remoteDataSource.getSpecialCards();
    } catch (e) {
      return const [];
    }
  }

  @override
  Future<List<CmsSection>> getHomepageLayout() async {
    try {
      return await _remoteDataSource.getHomepageLayout();
    } catch (e) {
      return const [];
    }
  }
}
