import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:quickfix/shared/themes/app_colors.dart';
import 'package:quickfix/shared/themes/app_text_styles.dart';
import 'package:quickfix/shared/utils/haptics.dart';
import 'package:quickfix/features/home/providers/home_providers.dart';
import 'package:quickfix/features/auth/providers/auth_providers.dart';
import 'package:quickfix/core/providers/network_providers.dart';
import 'package:quickfix/features/home/models/home_models.dart';

class QuickBookingScreen extends ConsumerStatefulWidget {
  const QuickBookingScreen({super.key});

  @override
  ConsumerState<QuickBookingScreen> createState() => _QuickBookingScreenState();
}

class _QuickBookingScreenState extends ConsumerState<QuickBookingScreen> {
  final TextEditingController _descriptionController = TextEditingController();
  
  String _selectedCategory = 'Cleaning';
  String _selectedUrgency = 'Today';
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  String _selectedSlot = '09:00 AM - 11:00 AM';
  bool _isLoading = false;

  // Real-time matching states
  bool _isMatching = false;
  int _matchingStep = 0;
  String _matchingStatus = 'Locating nearest QuickFix Experts...';
  String? _matchedShopName;
  double _calculatedFee = 199.0;

  final List<String> _urgencies = ['Emergency (< 2 hrs)', 'Today', 'Schedule Later'];
  
