import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  // Custom service fields
  final _customTitleController = TextEditingController();
  final _customPriceController = TextEditingController();
  final _customDurationController = TextEditingController();
  final _customBulletsController = TextEditingController();

  bool _initialized = false;

  @override
  void dispose() {
    _customTitleController.dispose();
    _customPriceController.dispose();
    _customDurationController.dispose();
    _customBulletsController.dispose();
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
      _initialized = true;
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
                TextFormField(
                  controller: _customPriceController,
                  decoration: const InputDecoration(labelText: 'Price (₹)'),
                  keyboardType: TextInputType.number,
                  validator: (val) => val == null || double.tryParse(val) == null ? 'Enter valid price' : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _customDurationController,
                  decoration: const InputDecoration(labelText: 'Duration (e.g. 2 hrs)'),
                  validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
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
                    price: double.parse(_customPriceController.text),
                    durationText: _customDurationController.text.trim(),
                    bulletPoints: bullets,
                  );

              if (success && mounted) {
                _customTitleController.clear();
                _customPriceController.clear();
                _customDurationController.clear();
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
    );
  }

  void _showEditPriceDialog(String serviceId, String title, double currentPrice) {
    final controller = TextEditingController(text: currentPrice.toStringAsFixed(0));
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Price: $title'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            prefixText: '₹ ',
            filled: true,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newPrice = double.tryParse(controller.text);
              if (newPrice != null) {
                final success = await ref.read(shopManagementProvider.notifier).updateServicePrice(serviceId, newPrice);
                if (success && mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Service price updated successfully!'), backgroundColor: AppColors.success),
                  );
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
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
                  // Visiting Charges and Radius Slider Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(12),
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
                            const Text('Service Radius', style: TextStyle(fontWeight: FontWeight.bold)),
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
                        const Divider(height: 32, color: Colors.white10),
                        
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Visiting / Consult Charges', style: TextStyle(fontWeight: FontWeight.bold)),
                            SizedBox(
                              width: 80,
                              height: 36,
                              child: TextFormField(
                                initialValue: _visitingCharges.toStringAsFixed(0),
                                keyboardType: TextInputType.number,
                                style: const TextStyle(color: Colors.white, fontSize: 14),
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
                        const Divider(height: 32, color: Colors.white10),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Emergency Availability', style: TextStyle(fontWeight: FontWeight.bold)),
                                Text('Show active for immediate booking requests', style: TextStyle(fontSize: 10, color: Colors.white54)),
                              ],
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
                      color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(12),
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
                                Text(day, style: const TextStyle(fontWeight: FontWeight.w500)),
                                Row(
                                  children: [
                                    Text(
                                      isClosed ? 'CLOSED' : '${dayData['openTime']} - ${dayData['closeTime']}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isClosed ? AppColors.danger : Colors.white,
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
                      color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(12),
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
                          const Text('No holidays scheduled. The shop is active daily.', style: TextStyle(color: Colors.white54, fontSize: 12))
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
                            color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
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
                                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                    const SizedBox(height: 4),
                                    Text(duration, style: const TextStyle(fontSize: 11, color: Colors.white54)),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Text(
                                          CurrencyFormatter.format(price),
                                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.success, fontSize: 13),
                                        ),
                                        const SizedBox(width: 8),
                                        InkWell(
                                          onTap: () => _showEditPriceDialog(serviceId, title, price),
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
                    child: IconButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Simulated picking image and uploading to Cloudinary...'), backgroundColor: AppColors.info),
                        );
                      },
                      icon: const Icon(Icons.add_photo_alternate_outlined, color: AppColors.primary),
                    ),
                  );
                }

                return ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    shop.portfolioImages[index],
                    fit: BoxFit.cover,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
