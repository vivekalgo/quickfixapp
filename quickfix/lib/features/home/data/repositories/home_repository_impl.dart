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
      // Try fetching from the NestJS REST API
      return await _remoteDataSource.getCategories();
    } catch (e) {
      // Fallback offline simulated data if NestJS is not yet deployed
      return const [
        ServiceCategory(
          id: 'cleaning',
          name: 'Cleaning',
          icon: Icons.cleaning_services_outlined,
          backgroundColor: Color(0xFFEEF2FF),
          iconColor: Color(0xFF4F46E5),
        ),
        ServiceCategory(
          id: 'plumbing',
          name: 'Plumbing',
          icon: Icons.plumbing_outlined,
          backgroundColor: Color(0xFFECFDF5),
          iconColor: Color(0xFF059669),
        ),
        ServiceCategory(
          id: 'electrician',
          name: 'Electrician',
          icon: Icons.bolt_outlined,
          backgroundColor: Color(0xFFFFFBEB),
          iconColor: Color(0xFFD97706),
        ),
        ServiceCategory(
          id: 'appliances',
          name: 'Appliances\nRepair',
          icon: Icons.local_laundry_service_outlined,
          backgroundColor: Color(0xFFF5F3FF),
          iconColor: Color(0xFF7C3AED),
        ),
        ServiceCategory(
          id: 'carpentry',
          name: 'Carpentry',
          icon: Icons.carpenter_outlined,
          backgroundColor: Color(0xFFFFF7ED),
          iconColor: Color(0xFFEA580C),
        ),
      ];
    }
  }

  @override
  Future<List<Shop>> getNearbyShops({String? filter, double? lat, double? lng}) async {
    try {
      return await _remoteDataSource.getNearbyShops(filter: filter, lat: lat, lng: lng);
    } catch (e) {
      final allShops = [
        const Shop(
          id: '1',
          name: 'QuickFix Solutions',
          categories: ['Plumbing', 'Electrical'],
          rating: 4.6,
          distanceKm: 1.2,
          deliveryTimeMins: 15,
          priceRange: '₹₹',
          imagePath: 'https://images.unsplash.com/photo-1621905251189-08b45d6a269e?w=500&auto=format&fit=crop&q=60',
        ),
        const Shop(
          id: '2',
          name: 'HomeFix Services',
          categories: ['Cleaning', 'Appliances'],
          rating: 4.4,
          distanceKm: 1.8,
          deliveryTimeMins: 20,
          priceRange: '₹',
          imagePath: 'https://images.unsplash.com/photo-1527515637462-cff94eecc1ac?w=500&auto=format&fit=crop&q=60',
        ),
        const Shop(
          id: '3',
          name: 'FixIt Pro',
          categories: ['Carpentry', 'Painting'],
          rating: 4.7,
          distanceKm: 0.9,
          deliveryTimeMins: 10,
          priceRange: '₹₹',
          imagePath: 'https://images.unsplash.com/photo-1534081333815-ae5019106622?w=500&auto=format&fit=crop&q=60',
        ),
      ];

      if (filter == 'Top Rated') {
        return allShops.where((shop) => shop.rating >= 4.5).toList();
      } else if (filter == 'Fast Delivery') {
        return allShops.where((shop) => shop.deliveryTimeMins <= 15).toList();
      } else if (filter == 'Affordable') {
        return allShops.where((shop) => shop.priceRange == '₹').toList();
      } else if (filter == '4.0+') {
        return allShops.where((shop) => shop.rating >= 4.0).toList();
      }
      return allShops;
    }
  }

  @override
  Future<List<Professional>> getTopProfessionals() async {
    try {
      return await _remoteDataSource.getTopProfessionals();
    } catch (e) {
      return const [
        Professional(
          id: 'p1',
          name: 'Rohan Sharma',
          specialty: 'Expert Electrician',
          rating: 4.9,
          reviewsCount: 320,
          avatarUrl: 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150',
        ),
        Professional(
          id: 'p2',
          name: 'Suresh Kumar',
          specialty: 'Master Plumber',
          rating: 4.8,
          reviewsCount: 240,
          avatarUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150',
        ),
      ];
    }
  }

  @override
  Future<List<Review>> getCustomerReviews() async {
    try {
      return await _remoteDataSource.getCustomerReviews();
    } catch (e) {
      return const [
        Review(
          id: 'r1',
          userName: 'Aman Verma',
          userAvatar: 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150',
          rating: 5.0,
          comment: 'Very quick service! Electrician was very professional and fixed the issue in no time.',
          serviceName: 'Electrician Service',
          locationName: 'Swaroop Nagar',
        ),
        Review(
          id: 'r2',
          userName: 'Neha Singh',
          userAvatar: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=150',
          rating: 5.0,
          comment: 'Booked through QuickFix and got the best plumbing service at a very affordable price.',
          serviceName: 'Plumbing Service',
          locationName: 'Kalyanpur',
        ),
        Review(
          id: 'r3',
          userName: 'Rohit Gupta',
          userAvatar: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150',
          rating: 4.8,
          comment: 'Excellent experience. On-time service and polite staff.',
          serviceName: 'AC Repair',
          locationName: 'Govind Nagar',
        ),
      ];
    }
  }

  @override
  Future<List<Shop>> searchShops({required String query, double? lat, double? lng}) async {
    try {
      return await _remoteDataSource.searchShops(query: query, lat: lat, lng: lng);
    } catch (e) {
      final allShops = await getNearbyShops(lat: lat, lng: lng);
      final clean = query.toLowerCase().trim();
      if (clean.isEmpty) return allShops;
      return allShops.where((s) => s.name.toLowerCase().contains(clean) || s.categories.any((c) => c.toLowerCase().contains(clean))).toList();
    }
  }
}