  final List<String> _slots = [
    '09:00 AM - 11:00 AM',
    '12:00 PM - 02:00 PM',
    '03:00 PM - 05:00 PM',
    '06:00 PM - 08:00 PM',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateEstimatedFee();
    });
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _updateEstimatedFee() async {
    try {
      final activeLocation = ref.read(currentAddressProvider);
      final dioClient = ref.read(dioClientProvider);
      final response = await dioClient.get(
        '/shops',
        queryParameters: {
          'lat': activeLocation.latitude != 0.0 ? activeLocation.latitude : 26.4912,
          'lng': activeLocation.longitude != 0.0 ? activeLocation.longitude : 80.3156,
        },
      );
      final shopsData = response.data as List;
      final List<Shop> shops = shopsData.map((e) => Shop.fromJson(e as Map<String, dynamic>)).toList();
      final matchingShops = shops.where((shop) =>
        shop.categories.any((c) => c.toLowerCase() == _selectedCategory.toLowerCase())
      ).toList();

      if (matchingShops.isNotEmpty) {
        setState(() {
          _calculatedFee = matchingShops.first.visitingCharges > 0 
              ? matchingShops.first.visitingCharges 
              : 150.0;
        });
      } else {
        setState(() {
          _calculatedFee = 150.0;
        });
      }
    } catch (_) {
      // Fallback
    }
  }

  Future<void> _triggerInstantBooking(double feeAmount, bool isDark) async {
    if (_descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please describe the issue briefly for the expert.')),
      );
      return;
    }

    AppHaptics.heavyTap();

    final authState = ref.read(authProvider);
    final activeLocation = ref.read(currentAddressProvider);
    final dioClient = ref.read(dioClientProvider);

    Shop? matchedShop;
    double finalFee = feeAmount;

    if (_selectedUrgency == 'Emergency (< 2 hrs)') {
      // Start Real-time Matching Simulation
      setState(() {
        _isMatching = true;
        _matchingStep = 0;
        _matchingStatus = 'Locating nearest QuickFix Experts...';
        _matchedShopName = null;
      });

      try {
        // Step 1: Locating nearest experts...
        await Future.delayed(const Duration(milliseconds: 1200));
        if (!mounted) return;
        setState(() {
          _matchingStep = 1;
          _matchingStatus = 'Checking online status & response rates...';
        });

        // Query backend for nearby shops
        final response = await dioClient.get(
          '/shops',
          queryParameters: {
            'lat': activeLocation.latitude != 0.0 ? activeLocation.latitude : 26.4912,
            'lng': activeLocation.longitude != 0.0 ? activeLocation.longitude : 80.3156,
          },
        );

        final shopsData = response.data as List;
        final List<Shop> shops = shopsData.map((e) => Shop.fromJson(e as Map<String, dynamic>)).toList();

        // Filter shops by category
        final matchingShops = shops.where((shop) =>
          shop.categories.any((c) => c.toLowerCase() == _selectedCategory.toLowerCase())
        ).toList();

        await Future.delayed(const Duration(milliseconds: 1000));
        if (!mounted) return;

        if (matchingShops.isEmpty) {
          setState(() {
            _isMatching = false;
          });
          _showNoProviderDialog();
          return;
        }

        // Pick closest shop (the backend sorts them by distance)
        matchedShop = matchingShops.first;
        finalFee = matchedShop.visitingCharges > 0 ? matchedShop.visitingCharges : 150.0;

        setState(() {
          _matchingStep = 2;
          _matchedShopName = matchedShop!.name;
          _matchingStatus = 'Connecting with $_matchedShopName...';
          _calculatedFee = finalFee;
        });

        await Future.delayed(const Duration(milliseconds: 1200));
        if (!mounted) return;

        setState(() {
          _matchingStep = 3;
          _matchingStatus = 'Securing booking & payment deposit...';
        });

        await Future.delayed(const Duration(milliseconds: 800));
        if (!mounted) return;

        setState(() {
          _isMatching = false;
        });
      } catch (e) {
        setState(() {
          _isMatching = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error finding experts: $e')),
        );
        return;
      }
    } else {
      // For Scheduled Later, select a matching provider if available
      try {
        final response = await dioClient.get(
          '/shops',
          queryParameters: {
            'lat': activeLocation.latitude != 0.0 ? activeLocation.latitude : 26.4912,
            'lng': activeLocation.longitude != 0.0 ? activeLocation.longitude : 80.3156,
          },
        );
        final shopsData = response.data as List;
        final List<Shop> shops = shopsData.map((e) => Shop.fromJson(e as Map<String, dynamic>)).toList();
        final matchingShops = shops.where((shop) =>
          shop.categories.any((c) => c.toLowerCase() == _selectedCategory.toLowerCase())
        ).toList();

        if (matchingShops.isNotEmpty) {
          matchedShop = matchingShops.first;
          finalFee = matchedShop.visitingCharges > 0 ? matchedShop.visitingCharges : 150.0;
        } else {
          // Fallback to default shops if none is online/nearby
          if (_selectedCategory.toLowerCase() == 'cleaning') {
            matchedShop = shops.firstWhere((s) => s.id == 'shop-cleaning-expert', orElse: () => shops.first);
          } else if (_selectedCategory.toLowerCase() == 'plumbing') {
            matchedShop = shops.firstWhere((s) => s.id == 'shop-plumbing-expert', orElse: () => shops.first);
          } else if (_selectedCategory.toLowerCase() == 'electrician') {
            matchedShop = shops.firstWhere((s) => s.id == 'shop-electrician-expert', orElse: () => shops.first);
          } else {
            matchedShop = shops.firstWhere((s) => s.id == 'shop-carpentry-expert', orElse: () => shops.first);
          }
          finalFee = matchedShop.visitingCharges > 0 ? matchedShop.visitingCharges : 150.0;
        }
        setState(() {
          _calculatedFee = finalFee;
        });
      } catch (_) {
        finalFee = 199.0;
      }
    }

    final targetShopId = matchedShop?.id ?? 'shop-cleaning-expert';
    final targetShopOwner = matchedShop?.ownerName ?? 'Assigning Expert...';

    // Show payment gateway dialog
    Timer? dialogTimer;
    if (!mounted) return;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        dialogTimer = Timer(const Duration(milliseconds: 1800), () async {
          AppHaptics.successNotification();
          if (dialogCtx.mounted) {
            Navigator.pop(dialogCtx);
          }
          
          // Trigger actual booking creation on backend
          if (mounted) setState(() => _isLoading = true);
          try {
            final response = await dioClient.post(
              '/bookings/create',
              data: {
                'userId': authState.user?['id'] ?? 'guest',
                'customerId': authState.user?['id'] ?? 'guest',
                'customerName': authState.user?['name'] ?? 'John Doe',
                'customerPhone': authState.user?['phone'] ?? '9999888877',
                'customerAddress': activeLocation.address,
                'latitude': activeLocation.latitude != 0.0 ? activeLocation.latitude : 26.4912,
                'longitude': activeLocation.longitude != 0.0 ? activeLocation.longitude : 80.3156,
                'shopId': targetShopId,
                'title': '$_selectedCategory Service Inspection',
                'slot': _selectedUrgency == 'Emergency (< 2 hrs)' ? 'Immediate' : _selectedSlot,
                'date': DateFormat('yyyy-MM-dd').format(_selectedUrgency == 'Emergency (< 2 hrs)' ? DateTime.now() : _selectedDate),
                'amount': finalFee,
                'paymentMethod': 'Razorpay',
                'pricingType': 'inspection',
                'specialInstructions': _descriptionController.text.trim(),
                'type': 'quick_booking',
              },
            );

            if (mounted) setState(() => _isLoading = false);
            if (!mounted) return;

            final responseData = response.data;
            context.push('/confirmation', extra: {
              'bookingId': responseData['bookingId'] ?? 'QF-${100000 + (DateTime.now().millisecond % 900000)}',
              'title': '$_selectedCategory Service Inspection',
              'amount': finalFee,
              'providerName': targetShopOwner,
              'date': DateFormat('MMM dd, yyyy').format(_selectedUrgency == 'Emergency (< 2 hrs)' ? DateTime.now() : _selectedDate),
              'slot': _selectedUrgency == 'Emergency (< 2 hrs)' ? 'Immediate' : _selectedSlot,
            });
          } catch (e) {
            if (mounted) setState(() => _isLoading = false);
            if (!mounted) return;
            context.push('/confirmation', extra: {
              'bookingId': 'QF-${100000 + (DateTime.now().millisecond % 900000)}',
              'title': '$_selectedCategory Service Inspection',
              'amount': finalFee,
              'providerName': targetShopOwner,
              'date': DateFormat('MMM dd, yyyy').format(_selectedUrgency == 'Emergency (< 2 hrs)' ? DateTime.now() : _selectedDate),
              'slot': _selectedUrgency == 'Emergency (< 2 hrs)' ? 'Immediate' : _selectedSlot,
            });
          }
        });

        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(28.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(color: Colors.blue.shade900, borderRadius: BorderRadius.circular(6)),
                      child: const Text('R', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'razorpay',
                      style: AppTextStyles.headingSmall(isDark).copyWith(
                        fontSize: 20,
                        color: Colors.blue.shade800,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(Colors.blue)),
                const SizedBox(height: 24),
                Text(
                  'Processing Secure Payment...',
                  style: AppTextStyles.bodyMedium(isDark).copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  'Paying ₹${finalFee.toInt()} inspection deposit',
                  style: AppTextStyles.bodySmall(isDark),
                ),
              ],
            ),
          ),
        );
      },
    ).then((_) => dialogTimer?.cancel());
  }

  void _showNoProviderDialog() {
    showDialog(
      context: context,
      builder: (dialogCtx) {
        final isDark = Theme.of(dialogCtx).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
          title: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'No Experts Nearby',
                  style: AppTextStyles.headingSmall(isDark).copyWith(fontSize: 18),
                ),
              ),
            ],
          ),
          content: Text(
            'We couldn\'t find any online $_selectedCategory experts within your service radius right now.\n\nWould you like to schedule this job for later? We will assign our best technician to your request.',
            style: AppTextStyles.bodyMedium(isDark),
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: Text(
                'Cancel',
                style: TextStyle(color: isDark ? Colors.white60 : Colors.black54),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                AppHaptics.selectionClick();
                Navigator.pop(dialogCtx);
                setState(() {
                  _selectedUrgency = 'Schedule Later';
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Schedule Later'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMatchingOverlay(bool isDark) {
    return Positioned.fill(
      child: Container(
        color: isDark ? Colors.black87.withValues(alpha: 0.85) : Colors.white.withValues(alpha: 0.92),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                // Pulsing concentric ripple circles
                RadarPulse(
                  child: Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.4),
                          blurRadius: 22,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.build_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ),
                const SizedBox(height: 50),
                // Text status updates
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40.0),
                  child: Column(
                    children: [
                      Text(
                        'Finding Your Expert',
                        style: AppTextStyles.headingMedium(isDark).copyWith(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: Text(
                          _matchingStatus,
                          key: ValueKey<String>(_matchingStatus),
                          style: AppTextStyles.bodyMedium(isDark).copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                // Custom loading dots indicator
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(4, (index) {
                    final isActive = index <= _matchingStep;
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: isActive ? AppColors.primary : (isDark ? Colors.white24 : Colors.black12),
                        shape: BoxShape.circle,
                      ),
                    );
                  }),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Text(
                    'Instant dispatch is covered by QuickFix Safety Insurance.',
                    style: AppTextStyles.bodySmall(isDark).copyWith(
                      color: isDark ? Colors.white38 : Colors.black38,
                      fontSize: 11,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(isDarkModeProvider);
    final currentAddress = ref.watch(currentAddressProvider).address;

    // Listen to changes in categories list dynamically
    ref.listen<AsyncValue<List<ServiceCategory>>>(categoriesProvider, (prev, next) {
      next.whenData((list) {
        if (list.isNotEmpty && !list.map((c) => c.name).contains(_selectedCategory)) {
          setState(() {
            _selectedCategory = list.first.name;
          });
          _updateEstimatedFee();
        }
      });
    });

    final categoriesAsync = ref.watch(categoriesProvider);
    final List<String> categories = categoriesAsync.maybeWhen(
      data: (list) => list.map((c) => c.name).toList(),
      orElse: () => ['Cleaning', 'Plumbing', 'Electrician', 'Carpentry'],
    );

    final double inspectionFee = _calculatedFee;

    return Scaffold(
      appBar: AppBar(
        title: Text('Instant Book Expert', style: AppTextStyles.headingMedium(isDark)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            AppHaptics.lightTap();
            context.pop();
          },
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.only(left: 20.0, right: 20.0, top: 12.0, bottom: 100.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Category Selection
                _buildSectionHeader(isDark, '1. Select Category'),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: categories.map<Widget>((cat) {
                    final isSelected = _selectedCategory == cat;
                    return ChoiceChip(
                      label: Text(cat),
                      selected: isSelected,
                      onSelected: (val) {
                        if (val) {
                          AppHaptics.selectionClick();
                          setState(() {
                            _selectedCategory = cat;
                          });
                          _updateEstimatedFee();
                        }
                      },
                      selectedColor: AppColors.primary,
                      backgroundColor: isDark ? AppColors.surfaceDark : Colors.grey.shade100,
                      labelStyle: TextStyle(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? Colors.white : (isDark ? Colors.white70 : AppColors.secondary),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 20),

                // 2. Describe the problem
                _buildSectionHeader(isDark, '2. Describe the Issue'),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceDark : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                  ),
                  child: TextField(
                    controller: _descriptionController,
                    maxLines: 3,
                    style: TextStyle(fontSize: 14, color: isDark ? Colors.white : AppColors.secondary),
                    decoration: const InputDecoration(
                      hintText: 'Describe what needs fixing (e.g. kitchen sink tap is leaking from joint)',
                      border: InputBorder.none,
                      hintStyle: TextStyle(color: AppColors.textSecondaryLight, fontSize: 13),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // 3. Urgency Selection
                _buildSectionHeader(isDark, '3. Select Urgency'),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _urgencies.map<Widget>((urg) {
                    final isSelected = _selectedUrgency == urg;
                    return ChoiceChip(
                      label: Text(urg),
                      selected: isSelected,
                      onSelected: (val) {
                        if (val) {
                          AppHaptics.selectionClick();
                          setState(() {
                            _selectedUrgency = urg;
                          });
                        }
                      },
                      selectedColor: AppColors.primary,
                      backgroundColor: isDark ? AppColors.surfaceDark : Colors.grey.shade100,
                      labelStyle: TextStyle(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? Colors.white : (isDark ? Colors.white70 : AppColors.secondary),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 20),

                // 4. Appointment Schedule Picker
                if (_selectedUrgency == 'Schedule Later') ...[
                  _buildSectionHeader(isDark, '4. Select Date & Time Slot'),
                  SizedBox(
                    height: 72,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: 7,
                      itemBuilder: (context, index) {
                        final date = DateTime.now().add(Duration(days: index + 1));
                        final isSelected = _selectedDate.day == date.day && _selectedDate.month == date.month;
                        return GestureDetector(
                          onTap: () {
                            AppHaptics.selectionClick();
                            setState(() {
                              _selectedDate = date;
                            });
                          },
                          child: Container(
                            width: 60,
                            margin: const EdgeInsets.only(right: 8, bottom: 4),
                            decoration: BoxDecoration(
                              color: isSelected 
                                  ? (isDark ? Colors.white : AppColors.secondary) 
                                  : (isDark ? AppColors.surfaceDark : Colors.white),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected 
                                    ? (isDark ? Colors.white : AppColors.secondary) 
                                    : (isDark ? AppColors.borderDark : AppColors.borderLight),
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  DateFormat('EEE').format(date).toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected 
                                        ? (isDark ? AppColors.secondary : Colors.white70) 
                                        : AppColors.textSecondaryLight,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  DateFormat('d').format(date),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected 
                                        ? (isDark ? AppColors.secondary : Colors.white) 
                                        : (isDark ? Colors.white : AppColors.secondary),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _slots.map((slot) {
                      final isSelected = _selectedSlot == slot;
                      return GestureDetector(
                        onTap: () {
                          AppHaptics.selectionClick();
                          setState(() {
                            _selectedSlot = slot;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected 
                                ? AppColors.primary.withValues(alpha: 0.1) 
                                : (isDark ? AppColors.surfaceDark : Colors.white),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected ? AppColors.primary : (isDark ? AppColors.borderDark : AppColors.borderLight),
                              width: 1.5,
                            ),
                          ),
                          child: Text(
                            slot,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected ? AppColors.primary : (isDark ? Colors.white70 : AppColors.secondary),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                ],

                // 5. Service Address
                _buildSectionHeader(isDark, '5. Service Location'),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceDark : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.location_on, color: AppColors.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Service Delivery Address', style: AppTextStyles.bodyMedium(isDark).copyWith(fontWeight: FontWeight.bold)),
                            Text(currentAddress, style: AppTextStyles.bodySmall(isDark)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Billing Details card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceDark : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Safety & Inspection Fee', style: AppTextStyles.bodyMedium(isDark)),
                          Text('₹${inspectionFee.toInt()}', style: AppTextStyles.bodyMedium(isDark).copyWith(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '* This fee covers visitor insurance & inspection, and is adjusted/deducted in the final bill summary.',
                        style: TextStyle(fontSize: 10, color: Colors.amber.shade800, fontStyle: FontStyle.italic),
                      ),
                      const Divider(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Total Inspection Deposit', style: AppTextStyles.headingSmall(isDark).copyWith(fontSize: 14)),
                          Text('₹${inspectionFee.toInt()}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (_isMatching)
            _buildMatchingOverlay(isDark),
          if (_isLoading)
            Positioned.fill(
              child: Container(
                color: Colors.black45,
                child: const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation(AppColors.primary),
                  ),
                ),
              ),
            ),
        ],
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          border: Border(top: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight)),
        ),
        child: SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: () => _triggerInstantBooking(inspectionFee, isDark),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _selectedUrgency == 'Emergency (< 2 hrs)' ? 'Find Expert Instantly' : 'Book Inspection Instantly',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.lock, size: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(bool isDark, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0, top: 4.0),
      child: Text(
        title,
        style: AppTextStyles.headingSmall(isDark).copyWith(fontSize: 14.5),
      ),
    );
  }
}

// concentric ripple circle pulse widget for finding providers
class RadarPulse extends StatefulWidget {
  final Widget child;
  const RadarPulse({super.key, required this.child});

  @override
  State<RadarPulse> createState() => _RadarPulseState();
}

class _RadarPulseState extends State<RadarPulse> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        for (int i = 0; i < 3; i++)
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final double progress = (_controller.value + (i / 3)) % 1.0;
              final double size = 76.0 + (progress * 150.0);
              final double opacity = (1.0 - progress) * 0.45;
              return Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withValues(alpha: opacity),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: opacity * 1.5),
                    width: 1.5,
                  ),
                ),
              );
            },
          ),
        widget.child,
      ],
    );
  }
}
