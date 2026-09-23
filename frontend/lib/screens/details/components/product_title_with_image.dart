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
          // Hero image with gradient glow
          SizedBox(
            width: double.infinity,
            height: 240,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          product.color.withValues(alpha: 0.15),
                          kSurfaceColor,
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: -30,
                  top: -30,
                  child: Container(
                    width: 120,
                    height: 120,
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
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: kPrimaryColor.withValues(alpha: 0.15),
                    ),
                  ),
                ),
                Hero(
                  tag: "${product.id}",
                  child: product.image.startsWith('http')
                      ? CachedNetworkImage(
                          imageUrl: product.image,
                          height: 200,
                          placeholder: (context, url) =>
                              const Center(
                                  child:
                                      CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: kPrimaryColor)),
                          errorWidget: (context, url, error) =>
                              const Icon(Icons.broken_image,
                                  color: kTextLightColor,
                                  size: 48),
                          fit: BoxFit.contain,
                        )
                      : Image.asset(
                          product.image,
                          height: 200,
                          fit: BoxFit.contain,
                        ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
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
          const SizedBox(height: 8),
          Text(
            "Baterpoint Listing",
            style: const TextStyle(
              color: kTextLightColor,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}