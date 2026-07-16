import 'package:flutter/material.dart';
import 'package:quickfix_provider/core/theme/app_colors.dart';

class BookingStatusCard extends StatelessWidget {
  final String status;
  final bool isDark;

  const BookingStatusCard({
    super.key,
    required this.status,
    required this.isDark,
  });

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.hourglass_top_rounded;
      case 'accepted':
        return Icons.handshake_rounded;
      case 'navigating':
        return Icons.directions_car_rounded;
      case 'arrived':
        return Icons.pin_drop_rounded;
      case 'quote_sent':
        return Icons.pending_actions_rounded;
      case 'work_started':
        return Icons.build_rounded;
      case 'work_completed':
        return Icons.done_outline_rounded;
      case 'payment_completed':
        return Icons.payments_rounded;
      case 'closed':
        return Icons.task_alt_rounded;
      default:
        return Icons.info_outline_rounded;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return AppColors.warning;
      case 'accepted':
        return AppColors.info;
      case 'navigating':
        return Colors.blue;
      case 'arrived':
        return Colors.deepPurpleAccent;
      case 'quote_sent':
        return Colors.orangeAccent;
      case 'work_started':
        return Colors.orangeAccent;
      case 'work_completed':
        return Colors.teal;
      case 'payment_completed':
      case 'closed':
        return AppColors.success;
      default:
        return AppColors.danger;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
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
          Icon(
            _getStatusIcon(status),
            color: _getStatusColor(status),
            size: 32,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CURRENT STATUS',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                    color: isDark
                        ? Colors.white60
                        : AppColors.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  status.toUpperCase().replaceAll('_', ' '),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: _getStatusColor(status),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
