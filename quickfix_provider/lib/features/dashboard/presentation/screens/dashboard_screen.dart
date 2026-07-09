import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:dio/dio.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/haptics.dart';
import '../../../../core/network/dio_client.dart';
import '../providers/provider_providers.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _currentTab = 0; // 0: Bookings, 1: Services, 2: Profile

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final shop = ref.watch(activeShopProvider);

    if (shop == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Session expired. Please login again.'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.go('/'),
                child: const Text('Login'),
              )
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.construction, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(shop['name'], style: AppTextStyles.headingMedium(isDark)),
          ],
        ),
        actions: [
          // Online/Offline quick switch
          Row(
            children: [
              Text(
                shop['isOnline'] == true ? 'ONLINE' : 'OFFLINE',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: shop['isOnline'] == true ? AppColors.success : AppColors.danger,
                ),
              ),
              Switch(
                value: shop['isOnline'] == true,
                activeColor: AppColors.success,
                onChanged: (val) {
                  AppHaptics.mediumTap();
                  ref.read(activeShopProvider.notifier).toggleOnlineStatus();
                },
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: IndexedStack(
        index: _currentTab,
        children: [
          _buildBookingsTab(shop, isDark),
          _buildServicesTab(shop, isDark),
          _buildProfileTab(shop, isDark),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentTab,
        selectedItemColor: AppColors.primary,
        onTap: (index) {
          AppHaptics.selectionClick();
          setState(() {
            _currentTab = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: 'Bookings'),
          BottomNavigationBarItem(icon: Icon(Icons.build_circle), label: 'Services'),
          BottomNavigationBarItem(icon: Icon(Icons.storefront), label: 'Profile'),
        ],
      ),
    );
  }

  // --- TAB 1: Bookings Feed ---
  Widget _buildBookingsTab(Map<String, dynamic> shop, bool isDark) {
    final bookingsAsync = ref.watch(providerBookingsProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(providerBookingsProvider);
      },
      color: AppColors.primary,
      child: ListView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        padding: const EdgeInsets.all(16),
        children: [
          // Stat Counters Header
          bookingsAsync.when(
            data: (list) {
              final todayEarnings = list
                  .where((b) => b['status'] == 'completed')
                  .fold(0.0, (sum, item) => sum + (item['amount'] ?? 0.0));
              final pendingJobs = list.where((b) => b['status'] == 'pending' || b['status'] == 'accepted' || b['status'] == 'on_the_way').length;
              return Row(
                children: [
                  Expanded(
                    child: _buildStatCard('Today\'s Income', '₹${todayEarnings.toInt()}', Icons.payments, isDark),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard('Active Jobs', '$pendingJobs', Icons.pending_actions, isDark),
                  ),
                ],
              );
            },
            loading: () => const SizedBox(height: 80, child: Center(child: CircularProgressIndicator())),
            error: (err, st) => const SizedBox(),
          ),

          const SizedBox(height: 20),
          Text('Incoming Service Bookings', style: AppTextStyles.headingMedium(isDark)),
          const SizedBox(height: 12),

          bookingsAsync.when(
            data: (list) {
              if (list.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 60.0),
                    child: Column(
                      children: [
                        const Icon(Icons.receipt_long_outlined, size: 48, color: AppColors.textSecondaryLight),
                        const SizedBox(height: 12),
                        Text('No bookings found for your shop', style: AppTextStyles.bodyMedium(isDark)),
                      ],
                    ),
                  ),
                );
              }

              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: list.length,
                itemBuilder: (context, index) {
                  final booking = list[index];
                  final status = booking['status'];
                  final isAccepted = status == 'accepted' || status == 'on_the_way' || status == 'completed';

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceDark : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('ID: #${booking['id']}', style: AppTextStyles.headingSmall(isDark)),
                            _buildStatusBadge(status),
                          ],
                        ),
                        const Divider(height: 20),
                        Text(booking['title'] ?? 'General Service', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        const SizedBox(height: 4),
                        Text(
                          'Scheduled: ${booking['slot']}',
                          style: AppTextStyles.bodySmall(isDark),
                        ),
                        Text(
                          'Amount: ₹${booking['amount']}',
                          style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 14),
                        ),

                        // Show Customer Details only after Accepting
                        if (isAccepted) ...[
                          const Divider(height: 20),
                          Row(
                            children: [
                              const Icon(Icons.person_outline, size: 14, color: AppColors.primary),
                              const SizedBox(width: 8),
                              Text(booking['customerName'] ?? 'John Doe', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.location_on_outlined, size: 14, color: AppColors.primary),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  booking['customerAddress'] ?? 'Swaroop Nagar, Kanpur',
                                  style: AppTextStyles.bodySmall(isDark),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.phone_outlined, size: 14, color: AppColors.primary),
                              const SizedBox(width: 8),
                              Text(booking['customerPhone'] ?? '9999888877', style: AppTextStyles.bodySmall(isDark)),
                            ],
                          ),
                        ],

                        const SizedBox(height: 16),

                        // Booking Milestones Action Trigger
                        _buildBookingActions(booking, status, shop['ownerName']),
                      ],
                    ),
                  ).animate().fadeIn().slideY(begin: 0.1, end: 0);
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, st) => Center(child: Text('Error loading bookings: $err')),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 28),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label.toUpperCase(), style: AppTextStyles.bodySmall(isDark).copyWith(fontSize: 10)),
              Text(value, style: AppTextStyles.headingMedium(isDark).copyWith(fontSize: 18)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg = Colors.grey.withOpacity(0.15);
    Color fg = Colors.grey;

    if (status == 'pending') {
      bg = Colors.amber.withOpacity(0.15);
      fg = Colors.amber;
    } else if (status == 'accepted') {
      bg = Colors.blue.withOpacity(0.15);
      fg = Colors.blue;
    } else if (status == 'on_the_way') {
      bg = AppColors.primary.withOpacity(0.15);
      fg = AppColors.primary;
    } else if (status == 'completed') {
      bg = Colors.green.withOpacity(0.15);
      fg = Colors.green;
    } else if (status == 'cancelled' || status == 'rejected') {
      bg = Colors.red.withOpacity(0.15);
      fg = Colors.red;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Text(
        status.replaceAll('_', ' ').toUpperCase(),
        style: TextStyle(color: fg, fontWeight: FontWeight.bold, fontSize: 9),
      ),
    );
  }

  Widget _buildBookingActions(Map<String, dynamic> booking, String status, String ownerName) {
    if (status == 'pending') {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => _updateBookingStatus(booking['id'], 'rejected', ownerName),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
              ),
              child: const Text('Reject', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: () => _updateBookingStatus(booking['id'], 'accepted', ownerName),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.success, foregroundColor: Colors.white),
              child: const Text('Accept', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      );
    }

    if (status == 'accepted') {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () => _updateBookingStatus(booking['id'], 'on_the_way', ownerName),
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
          child: const Text('Mark "On The Way"', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      );
    }

    if (status == 'on_the_way') {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () => _updateBookingStatus(booking['id'], 'completed', ownerName),
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.success, foregroundColor: Colors.white),
          child: const Text('Mark "Completed"', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      );
    }

    return const SizedBox();
  }

  Future<void> _updateBookingStatus(String bookingId, String status, String providerName) async {
    AppHaptics.heavyTap();
    try {
      final dio = DioClient().dio;
      final res = await dio.post('/bookings/update-status', data: {
        'id': bookingId,
        'status': status,
        'providerName': providerName,
      });

      if (res.statusCode == 200) {
        ref.invalidate(providerBookingsProvider);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update booking status.')),
      );
    }
  }

  // --- TAB 2: Services Catalog ---
  Widget _buildServicesTab(Map<String, dynamic> shop, bool isDark) {
    final services = List.from(shop['services'] ?? []);

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        Text('Service Price Catalog', style: AppTextStyles.headingMedium(isDark)),
        Text(
          'Manage services you offer and set custom pricing that customers see instantly.',
          style: AppTextStyles.bodySmall(isDark),
        ),
        const SizedBox(height: 16),

        if (services.isEmpty) ...[
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 40.0),
              child: Text('No catalog services added by Admin yet.', style: AppTextStyles.bodyMedium(isDark)),
            ),
          )
        ] else
          ...services.map((srv) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      srv['imageUrl'] ?? 'https://images.unsplash.com/photo-1581578731548-c64695cc6952?w=100',
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(srv['title'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                        const SizedBox(height: 2),
                        Text('Original Price: ₹${srv['originalPrice']}', style: AppTextStyles.bodySmall(isDark)),
                        Text(
                          'Your Price: ₹${srv['price']}',
                          style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit, color: AppColors.primary),
                    onPressed: () => _showEditPriceDialog(srv['id'], srv['title'], srv['price']),
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  void _showEditPriceDialog(String serviceId, String title, dynamic currentPrice) {
    final controller = TextEditingController(text: currentPrice.toString());
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Price: $title', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'New Service Price (₹)',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final newPrice = double.tryParse(controller.text);
              if (newPrice != null) {
                AppHaptics.heavyTap();
                ref.read(activeShopProvider.notifier).updateServicePrice(serviceId, newPrice);
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // --- TAB 3: Shop Profile ---
  Widget _buildProfileTab(Map<String, dynamic> shop, bool isDark) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        // 1. Owner Profile Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
          ),
          child: Column(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundImage: NetworkImage(
                  shop['imagePath'] ?? 'https://images.unsplash.com/photo-1581578731548-c64695cc6952?w=150',
                ),
              ),
              const SizedBox(height: 12),
              Text(shop['ownerName'], style: AppTextStyles.headingMedium(isDark)),
              Text('Shop Phone: +91 ${shop['phone']}', style: AppTextStyles.bodyMedium(isDark)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('Partner ID: ${shop['id']}', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 11)),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),
        Text('Operating Timings', style: AppTextStyles.headingSmall(isDark)),
        const SizedBox(height: 8),
        InkWell(
          onTap: () => _showEditTimingsDialog(shop['timings'] ?? '09:00 AM - 08:00 PM'),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.access_time, color: AppColors.primary),
                    const SizedBox(width: 12),
                    Text(shop['timings'] ?? '09:00 AM - 08:00 PM', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                const Icon(Icons.edit, size: 18, color: AppColors.textSecondaryLight),
              ],
            ),
          ),
        ),

        const SizedBox(height: 24),
        Text('Portfolio Repair Images / Gallery', style: AppTextStyles.headingSmall(isDark)),
        const SizedBox(height: 12),

        // Grid of images
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: (shop['portfolioImages'] as List? ?? []).length + 1,
          itemBuilder: (context, index) {
            final imagesList = List.from(shop['portfolioImages'] ?? []);
            if (index == imagesList.length) {
              // Add button
              return InkWell(
                onTap: _showAddImageUrlDialog,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceDark : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight, style: BorderStyle.values[0] == BorderStyle.none ? BorderStyle.solid : BorderStyle.solid), // Dotted replacement
                  ),
                  child: const Icon(Icons.add_photo_alternate_outlined, color: AppColors.primary, size: 28),
                ),
              );
            }

            return ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                imagesList[index],
                fit: BoxFit.cover,
              ),
            );
          },
        ),

        const SizedBox(height: 32),
        ElevatedButton(
          onPressed: () {
            AppHaptics.heavyTap();
            ref.read(activeShopProvider.notifier).logout();
            context.go('/');
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 48),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text('Log Out Account', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  void _showEditTimingsDialog(String currentTimings) {
    final controller = TextEditingController(text: currentTimings);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Timing Windows', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Operating Hours',
            hintText: 'e.g. 09:00 AM - 09:00 PM',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                AppHaptics.heavyTap();
                ref.read(activeShopProvider.notifier).updateTimings(controller.text.trim());
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showAddImageUrlDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Portfolio Image', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Image Web URL',
            hintText: 'https://images.unsplash.com/...',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                AppHaptics.heavyTap();
                ref.read(activeShopProvider.notifier).addPortfolioImage(controller.text.trim());
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Add Image', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
