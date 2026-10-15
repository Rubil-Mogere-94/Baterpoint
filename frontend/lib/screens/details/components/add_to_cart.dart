import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../utils/app_haptics.dart';
import '../../../constants.dart';
import '../../../models/product.dart';
import '../../../services/api_service.dart';

class AddToCart extends StatelessWidget {
  const AddToCart({super.key, required this.product});

  final Product product;

  Future<void> _addToCart(BuildContext context) async {
    try {
      await ApiService().addToCart(product.id);
      if (!context.mounted) return;
      AppHaptics.success();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Added to your cart.')),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  Future<void> _makeOffer(BuildContext context) async {
    final itemController = TextEditingController();
    final priceController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final offer = await showDialog<Map<String, String?>>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Make a trade offer'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (product.acceptsBarter)
                  TextFormField(
                    controller: itemController,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(labelText: 'What would you offer?'),
                  ),
                if (product.acceptsCurrency) ...[
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: priceController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Cash offer (optional)', prefixText: 'KSh '),
                  ),
                ],
                const SizedBox(height: 8),
                const Text('The seller will review your offer before any trade is agreed.', style: TextStyle(color: kTextLightColor, fontSize: 12, height: 1.4)),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final offeredItem = itemController.text.trim();
              final rawPrice = priceController.text.trim();
              final price = rawPrice.isEmpty ? null : double.tryParse(rawPrice);
              if (rawPrice.isNotEmpty && (price == null || price < 0)) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(const SnackBar(content: Text('Enter a valid cash amount.')));
                return;
              }
              if (product.acceptsBarter && offeredItem.isEmpty && price == null) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(const SnackBar(content: Text('Add an item or cash amount to your offer.')));
                return;
              }
              if (!product.acceptsBarter && price == null) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(const SnackBar(content: Text('Enter a cash offer.')));
                return;
              }
              Navigator.pop(dialogContext, {
                'item': offeredItem,
                'price': rawPrice,
              });
            },
            child: const Text('Send offer'),
          ),
        ],
      ),
    );
    itemController.dispose();
    priceController.dispose();
    if (offer == null) return;

    try {
      final rawPrice = (offer['price'] ?? '').trim();
      await ApiService().createOffer(
        product.id,
        offeredItem: offer['item'],
        offeredPrice: rawPrice.isEmpty ? null : double.tryParse(rawPrice),
      );
      if (!context.mounted) return;
      AppHaptics.success();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Offer sent to the seller.')));
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasBarter = product.acceptsBarter;
    final hasCurrency = product.acceptsCurrency;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          if (hasCurrency)
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
                tooltip: 'Add to cart',
                icon: SvgPicture.asset(
                  'assets/icons/add_to_cart.svg',
                  colorFilter: const ColorFilter.mode(kPrimaryColor, BlendMode.srcIn),
                ),
                onPressed: () => _addToCart(context),
              ),
            ),
          if (hasBarter)
            Expanded(
              child: _ActionButton(
                label: 'Make offer',
                color: kBarterColor,
                onTap: () => _makeOffer(context),
              ),
            ),
          if (hasBarter && hasCurrency) const SizedBox(width: 8),
          if (hasCurrency)
            Expanded(
              child: _ActionButton(
                label: 'Add · ${formatKes(product.price)}',
                color: kPrimaryColor,
                onTap: () => _addToCart(context),
              ),
            ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.label, required this.color, required this.onTap});

  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          backgroundColor: color,
          elevation: 0,
          shadowColor: Colors.transparent,
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
        ),
        child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
      );
}
