import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import 'dart:convert';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/haptics.dart';
import '../../../../core/database/hive_service.dart';
import '../providers/home_providers.dart';

class LocationSelectorScreen extends ConsumerStatefulWidget {
  const LocationSelectorScreen({super.key});

  @override
  ConsumerState<LocationSelectorScreen> createState() => _LocationSelectorScreenState();
}

class _LocationSelectorScreenState extends ConsumerState<LocationSelectorScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isLocating = false;
  bool _isSearching = false;
  List<Map<String, dynamic>> _searchResults = [];
  late final List<String> _savedAddresses;

  @override
  void initState() {
    super.initState();
    _savedAddresses = HiveService.getSavedAddresses();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchGPSLocation() async {
    AppHaptics.heavyTap();
    setState(() {
      _isLocating = true;
    });

    try {
      bool success = await ref.read(currentAddressProvider.notifier).fetchGPSLocation(requestPermission: true);
      if (success) {
        AppHaptics.successNotification();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('GPS Location updated successfully!'), behavior: SnackBarBehavior.floating),
          );
          context.pop();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location access is off. Please enable GPS and allow permission.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
          setState(() {
            _isLocating = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to fetch current location: $e'), behavior: SnackBarBehavior.floating),
        );
        setState(() {
          _isLocating = false;
        });
      }
    }
  }

  void _selectAddress(String addr, {double? lat, double? lng}) {
    AppHaptics.lightTap();
    if (lat != null && lng != null) {
      ref.read(currentAddressProvider.notifier).updateLocation(addr, lat, lng);
    } else {
      // Map popular areas or unknown addresses
      double finalLat = 26.4912;
      double finalLng = 80.3156;
      if (addr.contains('Swaroop Nagar')) {
        finalLat = 26.4912; finalLng = 80.3156;
      } else if (addr.contains('Kakadeo')) {
        finalLat = 26.4842; finalLng = 80.3015;
      } else if (addr.contains('Civil Lines')) {
        finalLat = 26.4715; finalLng = 80.3478;
      } else if (addr.contains('Kalyanpur')) {
        finalLat = 26.5168; finalLng = 80.2584;
      } else if (addr.contains('Govind Nagar')) {
        finalLat = 26.4442; finalLng = 80.3125;
      } else if (addr.contains('Lajpat Nagar')) {
        finalLat = 26.4754; finalLng = 80.3190;
      }
      ref.read(currentAddressProvider.notifier).updateLocation(addr, finalLat, finalLng);
    }
    context.pop();
  }

  Future<void> _searchLocation(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }
    setState(() {
      _isSearching = true;
    });
    try {
      final dio = Dio();
      dio.options.headers['User-Agent'] = 'QuickFixApp/1.0';
      final response = await dio.get(
        'https://nominatim.openstreetmap.org/search',
        queryParameters: {
          'q': query,
          'format': 'json',
          'limit': 6,
          'addressdetails': 1,
          'countrycodes': 'in', // Kanpur, India context
        },
      );
      if (response.statusCode == 200 && response.data != null) {
        final list = response.data as List;
        if (mounted) {
          setState(() {
            _searchResults = list.map((item) {
              final displayName = item['display_name'] as String;
              final address = item['address'] as Map<String, dynamic>?;
              String shortName = displayName;
              if (address != null) {
                final first = address['road'] ?? address['suburb'] ?? address['neighbourhood'] ?? address['amenity'] ?? address['city_district'] ?? '';
                final second = address['city'] ?? address['town'] ?? address['state'] ?? '';
                if (first.toString().isNotEmpty && second.toString().isNotEmpty) {
                  shortName = "$first, $second";
                }
              }
              return {
                'display': shortName,
                'full': displayName,
                'lat': item['lat'],
                'lon': item['lon'],
              };
            }).toList();
          });
        }
      }
    } catch (e) {
      // Ignore search failures and keep the manual location flow usable.
    } finally {
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(isDarkModeProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Select Location', style: AppTextStyles.headingMedium(isDark)),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            AppHaptics.lightTap();
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
      ),
      body: Column(
        children: [
          // 1. Zomato-style Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search, color: AppColors.primary, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      style: TextStyle(fontSize: 14, color: isDark ? Colors.white : AppColors.secondary),
                      decoration: const InputDecoration(
                        hintText: 'Search for area, street name...',
                        border: InputBorder.none,
                        hintStyle: TextStyle(color: AppColors.textSecondaryLight, fontSize: 13),
                      ),
                      onChanged: (val) {
                        setState(() {});
                        _searchLocation(val);
                      },
                      onSubmitted: (val) {
                        if (val.trim().isNotEmpty) {
                          _selectAddress(val);
                        }
                      },
                    ),
                  ),
                  if (_searchController.text.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.close, size: 18, color: AppColors.textSecondaryLight),
                      onPressed: () {
                        AppHaptics.lightTap();
                        _searchController.clear();
                        setState(() {
                          _searchResults = [];
                        });
                      },
                    ),
                ],
              ),
            ),
          ),

          Expanded(
            child: _searchController.text.trim().isNotEmpty
                ? _buildSearchResults(isDark)
                : _buildDefaultList(isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults(bool isDark) {
    if (_isSearching) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }
    if (_searchResults.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.location_off_outlined, size: 48, color: AppColors.textSecondaryLight),
              const SizedBox(height: 16),
              Text(
                'No locations found',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.secondary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Try searching for a different area or neighborhood name.',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodySmall(isDark),
              ),
            ],
          ),
        ),
      );
    }
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final result = _searchResults[index];
        final double? lat = double.tryParse(result['lat']?.toString() ?? '');
        final double? lng = double.tryParse(result['lon']?.toString() ?? '');
        return InkWell(
          onTap: () => _selectAddress(result['full']!, lat: lat, lng: lng),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.location_on_outlined, color: AppColors.primary, size: 20),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        result['display']!,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : AppColors.secondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        result['full']!,
                        style: AppTextStyles.bodySmall(isDark).copyWith(fontSize: 12),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDefaultList(bool isDark) {
    final savedAddresses = _savedAddresses;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 2. Use Current Location GPS trigger
          InkWell(
            onTap: _isLocating ? null : _fetchGPSLocation,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.08),
                      shape: BoxShape.circle,
                    ),
                    child: _isLocating 
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(AppColors.primary)))
                        : const Icon(Icons.gps_fixed, color: AppColors.primary, size: 18),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Use Current Location',
                          style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        Text(
                          _isLocating ? 'Locating using GPS satellites...' : 'Using Geolocator coordinates mapping',
                          style: AppTextStyles.bodySmall(isDark),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: AppColors.textSecondaryLight),
                ],
              ),
            ),
          ),

          const Divider(height: 32),

          // 3. Saved Addresses Section
          Text('Saved Addresses', style: AppTextStyles.headingSmall(isDark).copyWith(fontSize: 14)),
          const SizedBox(height: 12),
          if (savedAddresses.isEmpty)
            Text(
              'No saved addresses yet',
              style: AppTextStyles.bodySmall(isDark),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: savedAddresses.length,
              itemBuilder: (context, index) {
                final addrRaw = savedAddresses[index];
                String cleanAddr = addrRaw;
                double? lat;
                double? lng;
                if (addrRaw.startsWith('{')) {
                  try {
                    final parsed = jsonDecode(addrRaw) as Map<String, dynamic>;
                    cleanAddr = parsed['address'] ?? '';
                    lat = (parsed['latitude'] as num?)?.toDouble();
                    lng = (parsed['longitude'] as num?)?.toDouble();
                  } catch (_) {}
                }
                return InkWell(
                  onTap: () => _selectAddress(cleanAddr, lat: lat, lng: lng),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.location_on_outlined, color: isDark ? Colors.white70 : AppColors.secondary, size: 20),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Saved Address ${index + 1}',
                                style: AppTextStyles.bodyMedium(isDark).copyWith(fontWeight: FontWeight.bold, fontSize: 13.5),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                cleanAddr,
                                style: AppTextStyles.bodySmall(isDark).copyWith(fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

          const Divider(height: 32),

          // 4. Recent Locations
          Text('Recent Locations', style: AppTextStyles.headingSmall(isDark).copyWith(fontSize: 14)),
          const SizedBox(height: 12),
          if (savedAddresses.isEmpty)
            Text(
              'Your recently used locations will appear here after you save one.',
              style: AppTextStyles.bodySmall(isDark),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: savedAddresses.take(6).map((area) {
                return InkWell(
                  onTap: () => _selectAddress(area),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceDark : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: isDark ? AppColors.borderDark : Colors.grey.shade200),
                    ),
                    child: Text(
                      area,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: isDark ? Colors.white70 : AppColors.secondary,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
