import 'package:flutter/material.dart';
import 'package:quickfix_provider/core/theme/app_colors.dart';
import 'package:quickfix_provider/core/theme/app_text_styles.dart';
import 'package:quickfix_provider/core/utils/currency_formatter.dart';

class CatalogTab extends StatelessWidget {
  final List<dynamic> services;
  final bool isDark;
  final VoidCallback onAddService;
  final Function(Map<String, dynamic>) onEditService;
  final Function(String, bool) onToggleService;
  final Function(Map<String, dynamic>) onDeleteService;

  const CatalogTab({
    super.key,
    required this.services,
    required this.isDark,
    required this.onAddService,
    required this.onEditService,
    required this.onToggleService,
    required this.onDeleteService,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'MY SERVICES CATALOGUE',
                style: AppTextStyles.headingSmall(isDark).copyWith(
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
              ),
              ElevatedButton.icon(
                onPressed: onAddService,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add Custom'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
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
                  Icon(
                    Icons.category_outlined,
                    size: 40,
                    color: Colors.white24,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'No services added yet',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
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
                        color: Colors.black.withValues(
                          alpha: isDark ? 0.25 : 0.04,
                        ),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                    border: Border.all(
                      color: isDark ? AppColors.borderDark : AppColors.borderLight,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          image: DecorationImage(
                            image: NetworkImage(
                              service['imageUrl']?.toString() ??
                                  'https://images.unsplash.com/photo-1581578731548-c64695cc6952?w=100',
                            ),
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
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.success,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                InkWell(
                                  onTap: () => onEditService(service),
                                  child: const Icon(
                                    Icons.edit,
                                    size: 14,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: isEnabled,
                        activeThumbColor: AppColors.primary,
                        onChanged: (val) => onToggleService(serviceId, val),
                      ),
                      if (serviceId.contains('custom'))
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: AppColors.danger,
                            size: 20,
                          ),
                          tooltip: 'Delete service',
                          onPressed: () => onDeleteService(service),
                        ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
