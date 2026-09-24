import 'package:flutter/material.dart';
import '../../../constants.dart';

class CartItemTile extends StatelessWidget {
  final dynamic product;
  const CartItemTile({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: kPrimaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(Icons.image_outlined, color: kPrimaryColor),
      ),
      title: Text(product.title ?? ''),
      subtitle: Text('\$${product.price ?? 0}'),
      trailing: IconButton(
        icon: Icon(Icons.delete_outline, color: kErrorColor),
        onPressed: () {},
      ),
    );
  }
}