import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _notificationsEnabled = true;
  String _selectedLanguage = 'English';
  final _newPasswordController = TextEditingController();
  final _formKeyPassword = GlobalKey<FormState>();

  @override
  void dispose() {
    _newPasswordController.dispose();
    super.dispose();
  }

  void _showPasswordChangeSheet() {
    final oldPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceDark,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
          child: Form(
            key: _formKeyPassword,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Change Password', style: AppTextStyles.headingMedium(true)),
                const SizedBox(height: 20),
                TextFormField(
                  controller: oldPasswordController,
                  obscureText: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'Current Password', filled: true),
                  validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _newPasswordController,
                  obscureText: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'New Password', filled: true),
                  validator: (val) => val == null || val.length < 6 ? 'Min 6 characters' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: confirmPasswordController,
                  obscureText: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'Confirm New Password', filled: true),
                  validator: (val) {
                    if (val == null || val.isEmpty) return 'Required';
                    if (val != _newPasswordController.text) return 'Passwords do not match';
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () async {
                    if (!_formKeyPassword.currentState!.validate()) return;
                    
                    final success = await ref.read(authProvider.notifier).changePassword(
                          oldPasswordController.text,
                          _newPasswordController.text,
                        );

                    if (success && mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Password updated successfully!'), backgroundColor: AppColors.success),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, padding: const EdgeInsets.symmetric(vertical: 14)),
                  child: const Text('Update Password', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showInfoDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
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

    final shop = authState.shop!;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('My Partner Profile'),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          await ref.read(authProvider.notifier).refreshProfile();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
            // Profile Card Details
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                    backgroundImage: const NetworkImage('https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150'),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(shop.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                        const SizedBox(height: 4),
                        Text(
                          'Owner: ${shop.ownerName}',
                          style: TextStyle(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight, fontSize: 13),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              '${shop.rating} Rating',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Verified Documents Section
            Text(
              'VERIFIED DOCUMENT COMPLIANCE',
              style: AppTextStyles.headingSmall(isDark).copyWith(
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                fontSize: 11,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
              ),
              child: Column(
                children: [
                  _buildDetailRow('PAN Number', shop.pan.isNotEmpty ? shop.pan : 'Not Verified', Icons.credit_card_rounded),
                  const Divider(height: 24, color: Colors.white10),
                  _buildDetailRow('GSTIN Code', shop.gst.isNotEmpty ? shop.gst : 'Not Provided', Icons.receipt_long_rounded),
                  const Divider(height: 24, color: Colors.white10),
                  _buildDetailRow('Owner Phone', '+91 ${shop.phone}', Icons.phone_android_rounded),
                  const Divider(height: 24, color: Colors.white10),
                  _buildDetailRow('Owner Email', shop.email.isNotEmpty ? shop.email : 'Not Provided', Icons.email_rounded),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Bank Settlement Details
            Text(
              'BANK SETTLEMENT DETAILS',
              style: AppTextStyles.headingSmall(isDark).copyWith(
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                fontSize: 11,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
              ),
              child: Column(
                children: [
                  _buildDetailRow('Bank Account Number', shop.bankAccountNumber.isNotEmpty ? shop.bankAccountNumber : 'Not Provided', Icons.account_balance_rounded),
                  const Divider(height: 24, color: Colors.white10),
                  _buildDetailRow('IFSC Code', shop.ifscCode.isNotEmpty ? shop.ifscCode : 'Not Provided', Icons.gavel_rounded),
                  const Divider(height: 24, color: Colors.white10),
                  _buildDetailRow('UPI ID', shop.upiId.isNotEmpty ? shop.upiId : 'Not Provided', Icons.payments_rounded),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Settings & Customization
            Text(
              'APP SETTINGS & UTILITIES',
              style: AppTextStyles.headingSmall(isDark).copyWith(
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                fontSize: 11,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
              ),
              child: Column(
                children: [
                  // Change Password Option
                  ListTile(
                    leading: const Icon(Icons.lock_reset_rounded, color: AppColors.primary),
                    title: const Text('Change Portal Password', style: TextStyle(fontSize: 13.5)),
                    trailing: const Icon(Icons.chevron_right, color: Colors.white54),
                    onTap: _showPasswordChangeSheet,
                  ),
                  const Divider(height: 1, color: Colors.white10),

                  // Notifications Toggle
                  SwitchListTile(
                    secondary: const Icon(Icons.notifications_active_outlined, color: Colors.blue),
                    title: const Text('Push Booking Alerts', style: TextStyle(fontSize: 13.5)),
                    value: _notificationsEnabled,
                    activeThumbColor: AppColors.primary,
                    onChanged: (val) {
                      setState(() {
                        _notificationsEnabled = val;
                      });
                    },
                  ),
                  const Divider(height: 1, color: Colors.white10),

                  // Language selector
                  ListTile(
                    leading: const Icon(Icons.language_rounded, color: Colors.orange),
                    title: const Text('Portal Language', style: TextStyle(fontSize: 13.5)),
                    trailing: DropdownButton<String>(
                      value: _selectedLanguage,
                      underline: const SizedBox.shrink(),
                      dropdownColor: AppColors.surfaceDark,
                      items: const [
                        DropdownMenuItem(value: 'English', child: Text('English', style: TextStyle(fontSize: 12))),
                        DropdownMenuItem(value: 'Hindi', child: Text('हिन्दी (Hindi)', style: TextStyle(fontSize: 12))),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _selectedLanguage = val;
                          });
                        }
                      },
                    ),
                  ),
                  const Divider(height: 1, color: Colors.white10),

                  // Support
                  ListTile(
                    leading: const Icon(Icons.support_agent_rounded, color: Colors.green),
                    title: const Text('Partner Support & Helpdesk', style: TextStyle(fontSize: 13.5)),
                    onTap: () => _showInfoDialog('Partner Support', 'Email: partnersupport@quickfix.app\nTel: +91 1800-456-789\nWe are here 24/7 to support your shop operational queries.'),
                  ),
                  const Divider(height: 1, color: Colors.white10),

                  // Privacy
                  ListTile(
                    leading: const Icon(Icons.description_outlined, color: Colors.teal),
                    title: const Text('Privacy & Terms compliance', style: TextStyle(fontSize: 13.5)),
                    onTap: () => _showInfoDialog('Compliance', 'All customer details revealed to partners must strictly remain confidential. Providers must not copy, distribute, or contact customers post-service closure.'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 36),

            // Logout Button
            ElevatedButton(
              onPressed: () async {
                await ref.read(authProvider.notifier).logout();
                if (mounted) {
                  context.go('/login');
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.danger.withValues(alpha: 0.15),
                foregroundColor: AppColors.danger,
                side: const BorderSide(color: AppColors.danger, width: 1),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.logout_rounded),
                  SizedBox(width: 8),
                  Text('Log Out Partner Portal', style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primary.withValues(alpha: 0.8)),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 10, color: Colors.white54)),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ],
    );
  }
}
