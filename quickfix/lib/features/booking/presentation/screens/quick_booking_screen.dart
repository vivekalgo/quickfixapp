import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/haptics.dart';
import '../../../home/presentation/providers/home_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../../core/database/hive_service.dart';

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

  final List<String> _categories = ['Cleaning', 'Plumbing', 'Electrician', 'Carpentry'];
  final List<String> _urgencies = ['Emergency (< 2 hrs)', 'Today', 'Schedule Later'];
  
  final List<String> _slots = [
    '09:00 AM - 11:00 AM',
    '12:00 PM - 02:00 PM',
    '03:00 PM - 05:00 PM',
    '06:00 PM - 08:00 PM',
  ];

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _triggerInstantBooking(double feeAmount, bool isDark) async {
    if (_descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please describe the issue briefly for the expert.')),
      );
      return;
    }

    AppHaptics.heavyTap();
    setState(() => _isLoading = true);

    try {
      final authState = ref.read(authProvider);
      final activeLocation = ref.read(currentAddressProvider);
      final dio = Dio();
      dio.options.baseUrl = 'http://10.0.2.2:5000/api';

      final token = HiveService.getAuthToken();

      await dio.post(
        '/bookings/create',
        data: {
          'userId': authState.user?['id'] ?? 'guest',
          'category': _selectedCategory,
          'description': _descriptionController.text.trim(),
          'urgency': _selectedUrgency,
          'slot': _selectedSlot,
          'date': DateFormat('yyyy-MM-dd').format(_selectedDate),
          'address': activeLocation.address,
          'latitude': activeLocation.latitude,
          'longitude': activeLocation.longitude,
          'amount': feeAmount,
          'type': 'quick_booking',
        },
        options: Options(headers: {
          if (token != null) 'Authorization': 'Bearer $token',
        }),
      );

      if (!mounted) return;
      setState(() => _isLoading = false);
    } catch (e) {
      // Non-blocking: even if backend fails (e.g. offline), proceed to confirm flow
      if (mounted) setState(() => _isLoading = false);
    }

    if (!mounted) return;

    // Show payment gateway dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        Future.delayed(const Duration(milliseconds: 1500), () {
          AppHaptics.successNotification();
          Navigator.pop(context);
          context.push('/confirmation');
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
                  'Paying ₹${feeAmount.toInt()} inspection deposit',
                  style: AppTextStyles.bodySmall(isDark),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(isDarkModeProvider);
    final currentAddress = ref.watch(currentAddressProvider).address;
    const double inspectionFee = 199.0;

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
      body: SingleChildScrollView(
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
              children: _categories.map<Widget>((cat) {
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
                            ? AppColors.primary.withOpacity(0.1) 
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
                      Text('₹${inspectionFee.toInt()}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
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
              children: const [
                Text('Book Inspection Instantly', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                SizedBox(width: 8),
                Icon(Icons.lock, size: 16),
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
