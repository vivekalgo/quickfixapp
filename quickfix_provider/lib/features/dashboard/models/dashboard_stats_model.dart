class DashboardStatsModel {
  final int todayOrders;
  final int pendingOrders;
  final int acceptedOrders;
  final int completedOrders;
  final int cancelledOrders;
  final double revenue;
  final double totalRevenue;
  final double walletBalance;
  final double rating;
  final int reviewsCount;
  final bool isOnline;

  DashboardStatsModel({
    required this.todayOrders,
    required this.pendingOrders,
    required this.acceptedOrders,
    required this.completedOrders,
    required this.cancelledOrders,
    required this.revenue,
    required this.totalRevenue,
    required this.walletBalance,
    required this.rating,
    required this.reviewsCount,
    required this.isOnline,
  });

  factory DashboardStatsModel.fromJson(Map<String, dynamic> json) {
    return DashboardStatsModel(
      todayOrders: json['todayOrders'] as int? ?? 0,
      pendingOrders: json['pendingOrders'] as int? ?? 0,
      acceptedOrders: json['acceptedOrders'] as int? ?? 0,
      completedOrders: json['completedOrders'] as int? ?? 0,
      cancelledOrders: json['cancelledOrders'] as int? ?? 0,
      revenue: (json['revenue'] as num?)?.toDouble() ?? 0.0,
      totalRevenue: (json['totalRevenue'] as num?)?.toDouble() ?? 0.0,
      walletBalance: (json['walletBalance'] as num?)?.toDouble() ?? 0.0,
      rating: (json['rating'] as num?)?.toDouble() ?? 5.0,
      reviewsCount: json['reviewsCount'] as int? ?? 0,
      isOnline: json['isOnline'] as bool? ?? true,
    );
  }

  factory DashboardStatsModel.empty() {
    return DashboardStatsModel(
      todayOrders: 0,
      pendingOrders: 0,
      acceptedOrders: 0,
      completedOrders: 0,
      cancelledOrders: 0,
      revenue: 0.0,
      totalRevenue: 0.0,
      walletBalance: 0.0,
      rating: 5.0,
      reviewsCount: 0,
      isOnline: true,
    );
  }
}
