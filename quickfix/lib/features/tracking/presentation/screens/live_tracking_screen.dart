import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/haptics.dart';
import '../../../../features/home/presentation/providers/home_providers.dart';

class LiveTrackingScreen extends ConsumerStatefulWidget {
  final String bookingId;
  const LiveTrackingScreen({super.key, required this.bookingId});

  @override
  ConsumerState<LiveTrackingScreen> createState() => _LiveTrackingScreenState();
}

class _LiveTrackingScreenState extends ConsumerState<LiveTrackingScreen> {
  int _currentStep = 2; // 0: Confirmed, 1: Assigned, 2: Arriving/On the way, 3: Started, 4: Completed
  double _providerDistance = 1.2;
  int _providerTime = 12;
  GoogleMapController? _mapController;
  LatLng _driverPosition = const LatLng(26.4820, 80.3080);

  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(26.4912, 80.3156), // Swaroop Nagar, Kanpur location coordinates
    zoom: 14.5,
  );

  @override
  void initState() {
    super.initState();
    // Simulate provider moving closer over time
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        setState(() {
          _providerDistance = 0.6;
          _providerTime = 6;
          _driverPosition = const LatLng(26.4870, 80.3120);
        });
        _mapController?.animateCamera(
          CameraUpdate.newLatLng(_driverPosition),
        );
      }
    });

    Future.delayed(const Duration(seconds: 8), () {
      if (mounted) {
        setState(() {
          _providerDistance = 0.1;
          _providerTime = 2;
          _currentStep = 3; // Work Started
          _driverPosition = const LatLng(26.4908, 80.3152);
        });
        _mapController?.animateCamera(
          CameraUpdate.newLatLng(_driverPosition),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(isDarkModeProvider);

    final List<Map<String, dynamic>> milestones = [
      {'title': 'Booking Confirmed', 'subtitle': 'Order placed at 12:40 PM', 'icon': Icons.check_circle},
      {'title': 'Expert Assigned', 'subtitle': 'Rohan Sharma (Electrician)', 'icon': Icons.person_pin},
      {'title': 'Arriving / On the way', 'subtitle': 'Expert is riding a bike', 'icon': Icons.motorcycle},
      {'title': 'Service Started', 'subtitle': 'Pin OTP verification matched', 'icon': Icons.construction},
      {'title': 'Service Completed', 'subtitle': 'Rate & download invoice', 'icon': Icons.stars},
    ];

    return Scaffold(
      body: Stack(
        children: [
          // 1. Google Maps Live Widget Integration
          Positioned.fill(
            child: GoogleMap(
              initialCameraPosition: _initialPosition,
              mapType: MapType.normal,
              myLocationEnabled: true,
              zoomControlsEnabled: false,
              onMapCreated: (controller) {
                _mapController = controller;
              },
              markers: {
                Marker(
                  markerId: const MarkerId('home'),
                  position: const LatLng(26.4912, 80.3156),
                  infoWindow: const InfoWindow(title: 'Service Address (Home)'),
                  icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                ),
                Marker(
                  markerId: const MarkerId('driver'),
                  position: _driverPosition,
                  infoWindow: InfoWindow(title: 'Rohan Sharma ($_providerTime mins away)'),
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
                        const CircleAvatar(
                          radius: 24,
                          backgroundImage: NetworkImage(
                            'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Rohan Sharma',
                                style: AppTextStyles.headingSmall(isDark),
                              ),
                              Row(
                                children: [
                                  const Icon(Icons.star, color: Colors.amber, size: 12),
                                  const SizedBox(width: 4),
                                  Text(
                                    '4.9 (320 reviews) • Premium Expert',
                                    style: AppTextStyles.bodySmall(isDark),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        // Call button
                        IconButton(
                          icon: const Icon(Icons.phone_in_talk, color: AppColors.success),
                          onPressed: () {
                            AppHaptics.mediumTap();
                            // Call Action simulation
                          },
                        ),
                        // Chat button
                        IconButton(
                          icon: const Icon(Icons.chat_bubble_outline, color: AppColors.primary),
                          onPressed: () {
                            AppHaptics.mediumTap();
                            context.push('/support'); // Re-uses support chat
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

// Simulated map roads grid painter
class RoadPainter extends CustomPainter {
  final bool isDark;
  RoadPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isDark ? Colors.white10 : Colors.black.withOpacity(0.04)
      ..strokeWidth = 32
      ..strokeCap = StrokeCap.round;

    final dashPaint = Paint()
      ..color = isDark ? Colors.white24 : Colors.black12
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // Road 1
    canvas.drawLine(const Offset(40, 100), const Offset(360, 420), paint);
    canvas.drawLine(const Offset(40, 100), const Offset(360, 420), dashPaint);

    // Road 2
    canvas.drawLine(const Offset(300, 150), const Offset(20, 360), paint);
    canvas.drawLine(const Offset(300, 150), const Offset(20, 360), dashPaint);

    // Grid details
    canvas.drawCircle(const Offset(180, 200), 8, Paint()..color = Colors.green.withOpacity(0.15));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
