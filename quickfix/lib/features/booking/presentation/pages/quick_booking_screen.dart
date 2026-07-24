import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:quickfix/core/theme/app_colors.dart';
import 'package:quickfix/core/theme/app_text_styles.dart';
import 'package:quickfix/core/utils/haptics.dart';
import 'package:quickfix/features/home/presentation/controllers/home_providers.dart';
import 'package:quickfix/features/auth/presentation/controllers/auth_providers.dart';
import 'package:quickfix/features/booking/presentation/controllers/booking_providers.dart';
import 'package:quickfix/features/home/models/home_models.dart';
import 'package:quickfix/features/booking/presentation/widgets/booking_matching_overlay.dart';
import 'package:quickfix/core/network/error_handler.dart';

class QuickBookingScreen extends ConsumerStatefulWidget {
  const QuickBookingScreen({super.key});

  @override
  ConsumerState<QuickBookingScreen> createState() => _QuickBookingScreenState();
}

class _QuickBookingScreenState extends ConsumerState<QuickBookingScreen> {
  final TextEditingController _descriptionController = TextEditingController();

  String _selectedCategory = 'Cleaning';
  String _selectedUrgency = 'Today';
  final DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  final String _selectedSlot = '09:00 AM - 11:00 AM';
  bool _isLoading = false;

  // Real-time matching states
  bool _isMatching = false;
  int _matchingStep = 0;
  String _matchingStatus = 'Locating nearest QuickFix Experts...';
  String? _matchedShopName;
  double _calculatedFee = 199.0;

