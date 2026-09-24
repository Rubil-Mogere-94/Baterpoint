import 'package:flutter/material.dart';
import '../../constants.dart';

class CartItemTile extends StatelessWidget {
  final dynamic product;
  const CartItemTile({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(Icons.image_outlined, color: kPrimaryColor),
        title: Text(product.title ?? ''),
        subtitle: Text('\$${product.price ?? 0}'),
        trailing: IconButton(
          icon: Icon(Icons.delete_outline, color: kErrorColor),
          onPressed: () {},
        ),
      ),
    );
  }
}