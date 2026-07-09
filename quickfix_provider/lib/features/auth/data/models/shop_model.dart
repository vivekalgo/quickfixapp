class ShopModel {
  final String id;
  final String shopDisplayId;
  final String name;
  final String ownerName;
  final String phone;
  final String email;
  final double latitude;
  final double longitude;
  final String address;
  final double serviceRadius;
  final bool isOnline;
  final String timings;
  final String status;
  final String verificationStatus;
  final double visitingCharges;
  final bool isFirstLogin;
  final String bankAccountNumber;
  final String ifscCode;
  final String upiId;
  final String gst;
  final String pan;
  final double walletBalance;
  final Map<String, dynamic> workingHours;
  final List<String> holidays;
  final bool emergencyAvailable;
  final double rating;
  final List<String> portfolioImages;

  ShopModel({
    required this.id,
    required this.shopDisplayId,
    required this.name,
    required this.ownerName,
    required this.phone,
    required this.email,
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.serviceRadius,
    required this.isOnline,
    required this.timings,
    required this.status,
    required this.verificationStatus,
    required this.visitingCharges,
    required this.isFirstLogin,
    required this.bankAccountNumber,
    required this.ifscCode,
    required this.upiId,
    required this.gst,
    required this.pan,
    required this.walletBalance,
    required this.workingHours,
    required this.holidays,
    required this.emergencyAvailable,
    required this.rating,
    required this.portfolioImages,
  });

  factory ShopModel.fromJson(Map<String, dynamic> json) {
    return ShopModel(
      id: json['id']?.toString() ?? '',
      shopDisplayId: json['shopDisplayId']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      ownerName: json['ownerName']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 26.4912,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 80.3156,
      address: json['address']?.toString() ?? '',
      serviceRadius: (json['serviceRadius'] as num?)?.toDouble() ?? 5.0,
      isOnline: json['isOnline'] as bool? ?? true,
      timings: json['timings']?.toString() ?? '09:00 AM - 09:00 PM',
      status: json['status']?.toString() ?? 'active',
      verificationStatus: json['verificationStatus']?.toString() ?? 'approved',
      visitingCharges: (json['visitingCharges'] as num?)?.toDouble() ?? 150.0,
      isFirstLogin: json['isFirstLogin'] as bool? ?? false,
      bankAccountNumber: json['bankAccountNumber']?.toString() ?? '',
      ifscCode: json['ifscCode']?.toString() ?? '',
      upiId: json['upiId']?.toString() ?? '',
      gst: json['gst']?.toString() ?? '',
      pan: json['pan']?.toString() ?? '',
      walletBalance: (json['walletBalance'] as num?)?.toDouble() ?? 0.0,
      workingHours: json['workingHours'] is Map ? Map<String, dynamic>.from(json['workingHours'] as Map) : {},
      holidays: json['holidays'] is List ? List<String>.from(json['holidays'] as List) : [],
      emergencyAvailable: json['emergencyAvailable'] as bool? ?? false,
      rating: (json['rating'] as num?)?.toDouble() ?? 4.5,
      portfolioImages: json['portfolioImages'] is List ? List<String>.from(json['portfolioImages'] as List) : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'shopDisplayId': shopDisplayId,
      'name': name,
      'ownerName': ownerName,
      'phone': phone,
      'email': email,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'serviceRadius': serviceRadius,
      'isOnline': isOnline,
      'timings': timings,
      'status': status,
      'verificationStatus': verificationStatus,
      'visitingCharges': visitingCharges,
      'isFirstLogin': isFirstLogin,
      'bankAccountNumber': bankAccountNumber,
      'ifscCode': ifscCode,
      'upiId': upiId,
      'gst': gst,
      'pan': pan,
      'walletBalance': walletBalance,
      'workingHours': workingHours,
      'holidays': holidays,
      'emergencyAvailable': emergencyAvailable,
      'rating': rating,
      'portfolioImages': portfolioImages,
    };
  }
}
