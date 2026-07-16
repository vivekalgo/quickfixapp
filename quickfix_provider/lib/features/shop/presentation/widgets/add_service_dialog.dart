import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:quickfix_provider/core/theme/app_colors.dart';
import 'package:quickfix_provider/features/shop/presentation/controllers/shop_provider.dart';

class AddServiceDialog extends ConsumerStatefulWidget {
  const AddServiceDialog({super.key});

  @override
  ConsumerState<AddServiceDialog> createState() => _AddServiceDialogState();
}

class _AddServiceDialogState extends ConsumerState<AddServiceDialog> {
  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _priceController = TextEditingController();
  final _durationController = TextEditingController();
  final _bulletsController = TextEditingController();
  final _minPriceController = TextEditingController();
  final _maxPriceController = TextEditingController();
  final _visitingController = TextEditingController(text: '150');
  final _gstController = TextEditingController(text: '0');
  final _extraChargesController = TextEditingController(text: '0');
  final _extraLabelController = TextEditingController();

  String _pricingType = 'fixed';
  bool _isFreeInspection = false;
  String? _imageUrl;
  bool _isUploading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _priceController.dispose();
    _durationController.dispose();
    _bulletsController.dispose();
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
      title: const Text('Add Custom Service'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
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
                          child: Image.network(
                            _imageUrl!,
                            fit: BoxFit.cover,
                          ),
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
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Service Name',
                ),
                validator: (val) =>
                    val == null || val.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _pricingType,
                decoration: const InputDecoration(
                  labelText: 'Pricing Model',
                ),
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
                TextFormField(
                  controller: _priceController,
                  decoration: InputDecoration(
                    labelText: _pricingType == 'fixed'
                        ? 'Price (₹)'
                        : 'Starting Price (₹)',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (val) =>
                      val == null || double.tryParse(val) == null
                      ? 'Enter valid price'
                      : null,
                ),
              if (_pricingType == 'range') ...[
                TextFormField(
                  controller: _minPriceController,
                  decoration: const InputDecoration(
                    labelText: 'Min Price (₹)',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (val) =>
                      val == null || double.tryParse(val) == null
                      ? 'Enter min price'
                      : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _maxPriceController,
                  decoration: const InputDecoration(
                    labelText: 'Max Price (₹)',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (val) =>
                      val == null || double.tryParse(val) == null
                      ? 'Enter max price'
                      : null,
                ),
              ],
              const SizedBox(height: 8),
              TextFormField(
                controller: _durationController,
                decoration: const InputDecoration(
                  labelText: 'Duration (e.g. 2 hrs)',
                ),
                validator: (val) =>
                    val == null || val.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
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
              TextFormField(
                controller: _gstController,
                decoration: const InputDecoration(
                  labelText: 'GST (%) (Optional)',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _extraChargesController,
                decoration: const InputDecoration(
                  labelText: 'Extra Charges (₹) (Optional)',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _extraLabelController,
                decoration: const InputDecoration(
                  labelText: 'Extra Charges Label (Optional)',
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _bulletsController,
                decoration: const InputDecoration(
                  labelText: 'Features (comma separated)',
                ),
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
            if (!_formKey.currentState!.validate()) return;

            final bullets = _bulletsController.text
                .split(',')
                .map((e) => e.trim())
                .where((e) => e.isNotEmpty)
                .toList();

            final success = await ref
                .read(shopManagementProvider.notifier)
                .addCustomService(
                  title: _titleController.text.trim(),
                  price: double.tryParse(_priceController.text) ?? 0.0,
                  durationText: _durationController.text.trim(),
                  bulletPoints: bullets,
                  pricingType: _pricingType,
                  minPrice: double.tryParse(_minPriceController.text) ?? 0.0,
                  maxPrice: double.tryParse(_maxPriceController.text) ?? 0.0,
                  visitingCharges:
                      double.tryParse(_visitingController.text) ?? 0.0,
                  isFreeInspection: _isFreeInspection,
                  gst: double.tryParse(_gstController.text) ?? 0.0,
                  extraCharges:
                      double.tryParse(_extraChargesController.text) ?? 0.0,
                  extraChargesLabel: _extraLabelController.text.trim(),
                  imageUrl: _imageUrl,
                );

            if (success && context.mounted) {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Custom service added successfully!'),
                  backgroundColor: AppColors.success,
                ),
              );
            }
          },
          child: const Text('Add Service'),
        ),
      ],
    );
  }
}
