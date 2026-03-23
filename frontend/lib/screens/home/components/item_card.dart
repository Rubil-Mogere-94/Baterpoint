import 'package:flutter/material.dart';

import '../../../constants.dart';
import '../../../models/product.dart';

class ItemCard extends StatelessWidget {
  const ItemCard({super.key, required this.product, required this.press});

  final Product product;
  final VoidCallback press;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: press,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(kDefaultPaddin),
              decoration: BoxDecoration(
                color: product.color,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Hero(
                tag: "${product.id}",
                child: Image.asset(product.image),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: kDefaultPaddin / 4),
            child: Text(
              // products is out demo list
              product.title,
              style: const TextStyle(color: kTextLightColor),
            ),
          ),
          Row(
            children: [
              if (product.acceptsCurrency)
                Text(
                  "\$${product.price}",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              if (product.acceptsCurrency && product.acceptsBarter) 
                const SizedBox(width: 8),
              if (product.acceptsBarter)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: kBarterColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text("Barter", style: TextStyle(color: kBarterColor, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
            ],
          )
        ],
      ),
    );
  }
}