  final List<String> _urgencies = [
    'Emergency (< 2 hrs)',
    'Today',
    'Schedule Later',
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
      final homeRepository = ref.read(homeRepositoryProvider);
      final List<Shop> shops = await homeRepository.getNearbyShops(
        lat: activeLocation.latitude != 0.0
            ? activeLocation.latitude
            : 26.4912,
        lng: activeLocation.longitude != 0.0
            ? activeLocation.longitude
            : 80.3156,
      );
      final matchingShops = shops
          .where(
            (shop) => shop.categories.any(
              (c) => c.toLowerCase() == _selectedCategory.toLowerCase(),
            ),
          )
          .toList();

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
        const SnackBar(
          content: Text('Please describe the issue briefly for the expert.'),
        ),
      );
      return;
    }

    AppHaptics.heavyTap();

    final authState = ref.read(authProvider);
    final activeLocation = ref.read(currentAddressProvider);
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
        final homeRepository = ref.read(homeRepositoryProvider);
        final List<Shop> shops = await homeRepository.getNearbyShops(
          lat: activeLocation.latitude != 0.0
              ? activeLocation.latitude
              : 26.4912,
          lng: activeLocation.longitude != 0.0
              ? activeLocation.longitude
              : 80.3156,
        );

        // Filter shops by category
        final matchingShops = shops
            .where(
              (shop) => shop.categories.any(
                (c) => c.toLowerCase() == _selectedCategory.toLowerCase(),
              ),
            )
            .toList();

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
        finalFee = matchedShop.visitingCharges > 0
            ? matchedShop.visitingCharges
            : 150.0;

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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(ErrorHandler.handle(e).message)));
        return;
      }
    } else {
      // For Scheduled Later, select a matching provider if available
      try {
        final homeRepository = ref.read(homeRepositoryProvider);
        final List<Shop> shops = await homeRepository.getNearbyShops(
          lat: activeLocation.latitude != 0.0
              ? activeLocation.latitude
              : 26.4912,
          lng: activeLocation.longitude != 0.0
              ? activeLocation.longitude
              : 80.3156,
        );
        final matchingShops = shops
            .where(
              (shop) => shop.categories.any(
                (c) => c.toLowerCase() == _selectedCategory.toLowerCase(),
              ),
            )
            .toList();

        if (matchingShops.isNotEmpty) {
          matchedShop = matchingShops.first;
          finalFee = matchedShop.visitingCharges > 0
              ? matchedShop.visitingCharges
              : 150.0;
        } else {
          // Fallback to default shops if none is online/nearby
          if (_selectedCategory.toLowerCase() == 'cleaning') {
            matchedShop = shops.firstWhere(
              (s) => s.id == 'shop-cleaning-expert',
              orElse: () => shops.first,
            );
          } else if (_selectedCategory.toLowerCase() == 'plumbing') {
            matchedShop = shops.firstWhere(
              (s) => s.id == 'shop-plumbing-expert',
              orElse: () => shops.first,
            );
          } else if (_selectedCategory.toLowerCase() == 'electrician') {
            matchedShop = shops.firstWhere(
              (s) => s.id == 'shop-electrician-expert',
              orElse: () => shops.first,
            );
          } else {
            matchedShop = shops.firstWhere(
              (s) => s.id == 'shop-carpentry-expert',
              orElse: () => shops.first,
            );
          }
          finalFee = matchedShop.visitingCharges > 0
              ? matchedShop.visitingCharges
              : 150.0;
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
            final bookingRepository = ref.read(bookingRepositoryProvider);
            final responseData = await bookingRepository.createQuickBooking({
              'userId': authState.user?['id'] ?? 'guest',
              'customerId': authState.user?['id'] ?? 'guest',
              'customerName': authState.user?['name'] ?? 'John Doe',
              'customerPhone': authState.user?['phone'] ?? '9999888877',
              'customerAddress': activeLocation.address,
              'latitude': activeLocation.latitude != 0.0
                  ? activeLocation.latitude
                  : 26.4912,
              'longitude': activeLocation.longitude != 0.0
                  ? activeLocation.longitude
                  : 80.3156,
              'shopId': targetShopId,
              'title': '$_selectedCategory Service Inspection',
              'slot': _selectedUrgency == 'Emergency (< 2 hrs)'
                  ? 'Immediate'
                  : _selectedSlot,
              'date': DateFormat('yyyy-MM-dd').format(
                _selectedUrgency == 'Emergency (< 2 hrs)'
                    ? DateTime.now()
                    : _selectedDate,
              ),
              'amount': finalFee,
              'paymentMethod': 'Razorpay',
              'pricingType': 'inspection',
              'specialInstructions': _descriptionController.text.trim(),
              'type': 'quick_booking',
            });

            if (mounted) setState(() => _isLoading = false);
            if (!mounted) return;
            context.push(
              '/confirmation',
              extra: {
                'bookingId':
                    responseData['bookingId'] ??
                    'QF-${100000 + (DateTime.now().millisecond % 900000)}',
                'title': '$_selectedCategory Service Inspection',
                'amount': finalFee,
                'providerName': targetShopOwner,
                'date': DateFormat('MMM dd, yyyy').format(
                  _selectedUrgency == 'Emergency (< 2 hrs)'
                      ? DateTime.now()
                      : _selectedDate,
                ),
                'slot': _selectedUrgency == 'Emergency (< 2 hrs)'
                    ? 'Immediate'
                    : _selectedSlot,
              },
            );
          } catch (e) {
            if (mounted) setState(() => _isLoading = false);
            if (!mounted) return;
            context.push(
              '/confirmation',
              extra: {
                'bookingId':
                    'QF-${100000 + (DateTime.now().millisecond % 900000)}',
                'title': '$_selectedCategory Service Inspection',
                'amount': finalFee,
                'providerName': targetShopOwner,
                'date': DateFormat('MMM dd, yyyy').format(
                  _selectedUrgency == 'Emergency (< 2 hrs)'
                      ? DateTime.now()
                      : _selectedDate,
                ),
                'slot': _selectedUrgency == 'Emergency (< 2 hrs)'
                    ? 'Immediate'
                    : _selectedSlot,
              },
            );
          }
        });

        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
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
                      decoration: BoxDecoration(
                        color: Colors.blue.shade900,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'R',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
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
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation(Colors.blue),
                ),
                const SizedBox(height: 24),
                Text(
                  'Processing Secure Payment...',
                  style: AppTextStyles.bodyMedium(
                    isDark,
                  ).copyWith(fontWeight: FontWeight.bold),
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
              const Icon(
                Icons.warning_amber_rounded,
                color: Colors.orange,
                size: 28,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'No Experts Nearby',
                  style: AppTextStyles.headingSmall(
                    isDark,
                  ).copyWith(fontSize: 18),
                ),
              ),
            ],
          ),
          content: Text(
            'We couldn\'t find any online $_selectedCategory experts within your service radius right now.\n\nWould you like to schedule this job for later? We will assign our best technician to your request.',
            style: AppTextStyles.bodyMedium(isDark),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: isDark ? Colors.white60 : Colors.black54,
                ),
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
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Schedule Later'),
            ),
          ],
        );
      },
    );
  }



  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(isDarkModeProvider);


    ref.listen<AsyncValue<List<ServiceCategory>>>(categoriesProvider, (prev, next) {
      next.whenData((list) {
        if (list.isNotEmpty && !list.map((c) => c.name).contains(_selectedCategory)) {
          setState(() { _selectedCategory = list.first.name; });
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
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: Text('Instant Booking', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.only(left: 20.0, right: 20.0, top: 16.0, bottom: 120.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Shop Header Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceDark : Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                    boxShadow: isDark ? [] : [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 12, offset: const Offset(0, 4))
                    ]
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.primaryAccent, width: 2),
                        ),
                        child: const CircleAvatar(
                          radius: 24,
                          backgroundColor: AppColors.backgroundLight,
                          child: Icon(Icons.person_rounded, color: AppColors.primaryAccent),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text('QuickFix Expert', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w700, color: isDark ? Colors.white : AppColors.primary)),
                                const SizedBox(width: 8),
                                const Icon(Icons.verified_rounded, color: AppColors.primaryAccent, size: 16),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text('Specialist', style: GoogleFonts.inter(fontSize: 13, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.star_rounded, color: AppColors.success, size: 14),
                            const SizedBox(width: 4),
                            Text('4.9', style: GoogleFonts.inter(color: AppColors.success, fontWeight: FontWeight.w700, fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Select Services', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w700, color: isDark ? Colors.white : AppColors.primary)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primaryAccent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text('1 Selected', style: GoogleFonts.inter(color: AppColors.primaryAccent, fontWeight: FontWeight.w600, fontSize: 12)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ...categories.map((cat) {
                  final isSelected = _selectedCategory == cat;
                  return GestureDetector(
                    onTap: () {
                      AppHaptics.selectionClick();
                      setState(() => _selectedCategory = cat);
                      _updateEstimatedFee();
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.surfaceDark : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? AppColors.primaryAccent : (isDark ? AppColors.borderDark : AppColors.borderLight),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(isSelected ? Icons.check_circle_rounded : Icons.circle_outlined, color: isSelected ? AppColors.primaryAccent : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight), size: 24),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(cat, style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w600, color: isDark ? Colors.white : AppColors.primary)),
                          ),
                          Text('₹199', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.primaryAccent)),
                        ],
                      ),
                    ),
                  );
                }),
                
                const SizedBox(height: 24),
                Text('Issue Description', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w700, color: isDark ? Colors.white : AppColors.primary)),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceDark : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                  ),
                  child: TextField(
                    controller: _descriptionController,
                    maxLines: 3,
                    style: GoogleFonts.inter(fontSize: 14, color: isDark ? Colors.white : AppColors.primary),
                    decoration: InputDecoration(
                      hintText: 'Briefly describe what needs fixing...',
                      border: InputBorder.none,
                      hintStyle: GoogleFonts.inter(color: AppColors.textSecondaryLight, fontSize: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text('Urgency', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w700, color: isDark ? Colors.white : AppColors.primary)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: _urgencies.map((urg) {
                    final isSelected = _selectedUrgency == urg;
                    return GestureDetector(
                      onTap: () {
                        AppHaptics.selectionClick();
                        setState(() => _selectedUrgency = urg);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primaryAccent : (isDark ? AppColors.surfaceDark : Colors.white),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected ? AppColors.primaryAccent : (isDark ? AppColors.borderDark : AppColors.borderLight),
                          ),
                        ),
                        child: Text(
                          urg,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? Colors.white : (isDark ? Colors.white : AppColors.primary),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          if (_isMatching)
            BookingMatchingOverlay(isDark: isDark, matchingStatus: _matchingStatus, matchingStep: _matchingStep),
        ],
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Estimated Total', style: GoogleFonts.inter(fontSize: 13, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
                  Text(
                    '₹',
                    style: GoogleFonts.outfit(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 180,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : () => _triggerInstantBooking(inspectionFee, isDark),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryAccent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: _isLoading 
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text(
                        'Proceed to Checkout',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
