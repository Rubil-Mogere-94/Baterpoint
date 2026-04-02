import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:ui';
import '../../../utils/app_haptics.dart';
import '../../../constants.dart';
import '../../../models/product.dart';

class ItemCard extends StatefulWidget {
  const ItemCard({super.key, required this.product, required this.press});

  final Product product;
  final VoidCallback press;

  @override
  State<ItemCard> createState() => _ItemCardState();
}

class _ItemCardState extends State<ItemCard> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.95),
      onTapUp: (_) {
        setState(() => _scale = 1.0);
        AppHaptics.light();
        widget.press();
      },
      onTapCancel: () => setState(() => _scale = 1.0),
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutBack,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.08),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.product.color.withValues(alpha: 0.18),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: [
                // Product image background
                Positioned.fill(
                  child: Container(color: widget.product.color),
                ),

                // Glassmorphism overlay
                Positioned.fill(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 0, sigmaY: 0),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.55),
                          ],
                          stops: const [0.4, 1.0],
                        ),
                      ),
                    ),
                  ),
                ),

                // Hero image
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 52),
                  child: Hero(
                    tag: "${widget.product.id}",
                    child: widget.product.image.startsWith('http')
                        ? CachedNetworkImage(
                            imageUrl: widget.product.image,
                            placeholder: (context, url) => const Center(
                                child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white54)),
                            errorWidget: (context, url, error) =>
                                const Icon(Icons.broken_image,
                                    color: Colors.white38),
                            fit: BoxFit.contain,
                          )
                        : Image.asset(widget.product.image,
                            fit: BoxFit.contain),
                  ),
                ),

                // Barter badge (top-right)
                if (widget.product.acceptsBarter)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: kBarterColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: kBarterColor.withValues(alpha: 0.7),
                            width: 1),
                        boxShadow: [
                          BoxShadow(
                            color: kBarterColor.withValues(alpha: 0.4),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.swap_horiz_rounded,
                              color: kBarterColor, size: 11),
                          SizedBox(width: 3),
                          Text(
                            "Barter",
                            style: TextStyle(
                              color: kBarterColor,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Bottom info bar (glassmorphism)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                    child: BackdropFilter(
                      filter:
                          ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        color: Colors.black.withValues(alpha: 0.35),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                widget.product.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            if (widget.product.acceptsCurrency)
                              Text(
                                "\$${widget.product.price}",
                                style: const TextStyle(
                                  color: kCurrencyColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ).animate().fadeIn(duration: 400.ms).scale(
            begin: const Offset(0.92, 0.92),
            curve: Curves.easeOutBack),
      ),
    );
  }
}
