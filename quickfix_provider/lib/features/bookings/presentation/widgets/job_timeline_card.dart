import 'package:flutter/material.dart';
import 'package:quickfix_provider/core/theme/app_colors.dart';

class JobTimelineCard extends StatelessWidget {
  final String currentStatus;
  final bool isDark;

  const JobTimelineCard({
    super.key,
    required this.currentStatus,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final stages = [
      {'key': 'accepted', 'label': 'Accepted'},
      {'key': 'navigating', 'label': 'Travel'},
      {'key': 'arrived', 'label': 'Arrived'},
      {'key': 'work_started', 'label': 'Working'},
      {'key': 'work_completed', 'label': 'Complete'},
      {'key': 'closed', 'label': 'Closed'},
    ];

    int currentIndex = stages.indexWhere((s) => s['key'] == currentStatus);
    if (currentStatus == 'pending') currentIndex = -1;
    if (currentStatus == 'quote_sent') currentIndex = 2; // Map to arrived stage
    if (currentStatus == 'payment_completed') currentIndex = 4; // Map to complete stage

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(stages.length, (index) {
          final isPast = index < currentIndex;
          final isCurrent = index == currentIndex;

          return Expanded(
            child: Row(
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isPast
                            ? AppColors.primary
                            : (isCurrent
                                  ? AppColors.primary
                                  : (isDark
                                        ? Colors.white12
                                        : Colors.grey.shade200)),
                        border: Border.all(
                          color: isCurrent
                              ? (isDark ? Colors.white : AppColors.secondary)
                              : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      child: Center(
                        child: isPast
                            ? const Icon(
                                Icons.done,
                                size: 14,
                                color: Colors.white,
                              )
                            : Text(
                                '${index + 1}',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: isCurrent
                                      ? Colors.white
                                      : (isDark
                                            ? Colors.white70
                                            : AppColors.textSecondaryLight),
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      stages[index]['label']!,
                      style: TextStyle(
                        fontSize: 8.5,
                        fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                        color: isCurrent
                            ? (isDark ? Colors.white : AppColors.secondary)
                            : (isDark
                                  ? Colors.white54
                                  : AppColors.textSecondaryLight),
                      ),
                    ),
                  ],
                ),
                if (index < stages.length - 1)
                  Expanded(
                    child: Container(
                      height: 2,
                      color: index < currentIndex
                          ? AppColors.primary
                          : (isDark ? Colors.white12 : Colors.grey.shade200),
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }
}
