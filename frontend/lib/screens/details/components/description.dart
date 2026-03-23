import 'package:flutter/material.dart';

import '../../../constants.dart';
import '../../../models/product.dart';

class Description extends StatelessWidget {
  const Description({super.key, required this.product});

  final Product product;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: kDefaultPaddin),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              product.description,
              style: const TextStyle(height: 1.5, color: kTextLightColor),
            ),
            if (product.acceptsBarter && product.barterPreference != null) ...[
              const SizedBox(height: kDefaultPaddin),
              const Text(
                "Trade Preferences:",
                style: TextStyle(fontWeight: FontWeight.bold, color: kBarterColor),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: kBarterColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: kBarterColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  product.barterPreference!,
                  style: const TextStyle(fontStyle: FontStyle.italic),
                ),
              ),
            ],
          ],
        ),
    );
  }
}
