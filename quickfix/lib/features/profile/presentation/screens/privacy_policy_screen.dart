import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/haptics.dart';
import '../../../../features/home/presentation/providers/home_providers.dart';

class PrivacyPolicyScreen extends ConsumerWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(isDarkModeProvider);

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : AppColors.secondary),
          onPressed: () {
            AppHaptics.lightTap();
            Navigator.pop(context);
          },
        ),
        title: Text(
          'Privacy Policy',
          style: AppTextStyles.headingMedium(isDark),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Last Updated: July 2026',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'At QuickFix, we value your trust and are committed to protecting your personal data. This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you use our mobile application and related services.',
              style: AppTextStyles.bodyMedium(isDark).copyWith(height: 1.5),
            ),
            const SizedBox(height: 24),
            _buildSection(
              title: '1. Information We Collect',
              isDark: isDark,
              paragraphs: [
                '• Account Information: When you register, we collect your phone number. You may also provide your name, email address, gender, date of birth, and profile photo.',
                '• Service Addresses: We collect address details that you manually add or save to facilitate service delivery at your location.',
                '• Real-time Location: To display nearby service providers, show estimated arrival times, and enable live tracking, we collect precise location data with your permission.',
                '• Transaction Details: We collect transaction history and payment details related to bookings you make on the app.',
              ],
            ),
            _buildSection(
              title: '2. How We Use Your Information',
              isDark: isDark,
              paragraphs: [
                'We use the collected information for various operational and improvement purposes:',
                '• To match you with nearby service providers and facilitate service delivery.',
                '• To enable real-time tracking of providers on their way to your location.',
                '• To verify identity and process payments securely.',
                '• To send you booking confirmations, push alerts, and promotional announcements.',
                '• To analyze app performance and improve the user experience.',
              ],
            ),
            _buildSection(
              title: '3. Sharing with Service Providers',
              isDark: isDark,
              paragraphs: [
                'To fulfill bookings, we share necessary information with the selected service provider. When a booking is accepted, the provider receives your name, phone number, and service address. Providers are bound by strict compliance terms to keep this data confidential and are prohibited from contacting you after a job is closed.',
              ],
            ),
            _buildSection(
              title: '4. Data Security',
              isDark: isDark,
              paragraphs: [
                'We implement industry-standard physical, technical, and administrative security measures to protect your personal information against unauthorized access, loss, misuse, alteration, or disclosure. All transmission of sensitive payment details is encrypted.',
              ],
            ),
            _buildSection(
              title: '5. Your Rights and Choices',
              isDark: isDark,
              paragraphs: [
                'You have control over your data:',
                '• Device Permissions: You can enable or disable location tracking and push notifications anytime through your phone settings.',
                '• Account Deletion: You can permanently delete your QuickFix account and purge your personal information directly from the Settings menu.',
              ],
            ),
            _buildSection(
              title: '6. Contact Us',
              isDark: isDark,
              paragraphs: [
                'If you have any questions or feedback regarding this Privacy Policy, please reach out to us:',
                'Email: privacy@quickfix.app\nSupport: Helpdesk Support tab',
              ],
            ),
            const SizedBox(height: 30),
          ].animate(interval: 50.ms).fadeIn(duration: 300.ms).slideY(begin: 0.05, end: 0),
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<String> paragraphs,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppColors.secondary,
            ),
          ),
          const SizedBox(height: 10),
          ...paragraphs.map(
            (p) => Padding(
              padding: const EdgeInsets.only(bottom: 6.0),
              child: Text(
                p,
                style: TextStyle(
                  fontSize: 13.5,
                  height: 1.5,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
