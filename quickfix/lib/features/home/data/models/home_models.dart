import 'package:flutter/material.dart';

class ServiceCategory {
  final String id;
  final String name;
  final IconData icon;
  final Color backgroundColor;
  final Color iconColor;

  const ServiceCategory({
    required this.id,
    required this.name,
    required this.icon,
    required this.backgroundColor,
    required this.iconColor,
  });
}

class ShopService {
  final String id;
  final String title;
  final double price;
  final double originalPrice;
  final double rating;
  final int reviewsCount;
  final String durationText;
  final List<String> bulletPoints;
  final String imageUrl;

  const ShopService({
    required this.id,
    required this.title,
    required this.price,
    required this.originalPrice,
    required this.rating,
    required this.reviewsCount,
    required this.durationText,
    required this.bulletPoints,
    required this.imageUrl,
  });

  factory ShopService.fromJson(Map<String, dynamic> json) {
    return ShopService(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      price: double.tryParse(json['price']?.toString() ?? '0.0') ?? 0.0,
      originalPrice: double.tryParse(json['originalPrice']?.toString() ?? '0.0') ?? 0.0,
      rating: double.tryParse(json['rating']?.toString() ?? '5.0') ?? 5.0,
      reviewsCount: int.tryParse(json['reviewsCount']?.toString() ?? '0') ?? 0,
      durationText: json['durationText']?.toString() ?? '1 hr',
      bulletPoints: (json['bulletPoints'] as List?)?.map((e) => e.toString()).toList() ?? [],
      imageUrl: json['imageUrl']?.toString() ?? '',
    );
  }
}

class Shop {
  final String id;
  final String name;
  final List<String> categories;
  final double rating;
  final double distanceKm;
  final int deliveryTimeMins;
  final String priceRange;
  final String imagePath;
  final String ownerName;
  final String phone;
  final String email;
  final String address;
  final double visitingCharges;
  final String timings;
  final bool isOpen;
  final List<String> portfolioImages;
  final List<ShopService> services;
  final List<String> technicians;

  const Shop({
    required this.id,
    required this.name,
    required this.categories,
    required this.rating,
    required this.distanceKm,
    required this.deliveryTimeMins,
    required this.priceRange,
    required this.imagePath,
    required this.ownerName,
    required this.phone,
    required this.email,
    required this.address,
    required this.visitingCharges,
    required this.timings,
    required this.isOpen,
    required this.portfolioImages,
    required this.services,
    required this.technicians,
  });

  factory Shop.fromJson(Map<String, dynamic> json) {
    return Shop(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      categories: (json['categories'] as List?)?.map((e) => e.toString()).toList() ?? [],
      rating: double.tryParse(json['rating']?.toString() ?? '4.0') ?? 4.0,
      distanceKm: double.tryParse(json['distanceKm']?.toString() ?? '1.0') ?? 1.0,
      deliveryTimeMins: int.tryParse(json['deliveryTimeMins']?.toString() ?? '15') ?? 15,
      priceRange: json['priceRange']?.toString() ?? '₹',
      imagePath: json['imagePath']?.toString() ?? '',
      ownerName: json['ownerName']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      visitingCharges: double.tryParse(json['visitingCharges']?.toString() ?? '150.0') ?? 150.0,
      timings: json['timings']?.toString() ?? '09:00 AM - 09:00 PM',
      isOpen: json['isOpen'] == null ? true : (json['isOpen'] as bool),
      portfolioImages: (json['portfolioImages'] as List?)?.map((e) => e.toString()).toList() ?? [],
      services: (json['services'] as List?)?.map((e) => ShopService.fromJson(e as Map<String, dynamic>)).toList() ?? [],
      technicians: (json['technicians'] as List?)?.map((e) => e.toString()).toList() ?? [],
    );
  }
}

class Professional {
  final String id;
  final String name;
  final String specialty;
  final double rating;
  final int reviewsCount;
  final String avatarUrl;

  const Professional({
    required this.id,
    required this.name,
    required this.specialty,
    required this.rating,
    required this.reviewsCount,
    required this.avatarUrl,
  });
}

class Review {
  final String id;
  final String userName;
  final String userAvatar;
  final double rating;
  final String comment;
  final String serviceName;
  final String locationName;

  const Review({
    required this.id,
    required this.userName,
    required this.userAvatar,
    required this.rating,
    required this.comment,
    required this.serviceName,
    required this.locationName,
  });
}

class UserLocation {
  final String address;
  final double latitude;
  final double longitude;

  const UserLocation({
    required this.address,
    required this.latitude,
    required this.longitude,
  });

  Map<String, dynamic> toJson() => {
        'address': address,
        'latitude': latitude,
        'longitude': longitude,
      };

  factory UserLocation.fromJson(Map<String, dynamic> json) => UserLocation(
        address: json['address'] as String? ?? '',
        latitude: (json['latitude'] as num?)?.toDouble() ?? 26.4912,
        longitude: (json['longitude'] as num?)?.toDouble() ?? 80.3156,
      );
}

class PromoBanner {
  final String id;
  final String title;
  final String code;
  final String percent;
  final String imageUrl;

  const PromoBanner({
    required this.id,
    required this.title,
    required this.code,
    required this.percent,
    required this.imageUrl,
  });

  factory PromoBanner.fromJson(Map<String, dynamic> json) {
    return PromoBanner(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      percent: json['percent']?.toString() ?? '',
      imageUrl: json['imageUrl']?.toString() ?? '',
    );
  }
}

