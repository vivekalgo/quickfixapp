import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shimmer/shimmer.dart';
import 'package:quickfix/shared/themes/app_colors.dart';
import 'package:quickfix/shared/themes/app_text_styles.dart';
import 'package:quickfix/shared/utils/haptics.dart';
import 'package:quickfix/core/services/dio_client.dart';
import 'package:quickfix/core/providers/network_providers.dart';
import 'package:quickfix/features/home/providers/home_providers.dart';
import 'package:quickfix/core/network/error_handler.dart';

final _offersProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  try {
    final client = ref.watch(dioClientProvider);
    final res = await client.get('/offers');
    final data = res.data as List;
    return data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  } catch (e) {
    return [];
  }
});

// Static color palette cycling for coupon cards
const List<Color> _couponColors = [
  AppColors.primary,
  AppColors.success,
  AppColors.catAppliancesIcon,
  AppColors.accent,
  AppColors.info,
  Colors.teal,
];

class OffersScreen extends ConsumerWidget {
  const OffersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(isDarkModeProvider);
    final offersAsync = ref.watch(_offersProvider);

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
        elevation: 0,
        title: Text('Coupons & Offers', style: AppTextStyles.headingMedium(isDark)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            AppHaptics.lightTap();
            if (context.canPop()) context.pop();
            else { ref.read(currentNavIndexProvider.notifier).state = 0; context.go('/home'); }
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            onPressed: () {
              AppHaptics.lightTap();
              ref.invalidate(_offersProvider);
            },
          ),
        ],
      ),
      body: offersAsync.when(
        loading: () => _buildSkeleton(isDark),
        error: (err, st) => _buildError(isDark, ref, ErrorHandler.handle(err, st).message),
        data: (offers) {
          if (offers.isEmpty) {
            return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.local_offer_outlined, size: 70, color: AppColors.textSecondaryLight),
              const SizedBox(height: 16),
              Text('No offers available', style: AppTextStyles.headingSmall(isDark)),
              const SizedBox(height: 6),
              Text('Check back later for exclusive deals!', style: AppTextStyles.bodySmall(isDark)),
            ]));
          }

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async => await ref.refresh(_offersProvider.future),
            child: ListView.builder(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: offers.length,
              itemBuilder: (context, index) {
                final offer = offers[index];
                final baseColor = _couponColors[index % _couponColors.length];
                return _buildCouponTicket(context, offer, baseColor, isDark)
                    .animate(delay: (60 * index).ms)
                    .fadeIn()
                    .slideY(begin: 0.08, end: 0, duration: 350.ms, curve: Curves.easeOutQuad);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildCouponTicket(BuildContext context, Map<String, dynamic> offer, Color baseColor, bool isDark) {
    final code = offer['code']?.toString() ?? '';
    final title = offer['title']?.toString() ?? '';
    final description = offer['description']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      height: 140,
      child: ClipPath(
        clipper: _TicketClipper(),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 4))],
          ),
          child: Row(
            children: [
              // Left color banner
              Container(
                width: 90,
                height: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [baseColor, baseColor.withOpacity(0.85)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Center(
                  child: RotatedBox(
                    quarterTurns: 3,
                    child: Text(
                      code,
                      style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 2.0),
                    ),
                  ),
                ),
              ),
              // Dashed divider
              CustomPaint(
                size: const Size(1, double.infinity),
                painter: _DashedLinePainter(color: isDark ? Colors.white10 : Colors.black12),
              ),
              // Right details
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(title, style: AppTextStyles.headingSmall(isDark).copyWith(fontSize: 14.5)),
                        const SizedBox(height: 4),
                        Text(description, style: AppTextStyles.bodySmall(isDark).copyWith(fontSize: 11), maxLines: 2, overflow: TextOverflow.ellipsis),
                      ]),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              AppHaptics.heavyTap();
                              Clipboard.setData(ClipboardData(text: code));
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Row(children: [
                                    const Icon(Icons.check_circle_outline, color: Colors.white),
                                    const SizedBox(width: 8),
                                    Text('Code "$code" copied!'),
                                  ]),
                                  duration: const Duration(seconds: 2),
                                  behavior: SnackBarBehavior.floating,
                                  backgroundColor: AppColors.success,
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: baseColor.withOpacity(0.1),
                              foregroundColor: baseColor,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: const Text('COPY', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSkeleton(bool isDark) {
    final base = isDark ? AppColors.surfaceDark : Colors.grey.shade200;
    final highlight = isDark ? AppColors.borderDark : Colors.grey.shade100;
    return RepaintBoundary(
      child: Shimmer.fromColors(
        baseColor: base,
        highlightColor: highlight,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: 4,
          itemBuilder: (_, __) => Container(
            height: 140,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ),
    );
  }

  Widget _buildError(bool isDark, WidgetRef ref, String error) {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Icon(Icons.cloud_off_rounded, size: 64, color: AppColors.textSecondaryLight),
      const SizedBox(height: 16),
      Text('Could not load offers', style: AppTextStyles.headingSmall(isDark)),
      const SizedBox(height: 6),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Text(
          error,
          style: AppTextStyles.bodySmall(isDark),
          textAlign: TextAlign.center,
        ),
      ),
      const SizedBox(height: 16),
      ElevatedButton(
        onPressed: () => ref.invalidate(_offersProvider),
        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
        child: const Text('Retry', style: TextStyle(color: Colors.white)),
      ),
    ]));
  }
}

class _TicketClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    const radius = 10.0;
    path.lineTo(0, size.height);
    path.lineTo(90, size.height);
    path.arcToPoint(const Offset(100, 0) + Offset(0, size.height), radius: const Radius.circular(radius), clockwise: false);
    path.lineTo(size.width, size.height);
    path.lineTo(size.width, 0);
    path.lineTo(100, 0);
    path.arcToPoint(const Offset(90, 0), radius: const Radius.circular(radius), clockwise: false);
    path.lineTo(0, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class _DashedLinePainter extends CustomPainter {
  final Color color;
  const _DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color..strokeWidth = 1..style = PaintingStyle.stroke;
    const dashH = 5.0, dashSpace = 3.0;
    double startY = 12;
    while (startY < size.height - 12) {
      canvas.drawLine(Offset(0, startY), Offset(0, startY + dashH), paint);
      startY += dashH + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
