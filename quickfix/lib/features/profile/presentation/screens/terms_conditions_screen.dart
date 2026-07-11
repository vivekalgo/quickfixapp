import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/haptics.dart';
import '../../../../features/home/presentation/providers/home_providers.dart';

class TermsConditionsScreen extends ConsumerWidget {
  const TermsConditionsScreen({super.key});

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
          'Terms & Conditions',
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
              'Welcome to QuickFix. By downloading, installing, or using the QuickFix mobile application, you agree to comply with and be bound by the following Terms & Conditions. Please read them carefully.',
              style: AppTextStyles.bodyMedium(isDark).copyWith(height: 1.5),
            ),
            const SizedBox(height: 24),
            _buildSection(
              title: '1. Service Scope',
              isDark: isDark,
              paragraphs: [
                '• QuickFix is a hyperlocal marketplace platform connecting customers with independent, local service providers (shops/professionals).',
                '• QuickFix does not directly employ the service providers. We act as a booking platform to facilitate scheduling, tracking, and secure payment mediation.',
              ],
            ),
            _buildSection(
              title: '2. User Accounts',
              isDark: isDark,
              paragraphs: [
                '• You must register using a valid phone number. You are responsible for keeping your credentials secure and maintaining the accuracy of your profile details.',
                '• QuickFix reserves the right to suspend or terminate accounts that provide false information or engage in fraudulent activities.',
              ],
            ),
            _buildSection(
              title: '3. Fees and Payments',
              isDark: isDark,
              paragraphs: [
                '• Pricing: Prices shown for fixed-pricing services in the app are standard charges. Inspection-type services may involve a visiting fee plus cost of materials determined after evaluation.',
                '• Convenience Fees: A small convenience fee may be added to cover transaction costs and platform maintenance.',
                '• Payment Options: Payments can be made online via integrated gateways (Razorpay) or as cash paid directly to the service provider after job completion.',
              ],
            ),
            _buildSection(
              title: '4. Cancellations and Refunds',
              isDark: isDark,
              paragraphs: [
                '• Booking Cancellation: You can cancel a booking free of charge until the service provider starts traveling to your location. Once the provider is in transit, the cancellation option is removed.',
                '• Refunds: In case of payment failures, duplicate charges, or dispute settlements, refunds are processed back to the original source of payment within 5-7 business days.',
              ],
            ),
            _buildSection(
              title: '5. Limitation of Liability',
              isDark: isDark,
              paragraphs: [
                '• While QuickFix conducts background verification of partner shops, we are not liable for any direct, indirect, incidental, or consequential damages resulting from the service rendered by the provider.',
                '• Service quality, timelines, and warranties (if any) are the sole responsibility of the service provider.',
              ],
            ),
            _buildSection(
              title: '6. Modifications to Terms',
              isDark: isDark,
              paragraphs: [
                'QuickFix reserves the right to modify these Terms and Conditions at any time. We will notify users of significant changes through in-app alerts. Your continued use of the app constitutes acceptance of the modified terms.',
              ],
            ),
            _buildSection(
              title: '7. Contact and Support',
              isDark: isDark,
              paragraphs: [
                'If you have questions about these Terms, please contact our support desk through the Help & Support tab in the profile screen, or email us at support@quickfix.app.',
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
