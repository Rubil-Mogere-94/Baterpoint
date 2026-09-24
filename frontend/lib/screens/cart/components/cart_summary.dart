import 'package:flutter/material.dart';
import '../../../constants.dart';

class CartSummary extends StatelessWidget {
  final List<dynamic> items;
  const CartSummary({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    final total = items.fold<double>(
        0, (sum, item) => sum + (item.price ?? 0).toDouble());

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kSurfaceColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total:',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge!
                      .copyWith(fontWeight: FontWeight.w600),
                ),
                Text(
                  '\$${total.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: kPrimaryColor,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: total > 0 ? () {} : null,
                child: const Text('Checkout'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}