import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/haptics.dart';
import '../../../../features/home/presentation/providers/home_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _locationEnabled = true;
  bool _marketingEmails = false;

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(isDarkModeProvider);

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.canPop() ? context.pop() : context.go('/home'),
        ),
        title: Text('Settings', style: AppTextStyles.headingMedium(isDark)),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ---------- Appearance ----------
            _buildSectionHeader('Appearance', isDark),
            const SizedBox(height: 8),
            _buildSwitchTile(
              icon: isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
              label: 'Dark Mode',
              subtitle: isDark ? 'Switch to light theme' : 'Switch to dark theme',
              iconColor: isDark ? AppColors.accent : AppColors.secondary,
              value: isDark,
              isDark: isDark,
              onChanged: (v) {
                AppHaptics.mediumTap();
                ref.read(isDarkModeProvider.notifier).toggleTheme();
              },
            ),

            const SizedBox(height: 20),

            // ---------- Notifications ----------
            _buildSectionHeader('Notifications', isDark),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
              ),
              child: Column(
                children: [
                  _buildSwitchRow(
                    icon: Icons.notifications_outlined,
                    label: 'Push Notifications',
                    subtitle: 'Booking updates & alerts',
                    iconColor: AppColors.primary,
                    value: _notificationsEnabled,
                    isDark: isDark,
                    onChanged: (v) => setState(() => _notificationsEnabled = v),
                    isFirst: true,
                  ),
                  _buildDivider(isDark),
                  _buildSwitchRow(
                    icon: Icons.location_on_outlined,
                    label: 'Location Access',
                    subtitle: 'For finding nearby services',
                    iconColor: AppColors.info,
                    value: _locationEnabled,
                    isDark: isDark,
                    onChanged: (v) => setState(() => _locationEnabled = v),
                  ),
                  _buildDivider(isDark),
                  _buildSwitchRow(
                    icon: Icons.email_outlined,
                    label: 'Marketing Emails',
                    subtitle: 'Offers & promotional content',
                    iconColor: AppColors.catCleaningIcon,
                    value: _marketingEmails,
                    isDark: isDark,
                    onChanged: (v) => setState(() => _marketingEmails = v),
                    isLast: true,
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.04),

            const SizedBox(height: 20),

            // ---------- Privacy & Security ----------
            _buildSectionHeader('Privacy & Security', isDark),
            const SizedBox(height: 8),
            _buildTileGroup(isDark, [
              _SettingsTile(
                icon: Icons.privacy_tip_outlined,
                label: 'Privacy Policy',
                subtitle: 'How we use your data',
                iconColor: AppColors.catAppliancesIcon,
                onTap: () => context.push('/privacy'),
              ),
              _SettingsTile(
                icon: Icons.article_outlined,
                label: 'Terms & Conditions',
                subtitle: 'Usage policies & agreements',
                iconColor: AppColors.catCarpentryIcon,
                onTap: () => context.push('/terms'),
              ),
              _SettingsTile(
                icon: Icons.security_outlined,
                label: 'Data & Permissions',
                subtitle: 'Manage what data we store',
                iconColor: AppColors.catPlumbingIcon,
                onTap: () async {
                  await openAppSettings();
                },
              ),
            ]),

            const SizedBox(height: 20),

            // ---------- About ----------
            _buildSectionHeader('About', isDark),
            const SizedBox(height: 8),
            _buildTileGroup(isDark, [
              _SettingsTile(
                icon: Icons.info_outline,
                label: 'About QuickFix',
                subtitle: 'Version 1.0.0 • Build 2026',
                iconColor: AppColors.info,
                onTap: () => _showAboutDialog(context, isDark),
              ),
              _SettingsTile(
                icon: Icons.star_rate_outlined,
                label: 'Rate Our App',
                subtitle: 'Share feedback on Play Store',
                iconColor: AppColors.warning,
                onTap: () async {
                  final Uri url = Uri.parse('https://play.google.com/store/apps/details?id=com.quickfix.customer');
                  try {
                    await launchUrl(url, mode: LaunchMode.externalApplication);
                  } catch (_) {}
                },
              ),
              _SettingsTile(
                icon: Icons.headset_mic_outlined,
                label: 'Contact Support',
                subtitle: 'Reach our 24×7 helpdesk',
                iconColor: AppColors.catCarpentryIcon,
                onTap: () => context.push('/support'),
              ),
            ]),

            const SizedBox(height: 20),

            // ---------- Danger Zone ----------
            _buildSectionHeader('Account', isDark),
            const SizedBox(height: 8),
            _buildTileGroup(isDark, [
              _SettingsTile(
                icon: Icons.delete_forever_outlined,
                label: 'Delete Account',
                subtitle: 'Permanently remove your account & data',
                iconColor: AppColors.error,
                onTap: () => _showDeleteConfirm(context, ref, isDark),
                isDestructive: true,
              ),
            ]),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String label, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String label,
    required String subtitle,
    required Color iconColor,
    required bool value,
    required bool isDark,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
      ),
      child: _buildSwitchRow(
        icon: icon,
        label: label,
        subtitle: subtitle,
        iconColor: iconColor,
        value: value,
        isDark: isDark,
        onChanged: onChanged,
        isFirst: true,
        isLast: true,
      ),
    ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.04);
  }

  Widget _buildSwitchRow({
    required IconData icon,
    required String label,
    required String subtitle,
    required Color iconColor,
    required bool value,
    required bool isDark,
    required ValueChanged<bool> onChanged,
    bool isFirst = false,
    bool isLast = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14.5, color: isDark ? Colors.white : AppColors.secondary)),
                Text(subtitle, style: TextStyle(fontSize: 12, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 58),
      child: Divider(height: 1, color: isDark ? AppColors.borderDark : AppColors.borderLight),
    );
  }

  Widget _buildTileGroup(bool isDark, List<_SettingsTile> tiles) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
      ),
      child: Column(
        children: tiles.asMap().entries.map((entry) {
          final i = entry.key;
          final tile = entry.value;
          return Column(
            children: [
              InkWell(
                borderRadius: BorderRadius.vertical(
                  top: i == 0 ? const Radius.circular(16) : Radius.zero,
                  bottom: i == tiles.length - 1 ? const Radius.circular(16) : Radius.zero,
                ),
                onTap: () {
                  AppHaptics.lightTap();
                  tile.onTap();
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: tile.iconColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(tile.icon, color: tile.isDestructive ? Colors.red : tile.iconColor, size: 20),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tile.label,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14.5,
                                color: tile.isDestructive ? Colors.red : (isDark ? Colors.white : AppColors.secondary),
                              ),
                            ),
                            Text(tile.subtitle, style: TextStyle(fontSize: 12, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right, size: 18, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                    ],
                  ),
                ),
              ),
              if (i < tiles.length - 1)
                Padding(
                  padding: const EdgeInsets.only(left: 58),
                  child: Divider(height: 1, color: isDark ? AppColors.borderDark : AppColors.borderLight),
                ),
            ],
          );
        }).toList(),
      ),
    ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.04);
  }

  void _showAboutDialog(BuildContext context, bool isDark) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
            child: const Icon(Icons.flash_on, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          const Text('QuickFix', style: TextStyle(fontWeight: FontWeight.bold)),
        ]),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Hyperlocal home services, delivered fast.'),
            SizedBox(height: 12),
            Text('Version: 1.0.0', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('Build: 2026.07'),
            SizedBox(height: 8),
            Text('© 2026 QuickFix Technologies Pvt. Ltd.\nAll rights reserved.'),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Close', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirm(BuildContext context, WidgetRef ref, bool isDark) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(children: [
          Icon(Icons.warning_amber_rounded, color: Colors.red),
          SizedBox(width: 8),
          Text('Delete Account?', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        ]),
        content: const Text('This will permanently remove your account, bookings, wallet balance, and all associated data. This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ref.read(authProvider.notifier).deleteAccount();
                if (context.mounted) context.go('/login');
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _SettingsTile {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color iconColor;
  final VoidCallback onTap;
  final bool isDestructive;

  const _SettingsTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.iconColor,
    required this.onTap,
    this.isDestructive = false,
  });
}
