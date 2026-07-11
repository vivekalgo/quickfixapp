import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shimmer/shimmer.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/haptics.dart';
import '../../../../features/home/presentation/providers/home_providers.dart';
import '../../../../core/network/dio_client.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

class OrderItem {
  final String id;
  final String title;
  final DateTime date;
  final String slot;
  final double amount;
  final String providerName;
  final String status;
  final String shopId;
  final String pricingType;

  const OrderItem({
    required this.id,
    required this.title,
    required this.date,
    required this.slot,
    required this.amount,
    required this.providerName,
    required this.status,
    this.shopId = '',
    this.pricingType = 'fixed',
  });
}

// Fetches bookings for the REAL authenticated user (not hardcoded cust-789)
final customerBookingsProvider = FutureProvider<List<OrderItem>>((ref) async {
  final user = ref.watch(authProvider).user;
  final userId = user?['id']?.toString() ?? '';
  try {
    final res = await DioClient().get('/bookings', queryParameters: {
      if (userId.isNotEmpty) 'customerId': userId,
    });
    final data = res.data as List;
    return data.map((json) {
      return OrderItem(
        id: json['id']?.toString() ?? '',
        title: json['title']?.toString() ?? 'Home Service',
        date: DateTime.tryParse(json['date']?.toString() ?? '') ?? DateTime.now(),
        slot: json['slot']?.toString() ?? '09:00 AM – 11:00 AM',
        amount: double.tryParse(json['amount']?.toString() ?? '') ?? 0.0,
        providerName: json['providerName']?.toString() ?? 'Assigning Expert...',
        status: json['status']?.toString() ?? 'pending',
        shopId: json['shopId']?.toString() ?? '',
        pricingType: json['pricingType']?.toString() ?? 'fixed',
      );
    }).toList();
  } catch (e) {
    return [];
  }
});

