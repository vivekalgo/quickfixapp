import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../providers/shop_provider.dart';

class ShopManagementScreen extends ConsumerStatefulWidget {
  const ShopManagementScreen({super.key});

  @override
  ConsumerState<ShopManagementScreen> createState() => _ShopManagementScreenState();
}

class _ShopManagementScreenState extends ConsumerState<ShopManagementScreen> {
  final _formKeyHours = GlobalKey<FormState>();
  final _formKeyCustomSrv = GlobalKey<FormState>();

  // Operations state
  late double _serviceRadius;
  late double _visitingCharges;
  late bool _emergencyAvailable;
  late List<String> _holidays;
  late Map<String, dynamic> _workingHours;

  // Shop card display fields
  String _estimatedServiceTime = '20 mins';
  String _priceRange = '₹₹';
  bool _bannerUploading = false;
  bool _portfolioUploading = false;

  // Custom service fields
  final _customTitleController = TextEditingController();
  final _customPriceController = TextEditingController();
  final _customDurationController = TextEditingController();
  final _customBulletsController = TextEditingController();
  final _customMinPriceController = TextEditingController();
  final _customMaxPriceController = TextEditingController();
  final _customVisitingController = TextEditingController(text: '150');
  final _customGstController = TextEditingController(text: '0');
  final _customExtraChargesController = TextEditingController(text: '0');
  final _customExtraLabelController = TextEditingController();

  bool _initialized = false;

  @override
  void dispose() {
    _customTitleController.dispose();
    _customPriceController.dispose();
    _customDurationController.dispose();
    _customBulletsController.dispose();
    _customMinPriceController.dispose();
    _customMaxPriceController.dispose();
    _customVisitingController.dispose();
    _customGstController.dispose();
    _customExtraChargesController.dispose();
    _customExtraLabelController.dispose();
    super.dispose();
  }

  void _initFields() {
    if (_initialized) return;
    final shop = ref.read(authProvider).shop;
    if (shop != null) {
      _serviceRadius = shop.serviceRadius;
      _visitingCharges = shop.visitingCharges;
      _emergencyAvailable = shop.emergencyAvailable;
      _holidays = List<String>.from(shop.holidays);
      _workingHours = Map<String, dynamic>.from(shop.workingHours);
      _estimatedServiceTime = shop.estimatedServiceTime;
      _priceRange = shop.priceRange;
      _initialized = true;
    }
  }

