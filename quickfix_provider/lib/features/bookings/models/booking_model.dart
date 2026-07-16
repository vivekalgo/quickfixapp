class BookingModel {
  final String id;
  final String customerId;
  final String customerName;
  final String customerPhone;
  final String customerAddress;
  final String approxAddress;
  final double? customerLat;
  final double? customerLng;
  final double? providerLat;
  final double? providerLng;
  final String shopId;
  final String title;
  final String slot;
  final DateTime date;
  final double amount;
  final double visitingCharges;
  final double estEarnings;
  final String estDuration;
  final String specialInstructions;
  final double customerRating;
  final String status;
  final String providerName;
  final String pricingType;
  final Map<String, dynamic>? quotation;
  final List<dynamic>? quotationHistory;

  BookingModel({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    required this.customerAddress,
    required this.approxAddress,
    this.customerLat,
    this.customerLng,
    this.providerLat,
    this.providerLng,
    required this.shopId,
    required this.title,
    required this.slot,
    required this.date,
    required this.amount,
    required this.visitingCharges,
    required this.estEarnings,
    required this.estDuration,
    required this.specialInstructions,
    required this.customerRating,
    required this.status,
    required this.providerName,
    required this.pricingType,
    this.quotation,
    this.quotationHistory,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    return BookingModel(
      id: json['id']?.toString() ?? '',
      customerId: json['customerId']?.toString() ?? '',
      customerName: json['customerName']?.toString() ?? '',
      customerPhone: json['customerPhone']?.toString() ?? '',
      customerAddress: json['customerAddress']?.toString() ?? '',
      approxAddress: json['approxAddress']?.toString() ?? '',
      customerLat: (json['customerLat'] as num?)?.toDouble(),
      customerLng: (json['customerLng'] as num?)?.toDouble(),
      providerLat: (json['providerLat'] as num?)?.toDouble(),
      providerLng: (json['providerLng'] as num?)?.toDouble(),
      shopId: json['shopId']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      slot: json['slot']?.toString() ?? '09:00 AM - 10:00 AM',
      date: json['date'] != null
          ? DateTime.parse(json['date'].toString())
          : DateTime.now(),
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      visitingCharges: (json['visitingCharges'] as num?)?.toDouble() ?? 150.0,
      estEarnings: (json['estEarnings'] as num?)?.toDouble() ?? 0.0,
      estDuration: json['estDuration']?.toString() ?? '1.5 hrs',
      specialInstructions: json['specialInstructions']?.toString() ?? '',
      customerRating: (json['customerRating'] as num?)?.toDouble() ?? 4.8,
      status: json['status']?.toString() ?? 'pending',
      providerName: json['providerName']?.toString() ?? '',
      pricingType: json['pricingType']?.toString() ?? 'fixed',
      quotation: json['quotation'] as Map<String, dynamic>?,
      quotationHistory: json['quotationHistory'] as List<dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customerId': customerId,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'customerAddress': customerAddress,
      'approxAddress': approxAddress,
      'customerLat': customerLat,
      'customerLng': customerLng,
      'providerLat': providerLat,
      'providerLng': providerLng,
      'shopId': shopId,
      'title': title,
      'slot': slot,
      'date': date.toIso8601String(),
      'amount': amount,
      'visitingCharges': visitingCharges,
      'estEarnings': estEarnings,
      'estDuration': estDuration,
      'specialInstructions': specialInstructions,
      'customerRating': customerRating,
      'status': status,
      'providerName': providerName,
      'pricingType': pricingType,
      'quotation': quotation,
      'quotationHistory': quotationHistory,
    };
  }

  // Helper method to check if customer details are currently hidden/masked
  bool get isDetailsMasked {
    return status == 'pending' || status == 'rejected';
  }
}
