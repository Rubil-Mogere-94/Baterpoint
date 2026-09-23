import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../constants.dart';
import '../../../models/product.dart';

class ProductTitleWithImage extends StatelessWidget {
  const ProductTitleWithImage({super.key, required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product image with gradient overlay
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: SizedBox(
              height: 180,
              width: double.infinity,
              child: Stack(
                children: [
                  // Background color
                  Container(
                    color: product.color.withValues(alpha: 0.15),
                  ),
                  // Decorations
                  Positioned(
                    right: -30,
                    top: -30,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: product.color.withValues(alpha: 0.2),
                      ),
                    ),
                  ),
                  Positioned(
                    left: -20,
                    bottom: -20,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: kPrimaryColor.withValues(alpha: 0.15),
                      ),
                    ),
                  ),
                  // Product image - smaller, more concise
                  Positioned.fill(
                    child: Center(
                      child: product.image.startsWith('http')
                          ? CachedNetworkImage(
                              imageUrl: product.image,
                              height: 150,
                              placeholder: (context, url) =>
                                  const Center(
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2)),
                              errorWidget: (context, url, error) =>
                                  const Icon(Icons.broken_image,
                                      color: kTextLightColor, size: 48),
                              fit: BoxFit.contain,
                            )
                          : Image.asset(
                              product.image,
                              height: 150,
                              fit: BoxFit.contain,
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            product.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context)
                .textTheme
                .headlineMedium!
                .copyWith(
                  color: kTextColor,
                  fontWeight: FontWeight.bold,
                  height: 1.3,
                ),
          ),
        ],
      ),
    );
  }
}