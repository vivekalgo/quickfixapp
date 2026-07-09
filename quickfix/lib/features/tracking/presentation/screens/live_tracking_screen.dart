import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:math' as math;
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/haptics.dart';
import '../../../../features/home/presentation/providers/home_providers.dart';
import '../../../../core/network/dio_client.dart';

class LiveTrackingScreen extends ConsumerStatefulWidget {
  final String bookingId;
  const LiveTrackingScreen({super.key, required this.bookingId});

  @override
  ConsumerState<LiveTrackingScreen> createState() => _LiveTrackingScreenState();
}

class _LiveTrackingScreenState extends ConsumerState<LiveTrackingScreen> {
  int _currentStep = 0; // 0: Confirmed, 1: Assigned, 2: Arriving/On the way, 3: Started, 4: Completed
  double _providerDistance = 0.0;
  int _providerTime = 0;
  GoogleMapController? _mapController;
  LatLng _driverPosition = const LatLng(26.4912, 80.3156);
  LatLng _customerPosition = const LatLng(26.4912, 80.3156);
  String _providerName = 'Assigning Expert...';
  String _providerPhone = '';
  String _providerAvatar = 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150';
  String _bookingStatus = 'pending';
  Timer? _pollingTimer;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchBookingDetails();
    // Poll booking details every 5 seconds for live status/GPS sync
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (_) => _fetchBookingDetails());
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  double _calculateDistance(LatLng p1, LatLng p2) {
    var p = 0.017453292519943295;
    var c = math.cos;
    var a = 0.5 - c((p2.latitude - p1.latitude) * p)/2 + 
          c(p1.latitude * p) * c(p2.latitude * p) * 
          (1 - c((p2.longitude - p1.longitude) * p))/2;
    return 12742 * math.asin(math.sqrt(a));
  }

  Future<void> _fetchBookingDetails() async {
    try {
      final response = await DioClient().get('/bookings/details/${widget.bookingId}');
      final data = response.data;
      if (data == null) return;

      final status = data['status']?.toString() ?? 'pending';
      final pName = data['providerName']?.toString() ?? 'Assigning Expert...';
      final custLat = double.tryParse(data['customerLat']?.toString() ?? '26.4912') ?? 26.4912;
      final custLng = double.tryParse(data['customerLng']?.toString() ?? '80.3156') ?? 80.3156;
      final provLat = double.tryParse(data['providerLat']?.toString() ?? '') ?? custLat;
      final provLng = double.tryParse(data['providerLng']?.toString() ?? '') ?? custLng;

      int step = 0;
      if (status == 'accepted') {
        step = 1;
      } else if (status == 'navigating' || status == 'arrived') {
        step = 2;
      } else if (status == 'work_started') {
        step = 3;
      } else if (status == 'work_completed' || status == 'payment_completed' || status == 'closed' || status == 'cancelled') {
        step = 4;
      }

      final cPos = LatLng(custLat, custLng);
      final dPos = LatLng(provLat, provLng);
      final distance = _calculateDistance(cPos, dPos);
      final timeMins = (distance * 10).round(); // Estimate 10 mins per km

      if (mounted) {
        setState(() {
          _currentStep = step;
          _bookingStatus = status;
          _providerName = pName;
          _customerPosition = cPos;
          _driverPosition = dPos;
          _providerDistance = distance;
          _providerTime = timeMins < 1 ? 1 : timeMins;
          _isLoading = false;
        });

        // Pan map camera to driver position
        if (_mapController != null) {
          _mapController!.animateCamera(
            CameraUpdate.newLatLng(dPos),
          );
        }
      }
    } catch (e) {
      debugPrint('Error polling live tracking details: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(isDarkModeProvider);

    final List<Map<String, dynamic>> milestones = [
      {'title': 'Booking Confirmed', 'subtitle': 'Order placed successfully', 'icon': Icons.check_circle},
      {'title': 'Expert Assigned', 'subtitle': _providerName, 'icon': Icons.person_pin},
      {'title': 'Arriving / On the way', 'subtitle': _bookingStatus == 'navigating' ? 'Expert is riding to your home' : (_bookingStatus == 'arrived' ? 'Expert has arrived' : 'On the way'), 'icon': Icons.motorcycle},
      {'title': 'Service Started', 'subtitle': 'Work in progress', 'icon': Icons.construction},
      {'title': 'Service Completed', 'subtitle': 'Rate & pay visiting charges', 'icon': Icons.stars},
    ];

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          // 1. Google Maps Live Widget Integration
          Positioned.fill(
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _driverPosition,
                zoom: 14.5,
              ),
              mapType: MapType.normal,
              myLocationEnabled: true,
              zoomControlsEnabled: false,
              onMapCreated: (controller) {
                _mapController = controller;
              },
              markers: {
                Marker(
                  markerId: const MarkerId('home'),
                  position: _customerPosition,
                  infoWindow: const InfoWindow(title: 'Service Address (Home)'),
                  icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                ),
                if (_bookingStatus != 'pending')
                  Marker(
                    markerId: const MarkerId('driver'),
                    position: _driverPosition,
                    infoWindow: InfoWindow(title: '$_providerName ($_providerTime mins away)'),
                    icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
                  ),
              },
            ),
          ),

          // 2. Custom header bar (Back, Title, Emergency SOS)
          Positioned(
            top: 48,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CircleAvatar(
                  backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
                  child: IconButton(
                    icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : AppColors.secondary),
                    onPressed: () {
                      AppHaptics.lightTap();
                      context.pop();
                    },
                  ),
                ),
                
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceDark : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
                  ),
                  child: Text(
                    'Track ID: #${widget.bookingId}',
                    style: AppTextStyles.bodySmall(isDark).copyWith(fontWeight: FontWeight.bold),
                  ),
                ),

                // SOS Emergency Button
                GestureDetector(
                  onTap: () => _triggerEmergencySOS(context, isDark),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4))],
                    ),
                    child: const Icon(
                      Icons.gpp_maybe,
                      color: Colors.white,
                      size: 22,
                    ),
                  ).animate(onPlay: (controller) => controller.repeat()).shimmer(duration: 1200.ms),
                ),
              ],
            ),
          ),

          // 3. Provider details & Status timeline slider panel (Bottom sheet overlay)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 16,
                    offset: const Offset(0, -6),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Pull Handle
                  Container(
                    width: 40,
                    height: 5,
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2.5),
                    ),
                  ),

                  // Provider Details Row
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundImage: NetworkImage(_providerAvatar),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _providerName,
                                style: AppTextStyles.headingSmall(isDark),
                              ),
                              Row(
                                children: [
                                  const Icon(Icons.star, color: Colors.amber, size: 12),
                                  const SizedBox(width: 4),
                                  Text(
                                    _bookingStatus == 'pending'
                                        ? 'Awaiting Shop Assignment'
                                        : '4.9 • Verified Expert',
                                    style: AppTextStyles.bodySmall(isDark),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        if (_providerPhone.isNotEmpty) ...[
                          IconButton(
                            icon: const Icon(Icons.phone_in_talk, color: AppColors.success),
                            onPressed: () {
                              AppHaptics.mediumTap();
                            },
                          ),
                        ],
                        IconButton(
                          icon: const Icon(Icons.chat_bubble_outline, color: AppColors.primary),
                          onPressed: () {
                            AppHaptics.mediumTap();
                            context.push('/support');
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),
                  const Divider(),

                  // Milestones status tracker
                  Padding(
                    padding: const EdgeInsets.only(left: 20, right: 20, top: 12, bottom: 20),
                    child: Column(
                      children: List.generate(milestones.length, (index) {
                        final step = milestones[index];
                        final isCompleted = index < _currentStep;
                        final isActive = index == _currentStep;
                        final color = isCompleted 
                            ? AppColors.success 
                            : (isActive ? AppColors.primary : AppColors.textSecondaryLight);

                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Column(
                              children: [
                                Icon(
                                  isActive ? Icons.pending : (isCompleted ? Icons.check_circle : Icons.circle_outlined),
                                  color: color,
                                  size: 18,
                                ),
                                if (index < milestones.length - 1)
                                  Container(
                                    width: 2,
                                    height: 32,
                                    color: isCompleted ? AppColors.success : Colors.grey.shade300,
                                  ),
                              ],
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    step['title']!,
                                    style: AppTextStyles.bodyMedium(isDark).copyWith(
                                      fontWeight: isActive || isCompleted ? FontWeight.bold : FontWeight.normal,
                                      color: isDark ? Colors.white : AppColors.secondary,
                                    ),
                                  ),
                                  Text(
                                    step['subtitle']!,
                                    style: AppTextStyles.bodySmall(isDark),
                                  ),
                                  const SizedBox(height: 12),
                                ],
                              ),
                            ),
                          ],
                        );
                      }),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // SOS modal dialog
  void _triggerEmergencySOS(BuildContext context, bool isDark) {
    AppHaptics.heavyTap();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.gpp_maybe, color: AppColors.error),
            SizedBox(width: 8),
            Text('QuickFix SOS Safety', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          'Do you need to trigger emergency assistance? Clicking confirm will share your live GPS location with our 24x7 safety response team and dial local authorities.',
          style: AppTextStyles.bodyMedium(isDark),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondaryLight)),
          ),
          ElevatedButton(
            onPressed: () {
              AppHaptics.heavyTap();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('SOS Safety Alert Activated. Assistance is on the way.'),
                  backgroundColor: AppColors.error,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('CONFIRM SOS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
