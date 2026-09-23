import 'package:flutter/material.dart';
import '../../constants.dart';
import '../../models/product.dart';
import 'components/product_title_with_image.dart';
import 'components/color_and_size.dart';
import 'components/description.dart';
import 'components/counter_with_fav_btn.dart';
import 'components/add_to_cart.dart';

class DetailsScreen extends StatelessWidget {
  const DetailsScreen({super.key, required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: kBackgroundColor,
      body: CustomScrollView(
        physics: const ClampingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: size.height * 0.5,
            pinned: true,
            backgroundColor: kSurfaceColor,
            surfaceTintColor: Colors.transparent,
            flexibleSpace: FlexibleSpaceBar(
              background: ProductTitleWithImage(product: product),
              centerTitle: true,
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded),
              onPressed: () => Navigator.of(context).pop(),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.favorite_border_rounded),
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(Icons.share_rounded),
                onPressed: () {},
              ),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.all(kDefaultPadding),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Price and barter info
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: kPrimaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        if (product.acceptsBarter && product.barterPreference != null)
                          Row(
                            children: [
                              Icon(Icons.swap_horiz_rounded,
                                  color: kBarterColor, size: 14),
                              const SizedBox(width: 4),
                              Text(
                                product.barterPreference!,
                                style: const TextStyle(
                                  color: kBarterColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            '\$${product.price}',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge!
                                .copyWith(
                                  color: kTextColor,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Product details
                  ColorAndSize(product: product),
                  const SizedBox(height: 24),
                  Description(product: product),
                  const SizedBox(height: 32),
                  CounterWithFavBtn(),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          // CTA Button
          SliverFillRemaining(
            hasScrollBody: false,
            child: Container(
              color: kBackgroundColor,
              padding: const EdgeInsets.symmetric(
                  horizontal: kDefaultPadding, vertical: 12),
              child: SafeArea(
                bottom: true,
                child: AddToCart(product: product),
              ),
            ),
          ),
        ],
      ),
    );
  }
}