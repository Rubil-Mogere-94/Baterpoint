import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:ui';
import '../models/cart.dart';
import '../services/cart_service.dart';
import '../constants/theme.dart';
import '../widgets/holographic_background.dart';
import 'checkout_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final CartService _cartService = CartService();
  Cart? _cart;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCart();
  }

  Future<void> _loadCart() async {
    setState(() => _isLoading = true);
    try {
      final cart = await _cartService.fetchMyCart();
      if (mounted) setState(() { _cart = cart; _isLoading = false; });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading cart: $e'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: AppRadius.roundedLG),
            margin: const EdgeInsets.all(AppSpacing.md),
          ),
        );
      }
    }
  }

  Future<void> _updateQuantity(int itemId, int quantity) async {
    try {
      final cart = await _cartService.updateQuantity(itemId, quantity);
      if (mounted) setState(() => _cart = cart);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _removeItem(int itemId) async {
    try {
      final cart = await _cartService.removeFromCart(itemId);
      if (mounted) setState(() => _cart = cart);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isEmpty = _cart == null || _cart!.items.isEmpty;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Shopping Cart', style: TextStyle(fontWeight: FontWeight.w900)),
        centerTitle: true,
        actions: [
          if (!_isLoading && !isEmpty)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.md),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.15),
                    borderRadius: AppRadius.roundedPill,
                    border: Border.all(color: theme.colorScheme.primary.withOpacity(0.3)),
                  ),
                  child: Text(
                    '${_cart!.items.length} item${_cart!.items.length == 1 ? '' : 's'}',
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: HolographicBackground(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : isEmpty
                  ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      child: ClipRRect(
                        borderRadius: AppRadius.roundedXXL,
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
                            decoration: BoxDecoration(
                              color: (isDark ? Colors.white : Colors.black).withOpacity(0.04),
                              borderRadius: AppRadius.roundedXXL,
                              border: Border.all(
                                color: (isDark ? Colors.white : Colors.black).withOpacity(0.12),
                              ),
                              boxShadow: [
                                BoxShadow(color: theme.colorScheme.primary.withOpacity(0.05), blurRadius: 40),
                              ],
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Container(
                                      width: 120,
                                      height: 120,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: theme.colorScheme.primary.withOpacity(0.05),
                                      ),
                                    ).animate(onPlay: (controller) => controller.repeat())
                                      .scale(begin: const Offset(1, 1), end: const Offset(1.3, 1.3), duration: 2.seconds, curve: Curves.easeInOut)
                                      .fadeOut(duration: 2.seconds),
                                    Icon(
                                      Icons.shopping_cart_outlined,
                                      size: 72,
                                      color: theme.colorScheme.primary.withOpacity(0.8),
                                    ).animate().scale(curve: Curves.easeOutBack, duration: 600.ms)
                                     .then(delay: 1.seconds).shimmer(duration: 2.seconds, color: Colors.white54),
                                  ],
                                ),
                                const SizedBox(height: 32),
                                Text(
                                  'Your cart is empty',
                                  style: theme.textTheme.headlineSmall
                                      ?.copyWith(fontWeight: FontWeight.w900, letterSpacing: -0.5),
                                ).animate().fadeIn(delay: 200.ms),
                                const SizedBox(height: 12),
                                Text(
                                  'Explore the marketplace to find\nyour next great deal.',
                                  style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey, height: 1.5),
                                  textAlign: TextAlign.center,
                                ).animate().fadeIn(delay: 300.ms),
                                const SizedBox(height: 40),
                                SizedBox(
                                  width: 200,
                                  height: 50,
                                  child: ElevatedButton(
                                    onPressed: () => Navigator.pop(context),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: theme.colorScheme.primary,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(borderRadius: AppRadius.roundedPill),
                                    ),
                                    child: const Text('BROWSE MARKET', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1.2)),
                                  ).animate().fadeIn(delay: 400.ms)
                                      .slideY(begin: 0.2, end: 0, delay: 400.ms),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  )
                : Column(
                    children: [
                      Expanded(
                        child: ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(
                              AppSpacing.lg, 110, AppSpacing.lg, AppSpacing.md),
                          itemCount: _cart!.items.length,
                          itemBuilder: (context, index) {
                            return _CartItemTile(
                              item: _cart!.items[index],
                              isDark: isDark,
                              index: index,
                              onUpdateQuantity: _updateQuantity,
                              onRemove: _removeItem,
                            );
                          },
                        ),
                      ),
                      _CheckoutBar(cart: _cart!, isDark: isDark),
                    ],
                  ),
      ),
    );
  }
}

