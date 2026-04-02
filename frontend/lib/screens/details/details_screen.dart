import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../constants.dart';
import '../../models/product.dart';
import 'components/add_to_cart.dart';
import 'components/color_and_size.dart';
import 'components/counter_with_fav_btn.dart';
import 'components/description.dart';
import 'components/product_title_with_image.dart';

class DetailsScreen extends StatelessWidget {
  const DetailsScreen({super.key, required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: product.color,
      appBar: AppBar(
        backgroundColor: product.color,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded,
                color: Colors.white, size: 18),
          ),
        ),
        actions: [
          _ActionBtn(
            icon: Icons.favorite_border_rounded,
            onTap: () {},
          ),
          _ActionBtn(
            icon: Icons.share_rounded,
            onTap: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          // Scrollable content
          SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 110),
            child: Column(
              children: [
                SizedBox(
                  height: size.height * 0.82,
                  child: Stack(
                    children: [
                      // Bottom sheet (dark)
                      Positioned(
                        top: size.height * 0.28,
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: EdgeInsets.only(
                            top: size.height * 0.1,
                            left: kDefaultPaddin,
                            right: kDefaultPaddin,
                          ),
                          decoration: BoxDecoration(
                            color: kBackgroundColor,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(30),
                              topRight: Radius.circular(30),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.4),
                                blurRadius: 24,
                                offset: const Offset(0, -4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ColorAndSize(product: product)
                                  .animate()
                                  .fadeIn(delay: 100.ms)
                                  .slideY(begin: 0.1, end: 0),
                              const SizedBox(height: kDefaultPaddin / 2),
                              Description(product: product)
                                  .animate()
                                  .fadeIn(delay: 200.ms)
                                  .slideY(begin: 0.1, end: 0),
                              const SizedBox(height: kDefaultPaddin / 2),
                              const CounterWithFavBtn()
                                  .animate()
                                  .fadeIn(delay: 300.ms)
                                  .slideY(begin: 0.1, end: 0),
                            ],
                          ),
                        ),
                      ),
                      // Product title + image (floats above sheet)
                      ProductTitleWithImage(product: product),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Sticky frosted-glass CTA bar
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  padding: EdgeInsets.only(
                    left: kDefaultPaddin,
                    right: kDefaultPaddin,
                    top: 12,
                    bottom:
                        MediaQuery.of(context).padding.bottom + 12,
                  ),
                  decoration: BoxDecoration(
                    color: kBackgroundColor.withValues(alpha: 0.75),
                    border: Border(
                      top: BorderSide(
                          color: Colors.white.withValues(alpha: 0.08),
                          width: 1),
                    ),
                  ),
                  child: AddToCart(product: product)
                      .animate()
                      .fadeIn(delay: 400.ms)
                      .slideY(begin: 0.2, end: 0),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _ActionBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }
}