  Future<void> _pickAndUploadBanner() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 75);
    if (picked == null) return;

    final bytes = await picked.readAsBytes();
    final base64Image = base64Encode(bytes);
    final mimeType = picked.mimeType ?? 'image/jpeg';

    setState(() => _bannerUploading = true);
    final success = await ref.read(authProvider.notifier).uploadShopBanner(base64Image, mimeType);
    setState(() => _bannerUploading = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Shop banner updated!' : 'Failed to upload banner.'),
          backgroundColor: success ? AppColors.success : AppColors.danger,
        ),
      );
    }
  }

  Future<void> _pickAndUploadPortfolio() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 75);
    if (picked == null) return;

    final bytes = await picked.readAsBytes();
    final base64Image = base64Encode(bytes);
    final mimeType = picked.mimeType ?? 'image/jpeg';

    setState(() => _portfolioUploading = true);
    final success = await ref.read(authProvider.notifier).uploadPortfolioImage(base64Image, mimeType);
    setState(() => _portfolioUploading = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Gallery image added!' : 'Failed to upload image.'),
          backgroundColor: success ? AppColors.success : AppColors.danger,
        ),
      );
    }
  }

  Future<void> _deletePortfolioImage(String imageUrl) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Image'),
        content: const Text('Are you sure you want to delete this image from your gallery?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _portfolioUploading = true);
    final success = await ref.read(authProvider.notifier).deletePortfolioImage(imageUrl);
    setState(() => _portfolioUploading = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Image deleted from gallery!' : 'Failed to delete image.'),
          backgroundColor: success ? AppColors.success : AppColors.danger,
        ),
      );
    }
  }

  Future<void> _saveShopCardFields() async {
    final success = await ref.read(authProvider.notifier).updateShopDetails(
      estimatedServiceTime: _estimatedServiceTime,
      priceRange: _priceRange,
    );
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Shop card details updated!'), backgroundColor: AppColors.success),
      );
    }
  }

  Future<void> _saveOperationalHours() async {
    final success = await ref.read(shopManagementProvider.notifier).updateOperationalHours(
          workingHours: _workingHours,
          holidays: _holidays,
          serviceRadius: _serviceRadius,
          visitingCharges: _visitingCharges,
          emergencyAvailable: _emergencyAvailable,
        );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Operational parameters updated!'), backgroundColor: AppColors.success),
      );
    }
  }

  void _addHolidayDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Holiday Date'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'e.g. 15 Aug 2026',
            filled: true,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                setState(() {
                  _holidays.add(controller.text.trim());
                });
                Navigator.pop(context);
                _saveOperationalHours();
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showAddServiceDialog() {
    String pricingType = 'fixed';
    bool isFreeInspection = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Custom Service'),
          content: Form(
            key: _formKeyCustomSrv,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _customTitleController,
                    decoration: const InputDecoration(labelText: 'Service Name'),
                    validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: pricingType,
                    decoration: const InputDecoration(labelText: 'Pricing Model'),
                    items: const [
                      DropdownMenuItem(value: 'fixed', child: Text('🟢 Fixed Price')),
                      DropdownMenuItem(value: 'starting', child: Text('🟡 Starts From')),
                      DropdownMenuItem(value: 'range', child: Text('🔵 Price Range')),
                      DropdownMenuItem(value: 'inspection', child: Text('🟠 Quote Required')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() {
                          pricingType = val;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  if (pricingType == 'fixed' || pricingType == 'starting')
                    TextFormField(
                      controller: _customPriceController,
                      decoration: InputDecoration(
                        labelText: pricingType == 'fixed' ? 'Price (₹)' : 'Starting Price (₹)',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (val) => val == null || double.tryParse(val) == null ? 'Enter valid price' : null,
                    ),
                  if (pricingType == 'range') ...[
                    TextFormField(
                      controller: _customMinPriceController,
                      decoration: const InputDecoration(labelText: 'Min Price (₹)'),
                      keyboardType: TextInputType.number,
                      validator: (val) => val == null || double.tryParse(val) == null ? 'Enter min price' : null,
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _customMaxPriceController,
                      decoration: const InputDecoration(labelText: 'Max Price (₹)'),
                      keyboardType: TextInputType.number,
                      validator: (val) => val == null || double.tryParse(val) == null ? 'Enter max price' : null,
                    ),
                  ],
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _customDurationController,
                    decoration: const InputDecoration(labelText: 'Duration (e.g. 2 hrs)'),
                    validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _customVisitingController,
                    decoration: const InputDecoration(labelText: 'Visiting Charges (₹)'),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 8),
                  CheckboxListTile(
                    title: const Text('Free Inspection', style: TextStyle(fontSize: 14)),
                    value: isFreeInspection,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (val) {
                      setDialogState(() {
                        isFreeInspection = val ?? false;
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _customGstController,
                    decoration: const InputDecoration(labelText: 'GST (%) (Optional)'),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _customExtraChargesController,
                    decoration: const InputDecoration(labelText: 'Extra Charges (₹) (Optional)'),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _customExtraLabelController,
                    decoration: const InputDecoration(labelText: 'Extra Charges Label (Optional)'),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _customBulletsController,
                    decoration: const InputDecoration(labelText: 'Features (comma separated)'),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!_formKeyCustomSrv.currentState!.validate()) return;
                
                final bullets = _customBulletsController.text
                    .split(',')
                    .map((e) => e.trim())
                    .where((e) => e.isNotEmpty)
                    .toList();

                final success = await ref.read(shopManagementProvider.notifier).addCustomService(
                      title: _customTitleController.text.trim(),
                      price: double.tryParse(_customPriceController.text) ?? 0.0,
                      durationText: _customDurationController.text.trim(),
                      bulletPoints: bullets,
                      pricingType: pricingType,
                      minPrice: double.tryParse(_customMinPriceController.text) ?? 0.0,
                      maxPrice: double.tryParse(_customMaxPriceController.text) ?? 0.0,
                      visitingCharges: double.tryParse(_customVisitingController.text) ?? 0.0,
                      isFreeInspection: isFreeInspection,
                      gst: double.tryParse(_customGstController.text) ?? 0.0,
                      extraCharges: double.tryParse(_customExtraChargesController.text) ?? 0.0,
                      extraChargesLabel: _customExtraLabelController.text.trim(),
                    );

                if (success && mounted) {
                  _customTitleController.clear();
                  _customPriceController.clear();
                  _customMinPriceController.clear();
                  _customMaxPriceController.clear();
                  _customDurationController.clear();
                  _customVisitingController.clear();
                  _customGstController.clear();
                  _customExtraChargesController.clear();
                  _customExtraLabelController.clear();
                  _customBulletsController.clear();
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Custom service added successfully!'), backgroundColor: AppColors.success),
                  );
                }
              },
              child: const Text('Add Service'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditServiceDetailsDialog(Map<String, dynamic> service) {
    final serviceId = service['id']?.toString() ?? '';
    final title = service['title']?.toString() ?? '';
    String pricingType = service['pricingType']?.toString() ?? 'fixed';
    
    final priceController = TextEditingController(text: ((service['price'] as num?)?.toDouble() ?? 0.0).toStringAsFixed(0));
    final minPriceController = TextEditingController(text: ((service['minPrice'] as num?)?.toDouble() ?? 0.0).toStringAsFixed(0));
    final maxPriceController = TextEditingController(text: ((service['maxPrice'] as num?)?.toDouble() ?? 0.0).toStringAsFixed(0));
    final visitingController = TextEditingController(text: ((service['visitingCharges'] as num?)?.toDouble() ?? 150.0).toStringAsFixed(0));
    final gstController = TextEditingController(text: ((service['gst'] as num?)?.toDouble() ?? 0.0).toStringAsFixed(0));
    final extraChargesController = TextEditingController(text: ((service['extraCharges'] as num?)?.toDouble() ?? 0.0).toStringAsFixed(0));
    final extraLabelController = TextEditingController(text: service['extraChargesLabel']?.toString() ?? '');
    bool isFreeInspection = service['isFreeInspection'] as bool? ?? false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Edit Service: $title'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: pricingType,
                  decoration: const InputDecoration(labelText: 'Pricing Model'),
                  items: const [
                    DropdownMenuItem(value: 'fixed', child: Text('🟢 Fixed Price')),
                    DropdownMenuItem(value: 'starting', child: Text('🟡 Starts From')),
                    DropdownMenuItem(value: 'range', child: Text('🔵 Price Range')),
                    DropdownMenuItem(value: 'inspection', child: Text('🟠 Quote Required')),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setDialogState(() {
                        pricingType = val;
                      });
                    }
                  },
                ),
                const SizedBox(height: 8),
                if (pricingType == 'fixed' || pricingType == 'starting')
                  TextField(
                    controller: priceController,
                    decoration: InputDecoration(
                      labelText: pricingType == 'fixed' ? 'Price (₹)' : 'Starting Price (₹)',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                if (pricingType == 'range') ...[
                  TextField(
                    controller: minPriceController,
                    decoration: const InputDecoration(labelText: 'Min Price (₹)'),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: maxPriceController,
                    decoration: const InputDecoration(labelText: 'Max Price (₹)'),
                    keyboardType: TextInputType.number,
                  ),
                ],
                const SizedBox(height: 8),
                TextField(
                  controller: visitingController,
                  decoration: const InputDecoration(labelText: 'Visiting Charges (₹)'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 8),
                CheckboxListTile(
                  title: const Text('Free Inspection', style: TextStyle(fontSize: 14)),
                  value: isFreeInspection,
                  contentPadding: EdgeInsets.zero,
                  onChanged: (val) {
                    setDialogState(() {
                      isFreeInspection = val ?? false;
                    });
                  },
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: gstController,
                  decoration: const InputDecoration(labelText: 'GST (%) (Optional)'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: extraChargesController,
                  decoration: const InputDecoration(labelText: 'Extra Charges (₹) (Optional)'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: extraLabelController,
                  decoration: const InputDecoration(labelText: 'Extra Charges Label (Optional)'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final success = await ref.read(shopManagementProvider.notifier).updateServiceDetails(
                  serviceId,
                  {
                    'pricingType': pricingType,
                    'price': double.tryParse(priceController.text) ?? 0.0,
                    'minPrice': double.tryParse(minPriceController.text) ?? 0.0,
                    'maxPrice': double.tryParse(maxPriceController.text) ?? 0.0,
                    'visitingCharges': double.tryParse(visitingController.text) ?? 0.0,
                    'isFreeInspection': isFreeInspection,
                    'gst': double.tryParse(gstController.text) ?? 0.0,
                    'extraCharges': double.tryParse(extraChargesController.text) ?? 0.0,
                    'extraChargesLabel': extraLabelController.text.trim(),
                  },
                );

                if (success && mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Service details updated successfully!'), backgroundColor: AppColors.success),
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (authState.shop == null) {
      return Scaffold(
        backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
        body: const Center(child: Text('Please log in first')),
      );
    }

    _initFields();

    final shop = authState.shop!;
    // Parse services
    final services = shop.toJson()['services'] as List? ?? [];

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
        appBar: AppBar(
          title: const Text('Shop Management'),
          centerTitle: true,
          bottom: const TabBar(
            labelColor: AppColors.primary,
            unselectedLabelColor: Colors.white54,
            indicatorColor: AppColors.primary,
            tabs: [
              Tab(text: 'Settings'),
              Tab(text: 'Catalog'),
              Tab(text: 'Gallery'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Tab 1: Operational Settings
            SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Shop Card Appearance ──────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceDark : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(isDark ? 0.25 : 0.04),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                      border: Border.all(
                        color: isDark ? AppColors.borderDark : AppColors.borderLight,
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('SHOP CARD APPEARANCE', style: AppTextStyles.headingSmall(isDark).copyWith(fontSize: 11, color: AppColors.primary)),
                        const SizedBox(height: 16),

                        // Cover Banner
                        GestureDetector(
                          onTap: _bannerUploading ? null : _pickAndUploadBanner,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                SizedBox(
                                  height: 130,
                                  width: double.infinity,
                                  child: shop.imagePath.startsWith('data:')
                                      ? Image.memory(
                                          base64Decode(shop.imagePath.split(',').last),
                                          fit: BoxFit.cover,
                                        )
                                      : Image.network(
                                          shop.imagePath,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => Container(
                                            color: AppColors.primary.withOpacity(0.15),
                                            child: const Icon(Icons.store, color: AppColors.primary, size: 40),
                                          ),
                                        ),
                                ),
                                Container(
                                  height: 130,
                                  width: double.infinity,
                                  color: Colors.black45,
                                  child: _bannerUploading
                                      ? const CircularProgressIndicator(color: Colors.white)
                                      : const Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.camera_alt, color: Colors.white, size: 28),
                                            SizedBox(height: 4),
                                            Text('Tap to change shop banner', style: TextStyle(color: Colors.white, fontSize: 12)),
                                          ],
                                        ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Estimated Service Time dropdown
                        DropdownButtonFormField<String>(
                          value: _estimatedServiceTime,
                          decoration: const InputDecoration(
                            labelText: 'Estimated Service Time',
                            prefixIcon: Icon(Icons.timer_outlined),
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                          items: const [
                            DropdownMenuItem(value: '15 mins', child: Text('15 mins')),
                            DropdownMenuItem(value: '20 mins', child: Text('20 mins')),
                            DropdownMenuItem(value: '30 mins', child: Text('30 mins')),
                            DropdownMenuItem(value: '45 mins', child: Text('45 mins')),
                            DropdownMenuItem(value: '1 Hour', child: Text('1 Hour')),
                            DropdownMenuItem(value: '1.5 Hours', child: Text('1.5 Hours')),
                            DropdownMenuItem(value: '2 Hours', child: Text('2 Hours')),
                          ],
                          onChanged: (val) {
                            if (val != null) setState(() => _estimatedServiceTime = val);
                          },
                        ),
                        const SizedBox(height: 12),

                        // Price Level dropdown
                        DropdownButtonFormField<String>(
                          value: _priceRange,
                          decoration: const InputDecoration(
                            labelText: 'Price Level',
                            prefixIcon: Icon(Icons.currency_rupee),
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                          items: const [
                            DropdownMenuItem(value: '₹', child: Text('₹  — Budget')),
                            DropdownMenuItem(value: '₹₹', child: Text('₹₹ — Moderate')),
                            DropdownMenuItem(value: '₹₹₹', child: Text('₹₹₹ — Premium')),
                            DropdownMenuItem(value: '₹₹₹₹', child: Text('₹₹₹₹ — Luxury')),
                            DropdownMenuItem(value: 'Starting ₹199', child: Text('Starting ₹199')),
                            DropdownMenuItem(value: 'From ₹299', child: Text('From ₹299')),
                            DropdownMenuItem(value: 'Affordable', child: Text('Affordable')),
                            DropdownMenuItem(value: 'Premium', child: Text('Premium')),
                          ],
                          onChanged: (val) {
                            if (val != null) setState(() => _priceRange = val);
                          },
                        ),
                        const SizedBox(height: 16),

                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _saveShopCardFields,
                            icon: const Icon(Icons.save_outlined, size: 16),
                            label: const Text('Save Card Details'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Visiting Charges and Radius Slider Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceDark : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(isDark ? 0.25 : 0.04),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                      border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('SERVICE BOUNDARY', style: AppTextStyles.headingSmall(isDark).copyWith(fontSize: 11, color: AppColors.primary)),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Service Radius', style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.secondary)),
                            Text('${_serviceRadius.toStringAsFixed(0)} KM', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                          ],
                        ),
                        Slider(
                          value: _serviceRadius,
                          min: 1,
                          max: 30,
                          divisions: 29,
                          activeColor: AppColors.primary,
                          onChanged: (val) {
                            setState(() {
                              _serviceRadius = val;
                            });
                          },
                          onChangeEnd: (_) => _saveOperationalHours(),
                        ),
                        Divider(height: 32, color: isDark ? AppColors.borderDark : AppColors.borderLight),
                        
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Visiting / Consult Charges', style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.secondary)),
                            SizedBox(
                              width: 80,
                              height: 36,
                              child: TextFormField(
                                key: ValueKey('visiting_charges_$_visitingCharges'),
                                initialValue: _visitingCharges.toStringAsFixed(0),
                                keyboardType: TextInputType.number,
                                style: TextStyle(color: isDark ? Colors.white : AppColors.secondary, fontSize: 14),
                                textAlign: TextAlign.end,
                                decoration: const InputDecoration(
                                  prefixText: '₹',
                                  contentPadding: EdgeInsets.symmetric(horizontal: 8),
                                  border: OutlineInputBorder(),
                                ),
                                onFieldSubmitted: (val) {
                                  final numVal = double.tryParse(val);
                                  if (numVal != null) {
                                    setState(() {
                                      _visitingCharges = numVal;
                                    });
                                    _saveOperationalHours();
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                        Divider(height: 32, color: isDark ? AppColors.borderDark : AppColors.borderLight),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Emergency Availability', style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.secondary)),
                                  Text('Show active for immediate booking requests', style: TextStyle(fontSize: 10, color: isDark ? Colors.white54 : AppColors.textSecondaryLight)),
                                ],
                              ),
                            ),
                            Switch(
                              value: _emergencyAvailable,
                              activeColor: AppColors.primary,
                              onChanged: (val) {
                                setState(() {
                                  _emergencyAvailable = val;
                                });
                                _saveOperationalHours();
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Working Hours List Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceDark : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(isDark ? 0.25 : 0.04),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                      border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('WORKING HOURS', style: AppTextStyles.headingSmall(isDark).copyWith(fontSize: 11, color: AppColors.primary)),
                        const SizedBox(height: 12),
                        ..._workingHours.keys.map((day) {
                          final dayData = _workingHours[day] as Map<String, dynamic>;
                          final isClosed = dayData['isClosed'] as bool? ?? false;
                          
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(day, style: TextStyle(fontWeight: FontWeight.w500, color: isDark ? Colors.white : AppColors.secondary)),
                                Row(
                                  children: [
                                    Text(
                                      isClosed ? 'CLOSED' : '${dayData['openTime']} - ${dayData['closeTime']}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isClosed ? AppColors.danger : (isDark ? Colors.white : AppColors.secondary),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Checkbox(
                                      value: !isClosed,
                                      activeColor: AppColors.primary,
                                      onChanged: (val) {
                                        setState(() {
                                          _workingHours[day]['isClosed'] = !(val ?? true);
                                        });
                                        _saveOperationalHours();
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Holidays Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceDark : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(isDark ? 0.25 : 0.04),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                      border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('HOLIDAYS SCHEDULE', style: AppTextStyles.headingSmall(isDark).copyWith(fontSize: 11, color: AppColors.primary)),
                            IconButton(
                              onPressed: _addHolidayDialog,
                              icon: const Icon(Icons.add, color: AppColors.primary, size: 20),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (_holidays.isEmpty)
                          Text('No holidays scheduled. The shop is active daily.', style: TextStyle(color: isDark ? Colors.white54 : AppColors.textSecondaryLight, fontSize: 12))
                        else
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _holidays.map((date) => Chip(
                              label: Text(date, style: const TextStyle(fontSize: 11)),
                              deleteIcon: const Icon(Icons.close, size: 14),
                              onDeleted: () {
                                setState(() {
                                  _holidays.remove(date);
                                });
                                _saveOperationalHours();
                              },
                            )).toList(),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Tab 2: Services Catalogue
            SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'MY SERVICES CATALOGUE',
                        style: AppTextStyles.headingSmall(isDark).copyWith(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                      ),
                      ElevatedButton.icon(
                        onPressed: _showAddServiceDialog,
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Add Custom'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (services.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Column(
                        children: [
                          Icon(Icons.category_outlined, size: 40, color: Colors.white24),
                          SizedBox(height: 8),
                          Text('No services added yet', style: TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: services.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final service = services[index] as Map<String, dynamic>;
                        final serviceId = service['id']?.toString() ?? '';
                        final title = service['title']?.toString() ?? '';
                        final price = (service['price'] as num?)?.toDouble() ?? 0.0;
                        final duration = service['durationText']?.toString() ?? '1 hr';
                        final isEnabled = service['isEnabled'] as bool? ?? true;

                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.surfaceDark : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(isDark ? 0.25 : 0.04),
                                blurRadius: 16,
                                offset: const Offset(0, 8),
                              ),
                            ],
                            border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  image: const DecorationImage(
                                    image: NetworkImage('https://images.unsplash.com/photo-1581578731548-c64695cc6952?w=100'),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      title,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: isDark ? Colors.white : AppColors.secondary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      duration,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isDark ? Colors.white54 : AppColors.textSecondaryLight,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Text(
                                          CurrencyFormatter.format(price),
                                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.success, fontSize: 13),
                                        ),
                                        const SizedBox(width: 8),
                                        InkWell(
                                          onTap: () => _showEditServiceDetailsDialog(service),
                                          child: const Icon(Icons.edit, size: 14, color: AppColors.primary),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Switch(
                                value: isEnabled,
                                activeColor: AppColors.primary,
                                onChanged: (val) {
                                  ref.read(shopManagementProvider.notifier).toggleService(serviceId, val);
                                },
                              ),
                              if (serviceId.contains('custom'))
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: AppColors.danger, size: 20),
                                  tooltip: 'Delete service',
                                  onPressed: () async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title: const Text('Delete Service'),
                                        content: Text('Delete "$title"? This cannot be undone.'),
                                        actions: [
                                          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                                          ElevatedButton(
                                            onPressed: () => Navigator.pop(ctx, true),
                                            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
                                            child: const Text('Delete', style: TextStyle(color: Colors.white)),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (confirm == true && mounted) {
                                      final ok = await ref.read(shopManagementProvider.notifier).deleteService(serviceId);
                                      if (ok && mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Service deleted.'), backgroundColor: AppColors.danger),
                                        );
                                      }
                                    }
                                  },
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),

            // Tab 3: Gallery Portfolio
            GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: (shop.portfolioImages.length + 1),
              itemBuilder: (context, index) {
                if (index == shop.portfolioImages.length) {
                  return Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white12, style: BorderStyle.values[1]),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: _portfolioUploading
                        ? const Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                            ),
                          )
                        : IconButton(
                            onPressed: _pickAndUploadPortfolio,
                            icon: const Icon(Icons.add_photo_alternate_outlined, color: AppColors.primary),
                          ),
                  );
                }

                final imageUrl = shop.portfolioImages[index];
                return Stack(
                  children: [
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: Colors.white10,
                            child: const Icon(Icons.image_not_supported, color: Colors.white30),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: () => _deletePortfolioImage(imageUrl),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.delete_outline, size: 16, color: AppColors.danger),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
