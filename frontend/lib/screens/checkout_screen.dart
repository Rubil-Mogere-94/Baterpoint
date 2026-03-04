import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/listing.dart';
import '../models/cart.dart';
import '../services/cart_service.dart';
import '../services/auth_service.dart';
import '../services/environment_config.dart';

class CheckoutScreen extends StatefulWidget {
  final Listing? listing;

  const CheckoutScreen({super.key, this.listing});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final OrderService _orderService = OrderService();
  final CartService _cartService = CartService();
  Cart? _cart;
  int _currentStep = 0;
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
    if (widget.listing == null) {
      _loadCart();
    }
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
    
    try {
      // In a real Amazon-like app, we'd send the actual shipping address from a form
      await _orderService.createOrder(
        "123 Baterpoint Ave, Metropolis, NY 10001",
        couponCode: _appliedCouponCode,
      );
      
      if (!mounted) return;
      setState(() => _isProcessing = false);

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.green, size: 80),
              const SizedBox(height: 24),
              Text('Order Placed!', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('Your order has been placed successfully.', textAlign: TextAlign.center),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  ),
                  child: const Text('Back to Home', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
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
    final subtotal = widget.listing != null ? (widget.listing!.cashPrice ?? 0.0) : (_cart?.totalAmount ?? 0.0);
    final discountAmount = subtotal * (_discountPercentage / 100.0);
    final priceAfterDiscount = subtotal - discountAmount;
    final shippingFee = priceAfterDiscount > 0 ? 15.00 : 0.0;
    final total = priceAfterDiscount + shippingFee;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
        centerTitle: true,
      ),
      body: Stepper(
        type: StepperType.horizontal,
        currentStep: _currentStep,
        onStepTapped: (index) {
          if (index < _currentStep) {
            setState(() => _currentStep = index);
          }
        },
        onStepContinue: () {
          if (_currentStep < 2) {
            setState(() => _currentStep += 1);
          } else {
            _processPayment();
          }
        },
        onStepCancel: () {
          if (_currentStep > 0) {
            setState(() => _currentStep -= 1);
          } else {
            Navigator.pop(context);
          }
        },
        controlsBuilder: (context, details) {
          final isLastStep = _currentStep == 2;
          return Padding(
            padding: const EdgeInsets.only(top: 24.0),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isProcessing ? null : details.onStepContinue,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isProcessing 
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text(isLastStep ? 'Place Your Order' : 'Continue', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                if (_currentStep > 0 && !_isProcessing) ...[
                  const SizedBox(width: 16),
                  TextButton(
                    onPressed: details.onStepCancel,
                    child: const Text('Back'),
                  ),
                ]
              ],
            ),
          );
        },
        steps: [
          Step(
            title: const Text('Delivery'),
            state: _currentStep > 0 ? StepState.complete : StepState.indexed,
            isActive: _currentStep >= 0,
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Shipping Address', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: theme.colorScheme.primary, width: 2),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.location_on_rounded, color: theme.colorScheme.primary),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Home', style: TextStyle(fontWeight: FontWeight.bold)),
                              SizedBox(height: 4),
                              Text('123 Baterpoint Ave, Suite 400\nMetropolis, NY 10001\nUnited States', style: TextStyle(color: Colors.grey, height: 1.5)),
                            ],
                          ),
                        ),
                        Icon(Icons.check_circle_rounded, color: theme.colorScheme.primary),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Step(
            title: const Text('Payment'),
            state: _currentStep > 1 ? StepState.complete : StepState.indexed,
            isActive: _currentStep >= 1,
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Select Payment Method', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                _buildPaymentOption('Credit Card', 'credit_card', Icons.credit_card_rounded, '**** **** **** 1234'),
                const SizedBox(height: 12),
                _buildPaymentOption('PayPal', 'paypal', Icons.paypal_rounded, 'user@example.com'),
                const SizedBox(height: 12),
                _buildPaymentOption('Apple Pay', 'apple_pay', Icons.apple_rounded, 'Device Account'),
              ],
            ),
          ),
          Step(
            title: const Text('Confirm'),
            isActive: _currentStep >= 2,
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Divider(),
                ),
                Text('Promo Code', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _couponController,
                        decoration: InputDecoration(
                          hintText: 'Enter code',
                          errorText: _couponError,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
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
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                      ),
                      child: _isApplyingCoupon
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Apply'),
                    ),
                  ],
                ),
                if (_appliedCouponCode != null)
                   Padding(
                     padding: const EdgeInsets.only(top: 8.0),
                     child: Text('Coupon $_appliedCouponCode applied! (${_discountPercentage.toStringAsFixed(0)}% off)', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                   ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Divider(),
                ),
                _buildSummaryRow('Subtotal', '\$${subtotal.toStringAsFixed(2)}'),
                if (discountAmount > 0) ...[
                  const SizedBox(height: 12),
                  _buildSummaryRow('Discount (${_discountPercentage.toStringAsFixed(0)}%)', '-\$${discountAmount.toStringAsFixed(2)}', color: Colors.green),
                ],
                const SizedBox(height: 12),
                _buildSummaryRow('Shipping Fee', '\$${shippingFee.toStringAsFixed(2)}'),
                const SizedBox(height: 12),
                _buildSummaryRow('Tax', '\$0.00'),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Divider(),
                ),
                _buildSummaryRow('Total', '\$${total.toStringAsFixed(2)}', isTotal: true, color: theme.colorScheme.primary),
              ],
            ),
          ),
        ],
      ),
    );
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
