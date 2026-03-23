import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../utils/app_haptics.dart';


import '../../../constants.dart';
import '../../../models/product.dart';

class AddToCart extends StatelessWidget {
  const AddToCart({super.key, required this.product});

  final Product product;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: kDefaultPaddin),
      child: Row(
        children: <Widget>[
          Container(
            margin: const EdgeInsets.only(right: kDefaultPaddin),
            height: 50,
            width: 58,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: product.color,
              ),
            ),
            child: IconButton(
              icon: SvgPicture.asset(
                "assets/icons/add_to_cart.svg",
                colorFilter: ColorFilter.mode(product.color, BlendMode.srcIn),
              ),
              onPressed: () {
                AppHaptics.light();
              },
            ),
          ).animate().scale(delay: 100.ms, duration: 400.ms, curve: Curves.easeOutBack),

          if (product.acceptsBarter)
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  AppHaptics.success();
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 54),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18)),
                  backgroundColor: kBarterColor,
                  elevation: 5,
                  shadowColor: kBarterColor.withValues(alpha: 0.4),
                ),
                child: Text(
                  "Barter".toUpperCase(),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.2,
                  ),
                ),
              ).animate().fadeIn(delay: 200.ms).moveX(begin: 20, end: 0),
            ),

          if (product.acceptsBarter && product.acceptsCurrency)
            const SizedBox(width: kDefaultPaddin / 2),
          if (product.acceptsCurrency)
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  AppHaptics.success();
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 54),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18)),
                  backgroundColor: product.color,
                  elevation: 5,
                  shadowColor: product.color.withValues(alpha: 0.4),
                ),
                child: Text(
                  "Buy \$${product.price}".toUpperCase(),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.2,
                  ),
                ),
              ).animate().fadeIn(delay: 300.ms).moveX(begin: 20, end: 0),
            ),

        ],
      ),
    );
  }
}
