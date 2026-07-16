import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:geolocator/geolocator.dart';
import 'package:quickfix/features/profile/presentation/controllers/profile_providers.dart';
import 'package:quickfix/core/theme/app_colors.dart';
import 'package:quickfix/core/theme/app_text_styles.dart';
import 'package:quickfix/core/utils/haptics.dart';
import 'package:quickfix/features/home/presentation/controllers/home_providers.dart';
import 'package:quickfix/features/auth/presentation/controllers/auth_providers.dart';

class AddressesScreen extends ConsumerStatefulWidget {
  const AddressesScreen({super.key});

  @override
  ConsumerState<AddressesScreen> createState() => _AddressesScreenState();
}

class _AddressesScreenState extends ConsumerState<AddressesScreen> {
  IconData _getIconForLabel(String label) {
    final lower = label.toLowerCase();
    if (lower.contains('home')) return Icons.home_outlined;
    if (lower.contains('work') || lower.contains('office'))
      return Icons.work_outline;
    return Icons.location_on_outlined;
  }

  Future<void> _deleteAddress(Map<String, dynamic> address) async {
    final authState = ref.read(authProvider);
    final user = authState.user;
    if (user == null) return;

    AppHaptics.heavyTap();

    final currentList = List<dynamic>.from(user['savedAddresses'] ?? []);
    currentList.removeWhere((item) => item['id'] == address['id']);

    try {
      await ref.read(authProvider.notifier).updateProfile({
        'savedAddresses': currentList,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Address deleted successfully'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete address: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _setDefaultAddress(Map<String, dynamic> address) async {
    final authState = ref.read(authProvider);
    final user = authState.user;
    if (user == null) return;

    AppHaptics.mediumTap();

    final currentList = List<dynamic>.from(user['savedAddresses'] ?? []).map((
      item,
    ) {
      final copy = Map<String, dynamic>.from(item);
      copy['isDefault'] = copy['id'] == address['id'];
      return copy;
    }).toList();

    try {
      await ref.read(authProvider.notifier).updateProfile({
        'savedAddresses': currentList,
      });

      // Update current active location in the app
      ref
          .read(currentAddressProvider.notifier)
          .updateLocation(
            address['address']?.toString() ?? '',
            (address['latitude'] as num?)?.toDouble() ?? 26.4912,
            (address['longitude'] as num?)?.toDouble() ?? 80.3156,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Default address updated'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showAddressForm({Map<String, dynamic>? existingAddress}) {
    AppHaptics.lightTap();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddressFormSheet(
        existingAddress: existingAddress,
        onSave: (addressData) async {
          final authState = ref.read(authProvider);
          final user = authState.user;
          if (user == null) return;

          final currentList = List<dynamic>.from(user['savedAddresses'] ?? []);

          if (existingAddress != null) {
            // Update existing
            final index = currentList.indexWhere(
              (item) => item['id'] == existingAddress['id'],
            );
            if (index != -1) {
              currentList[index] = addressData;
            }
          } else {
            // Add new
            // If this is the first address, or isDefault is true, set others as non-default
            if (addressData['isDefault'] == true || currentList.isEmpty) {
              addressData['isDefault'] = true;
              for (var item in currentList) {
                item['isDefault'] = false;
              }
            }
            currentList.add(addressData);
          }

          try {
            await ref.read(authProvider.notifier).updateProfile({
              'savedAddresses': currentList,
            });

            // If default was added/updated, update the active location
            if (addressData['isDefault'] == true) {
              ref
                  .read(currentAddressProvider.notifier)
                  .updateLocation(
                    addressData['address']?.toString() ?? '',
                    (addressData['latitude'] as num?)?.toDouble() ?? 26.4912,
                    (addressData['longitude'] as num?)?.toDouble() ?? 80.3156,
                  );
            }

            if (mounted) {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    existingAddress != null
                        ? 'Address updated'
                        : 'Address added',
                  ),
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: AppColors.success,
                ),
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Failed to save address: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(isDarkModeProvider);
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final addresses = user?['savedAddresses'] as List<dynamic>? ?? [];

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: isDark
            ? AppColors.backgroundDark
            : AppColors.backgroundLight,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Saved Addresses',
          style: AppTextStyles.headingMedium(isDark),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: addresses.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.location_off_outlined,
                              size: 72,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'No Saved Addresses',
                            style: AppTextStyles.headingMedium(isDark),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Please add your home, office or other delivery addresses to find hyperlocal services easily.',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.bodyMedium(isDark).copyWith(
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondaryLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    itemCount: addresses.length,
                    itemBuilder: (context, index) {
                      final item = Map<String, dynamic>.from(addresses[index]);
                      final label = item['label']?.toString() ?? 'Other';
                      final address = item['address']?.toString() ?? '';
                      final isDefault = item['isDefault'] as bool? ?? false;

                      return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.surfaceDark
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isDefault
                                    ? AppColors.primary
                                    : (isDark
                                          ? AppColors.borderDark
                                          : AppColors.borderLight),
                                width: isDefault ? 1.5 : 1.0,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.02),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () => _setDefaultAddress(item),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color:
                                            (isDefault
                                                    ? AppColors.primary
                                                    : AppColors
                                                          .textSecondaryLight)
                                                .withValues(alpha: 0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        _getIconForLabel(label),
                                        color: isDefault
                                            ? AppColors.primary
                                            : AppColors.textSecondaryLight,
                                        size: 22,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Text(
                                                label,
                                                style:
                                                    AppTextStyles.bodyLarge(
                                                      isDark,
                                                    ).copyWith(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                              ),
                                              if (isDefault) ...[
                                                const SizedBox(width: 8),
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 2,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: AppColors.primary
                                                        .withValues(alpha: 0.1),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          6,
                                                        ),
                                                  ),
                                                  child: const Text(
                                                    'DEFAULT',
                                                    style: TextStyle(
                                                      color: AppColors.primary,
                                                      fontSize: 9,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      letterSpacing: 0.5,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            address,
                                            style:
                                                AppTextStyles.bodySmall(
                                                  isDark,
                                                ).copyWith(
                                                  color: isDark
                                                      ? AppColors
                                                            .textSecondaryDark
                                                      : AppColors
                                                            .textSecondaryLight,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(
                                            Icons.edit_outlined,
                                            size: 20,
                                          ),
                                          onPressed: () => _showAddressForm(
                                            existingAddress: item,
                                          ),
                                          color: isDark
                                              ? AppColors.textSecondaryDark
                                              : AppColors.textSecondaryLight,
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.delete_outline,
                                            size: 20,
                                          ),
                                          onPressed: () => _deleteAddress(item),
                                          color: AppColors.error,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          )
                          .animate(delay: (50 * index).ms)
                          .fadeIn()
                          .slideY(begin: 0.05, end: 0);
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: ElevatedButton.icon(
              onPressed: () => _showAddressForm(),
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                'Add New Address',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                minimumSize: const Size(double.infinity, 54),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddressFormSheet extends ConsumerStatefulWidget {
  final Map<String, dynamic>? existingAddress;
  final Function(Map<String, dynamic>) onSave;

  const _AddressFormSheet({this.existingAddress, required this.onSave});

  @override
  ConsumerState<_AddressFormSheet> createState() => _AddressFormSheetState();
}

class _AddressFormSheetState extends ConsumerState<_AddressFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _addressController;
  late TextEditingController _customLabelController;

  String _selectedLabel = 'Home';
  bool _isDefault = false;
  double _latitude = 26.4912;
  double _longitude = 80.3156;
  bool _isLocating = false;

  @override
  void initState() {
    super.initState();
    final addr = widget.existingAddress;
    _addressController = TextEditingController(
      text: addr?['address']?.toString() ?? '',
    );
    _customLabelController = TextEditingController();

    if (addr != null) {
      final label = addr['label']?.toString() ?? 'Home';
      if (['Home', 'Work'].contains(label)) {
        _selectedLabel = label;
      } else {
        _selectedLabel = 'Other';
        _customLabelController.text = label;
      }
      _isDefault = addr['isDefault'] as bool? ?? false;
      _latitude = (addr['latitude'] as num?)?.toDouble() ?? 26.4912;
      _longitude = (addr['longitude'] as num?)?.toDouble() ?? 80.3156;
    }
  }

  @override
  void dispose() {
    _addressController.dispose();
    _customLabelController.dispose();
    super.dispose();
  }

  Future<void> _fetchGPSLocation() async {
    setState(() => _isLocating = true);
    AppHaptics.mediumTap();

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw 'Location services are disabled.';
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw 'Location permissions are denied.';
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw 'Location permissions are permanently denied.';
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 8),
      );

      _latitude = position.latitude;
      _longitude = position.longitude;

      // Reverse geocoding
      final repository = ref.read(profileRepositoryProvider);
      final displayName = await repository.reverseGeocode(_latitude, _longitude);
      if (displayName != null) {
        setState(() {
          _addressController.text = displayName;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not get GPS location: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(isDarkModeProvider);
    final double keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 24, 20, 24 + keyboardHeight),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.existingAddress != null
                        ? 'Edit Address'
                        : 'Add Delivery Address',
                    style: AppTextStyles.headingMedium(
                      isDark,
                    ).copyWith(fontSize: 18),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _isLocating ? null : _fetchGPSLocation,
                icon: _isLocating
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primary,
                        ),
                      )
                    : const Icon(Icons.gps_fixed, size: 16),
                label: Text(
                  _isLocating ? 'Locating...' : 'Use Current GPS Location',
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  minimumSize: const Size(double.infinity, 44),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Complete Address',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white70 : AppColors.secondary,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _addressController,
                maxLines: 3,
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'Address detail is required'
                    : null,
                style: TextStyle(
                  color: isDark ? Colors.white : AppColors.secondary,
                  fontSize: 14,
                ),
                decoration: InputDecoration(
                  hintText: 'House/Flat No., Road Name, Suburb, City, Pin Code',
                  hintStyle: const TextStyle(
                    color: AppColors.textSecondaryLight,
                    fontSize: 13,
                  ),
                  filled: true,
                  fillColor: isDark
                      ? AppColors.backgroundDark
                      : Colors.grey.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: isDark
                          ? AppColors.borderDark
                          : AppColors.borderLight,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: isDark
                          ? AppColors.borderDark
                          : AppColors.borderLight,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: AppColors.primary,
                      width: 1.5,
                    ),
                  ),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Save Address As',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white70 : AppColors.secondary,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: ['Home', 'Work', 'Other'].map((label) {
                  final isSelected = _selectedLabel == label;
                  return Padding(
                    padding: const EdgeInsets.only(right: 12.0),
                    child: ChoiceChip(
                      label: Text(label),
                      selected: isSelected,
                      selectedColor: AppColors.primary,
                      checkmarkColor: Colors.white,
                      labelStyle: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : (isDark ? Colors.white70 : AppColors.secondary),
                        fontWeight: FontWeight.bold,
                      ),
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _selectedLabel = label;
                          });
                        }
                      },
                    ),
                  );
                }).toList(),
              ),
              if (_selectedLabel == 'Other') ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: _customLabelController,
                  validator: (v) =>
                      _selectedLabel == 'Other' &&
                          (v == null || v.trim().isEmpty)
                      ? 'Please enter a custom label'
                      : null,
                  style: TextStyle(
                    color: isDark ? Colors.white : AppColors.secondary,
                    fontSize: 14,
                  ),
                  decoration: InputDecoration(
                    hintText: 'e.g. Friends House, Gym, Parents Home',
                    hintStyle: const TextStyle(
                      color: AppColors.textSecondaryLight,
                      fontSize: 13,
                    ),
                    filled: true,
                    fillColor: isDark
                        ? AppColors.backgroundDark
                        : Colors.grey.shade50,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: isDark
                            ? AppColors.borderDark
                            : AppColors.borderLight,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: isDark
                            ? AppColors.borderDark
                            : AppColors.borderLight,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: AppColors.primary,
                        width: 1.5,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              CheckboxListTile(
                value: _isDefault,
                title: Text(
                  'Set as default delivery address',
                  style: AppTextStyles.bodyMedium(isDark),
                ),
                contentPadding: EdgeInsets.zero,
                activeColor: AppColors.primary,
                controlAffinity: ListTileControlAffinity.leading,
                onChanged: (v) => setState(() => _isDefault = v ?? false),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  if (!_formKey.currentState!.validate()) return;
                  final labelText = _selectedLabel == 'Other'
                      ? _customLabelController.text.trim()
                      : _selectedLabel;
                  final id =
                      widget.existingAddress?['id']?.toString() ??
                      'addr_${DateTime.now().millisecondsSinceEpoch}';
                  widget.onSave({
                    'id': id,
                    'label': labelText,
                    'address': _addressController.text.trim(),
                    'latitude': _latitude,
                    'longitude': _longitude,
                    'isDefault': _isDefault,
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Save Address',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
