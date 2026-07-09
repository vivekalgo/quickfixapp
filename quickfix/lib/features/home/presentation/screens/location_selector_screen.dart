import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/haptics.dart';
import '../../../../core/database/hive_service.dart';
import '../providers/home_providers.dart';

const String _mapsApiKey = 'AIzaSyDNwQdFkn1OJjBEd6_uKGNuJGnVYNNhBN4';

class LocationSelectorScreen extends ConsumerStatefulWidget {
  const LocationSelectorScreen({super.key});

  @override
  ConsumerState<LocationSelectorScreen> createState() =>
      _LocationSelectorScreenState();
}

class _LocationSelectorScreenState
    extends ConsumerState<LocationSelectorScreen> {
  final TextEditingController _searchController = TextEditingController();
  GoogleMapController? _mapController;

  // Track current pin position and resolved address
  LatLng _pinPosition = const LatLng(26.4912, 80.3156); // Default: Kanpur
  String _resolvedAddress = '';
  double _resolvedLat = 26.4912;
  double _resolvedLng = 80.3156;

  bool _isLocating = false;
  bool _isSearching = false;
  bool _isResolving = false;
  List<Map<String, dynamic>> _suggestions = [];
  bool _showSuggestions = false;

  final FocusNode _searchFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    final current = ref.read(currentAddressProvider);
    _pinPosition = LatLng(current.latitude, current.longitude);
    _resolvedLat = current.latitude;
    _resolvedLng = current.longitude;
    _resolvedAddress = current.address;

    _searchFocus.addListener(() {
      if (!_searchFocus.hasFocus) {
        setState(() {
          _showSuggestions = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _mapController?.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  // ──────────────────────────── GPS ────────────────────────────

  Future<void> _useCurrentGPS() async {
    AppHaptics.heavyTap();
    setState(() => _isLocating = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showSnack('Please enable location services on your device.');
        return;
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _showSnack('Location permission is required to use this feature.');
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 10));
      final latLng = LatLng(pos.latitude, pos.longitude);
      _movePinTo(latLng);
      _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: latLng, zoom: 16),
        ),
      );
      AppHaptics.successNotification();
    } catch (e) {
      _showSnack('Could not fetch GPS location: $e');
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  // ──────────────────────────── Reverse Geocode ────────────────────────────

  Future<void> _movePinTo(LatLng pos) async {
    setState(() {
      _pinPosition = pos;
      _resolvedLat = pos.latitude;
      _resolvedLng = pos.longitude;
      _isResolving = true;
      _resolvedAddress = '';
    });
    try {
      final dio = Dio();
      final response = await dio.get(
        'https://maps.googleapis.com/maps/api/geocode/json',
        queryParameters: {
          'latlng': '${pos.latitude},${pos.longitude}',
          'key': _mapsApiKey,
          'language': 'en',
        },
      );
      if (response.statusCode == 200) {
        final results = response.data['results'] as List?;
        if (results != null && results.isNotEmpty) {
          final addr = results[0]['formatted_address'] as String? ?? '';
          if (mounted) {
            setState(() {
              _resolvedAddress = addr;
            });
          }
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _resolvedAddress =
              'Lat: ${pos.latitude.toStringAsFixed(5)}, Lng: ${pos.longitude.toStringAsFixed(5)}';
        });
      }
    } finally {
      if (mounted) setState(() => _isResolving = false);
    }
  }

  // ──────────────────────────── Places Autocomplete ────────────────────────────

  Future<void> _fetchSuggestions(String input) async {
    if (input.trim().length < 2) {
      setState(() {
        _suggestions = [];
        _showSuggestions = false;
      });
      return;
    }
    setState(() => _isSearching = true);
    try {
      final dio = Dio();
      final response = await dio.get(
        'https://maps.googleapis.com/maps/api/place/autocomplete/json',
        queryParameters: {
          'input': input,
          'key': _mapsApiKey,
          'language': 'en',
          'components': 'country:in',
          'types': 'geocode',
        },
      );
      if (response.statusCode == 200) {
        final predictions = response.data['predictions'] as List? ?? [];
        if (mounted) {
          setState(() {
            _suggestions = predictions.map<Map<String, dynamic>>((p) {
              return {
                'description': p['description'] as String? ?? '',
                'place_id': p['place_id'] as String? ?? '',
                'main_text': (p['structured_formatting']?['main_text'] as String?) ?? (p['description'] as String? ?? ''),
                'secondary_text': (p['structured_formatting']?['secondary_text'] as String?) ?? '',
              };
            }).toList();
            _showSuggestions = _suggestions.isNotEmpty;
          });
        }
      }
    } catch (_) {
      // Keep last suggestions on network failure
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  Future<void> _selectSuggestion(Map<String, dynamic> suggestion) async {
    FocusScope.of(context).unfocus();
    _searchController.text = suggestion['description'] as String;
    setState(() {
      _showSuggestions = false;
      _isResolving = true;
    });
    AppHaptics.lightTap();

    try {
      final dio = Dio();
      final response = await dio.get(
        'https://maps.googleapis.com/maps/api/place/details/json',
        queryParameters: {
          'place_id': suggestion['place_id'],
          'fields': 'geometry,formatted_address',
          'key': _mapsApiKey,
        },
      );
      if (response.statusCode == 200 &&
          response.data['result'] != null) {
        final loc = response.data['result']['geometry']['location'];
        final lat = (loc['lat'] as num).toDouble();
        final lng = (loc['lng'] as num).toDouble();
        final addr = response.data['result']['formatted_address'] as String? ??
            suggestion['description'] as String;

        final latLng = LatLng(lat, lng);
        if (mounted) {
          setState(() {
            _pinPosition = latLng;
            _resolvedLat = lat;
            _resolvedLng = lng;
            _resolvedAddress = addr;
            _isResolving = false;
          });
        }
        _mapController?.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(target: latLng, zoom: 16),
          ),
        );
      }
    } catch (_) {
      if (mounted) setState(() => _isResolving = false);
    }
  }

  // ──────────────────────────── Confirm Selection ────────────────────────────

  void _confirmLocation() {
    AppHaptics.successNotification();
    ref.read(currentAddressProvider.notifier).updateLocation(
          _resolvedAddress.isNotEmpty
              ? _resolvedAddress
              : 'Lat: ${_resolvedLat.toStringAsFixed(5)}, Lng: ${_resolvedLng.toStringAsFixed(5)}',
          _resolvedLat,
          _resolvedLng,
        );
    // Save to hive saved addresses list for quick-pick
    HiveService.saveAddress(_resolvedAddress, lat: _resolvedLat, lng: _resolvedLng);

    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/home');
    }
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  // ──────────────────────────── Build ────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(isDarkModeProvider);

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // ─── 1. Full-screen Google Map ───
          Positioned.fill(
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _pinPosition,
                zoom: 15,
              ),
              mapType: MapType.normal,
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              compassEnabled: false,
              onMapCreated: (controller) {
                _mapController = controller;
              },
              onCameraMove: (pos) {
                // Update pin position as user drags map
                setState(() {
                  _pinPosition = pos.target;
                  _resolvedLat = pos.target.latitude;
                  _resolvedLng = pos.target.longitude;
                });
              },
              onCameraIdle: () {
                // Reverse geocode once camera stops moving
                _movePinTo(_pinPosition);
              },
            ),
          ),

          // ─── 2. Center pin overlay ───
          const Center(
            child: Padding(
              // Offset upward to pin tip appears at map center
              padding: EdgeInsets.only(bottom: 48),
              child: Icon(
                Icons.location_pin,
                color: AppColors.primary,
                size: 48,
                shadows: [
                  Shadow(
                    color: Colors.black38,
                    blurRadius: 8,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
            ),
          ),

          // ─── 3. Top search bar & back button ───
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      children: [
                        // Back button
                        Material(
                          color: isDark ? AppColors.surfaceDark : Colors.white,
                          shape: const CircleBorder(),
                          elevation: 4,
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: () {
                              AppHaptics.lightTap();
                              if (context.canPop()) {
                                context.pop();
                              } else {
                                context.go('/home');
                              }
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(10),
                              child: Icon(
                                Icons.arrow_back,
                                color: isDark ? Colors.white : AppColors.secondary,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Search field
                        Expanded(
                          child: Material(
                            color: isDark ? AppColors.surfaceDark : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            elevation: 4,
                            child: TextField(
                              controller: _searchController,
                              focusNode: _searchFocus,
                              style: TextStyle(
                                fontSize: 14,
                                color: isDark ? Colors.white : AppColors.secondary,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Search area, street, city...',
                                hintStyle: const TextStyle(
                                  color: AppColors.textSecondaryLight,
                                  fontSize: 13,
                                ),
                                prefixIcon: const Icon(
                                  Icons.search,
                                  color: AppColors.primary,
                                  size: 20,
                                ),
                                suffixIcon: _searchController.text.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.close, size: 18),
                                        color: AppColors.textSecondaryLight,
                                        onPressed: () {
                                          _searchController.clear();
                                          setState(() {
                                            _suggestions = [];
                                            _showSuggestions = false;
                                          });
                                        },
                                      )
                                    : (_isSearching
                                        ? const Padding(
                                            padding: EdgeInsets.all(12),
                                            child: SizedBox(
                                              width: 16,
                                              height: 16,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: AppColors.primary,
                                              ),
                                            ),
                                          )
                                        : null),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                    vertical: 14, horizontal: 12),
                              ),
                              onChanged: (val) {
                                setState(() {}); // to refresh suffixIcon
                                _fetchSuggestions(val);
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ─── Suggestions dropdown ───
                  if (_showSuggestions)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Material(
                        color: isDark ? AppColors.surfaceDark : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        elevation: 6,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 280),
                          child: ListView.separated(
                            shrinkWrap: true,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            physics: const BouncingScrollPhysics(),
                            itemCount: _suggestions.length,
                            separatorBuilder: (_, __) => Divider(
                              height: 1,
                              color: isDark
                                  ? AppColors.borderDark
                                  : AppColors.borderLight,
                              indent: 48,
                            ),
                            itemBuilder: (context, index) {
                              final s = _suggestions[index];
                              return InkWell(
                                onTap: () => _selectSuggestion(s),
                                borderRadius: BorderRadius.circular(8),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 12),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Icon(
                                        Icons.location_on_outlined,
                                        color: AppColors.primary,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              s['main_text'] as String,
                                              style: TextStyle(
                                                fontSize: 13.5,
                                                fontWeight: FontWeight.w600,
                                                color: isDark
                                                    ? Colors.white
                                                    : AppColors.secondary,
                                              ),
                                            ),
                                            if ((s['secondary_text']
                                                    as String)
                                                .isNotEmpty) ...[
                                              const SizedBox(height: 2),
                                              Text(
                                                s['secondary_text']
                                                    as String,
                                                style:
                                                    AppTextStyles.bodySmall(
                                                        isDark),
                                                maxLines: 1,
                                                overflow:
                                                    TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // ─── 4. Use GPS button (left side) ───
          Positioned(
            right: 16,
            bottom: 210,
            child: Material(
              color: isDark ? AppColors.surfaceDark : Colors.white,
              shape: const CircleBorder(),
              elevation: 4,
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: _isLocating ? null : _useCurrentGPS,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: _isLocating
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primary,
                          ),
                        )
                      : const Icon(
                          Icons.gps_fixed,
                          color: AppColors.primary,
                          size: 22,
                        ),
                ),
              ),
            ),
          ),

          // ─── 5. Bottom sheet: selected address + confirm button ───
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : Colors.white,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.10),
                    blurRadius: 20,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Pull handle
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white24
                                : Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.10),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.location_on,
                              color: AppColors.primary,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _isResolving
                                ? Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        height: 14,
                                        width: 200,
                                        decoration: BoxDecoration(
                                          color: isDark
                                              ? Colors.white12
                                              : Colors.grey.shade200,
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Container(
                                        height: 10,
                                        width: 120,
                                        decoration: BoxDecoration(
                                          color: isDark
                                              ? Colors.white12
                                              : Colors.grey.shade200,
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                      ),
                                    ],
                                  )
                                : Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _resolvedAddress.isNotEmpty
                                            ? _resolvedAddress
                                            : 'Move map to select location',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: isDark
                                              ? Colors.white
                                              : AppColors.secondary,
                                          height: 1.35,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      // Small coordinates display
                                      Text(
                                        '${_resolvedLat.toStringAsFixed(5)}, ${_resolvedLng.toStringAsFixed(5)}',
                                        style: TextStyle(
                                          fontSize: 10.5,
                                          color: isDark
                                              ? Colors.white38
                                              : Colors.grey.shade500,
                                          fontFeatures: const [
                                            FontFeature('tnum'),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Confirm button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed:
                              (_isResolving || _resolvedAddress.isEmpty)
                                  ? null
                                  : _confirmLocation,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor:
                                AppColors.primary.withOpacity(0.4),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                            elevation: 0,
                          ),
                          child: _isResolving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Confirm This Location',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
