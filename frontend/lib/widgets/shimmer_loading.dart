import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../constants/ui_constants.dart';

class ShimmerLoading extends StatelessWidget {
  final double width;
  final double height;
  final ShapeBorder shapeBorder;

  const ShimmerLoading.rectangular({
    super.key,
    this.width = double.infinity,
    required this.height,
    double borderRadius = AppRadius.md,
  }) : shapeBorder = RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(borderRadius)));

  const ShimmerLoading.circular({
    super.key,
    required this.width,
    required this.height,
    this.shapeBorder = const CircleBorder(),
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Shimmer.fromColors(
      baseColor: isDark ? Colors.grey[850]! : Colors.grey[200]!,
      highlightColor: isDark ? Colors.grey[700]! : Colors.grey[50]!,
      period: const Duration(milliseconds: 1500),
      child: Container(
        width: width,
        height: height,
        decoration: ShapeDecoration(
          color: Colors.grey,
          shape: shapeBorder,
        ),
      ),
    );
  }
}

class ListingCardShimmer extends StatelessWidget {
  const ListingCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: AppRadius.roundedXL,
        border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 12,
            child: ShimmerLoading.rectangular(
              height: double.infinity,
              borderRadius: AppRadius.xl,
            ),
          ),
          Expanded(
            flex: 9,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const ShimmerLoading.rectangular(height: 14, width: 140),
                  const SizedBox(height: 6),
                  const ShimmerLoading.rectangular(height: 14, width: 100),
                  const Spacer(),
                  const ShimmerLoading.rectangular(height: 18, width: 60),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const ShimmerLoading.circular(width: 20, height: 20),
                      const SizedBox(width: 8),
                      const ShimmerLoading.rectangular(height: 10, width: 80),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
