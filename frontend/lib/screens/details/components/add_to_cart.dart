import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../utils/app_haptics.dart';
import '../../../constants.dart';
import '../../../models/product.dart';

class AddToCart extends StatelessWidget {
  const AddToCart({super.key, required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final hasBarter = product.acceptsBarter;
    final hasCurrency = product.acceptsCurrency;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: <Widget>[
          // Add to cart button
          Container(
            margin: const EdgeInsets.only(right: 8),
            height: 52,
            width: 52,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: kPrimaryColor, width: 1.5),
              color: kPrimaryColor.withValues(alpha: 0.1),
            ),
            child: IconButton(
              icon: SvgPicture.asset(
                "assets/icons/add_to_cart.svg",
                colorFilter: ColorFilter.mode(kPrimaryColor, BlendMode.srcIn),
              ),
              onPressed: () {
                AppHaptics.light();
              },
            ),
          ),

          // Barter button
          if (hasBarter) Expanded(
            child: _ActionButton(
              label: "Trade",
              color: kBarterColor,
              onTap: () {
                AppHaptics.success();
              },
            ),
          ),

          if (hasBarter && hasCurrency)
            const SizedBox(width: 8),

          // Buy button
          if (hasCurrency) Expanded(
            child: _ActionButton(
              label: "\$${product.price}",
              color: kPrimaryColor,
              onTap: () {
                AppHaptics.success();
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          backgroundColor: color,
          elevation: 0,
          shadowColor: Colors.transparent,
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        child: Text(label),
      ),
    );
  }
}