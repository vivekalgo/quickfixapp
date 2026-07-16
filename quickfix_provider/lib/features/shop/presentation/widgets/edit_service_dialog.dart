import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:quickfix_provider/core/theme/app_colors.dart';
import 'package:quickfix_provider/features/shop/presentation/controllers/shop_provider.dart';

class EditServiceDialog extends ConsumerStatefulWidget {
  final Map<String, dynamic> service;

  const EditServiceDialog({super.key, required this.service});

  @override
  ConsumerState<EditServiceDialog> createState() => _EditServiceDialogState();
}

class _EditServiceDialogState extends ConsumerState<EditServiceDialog> {
  late final String _serviceId;
  late final String _title;

  late final TextEditingController _priceController;
  late final TextEditingController _minPriceController;
  late final TextEditingController _maxPriceController;
  late final TextEditingController _visitingController;
  late final TextEditingController _gstController;
  late final TextEditingController _extraChargesController;
  late final TextEditingController _extraLabelController;

  late String _pricingType;
  late bool _isFreeInspection;
  String? _imageUrl;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    final service = widget.service;
    _serviceId = service['id']?.toString() ?? '';
    _title = service['title']?.toString() ?? '';
    _pricingType = service['pricingType']?.toString() ?? 'fixed';

    _priceController = TextEditingController(
      text: ((service['price'] as num?)?.toDouble() ?? 0.0).toStringAsFixed(0),
    );
    _minPriceController = TextEditingController(
      text: ((service['minPrice'] as num?)?.toDouble() ?? 0.0).toStringAsFixed(0),
    );
    _maxPriceController = TextEditingController(
      text: ((service['maxPrice'] as num?)?.toDouble() ?? 0.0).toStringAsFixed(0),
    );
    _visitingController = TextEditingController(
      text: ((service['visitingCharges'] as num?)?.toDouble() ?? 150.0).toStringAsFixed(0),
    );
    _gstController = TextEditingController(
      text: ((service['gst'] as num?)?.toDouble() ?? 0.0).toStringAsFixed(0),
    );
    _extraChargesController = TextEditingController(
      text: ((service['extraCharges'] as num?)?.toDouble() ?? 0.0).toStringAsFixed(0),
    );
    _extraLabelController = TextEditingController(
      text: service['extraChargesLabel']?.toString() ?? '',
    );
    _isFreeInspection = service['isFreeInspection'] as bool? ?? false;
    _imageUrl = service['imageUrl']?.toString();
  }

  @override
  void dispose() {
    _priceController.dispose();
    _minPriceController.dispose();
    _maxPriceController.dispose();
    _visitingController.dispose();
    _gstController.dispose();
    _extraChargesController.dispose();
    _extraLabelController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 75,
    );
    if (picked == null) return;

    setState(() {
      _isUploading = true;
    });

    try {
      final bytes = await picked.readAsBytes();
      final base64Image = base64Encode(bytes);
      final mimeType = picked.mimeType ?? 'image/jpeg';

      final uploadedUrl = await ref
          .read(shopManagementProvider.notifier)
          .uploadServiceImage(base64Image, mimeType);
      if (uploadedUrl != null) {
        setState(() {
          _imageUrl = uploadedUrl;
        });
      }
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Edit Service: $_title'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: _isUploading ? null : _pickAndUploadImage,
              child: Container(
                height: 100,
                width: 100,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.5),
                  ),
                ),
                child: _isUploading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      )
                    : _imageUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(_imageUrl!, fit: BoxFit.cover),
                      )
                    : const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_photo_alternate_outlined,
                            color: AppColors.primary,
                            size: 32,
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Service Icon',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.white54,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            DropdownButtonFormField<String>(
              initialValue: _pricingType,
              decoration: const InputDecoration(labelText: 'Pricing Model'),
              items: const [
                DropdownMenuItem(
                  value: 'fixed',
                  child: Text('🟢 Fixed Price'),
                ),
                DropdownMenuItem(
                  value: 'starting',
                  child: Text('🟡 Starts From'),
                ),
                DropdownMenuItem(
                  value: 'range',
                  child: Text('🔵 Price Range'),
                ),
                DropdownMenuItem(
                  value: 'inspection',
                  child: Text('🟠 Quote Required'),
                ),
              ],
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _pricingType = val;
                  });
                }
              },
            ),
            const SizedBox(height: 8),
            if (_pricingType == 'fixed' || _pricingType == 'starting')
              TextField(
                controller: _priceController,
                decoration: InputDecoration(
                  labelText: _pricingType == 'fixed'
                      ? 'Price (₹)'
                      : 'Starting Price (₹)',
                ),
                keyboardType: TextInputType.number,
              ),
            if (_pricingType == 'range') ...[
              TextField(
                controller: _minPriceController,
                decoration: const InputDecoration(
                  labelText: 'Min Price (₹)',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _maxPriceController,
                decoration: const InputDecoration(
                  labelText: 'Max Price (₹)',
                ),
                keyboardType: TextInputType.number,
              ),
            ],
            const SizedBox(height: 8),
            TextField(
              controller: _visitingController,
              decoration: const InputDecoration(
                labelText: 'Visiting Charges (₹)',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 8),
            CheckboxListTile(
              title: const Text(
                'Free Inspection',
                style: TextStyle(fontSize: 14),
              ),
              value: _isFreeInspection,
              contentPadding: EdgeInsets.zero,
              onChanged: (val) {
                setState(() {
                  _isFreeInspection = val ?? false;
                });
              },
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _gstController,
              decoration: const InputDecoration(
                labelText: 'GST (%) (Optional)',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _extraChargesController,
              decoration: const InputDecoration(
                labelText: 'Extra Charges (₹) (Optional)',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _extraLabelController,
              decoration: const InputDecoration(
                labelText: 'Extra Charges Label (Optional)',
              ),
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
            final success = await ref
                .read(shopManagementProvider.notifier)
                .updateServiceDetails(_serviceId, {
                  'pricingType': _pricingType,
                  'price': double.tryParse(_priceController.text) ?? 0.0,
                  'minPrice': double.tryParse(_minPriceController.text) ?? 0.0,
                  'maxPrice': double.tryParse(_maxPriceController.text) ?? 0.0,
                  'visitingCharges':
                      double.tryParse(_visitingController.text) ?? 0.0,
                  'isFreeInspection': _isFreeInspection,
                  'gst': double.tryParse(_gstController.text) ?? 0.0,
                  'extraCharges':
                      double.tryParse(_extraChargesController.text) ?? 0.0,
                  'extraChargesLabel': _extraLabelController.text.trim(),
                  'imageUrl': _imageUrl,
                });

            if (success && context.mounted) {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Service details updated successfully!'),
                  backgroundColor: AppColors.success,
                ),
              );
            }
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
