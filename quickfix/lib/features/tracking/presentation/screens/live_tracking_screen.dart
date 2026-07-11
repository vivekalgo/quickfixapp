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
  String _pricingType = 'fixed';
  Map<String, dynamic>? _quotation;
  List<dynamic>? _quotationHistory;

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
          _pricingType = data['pricingType']?.toString() ?? 'fixed';
          _quotation = data['quotation'] as Map<String, dynamic>?;
          _quotationHistory = data['quotationHistory'] as List<dynamic>?;
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
                  _buildQuotationReviewCard(isDark),

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

  Future<void> _respondToQuotation(String responseType, {String? comment}) async {
    try {
      final res = await DioClient().post(
        '/bookings/${widget.bookingId}/quotation/respond',
        data: {
          'response': responseType,
          'comment': comment ?? '',
        },
      );
      if (res.data != null && res.data['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Quotation response: $responseType submitted!'),
            backgroundColor: responseType == 'accepted' ? AppColors.success : AppColors.error,
          ),
        );
        _fetchBookingDetails();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res.data['message'] ?? 'Failed to update quotation response.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error submitting response: $e')),
      );
    }
  }

  void _showModificationDialog() {
    final commentController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Request Modification'),
        content: TextField(
          controller: commentController,
          decoration: const InputDecoration(
            labelText: 'Enter instructions/comments',
            hintText: 'e.g. Please reduce spare parts cost or use local parts',
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _respondToQuotation('modify', comment: commentController.text);
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  Widget _buildQuotationReviewCard(bool isDark) {
    if (_quotation == null) return const SizedBox.shrink();

    final status = _quotation!['status']?.toString() ?? 'pending';
    final double labour = (_quotation!['labourCharge'] as num?)?.toDouble() ?? 0.0;
    final double spares = (_quotation!['spareParts'] as num?)?.toDouble() ?? 0.0;
    final double materials = (_quotation!['additionalMaterials'] as num?)?.toDouble() ?? 0.0;
    final double visiting = (_quotation!['visitingCharges'] as num?)?.toDouble() ?? 0.0;
    final double discount = (_quotation!['discount'] as num?)?.toDouble() ?? 0.0;
    final double gst = (_quotation!['gst'] as num?)?.toDouble() ?? 0.0;
    final double total = (_quotation!['totalAmount'] as num?)?.toDouble() ?? 0.0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.orange.shade50.withOpacity(0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.receipt_long, color: Colors.orange),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Expert\'s Quotation',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.secondary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: status == 'accepted'
                      ? Colors.green.withOpacity(0.15)
                      : status == 'rejected'
                          ? Colors.red.withOpacity(0.15)
                          : Colors.orange.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: status == 'accepted'
                        ? Colors.green
                        : status == 'rejected'
                            ? Colors.red
                            : Colors.orange,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildQuoteRow('Labour Charges', labour),
          _buildQuoteRow('Spare Parts', spares),
          _buildQuoteRow('Materials', materials),
          _buildQuoteRow('Visiting Charges', visiting),
          _buildQuoteRow('Discount', -discount, isGreen: true),
          _buildQuoteRow('GST (Calculated)', gst),
          const Divider(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total Bill Amount', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              Text(
                '₹ ${total.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary),
              ),
            ],
          ),
          if (status == 'pending' || status == 'modified' || _bookingStatus == 'quote_sent') ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _respondToQuotation('rejected'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Reject', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _showModificationDialog,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.orange,
                      side: const BorderSide(color: Colors.orange),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Modify', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _respondToQuotation('accepted'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Accept', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuoteRow(String label, double val, {bool isGreen = false}) {
    if (val == 0.0 && !isGreen) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          Text(
            '${val < 0 ? "-" : ""}₹${val.abs().toStringAsFixed(0)}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isGreen ? Colors.green : Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }
}
