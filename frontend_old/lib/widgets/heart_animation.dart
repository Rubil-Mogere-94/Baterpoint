import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class HeartAnimation extends StatelessWidget {
  final bool isVisible;
  final VoidCallback onCompleted;

  const HeartAnimation({
    super.key,
    required this.isVisible,
    required this.onCompleted,
  });

  @override
  Widget build(BuildContext context) {
    if (!isVisible) return const SizedBox.shrink();

    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Inner Glow
          const Icon(
            Icons.favorite_rounded,
            color: Colors.white24,
            size: 110,
          ).animate(onComplete: (_) => onCompleted())
            .scale(duration: 400.ms, curve: Curves.easeOutBack)
            .fadeOut(duration: 400.ms),
            
          // Main Heart
          const Icon(
            Icons.favorite_rounded,
            color: Colors.white,
            size: 80,
          )
          .animate()
          .scale(
            duration: 400.ms,
            begin: const Offset(0.4, 0.4),
            end: const Offset(1.2, 1.2),
            curve: Curves.elasticOut,
          )
          .rotate(begin: -0.1, end: 0, duration: 400.ms, curve: Curves.elasticOut)
          .fadeIn(duration: 200.ms)
          .then()
          .fadeOut(delay: 200.ms, duration: 200.ms),
        ],
      ),
    );
  }
}