class _CartItemTile extends StatelessWidget {
  final CartItem item;
  final bool isDark;
  final int index;
  final Future<void> Function(int, int) onUpdateQuantity;
  final Future<void> Function(int) onRemove;

  const _CartItemTile({
    required this.item,
    required this.isDark,
    required this.index,
    required this.onUpdateQuantity,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: ClipRRect(
        borderRadius: AppRadius.roundedXL,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: (isDark ? Colors.white : Colors.black).withOpacity(0.04),
              borderRadius: AppRadius.roundedXL,
              border: Border.all(
                color: (isDark ? Colors.white : Colors.black).withOpacity(0.12),
              ),
              boxShadow: isDark ? [] : [
                BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product image
                ClipRRect(
                  borderRadius: AppRadius.roundedLG,
                  child: Image.network(
                    item.listing.imageUrl ?? 'https://via.placeholder.com/90',
                    width: 90,
                    height: 90,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      width: 90,
                      height: 90,
                      color: Colors.grey.withOpacity(0.1),
                      child: const Icon(Icons.image_rounded, color: Colors.grey),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.listing.title,
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        '\$${item.listing.cashPrice?.toStringAsFixed(2) ?? '0.00'}',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF10B981),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        children: [
                          // Quantity selector
                          ClipRRect(
                            borderRadius: AppRadius.roundedPill,
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: (isDark ? Colors.white : Colors.black).withOpacity(0.07),
                                  borderRadius: AppRadius.roundedPill,
                                  border: Border.all(
                                    color: (isDark ? Colors.white : Colors.black).withOpacity(0.1),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _QtyButton(
                                      icon: Icons.remove_rounded,
                                      onTap: item.quantity > 1
                                          ? () => onUpdateQuantity(item.id, item.quantity - 1)
                                          : null,
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                                      child: Text(
                                        '${item.quantity}',
                                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                                      ),
                                    ),
                                    _QtyButton(
                                      icon: Icons.add_rounded,
                                      onTap: () => onUpdateQuantity(item.id, item.quantity + 1),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const Spacer(),
                          // Remove
                          IconButton(
                            onPressed: () => onRemove(item.id),
                            icon: const Icon(Icons.delete_outline_rounded),
                            color: Colors.grey,
                            visualDensity: VisualDensity.compact,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    )
        .animate()
        .slideY(
          begin: 0.1,
          end: 0,
          delay: Duration(milliseconds: 80 + (index * 60)),
          duration: 400.ms,
          curve: Curves.easeOutCubic,
        )
        .fadeIn(delay: Duration(milliseconds: 80 + (index * 60)));
  }
}

class _QtyButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _QtyButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.roundedPill,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Icon(
          icon,
          size: 16,
          color: onTap == null ? Colors.grey.shade400 : null,
        ),
      ),
    );
  }
}

class _CheckoutBar extends StatelessWidget {
  final Cart cart;
  final bool isDark;

  const _CheckoutBar({required this.cart, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            MediaQuery.of(context).padding.bottom + AppSpacing.md,
          ),
          decoration: BoxDecoration(
            color: (isDark ? Colors.white : Colors.black).withOpacity(0.06),
            border: Border(
              top: BorderSide(
                color: (isDark ? Colors.white : Colors.black).withOpacity(0.1),
              ),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Subtotal (${cart.items.length} item${cart.items.length == 1 ? '' : 's'})',
                    style: theme.textTheme.titleSmall?.copyWith(color: Colors.grey),
                  ),
                  Text(
                    '\$${cart.totalAmount.toStringAsFixed(2)}',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF10B981),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const CheckoutScreen()),
                    );
                  },
                  icon: const Icon(Icons.shopping_bag_rounded, size: 20),
                  label: const Text(
                    'Proceed to Checkout',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                  ),
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: AppRadius.roundedPill),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
