import 'package:flutter_test/flutter_test.dart';
import 'package:quickfix/features/home/models/home_models.dart';

void main() {
  group('Shop Model Filter Tests', () {
    test('estimatedTimeMinutes parses standard duration texts', () {
      const shop15 = Shop(
        id: '1',
        name: 'Plumbing Shop',
        categories: ['Plumbing'],
        rating: 4.8,
        reviewsCount: 10,
        distanceKm: 1.5,
        deliveryTimeMins: 15,
        estimatedServiceTime: '15 mins',
        priceRange: '₹',
        imagePath: '',
        ownerName: '',
        phone: '',
        email: '',
        address: '',
        visitingCharges: 100,
        timings: '',
        isOpen: true,
        portfolioImages: [],
        services: [],
        technicians: [],
      );

      const shop30 = Shop(
        id: '2',
        name: 'Cleaning Shop',
        categories: ['Cleaning'],
        rating: 4.9,
        reviewsCount: 15,
        distanceKm: 2.0,
        deliveryTimeMins: 30,
        estimatedServiceTime: '30 mins',
        priceRange: '₹₹₹',
        imagePath: '',
        ownerName: '',
        phone: '',
        email: '',
        address: '',
        visitingCharges: 150,
        timings: '',
        isOpen: true,
        portfolioImages: [],
        services: [],
        technicians: [],
      );

      const shopDefault = Shop(
        id: '3',
        name: 'Default Shop',
        categories: ['Electrician'],
        rating: 4.5,
        reviewsCount: 5,
        distanceKm: 2.5,
        deliveryTimeMins: 20,
        estimatedServiceTime: null,
        priceRange: '₹₹',
        imagePath: '',
        ownerName: '',
        phone: '',
        email: '',
        address: '',
        visitingCharges: 120,
        timings: '',
        isOpen: true,
        portfolioImages: [],
        services: [],
        technicians: [],
      );

      // Verify estimatedTimeMinutes parsing
      expect(shop15.estimatedTimeMinutes, equals(15));
      expect(shop30.estimatedTimeMinutes, equals(30));
      expect(shopDefault.estimatedTimeMinutes, equals(20));

      // Test "Fast Delivery" filter (<= 25 mins)
      final List<Shop> shops = [shop15, shop30, shopDefault];
      final fastShops = shops.where((s) => s.estimatedTimeMinutes <= 25).toList();
      expect(fastShops.length, equals(2));
      expect(fastShops.any((s) => s.name == 'Plumbing Shop'), isTrue);
      expect(fastShops.any((s) => s.name == 'Default Shop'), isTrue);
      expect(fastShops.any((s) => s.name == 'Cleaning Shop'), isFalse);

      // Test "Affordable" filter (₹ or ₹₹)
      final affordableShops = shops.where((s) => s.priceRange == '₹' || s.priceRange == '₹₹').toList();
      expect(affordableShops.length, equals(2));
      expect(affordableShops.any((s) => s.name == 'Plumbing Shop'), isTrue);
      expect(affordableShops.any((s) => s.name == 'Default Shop'), isTrue);
      expect(affordableShops.any((s) => s.name == 'Cleaning Shop'), isFalse);
    });
  });
}
