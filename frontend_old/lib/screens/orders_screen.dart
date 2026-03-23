import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:ui';
import '../models/order.dart' as model;
import '../services/cart_service.dart';
import 'package:intl/intl.dart';
import '../constants/theme.dart';
import '../widgets/holographic_background.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  final OrderService _orderService = OrderService();
  List<model.Order> _orders = [];
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    try {
      final orders = await _orderService.fetchMyOrders();
      if (mounted) {
        setState(() {
          _orders = orders;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'delivered': return const Color(0xFF10B981);
      case 'shipped': return const Color(0xFF4F46E5);
      case 'processing': return Colors.orange;
      case 'cancelled': return Colors.redAccent;
      default: return Colors.orange;
    }
  }

  IconData _statusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'delivered': return Icons.check_circle_rounded;
      case 'shipped': return Icons.local_shipping_rounded;
      case 'processing': return Icons.autorenew_rounded;
      case 'cancelled': return Icons.cancel_rounded;
      default: return Icons.schedule_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Your Orders', style: TextStyle(fontWeight: FontWeight.w900)),
        centerTitle: true,
      ),
      body: HolographicBackground(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _hasError
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      child: ClipRRect(
                        borderRadius: AppRadius.roundedXXL,
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                          child: Container(
                            padding: const EdgeInsets.all(AppSpacing.xl),
                            decoration: BoxDecoration(
                              color: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
                              borderRadius: AppRadius.roundedXXL,
                              border: Border.all(color: Colors.redAccent.withOpacity(0.2)),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.error_outline_rounded,
                                    size: 52, color: Colors.redAccent),
                                const SizedBox(height: AppSpacing.md),
                                const Text('Failed to load orders',
                                    style: TextStyle(fontWeight: FontWeight.w700)),
                                const SizedBox(height: AppSpacing.md),
                                ElevatedButton.icon(
                                  onPressed: _loadOrders,
                                  icon: const Icon(Icons.refresh_rounded),
                                  label: const Text('Retry'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  )
                : _orders.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.xl),
                          child: ClipRRect(
                            borderRadius: AppRadius.roundedXXL,
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                              child: Container(
                                padding: const EdgeInsets.all(AppSpacing.xl),
                                decoration: BoxDecoration(
                                  color: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
                                  borderRadius: AppRadius.roundedXXL,
                                  border: Border.all(
                                    color: (isDark ? Colors.white : Colors.black).withOpacity(0.08),
                                  ),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.receipt_long_outlined,
                                            size: 72, color: Colors.grey.shade400)
                                        .animate()
                                        .scale(curve: Curves.easeOutBack, duration: 600.ms),
                                    const SizedBox(height: AppSpacing.md),
                                    Text(
                                      'No orders yet',
                                      style: theme.textTheme.titleLarge
                                          ?.copyWith(fontWeight: FontWeight.w800),
                                    ).animate().fadeIn(delay: 200.ms),
                                    const SizedBox(height: AppSpacing.sm),
                                    Text(
                                      "You haven't placed any orders. Start exploring!",
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(color: Colors.grey),
                                      textAlign: TextAlign.center,
                                    ).animate().fadeIn(delay: 300.ms),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadOrders,
                        child: ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(
                              AppSpacing.lg, 110, AppSpacing.lg, AppSpacing.xl),
                          itemCount: _orders.length,
                          itemBuilder: (context, index) {
                            return _buildOrderCard(context, _orders[index], index, isDark);
                          },
                        ),
                      ),
      ),
    );
  }

  Widget _buildOrderCard(
      BuildContext context, model.Order order, int index, bool isDark) {
    final theme = Theme.of(context);
    final dateStr = DateFormat('MMM dd, yyyy').format(order.createdAt);
    final statusColor = _statusColor(order.status);
    final statusIcn = _statusIcon(order.status);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: ClipRRect(
        borderRadius: AppRadius.roundedXL,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            decoration: BoxDecoration(
              color: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
              borderRadius: AppRadius.roundedXL,
              border: Border.all(color: statusColor.withOpacity(0.2), width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Order header
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md, vertical: 12),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.07),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: Row(
                    children: [
                      Icon(statusIcn, color: statusColor, size: 16),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        order.status.toUpperCase(),
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        dateStr,
                        style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Text(
                        'Order #${order.id}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),

                // Order items
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ...order.items.map((item) => _buildOrderItem(context, item)),
                      Divider(
                        height: AppSpacing.xl,
                        color: (isDark ? Colors.white : Colors.black).withOpacity(0.07),
                      ),
                      // Total row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Order Total',
                            style: theme.textTheme.titleSmall?.copyWith(color: Colors.grey),
                          ),
                          Text(
                            '\$${order.totalAmount.toStringAsFixed(2)}',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFF10B981),
                            ),
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
          delay: Duration(milliseconds: 100 + (index * 80)),
          duration: 450.ms,
          curve: Curves.easeOutCubic,
        )
        .fadeIn(delay: Duration(milliseconds: 100 + (index * 80)));
  }

  Widget _buildOrderItem(BuildContext context, model.OrderItem item) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: AppRadius.roundedMD,
            child: Image.network(
              item.listing.imageUrl ?? 'https://via.placeholder.com/60',
              width: 60,
              height: 60,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Container(
                width: 60,
                height: 60,
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
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  'Qty: ${item.quantity}',
                  style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                ),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.secondary,
              side: BorderSide(color: Theme.of(context).colorScheme.secondary.withOpacity(0.5)),
              shape: RoundedRectangleBorder(borderRadius: AppRadius.roundedPill),
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 6),
              visualDensity: VisualDensity.compact,
            ),
            child: const Text('Buy Again', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}
