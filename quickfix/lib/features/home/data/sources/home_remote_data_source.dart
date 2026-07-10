import 'package:flutter/material.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../models/home_models.dart';

class HomeRemoteDataSource {
  final DioClient _client;

  HomeRemoteDataSource(this._client);

  Future<List<ServiceCategory>> getCategories() async {
    final response = await _client.get(ApiEndpoints.categories);
    final data = response.data as List;
    
    // Parse categories from REST response
    return data.map((json) {
      final id = json['id']?.toString() ?? '';
      // Map domain icons and colors dynamically based on category IDs
      return ServiceCategory(
        id: id,
        name: json['name']?.toString() ?? '',
        icon: _parseIcon(id),
        backgroundColor: _parseColor(id, isBg: true),
        iconColor: _parseColor(id, isBg: false),
        iconUrl: json['iconUrl']?.toString() ?? json['imageUrl']?.toString(),
      );
    }).toList();
  }

  Future<List<Shop>> getNearbyShops({String? filter, double? lat, double? lng}) async {
    final Map<String, dynamic> query = {};
    if (filter != null && filter != 'All') {
      query['filter'] = filter;
    }
    if (lat != null && lng != null) {
      query['lat'] = lat;
      query['lng'] = lng;
    }
    
    final response = await _client.get(ApiEndpoints.shops, queryParameters: query);
    final data = response.data as List;

    return data.map((json) {
      return Shop.fromJson(json as Map<String, dynamic>);
    }).toList();
  }

  Future<List<Shop>> searchShops({required String query, double? lat, double? lng}) async {
    final Map<String, dynamic> queryParams = {'q': query};
    if (lat != null && lng != null) {
      queryParams['lat'] = lat;
      queryParams['lng'] = lng;
    }
    
    final response = await _client.get('/shops/search', queryParameters: queryParams);
    final data = response.data as List;

    return data.map((json) {
      return Shop.fromJson(json as Map<String, dynamic>);
    }).toList();
  }

  Future<List<PromoBanner>> getBanners() async {
    final response = await _client.get(ApiEndpoints.banners);
    final data = response.data as List;
    return data.map((json) => PromoBanner.fromJson(json as Map<String, dynamic>)).toList();
  }

  Future<List<Professional>> getTopProfessionals() async {
    final response = await _client.get(ApiEndpoints.professionals);
    final data = response.data as List;
    return data.map((json) => Professional.fromJson(json as Map<String, dynamic>)).toList();
  }

  Future<List<Review>> getCustomerReviews() async {
    final response = await _client.get(ApiEndpoints.reviews);
    final data = response.data as List;
    return data.map((json) => Review.fromJson(json as Map<String, dynamic>)).toList();
  }

  Future<List<Promotion>> getPromotions() async {
    final response = await _client.get(ApiEndpoints.promotions);
    final data = response.data as List;
    return data.map((json) => Promotion.fromJson(json as Map<String, dynamic>)).toList();
  }

  Future<List<SpecialCard>> getSpecialCards() async {
    final response = await _client.get(ApiEndpoints.specialCards);
    final data = response.data as List;
    return data.map((json) => SpecialCard.fromJson(json as Map<String, dynamic>)).toList();
  }

  Future<List<CmsSection>> getHomepageLayout() async {
    final response = await _client.get(ApiEndpoints.homepageLayout);
    final data = response.data as List;
    return data.map((json) => CmsSection.fromJson(json as Map<String, dynamic>)).toList();
  }

  // Helper icons and color utilities
  IconData _parseIcon(String id) {
    switch (id) {
      case 'cleaning':
        return Icons.cleaning_services_outlined;
      case 'plumbing':
        return Icons.plumbing_outlined;
      case 'electrician':
        return Icons.bolt_outlined;
      case 'appliances':
        return Icons.local_laundry_service_outlined;
      case 'carpentry':
        return Icons.carpenter_outlined;
      default:
        return Icons.grid_view_outlined;
    }
  }

  Color _parseColor(String id, {required bool isBg}) {
    // Dynamic color matching
    if (isBg) {
      switch (id) {
        case 'cleaning': return const Color(0xFFEEF2FF);
        case 'plumbing': return const Color(0xFFECFDF5);
        case 'electrician': return const Color(0xFFFFFBEB);
        case 'appliances': return const Color(0xFFF5F3FF);
        case 'carpentry': return const Color(0xFFFFF7ED);
        default: return const Color(0xFFF1F5F9);
      }
    } else {
      switch (id) {
        case 'cleaning': return const Color(0xFF4F46E5);
        case 'plumbing': return const Color(0xFF059669);
        case 'electrician': return const Color(0xFFD97706);
        case 'appliances': return const Color(0xFF7C3AED);
        case 'carpentry': return const Color(0xFFEA580C);
        default: return const Color(0xFF475569);
      }
    }
  }
}
