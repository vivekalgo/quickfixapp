import 'package:flutter/material.dart';
import 'package:quickfix/shared/themes/app_colors.dart';
import 'package:quickfix/shared/widgets/shimmer_loading.dart';

class CommonLoadingWidget extends StatelessWidget {
  final double size;
  final Color? color;

  const CommonLoadingWidget({
    super.key,
    this.size = 36,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: size,
        height: size,
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(color ?? AppColors.primary),
          strokeWidth: 3,
        ),
      ),
    );
  }
}

class SkeletonListWidget extends StatelessWidget {
  final int itemCount;
  final double height;
  final double borderRadius;

  const SkeletonListWidget({
    super.key,
    this.itemCount = 3,
    this.height = 80,
    this.borderRadius = 16,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) => ShimmerLoading(
        width: double.infinity,
        height: height,
        borderRadius: borderRadius,
      ),
    );
  }
}
