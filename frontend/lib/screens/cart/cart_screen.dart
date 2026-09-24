import 'package:flutter/material.dart';
import '../../constants.dart';
import '../../models/product.dart';
import 'components/cart_item_tile.dart';
import 'components/cart_summary.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final items = <Product>[];

    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(title: const Text('Cart')),
      body: items.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_cart_outlined,
                      size: 64, color: kTextLightColor),
                  const SizedBox(height: 16),
                  Text(
                    'Your cart is empty',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: kTextLightColor,
                        ),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(kDefaultPadding),
                    itemCount: items.length,
                    itemBuilder: (context, index) => Card.outlined(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: CartItemTile(product: items[index]),
                    ),
                  ),
                ),
                CartSummary(items: items),
              ],
            ),
    );
  }
}