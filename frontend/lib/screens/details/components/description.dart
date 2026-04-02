import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../constants.dart';
import '../../../models/product.dart';

class Description extends StatelessWidget {
  const Description({super.key, required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          product.description,
          style: const TextStyle(
              height: 1.6, color: kTextLightColor, fontSize: 14),
        ),
        if (product.acceptsBarter && product.barterPreference != null) ...[
          const SizedBox(height: kDefaultPaddin),
          const Text(
            "Trade Preferences",
            style: TextStyle(
                fontWeight: FontWeight.bold,
                color: kBarterColor,
                fontSize: 14),
          ),
          const SizedBox(height: 8),
          // Animated pulsing border card
          _PulsingCard(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.swap_horiz_rounded,
                    color: kBarterColor, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    product.barterPreference!,
                    style: const TextStyle(
                      fontStyle: FontStyle.italic,
                      color: kTextColor,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _PulsingCard extends StatelessWidget {
  final Widget child;
  const _PulsingCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kBarterColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border:
            Border.all(color: kBarterColor.withValues(alpha: 0.35), width: 1.5),
      ),
      child: child,
    )
        .animate(onPlay: (ctrl) => ctrl.repeat(reverse: true))
        .custom(
          duration: const Duration(milliseconds: 1800),
          builder: (context, value, child) {
            return Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color:
                        kBarterColor.withValues(alpha: 0.15 + value * 0.25),
                    blurRadius: 8 + value * 14,
                    spreadRadius: value * 2,
                  ),
                ],
              ),
              child: child,
            );
          },
        );
  }
}
