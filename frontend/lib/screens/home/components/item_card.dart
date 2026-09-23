import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../utils/app_haptics.dart';
import '../../../constants.dart';
import '../../../models/product.dart';

class ItemCard extends StatelessWidget {
  const ItemCard({super.key, required this.product, required this.press});

  final Product product;
  final VoidCallback press;

  @override
  Widget build(BuildContext context) {
    final isBarter = product.acceptsBarter;
    final isSale = product.acceptsCurrency;

    return InkWell(
      onTap: () {
        AppHaptics.light();
        press();
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: kSurfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: kBorderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image - consistent aspect ratio, not oversized
            AspectRatio(
              aspectRatio: 4 / 5,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: product.image.startsWith('http')
                        ? CachedNetworkImage(
                            imageUrl: product.image,
                            placeholder: (context, url) =>
                                const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                            errorWidget: (context, url, error) =>
                                const Icon(Icons.broken_image, color: Colors.white38),
                            fit: BoxFit.cover,
                          )
                        : Image.asset(product.image, fit: BoxFit.cover),
                  ),
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.35),
                          ],
                          stops: const [0.0, 0.55, 1.0],
                        ),
                      ),
                    ),
                  ),
                  // Barter badge - clear and visible
                  if (isBarter)
                    Positioned(
                      top: 10,
                      left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: kBarterColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.swap_horiz_rounded,
                                color: Colors.white, size: 10),
                            const SizedBox(width: 4),
                            Text(
                              "Barter",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  // Condition badge
                  if (product.condition != null &&
                      product.condition!.isNotEmpty)
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: kSurfaceColor.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          product.condition!,
                          style: TextStyle(
                            color: kTextColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  // Rating badge
                  Positioned(
                    bottom: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.75),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star_rounded,
                              color: Colors.amber, size: 12),
                          const SizedBox(width: 2),
                          Text(
                            product.rating > 0
                                ? product.rating.toStringAsFixed(1)
                                : 'New',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Product info
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: kTextColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      if (isBarter)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: kBarterColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.swap_horiz_rounded,
                                  color: kBarterColor, size: 12),
                              const SizedBox(width: 4),
                              const Text(
                                "Trade",
                                style: TextStyle(
                                  color: kBarterColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(width: 8),
                      if (isSale)
                        Text(
                          "\$${product.price}",
                          style: const TextStyle(
                            color: kCurrencyColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Trade preference - most important for barter
                  if (product.barterPreference != null &&
                      product.barterPreference!.isNotEmpty)
                    Text(
                      'Wants: ${product.barterPreference!}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: kTextLightColor,
                        fontSize: 11,
                        height: 1.4,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}