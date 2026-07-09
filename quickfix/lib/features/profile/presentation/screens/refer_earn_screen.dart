import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/haptics.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../features/home/presentation/providers/home_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

final _referralInfoProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final client = DioClient();
  final res = await client.get('/auth/referral');
  return res.data as Map<String, dynamic>;
});

class ReferEarnScreen extends ConsumerStatefulWidget {
  const ReferEarnScreen({super.key});

  @override
  ConsumerState<ReferEarnScreen> createState() => _ReferEarnScreenState();
}

class _ReferEarnScreenState extends ConsumerState<ReferEarnScreen> {
  void _copyCode(String code, BuildContext context) {
    AppHaptics.heavyTap();
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          const Icon(Icons.check_circle, color: Colors.white),
          const SizedBox(width: 8),
          Text('Code "$code" copied to clipboard!'),
        ]),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _shareCode(String code, String link, BuildContext context) {
    AppHaptics.mediumTap();
    // In production, use share_plus: Share.share(...)
    Clipboard.setData(ClipboardData(text: 'Use my QuickFix referral code $code: $link'));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Referral link copied! Share it with friends.'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(isDarkModeProvider);
    final referralAsync = ref.watch(_referralInfoProvider);
    final user = ref.watch(authProvider).user;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.canPop() ? context.pop() : context.go('/home'),
        ),
        title: Text('Refer & Earn', style: AppTextStyles.headingMedium(isDark)),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            // ---------- Hero Banner ----------
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 40),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF6C3AFF), Color(0xFF9B59FF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.card_giftcard_outlined, size: 48, color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Invite Friends,\nEarn Rewards!',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold, height: 1.2),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'You get ₹100 wallet cash for every friend who joins,\nyour friend gets ₹50 as a welcome bonus!',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                  ),
                ].animate(interval: 100.ms).fadeIn().slideY(begin: 0.1),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: referralAsync.when(
                loading: () => _buildSkeleton(isDark),
                error: (err, _) => Center(
                  child: Column(children: [
                    const SizedBox(height: 32),
                    const Icon(Icons.wifi_off_rounded, size: 48, color: AppColors.textSecondaryLight),
                    const SizedBox(height: 12),
                    Text('Could not load referral info', style: AppTextStyles.bodyMedium(isDark)),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () => ref.invalidate(_referralInfoProvider),
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                      child: const Text('Retry', style: TextStyle(color: Colors.white)),
                    ),
                  ]),
                ),
                data: (info) {
                  final code = info['referralCode']?.toString() ?? '';
                  final link = info['referralLink']?.toString() ?? '';
                  final count = (info['referralCount'] as num?)?.toInt() ?? 0;
                  final earned = (info['referralRewardsEarned'] as num?)?.toDouble() ?? 0.0;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ---------- Referral Code Card ----------
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.surfaceDark : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4))],
                        ),
                        child: Column(
                          children: [
                            Text('Your Referral Code', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                              decoration: BoxDecoration(
                                color: const Color(0xFF6C3AFF).withOpacity(0.08),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFF6C3AFF).withOpacity(0.3), width: 1.5),
                              ),
                              child: Text(
                                code.isNotEmpty ? code : '---',
                                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 3, color: Color(0xFF6C3AFF)),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: code.isNotEmpty ? () => _copyCode(code, context) : null,
                                    icon: const Icon(Icons.copy_outlined, size: 16),
                                    label: const Text('Copy Code'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: const Color(0xFF6C3AFF),
                                      side: const BorderSide(color: Color(0xFF6C3AFF)),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: code.isNotEmpty ? () => _shareCode(code, link, context) : null,
                                    icon: const Icon(Icons.share_outlined, size: 16, color: Colors.white),
                                    label: const Text('Share Link', style: TextStyle(color: Colors.white)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF6C3AFF),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      elevation: 0,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05),

                      const SizedBox(height: 20),

                      // ---------- Stats Row ----------
                      Row(children: [
                        _buildStatCard('Friends Invited', count.toString(), Icons.group_add_outlined, AppColors.info, isDark),
                        const SizedBox(width: 12),
                        _buildStatCard('Rewards Earned', '₹${earned.toStringAsFixed(0)}', Icons.account_balance_wallet_outlined, AppColors.success, isDark),
                      ]).animate().fadeIn(delay: 100.ms, duration: 400.ms),

                      const SizedBox(height: 24),

                      // ---------- How It Works ----------
                      Text('How It Works', style: AppTextStyles.headingSmall(isDark)),
                      const SizedBox(height: 14),
                      ...[
                        _HowItWorksStep(number: '1', title: 'Share your code', desc: 'Send your unique referral code to friends via WhatsApp, SMS or any platform.'),
                        _HowItWorksStep(number: '2', title: 'Friend signs up', desc: 'Your friend downloads QuickFix and registers with your referral code.'),
                        _HowItWorksStep(number: '3', title: 'Both get rewarded', desc: 'You earn ₹100 wallet cash. Your friend gets ₹50 as a welcome bonus!'),
                      ].asMap().entries.map((e) => _buildStep(e.value, isDark).animate(delay: (100 * e.key).ms).fadeIn().slideX(begin: 0.05)),

                      const SizedBox(height: 24),

                      // ---------- Terms ----------
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.surfaceDark : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              const Icon(Icons.info_outline, size: 14, color: AppColors.textSecondaryLight),
                              const SizedBox(width: 6),
                              Text('Terms & Conditions', style: AppTextStyles.bodySmall(isDark).copyWith(fontWeight: FontWeight.bold)),
                            ]),
                            const SizedBox(height: 8),
                            ...['Referral rewards apply only when the invited user completes their first booking.',
                                'Both referrer and referred must have valid QuickFix accounts.',
                                'Rewards are credited to QuickFix Wallet within 24 hours of booking completion.',
                                'QuickFix reserves the right to revoke rewards for misuse or fraud.']
                                .map((t) => Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    const Text('• ', style: TextStyle(color: AppColors.textSecondaryLight, fontSize: 11)),
                                    Expanded(child: Text(t, style: AppTextStyles.bodySmall(isDark).copyWith(fontSize: 11))),
                                  ]),
                                )),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color, bool isDark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
        ),
        child: Column(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.secondary)),
          Text(label, style: TextStyle(fontSize: 11, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight), textAlign: TextAlign.center),
        ]),
      ),
    );
  }

  Widget _buildStep(_HowItWorksStep step, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
      ),
      child: Row(children: [
        Container(
          width: 32, height: 32,
          decoration: const BoxDecoration(color: Color(0xFF6C3AFF), shape: BoxShape.circle),
          child: Center(child: Text(step.number, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(step.title, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: isDark ? Colors.white : AppColors.secondary)),
          Text(step.desc, style: TextStyle(fontSize: 12, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
        ])),
      ]),
    );
  }

  Widget _buildSkeleton(bool isDark) {
    final baseColor = isDark ? AppColors.surfaceDark : Colors.grey.shade200;
    final highlightColor = isDark ? AppColors.borderDark : Colors.grey.shade100;
    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Column(children: [
        Container(height: 160, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20))),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(child: Container(height: 90, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)))),
          const SizedBox(width: 12),
          Expanded(child: Container(height: 90, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)))),
        ]),
      ]),
    );
  }
}

class _HowItWorksStep {
  final String number;
  final String title;
  final String desc;
  const _HowItWorksStep({required this.number, required this.title, required this.desc});
}
