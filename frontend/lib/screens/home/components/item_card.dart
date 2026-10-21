import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../constants.dart';
import '../../../models/product.dart';
import '../../../utils/app_haptics.dart';

class ItemCard extends StatelessWidget {
  const ItemCard({super.key, required this.product, required this.press});

  final Product product;
  final VoidCallback press;

  @override
  Widget build(BuildContext context) {
    final tradeLabel = product.acceptsBarter && product.acceptsCurrency
        ? 'MIXED TRADE'
        : product.acceptsBarter
            ? 'BARTER'
            : 'CURRENCY';
    final tradeColor = product.acceptsBarter ? kBarterColor : kCurrencyColor;

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      color: kSurfaceColor,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: kBorderColor),
      ),
      child: InkWell(
        onTap: () {
          AppHaptics.light();
          press();
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _productImage(),
                  Positioned(
                    top: 9,
                    left: 9,
                    right: 9,
                    child: Row(
                      children: [
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.96),
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(color: kBorderColor.withValues(alpha: 0.8)),
                            ),
                            child: Text(
                              tradeLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: tradeColor,
                                fontSize: 9,
                                letterSpacing: 0.35,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                        if (product.rating > 0) ...[
                          const SizedBox(width: 5),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.96),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.star_rounded, color: Color(0xFFE1A323), size: 13),
                                const SizedBox(width: 2),
                                Text(
                                  product.rating.toStringAsFixed(1),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: kTextColor,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(11, 10, 11, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      product.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: kTextColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        height: 1.22,
                      ),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            product.acceptsCurrency
                                ? formatKes(product.price)
                                : 'Open to exchange',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: product.acceptsCurrency ? kTextColor : kBarterColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          product.acceptsBarter && product.acceptsCurrency
                              ? Icons.swap_horiz_rounded
                              : product.acceptsBarter
                                  ? Icons.handshake_outlined
                                  : Icons.arrow_outward_rounded,
                          size: 16,
                          color: tradeColor,
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
    );
  }

  Widget _productImage() {
    final fallback = Container(
      color: kBackgroundColor,
      alignment: Alignment.center,
      child: const Icon(Icons.image_outlined, color: kTextLightColor, size: 34),
    );

    if (product.image.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: product.image,
        fit: BoxFit.cover,
        placeholder: (_, __) => Container(
          color: kBackgroundColor,
          alignment: Alignment.center,
          child: const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
        errorWidget: (_, __, ___) => fallback,
      );
    }

    return Image.asset(
      product.image,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => fallback,
    );
  }
}
