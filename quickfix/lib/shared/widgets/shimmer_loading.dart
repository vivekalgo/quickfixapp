import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:quickfix/shared/themes/app_colors.dart';

class ShimmerLoading extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;
  final BoxShape shape;

  const ShimmerLoading({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8.0,
    this.shape = BoxShape.rectangle,
  });

  const ShimmerLoading.circular({
    super.key,
    required double size,
  })  : width = size,
        height = size,
        borderRadius = size / 2,
        shape = BoxShape.circle;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return RepaintBoundary(
      child: Shimmer.fromColors(
        baseColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
        highlightColor: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
            shape: shape,
            borderRadius: shape == BoxShape.rectangle 
                ? BorderRadius.circular(borderRadius) 
                : null,
          ),
        ),
      ),
    );
  }
}
