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

class Shop {
  final String id;
  final String name;
  final List<String> categories;
  final double rating;
  final double distanceKm;
  final int deliveryTimeMins;
  final String priceRange;
  final String imagePath;

  const Shop({
    required this.id,
    required this.name,
    required this.categories,
    required this.rating,
    required this.distanceKm,
    required this.deliveryTimeMins,
    required this.priceRange,
    required this.imagePath,
  });
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
