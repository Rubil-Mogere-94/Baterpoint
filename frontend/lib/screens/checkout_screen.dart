import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:confetti/confetti.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/listing.dart';
import '../models/cart.dart';
import '../services/cart_service.dart';
import '../services/auth_service.dart';
import '../services/environment_config.dart';
import '../constants/ui_constants.dart';
import '../widgets/holographic_background.dart';

class CheckoutScreen extends StatefulWidget {
  final Listing? listing;

  const CheckoutScreen({super.key, this.listing});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final OrderService _orderService = OrderService();
  final CartService _cartService = CartService();
  late ConfettiController _confettiController;
  Cart? _cart;
  String _selectedPaymentMethod = 'credit_card';
  bool _isProcessing = false;
  bool _isLoadingCart = false;
  
  final TextEditingController _couponController = TextEditingController();
  double _discountPercentage = 0.0;
  bool _isApplyingCoupon = false;
  String? _couponError;
  String? _appliedCouponCode;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    if (widget.listing == null) {
      _loadCart();
    }
  }
  
  @override
  void dispose() {
    _confettiController.dispose();
    _couponController.dispose();
    super.dispose();
  }

  Future<void> _loadCart() async {
    setState(() => _isLoadingCart = true);
    try {
      final cart = await _cartService.fetchMyCart();
      setState(() {
        _cart = cart;
        _isLoadingCart = false;
      });
    } catch (e) {
      setState(() => _isLoadingCart = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading cart: $e')));
      }
    }
  }

  Future<void> _applyCoupon() async {
    final code = _couponController.text.trim();
    if (code.isEmpty) return;

    setState(() {
      _isApplyingCoupon = true;
      _couponError = null;
    });

    try {
      final token = await AuthService().getToken();
      final response = await http.get(
        Uri.parse('${EnvironmentConfig.apiUrl}/coupons/validate/$code'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _discountPercentage = data['discount_percentage'].toDouble();
          _appliedCouponCode = code;
          _isApplyingCoupon = false;
        });
      } else {
        final error = jsonDecode(response.body);
        setState(() {
          _couponError = error['detail'] ?? 'Invalid coupon';
          _discountPercentage = 0.0;
          _appliedCouponCode = null;
          _isApplyingCoupon = false;
        });
      }
    } catch (e) {
      setState(() {
        _couponError = 'Network error';
        _isApplyingCoupon = false;
      });
    }
  }

  void _processPayment() async {
    setState(() => _isProcessing = true);
    HapticFeedback.heavyImpact();
    
    try {
      // In a real Amazon-like app, we'd send the actual shipping address from a form
      await _orderService.createOrder(
        "123 Baterpoint Ave, Metropolis, NY 10001",
        couponCode: _appliedCouponCode,
      );
      
      if (!mounted) return;
      
      // Fire confetti and play success haptics
      _confettiController.play();
      HapticFeedback.vibrate();
      
      setState(() => _isProcessing = false);

      showModalBottomSheet(
        context: context,
        isDismissible: false,
        enableDrag: false,
        backgroundColor: Colors.transparent,
        builder: (context) => Stack(
          alignment: Alignment.topCenter,
          children: [
            ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              emissionFrequency: 0.05,
              numberOfParticles: 50,
              maxBlastForce: 100,
              minBlastForce: 80,
              gravity: 0.3,
              colors: const [Colors.green, Colors.blue, Colors.pink, Colors.orange, Colors.purple],
            ),
            Container(
              margin: const EdgeInsets.only(top: 100),
              padding: const EdgeInsets.all(AppPadding.xl),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 30,
                    offset: const Offset(0, -10),
                  )
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check_circle_rounded, color: Colors.green, size: 80),
                  ),
                  const SizedBox(height: AppPadding.lg),
                  Text('Order Placed!', style: Theme.of(context).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w900, color: Colors.green)),
                  const SizedBox(height: AppPadding.sm),
                  Text(
                    'Your treasures are on the way. Plus, you just earned XP towards your next Bater-Pass tier!',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey),
                  ),
                  const SizedBox(height: AppPadding.xl),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).popUntil((route) => route.isFirst);
                      },
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: AppRadius.roundedLG),
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Back to Home', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                    ),
                  ),
                  const SizedBox(height: AppPadding.xl),
                ],
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Payment/Order error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingCart) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    
    final theme = Theme.of(context);
    
    double subtotal = 0.0;
    if (widget.listing != null) {
      subtotal = widget.listing!.cashPrice ?? 0.0;
    } else if (_cart != null) {
      subtotal = _cart!.items.fold(0.0, (sum, item) => sum + (item.listing.cashPrice ?? 0.0));
    }
    
    double discountAmount = subtotal * (_discountPercentage / 100);
    double shippingFee = subtotal > 0 ? 5.99 : 0.0; 
    double total = (subtotal - discountAmount) + shippingFee;

    return HolographicBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: const Text('Fast Checkout', style: TextStyle(fontWeight: FontWeight.w900)),
          centerTitle: true,
        ),
        body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(AppPadding.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(AppPadding.md),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: AppRadius.roundedLG,
                    border: Border.all(color: theme.dividerColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.local_shipping_rounded, color: theme.colorScheme.primary),
                          const SizedBox(width: 8),
                          Text('1-Click Delivery to Home', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('123 Baterpoint Ave, Suite 400\nMetropolis, NY 10001', style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey)),
                    ],
                  ),
                ),
                
                const SizedBox(height: AppPadding.xl),
                Text('Order Summary', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                if (widget.listing != null)
                  _buildListingRow(widget.listing!)
                else if (_cart != null)
                  ..._cart!.items.map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: _buildListingRow(item.listing),
                  )),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Divider(),
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _couponController,
                        decoration: InputDecoration(
                          hintText: 'Promo / Gift Code',
                          errorText: _couponError,
                          border: OutlineInputBorder(borderRadius: AppRadius.roundedMD),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          suffixIcon: _appliedCouponCode != null 
                              ? const Icon(Icons.check_circle, color: Colors.green)
                              : null,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _isApplyingCoupon || _appliedCouponCode != null ? null : _applyCoupon,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: AppRadius.roundedMD),
                        backgroundColor: theme.colorScheme.secondary,
                        foregroundColor: Colors.white,
                      ),
                      child: _isApplyingCoupon
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Apply', style: TextStyle(fontWeight: FontWeight.w900)),
                    ),
                  ],
                ),
                if (_appliedCouponCode != null)
                   Padding(
                     padding: const EdgeInsets.only(top: 8.0),
                     child: Text('Coupon $_appliedCouponCode applied! (${_discountPercentage.toStringAsFixed(0)}% off)', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                   ),
                
                const SizedBox(height: AppPadding.xxl),
                
                Container(
                  padding: const EdgeInsets.all(AppPadding.md),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.05),
                    borderRadius: AppRadius.roundedLG,
                  ),
                  child: Column(
                    children: [
                      _buildSummaryRow('Subtotal', '\$${subtotal.toStringAsFixed(2)}'),
                      if (discountAmount > 0) ...[
                        const SizedBox(height: 8),
                        _buildSummaryRow('Discount (${_discountPercentage.toStringAsFixed(0)}%)', '-\$${discountAmount.toStringAsFixed(2)}', color: Colors.green),
                      ],
                      const SizedBox(height: 8),
                      _buildSummaryRow('Shipping & Tax', '\$${shippingFee.toStringAsFixed(2)}', color: Colors.grey),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Divider(),
                      ),
                      _buildSummaryRow('Total', '\$${total.toStringAsFixed(2)}', isTotal: true, color: theme.colorScheme.primary),
                    ],
                  ),
                ),
                
                const SizedBox(height: 100), // padding for bottom button
              ],
            ),
          ),
          
          // Sticky Bottom Checkout Button
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              padding: const EdgeInsets.all(AppPadding.md),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10, offset: const Offset(0, -5),
                  )
                ]
              ),
              child: SafeArea(
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isProcessing ? null : _processPayment,
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: AppRadius.roundedLG),
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: _isProcessing 
                      ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.bolt, color: Colors.amber),
                            const SizedBox(width: 8),
                            Text('Swipe to Buy • \$${total.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                          ],
                        ),
                  ),
                ),
              ),
            ),
          )
        ],
      ),
    ));
  }

  Widget _buildListingRow(Listing listing) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 80,
          width: 80,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.grey.shade200,
            image: listing.imageUrl != null 
              ? DecorationImage(image: NetworkImage(listing.imageUrl!), fit: BoxFit.cover)
              : null,
          ),
          child: listing.imageUrl == null ? const Icon(Icons.image, color: Colors.grey) : null,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(listing.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 4),
              Text(listing.category, style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
              const SizedBox(height: 8),
              Text('\$${listing.cashPrice?.toStringAsFixed(2)}', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary, fontSize: 16)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentOption(String title, String value, IconData icon, String subtitle) {
    final theme = Theme.of(context);
    final isSelected = _selectedPaymentMethod == value;
    
    return InkWell(
      onTap: () => setState(() => _selectedPaymentMethod = value),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: isSelected ? theme.colorScheme.primary : theme.dividerColor, width: isSelected ? 2 : 1),
          borderRadius: BorderRadius.circular(12),
          color: isSelected ? theme.colorScheme.primary.withOpacity(0.05) : theme.cardColor,
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? theme.colorScheme.primary : Colors.grey.shade600, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? theme.colorScheme.primary : null)),
                  Text(subtitle, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle_rounded, color: theme.colorScheme.primary),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false, Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 18 : 16,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            color: isTotal ? null : Colors.grey.shade700,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isTotal ? 22 : 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