class OrderHistoryScreen extends ConsumerStatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  ConsumerState<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends ConsumerState<OrderHistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(isDarkModeProvider);
    final bookingsAsync = ref.watch(customerBookingsProvider);

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
        elevation: 0,
        title: Text('Booking History', style: AppTextStyles.headingMedium(isDark)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            AppHaptics.lightTap();
            if (context.canPop()) {
              context.pop();
            } else {
              ref.read(currentNavIndexProvider.notifier).state = 0;
              context.go('/home');
            }
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            onPressed: () {
              AppHaptics.lightTap();
              ref.invalidate(customerBookingsProvider);
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(text: 'Active'),
            Tab(text: 'Completed'),
            Tab(text: 'Cancelled'),
          ],
        ),
      ),
      body: bookingsAsync.when(
        loading: () => _buildSkeletonLoader(isDark),
        error: (err, st) => _buildErrorState(context, isDark, err.toString()),
        data: (list) {
          final active = list.where((o) => o.status == 'pending' || o.status == 'accepted' || o.status == 'navigating' || o.status == 'on_the_way' || o.status == 'arrived' || o.status == 'quote_sent' || o.status == 'work_started').toList();
          final completed = list.where((o) => o.status == 'completed' || o.status == 'work_completed' || o.status == 'payment_completed' || o.status == 'closed').toList();
          final cancelled = list.where((o) => o.status == 'cancelled' || o.status == 'rejected').toList();
          return TabBarView(
            controller: _tabController,
            children: [
              _buildOrdersList(active, isDark, tabType: 'active'),
              _buildOrdersList(completed, isDark, tabType: 'completed'),
              _buildOrdersList(cancelled, isDark, tabType: 'cancelled'),
            ],
          );
        },
      ),
    );
  }

  Widget _buildOrdersList(List<OrderItem> list, bool isDark, {required String tabType}) {
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              tabType == 'active' ? Icons.pending_actions_outlined : tabType == 'completed' ? Icons.check_circle_outline : Icons.cancel_outlined,
              size: 70,
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            ),
            const SizedBox(height: 16),
            Text(
              tabType == 'active' ? 'No active bookings' : tabType == 'completed' ? 'No completed orders yet' : 'No cancelled orders',
              style: AppTextStyles.headingSmall(isDark),
            ),
            const SizedBox(height: 6),
            Text(
              tabType == 'active' ? 'Book a service to get started!' : 'Your ${tabType} orders will appear here',
              style: AppTextStyles.bodySmall(isDark),
            ),
            if (tabType == 'active') ...[
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () {
                  ref.read(currentNavIndexProvider.notifier).state = 0;
                  context.go('/home');
                },
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text('Book a Service', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              ),
            ],
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async => ref.invalidate(customerBookingsProvider),
      child: ListView.builder(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: list.length,
        itemBuilder: (context, index) {
          final order = list[index];
          return _buildOrderCard(order, isDark, tabType).animate(delay: (50 * index).ms).fadeIn().slideY(begin: 0.05, end: 0);
        },
      ),
    );
  }

  Widget _buildOrderCard(OrderItem order, bool isDark, String tabType) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.25 : 0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(order.title, style: AppTextStyles.headingSmall(isDark).copyWith(fontSize: 15)),
                  const SizedBox(height: 2),
                  Text('Booking #${order.id}', style: AppTextStyles.bodySmall(isDark)),
                ]),
              ),
              _buildStatusBadge(order.status),
            ],
          ),
          const Divider(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildInfoColumn('Scheduled', '${DateFormat('dd MMM yyyy').format(order.date)}\n${order.slot}', isDark),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInfoColumn('Expert', order.providerName, isDark),
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Amount', style: AppTextStyles.bodySmall(isDark)),
                if (order.pricingType == 'inspection' && order.amount == 0)
                  Text('Awaiting Quote', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontStyle: FontStyle.italic, color: Colors.orange.shade700))
                else
                  Text('₹${order.amount.toStringAsFixed(0)}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.secondary)),
                if (order.pricingType != 'fixed')
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: order.pricingType == 'inspection'
                          ? Colors.orange.withOpacity(0.1)
                          : order.pricingType == 'starting'
                              ? Colors.amber.withOpacity(0.1)
                              : Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      order.pricingType == 'inspection'
                          ? 'Quote Required'
                          : order.pricingType == 'starting'
                              ? 'Starts From'
                              : 'Price Range',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: order.pricingType == 'inspection'
                            ? Colors.orange
                            : order.pricingType == 'starting'
                                ? Colors.amber.shade700
                                : Colors.blue,
                      ),
                    ),
                  ),
              ]),
              Row(children: [
                // Actions based on tab type
                if (tabType == 'active') ...[
                  if (order.status == 'pending' || order.status == 'accepted')
                    OutlinedButton(
                      onPressed: () => _showCancelDialog(context, order.id, isDark),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Cancel', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () {
                      AppHaptics.heavyTap();
                      context.push('/tracking/${order.id}');
                    },
                    icon: const Icon(Icons.location_on, size: 14, color: Colors.white),
                    label: const Text('Track', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                  ),
                ] else if (tabType == 'completed') ...[
                  OutlinedButton.icon(
                    onPressed: () => _triggerInvoiceDownload(context, order.id),
                    icon: const Icon(Icons.download_outlined, size: 14),
                    label: const Text('Invoice', style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () => _showRatingBottomSheet(context, order.title, isDark),
                    icon: const Icon(Icons.star_outline, size: 14, color: Colors.white),
                    label: const Text('Rate', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                  ),
                ],
              ]),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoColumn(String label, String value, bool isDark) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: AppTextStyles.bodySmall(isDark)),
      const SizedBox(height: 2),
      Text(value, style: AppTextStyles.bodyMedium(isDark).copyWith(fontWeight: FontWeight.bold, fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis),
    ]);
  }

  Widget _buildStatusBadge(String status) {
    late Color bg, textColor;
    late String label;
    switch (status) {
      case 'pending':
        bg = Colors.orange.withOpacity(0.12);
        textColor = Colors.orange.shade800;
        label = 'PENDING';
        break;
      case 'accepted':
        bg = Colors.blue.withOpacity(0.12);
        textColor = Colors.blue.shade800;
        label = 'ACCEPTED';
        break;
      case 'on_the_way':
      case 'navigating':
        bg = Colors.purple.withOpacity(0.12);
        textColor = Colors.purple.shade800;
        label = 'ON THE WAY';
        break;
      case 'arrived':
        bg = Colors.deepPurple.withOpacity(0.12);
        textColor = Colors.deepPurple.shade800;
        label = 'ARRIVED';
        break;
      case 'quote_sent':
        bg = Colors.orange.withOpacity(0.12);
        textColor = Colors.orange.shade800;
        label = 'QUOTE SENT';
        break;
      case 'work_started':
        bg = Colors.amber.withOpacity(0.12);
        textColor = Colors.amber.shade900;
        label = 'IN PROGRESS';
        break;
      case 'work_completed':
        bg = Colors.teal.withOpacity(0.12);
        textColor = Colors.teal.shade800;
        label = 'WORK COMPLETED';
        break;
      case 'payment_completed':
        bg = Colors.green.withOpacity(0.12);
        textColor = Colors.green.shade800;
        label = 'PAYMENT COMPLETED';
        break;
      case 'closed':
      case 'completed':
        bg = Colors.green.withOpacity(0.12);
        textColor = Colors.green.shade800;
        label = 'COMPLETED';
        break;
      case 'rejected':
        bg = Colors.red.withOpacity(0.12);
        textColor = Colors.red.shade800;
        label = 'REJECTED';
        break;
      default:
        bg = Colors.grey.withOpacity(0.12);
        textColor = Colors.grey.shade700;
        label = 'CANCELLED';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w900,
          color: textColor,
          letterSpacing: 0.6,
        ),
      ),
    );
  }

  void _showCancelDialog(BuildContext context, String orderId, bool isDark) {
    AppHaptics.heavyTap();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Cancel Booking?', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        content: const Text('Cancellations within 2 hours of scheduled service may incur a ₹99 convenience fee.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Keep It')),
          ElevatedButton(
            onPressed: () async {
              AppHaptics.heavyTap();
              try {
                final res = await DioClient().post('/bookings/cancel', data: {'id': orderId});
                if (res.statusCode == 200) {
                  ref.invalidate(customerBookingsProvider);
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Booking cancelled successfully.'), backgroundColor: AppColors.success, behavior: SnackBarBehavior.floating),
                    );
                  }
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Failed to cancel. Is server running?'), behavior: SnackBarBehavior.floating),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Yes, Cancel', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _triggerInvoiceDownload(BuildContext context, String orderId) {
    AppHaptics.mediumTap();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Downloading Invoice #$orderId...'), backgroundColor: AppColors.success, behavior: SnackBarBehavior.floating),
    );
  }

  void _showRatingBottomSheet(BuildContext context, String serviceTitle, bool isDark) {
    AppHaptics.mediumTap();
    int currentRating = 5;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      backgroundColor: isDark ? AppColors.backgroundDark : Colors.white,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 24, top: 24, left: 24, right: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 20),
              Text('Rate Your Experience', style: AppTextStyles.headingMedium(isDark)),
              const SizedBox(height: 6),
              Text(serviceTitle, style: AppTextStyles.bodyMedium(isDark)),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) => GestureDetector(
                  onTap: () => setModalState(() => currentRating = i + 1),
                  child: Icon(i < currentRating ? Icons.star_rounded : Icons.star_outline_rounded, size: 44, color: Colors.amber),
                )),
              ),
              const SizedBox(height: 8),
              Text(['', 'Poor', 'Fair', 'Good', 'Very Good', 'Excellent!'][currentRating],
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.amber.shade700)),
              const SizedBox(height: 16),
              TextField(
                decoration: InputDecoration(
                  hintText: 'Share your experience (optional)...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: isDark ? AppColors.surfaceDark : Colors.grey.shade50,
                ),
                maxLines: 3,
                style: TextStyle(color: isDark ? Colors.white : AppColors.secondary),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  AppHaptics.heavyTap();
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Thank you for your feedback! ⭐'), behavior: SnackBarBehavior.floating, backgroundColor: AppColors.success),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: const Text('Submit Review', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSkeletonLoader(bool isDark) {
    final base = isDark ? AppColors.surfaceDark : Colors.grey.shade200;
    final highlight = isDark ? AppColors.borderDark : Colors.grey.shade100;
    return Shimmer.fromColors(
      baseColor: base,
      highlightColor: highlight,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 4,
        itemBuilder: (_, __) => Container(
          height: 160,
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, bool isDark, String error) {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.cloud_off_rounded, size: 64, color: AppColors.textSecondaryLight),
        const SizedBox(height: 16),
        Text('Could not load orders', style: AppTextStyles.headingSmall(isDark)),
        const SizedBox(height: 6),
        Text('Make sure the server is running', style: AppTextStyles.bodySmall(isDark)),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          onPressed: () => ref.invalidate(customerBookingsProvider),
          icon: const Icon(Icons.refresh, color: Colors.white),
          label: const Text('Retry', style: TextStyle(color: Colors.white)),
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
        ),
      ]),
    );
  }
}
