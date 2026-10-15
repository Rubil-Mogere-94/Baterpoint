import 'package:flutter/material.dart';
import '../../constants.dart';
import '../../services/api_service.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final ApiService _apiService = ApiService();
  late Future<Map<String, dynamic>> _cartFuture;
  bool _checkingOut = false;

  @override
  void initState() {
    super.initState();
    _cartFuture = _apiService.getCart();
  }

  Future<void> _reload() async {
    setState(() => _cartFuture = _apiService.getCart());
    try { await _cartFuture; } catch (_) {}
  }

  Future<void> _removeItem(int itemId) async {
    try {
      await _apiService.removeCartItem(itemId);
      if (mounted) {
        setState(() => _cartFuture = _apiService.getCart());
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Item removed from cart.')));
      }
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))));
    }
  }

  Future<void> _checkout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Place this order?'),
        content: const Text('This will create a pending order from the cash items in your cart.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Keep shopping')),
          ElevatedButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Place order')),
        ],
      ),
    );
    if (confirm != true) return;
    setState(() => _checkingOut = true);
    try {
      final order = await _apiService.createOrder();
      if (!mounted) return;
      setState(() => _cartFuture = _apiService.getCart());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Order #${order['id']} created and marked pending.')),
      );
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))));
    } finally {
      if (mounted) setState(() => _checkingOut = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(title: const Text('Your cart')),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _cartFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.cloud_off_rounded, size: 48, color: kTextLightColor),
                  const SizedBox(height: 12),
                  const Text('Your cart could not be loaded.'),
                  TextButton(onPressed: _reload, child: const Text('Try again')),
                ],
              ),
            );
          }
          final rawItems = snapshot.data?['items'];
          final items = rawItems is List
              ? rawItems.map((item) => Map<String, dynamic>.from(item as Map)).toList()
              : <Map<String, dynamic>>[];
          double total = 0;
          for (final item in items) {
            final listing = item['listing'];
            if (listing is Map) {
              final price = (listing['cashPrice'] as num?)?.toDouble() ?? 0;
              final quantity = (item['quantity'] as num?)?.toInt() ?? 1;
              total += price * quantity;
            }
          }
          if (items.isEmpty) {
            return RefreshIndicator(
              onRefresh: _reload,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(28),
                children: const [
                  SizedBox(height: 80),
                  Icon(Icons.shopping_bag_outlined, size: 68, color: kTextLightColor),
                  SizedBox(height: 16),
                  Center(child: Text('Your cart is empty', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600))),
                  SizedBox(height: 8),
                  Center(child: Text('Add cash listings from an item page. Barter offers are sent separately.', textAlign: TextAlign.center, style: TextStyle(color: kTextLightColor, height: 1.45))),
                ],
              ),
            );
          }
          return Column(
            children: [
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _reload,
                  child: ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(kDefaultPadding),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      final listing = item['listing'] is Map
                          ? Map<String, dynamic>.from(item['listing'] as Map)
                          : <String, dynamic>{};
                      final itemId = (item['id'] as num?)?.toInt();
                      final quantity = (item['quantity'] as num?)?.toInt() ?? 1;
                      final title = (listing['title'] ?? 'Listing').toString();
                      final price = (listing['cashPrice'] as num?)?.toDouble() ?? 0;
                      final image = (listing['imageUrl'] ?? '').toString();
                      return Card.outlined(
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: SizedBox(
                              width: 56,
                              height: 56,
                              child: image.startsWith('http')
                                  ? Image.network(image, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported_outlined))
                                  : const Icon(Icons.inventory_2_outlined, color: kPrimaryColor),
                            ),
                          ),
                          title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
                          subtitle: Text('$quantity × \$${price.toStringAsFixed(2)}'),
                          trailing: IconButton(
                            tooltip: 'Remove item',
                            onPressed: itemId == null ? null : () => _removeItem(itemId),
                            icon: const Icon(Icons.delete_outline_rounded, color: kErrorColor),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              SafeArea(
                top: false,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                  decoration: const BoxDecoration(color: kSurfaceColor, border: Border(top: BorderSide(color: kBorderColor))),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Text('Subtotal', style: TextStyle(color: kTextLightColor)),
                          const Spacer(),
                          Text('\$${total.toStringAsFixed(2)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _checkingOut ? null : _checkout,
                          child: _checkingOut
                              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Text('Place order'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
