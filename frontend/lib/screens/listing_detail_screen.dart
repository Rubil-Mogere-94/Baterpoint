import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:ui';
import '../models/listing.dart';
import '../providers/auth_provider.dart';
import '../services/listing_service.dart';
import '../services/offer_service.dart';
import '../services/cart_service.dart';
import '../constants/ui_constants.dart';
import 'chat_screen.dart';
import 'edit_listing_screen.dart';
import 'checkout_screen.dart';
import 'cart_screen.dart';

class ListingDetailScreen extends StatefulWidget {
  final Listing listing;

  const ListingDetailScreen({super.key, required this.listing});

  @override
  State<ListingDetailScreen> createState() => _ListingDetailScreenState();
}

class _ListingDetailScreenState extends State<ListingDetailScreen> {
  late Listing _currentListing;
  bool _isLoading = false;
  final ListingService _listingService = ListingService();
  final OfferService _offerService = OfferService();
  final CartService _cartService = CartService();

  @override
  void initState() {
    super.initState();
    _currentListing = widget.listing;
  }

  Future<void> _refreshListing() async {
    setState(() => _isLoading = true);
    try {
      final updated = await _listingService.fetchListingById(_currentListing.id);
      setState(() {
        _currentListing = updated;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to refresh listing: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isOwner = authProvider.user?.id == _currentListing.userId;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Stack(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _isLoading 
              ? Center(
                  key: const ValueKey('loading'), 
                  child: CircularProgressIndicator(color: colorScheme.primary),
                )
              : CustomScrollView(
                  key: const ValueKey('content'),
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    SliverAppBar(
                      expandedHeight: 400.0,
                      pinned: true,
                      stretch: true,
                      backgroundColor: colorScheme.surface,
                      iconTheme: IconThemeData(color: Colors.white),
                      actionsIconTheme: IconThemeData(color: Colors.white),
                      leading: Container(
                        margin: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.3),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () => Navigator.pop(context, true),
                        ),
                      ),
                      flexibleSpace: FlexibleSpaceBar(
                        background: Hero(
                          tag: 'listing_image_${_currentListing.id}',
                          child: _currentListing.imageUrl != null
                              ? CachedNetworkImage(
                                  imageUrl: _currentListing.imageUrl!,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Container(
                                    color: colorScheme.surfaceContainerHighest,
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: colorScheme.primary,
                                      ),
                                    ),
                                  ),
                                  errorWidget: (context, url, error) => Container(
                                    color: colorScheme.surfaceContainerHighest,
                                    child: Icon(Icons.broken_image, size: 64, color: colorScheme.onSurfaceVariant),
                                  ),
                                )
                              : Container(
                                  color: colorScheme.surfaceContainerHighest,
                                  child: Icon(Icons.image_not_supported, size: 64, color: colorScheme.onSurfaceVariant),
                                ),
                        ),
                      ),
                      actions: [
                        if (isOwner) ...[
                          Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: CircleAvatar(
                              backgroundColor: Colors.black.withOpacity(0.3),
                              child: IconButton(
                                icon: const Icon(Icons.edit, color: Colors.white),
                                onPressed: () async {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => EditListingScreen(listing: _currentListing),
                                    ),
                                  );
                                  if (result == true) {
                                    _refreshListing();
                                  }
                                },
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: CircleAvatar(
                              backgroundColor: Colors.black.withOpacity(0.3),
                              child: IconButton(
                                icon: const Icon(Icons.delete, color: Colors.redAccent),
                                onPressed: () => _showDeleteDialog(context, _listingService),
                              ),
                            ),
                          ),
                        ] else ...[
                          Container(
                            margin: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.3),
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.favorite_border, color: Colors.white),
                              onPressed: () {},
                            ),
                          ),
                          Container(
                            margin: const EdgeInsets.only(right: 8, top: 8, bottom: 8),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.3),
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.share, color: Colors.white),
                              onPressed: () {},
                            ),
                          ),
                          Container(
                            margin: const EdgeInsets.only(right: 8, top: 8, bottom: 8),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.3),
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.shopping_cart, color: Colors.white),
                              onPressed: () {
                                Navigator.push(context, MaterialPageRoute(builder: (context) => CartScreen()));
                              },
                            ),
                          ),
                        ],
                      ],
                    ),
                    SliverToBoxAdapter(
                      child: Container(
                        decoration: BoxDecoration(
                          color: colorScheme.surface,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                        ),
                        transform: Matrix4.translationValues(0, -24, 0),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(24, 32, 24, 120),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Category Chip
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: colorScheme.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  _currentListing.category.toUpperCase(),
                                  style: TextStyle(
                                    color: colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),

                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Text(
                                      _currentListing.title,
                                      style: textTheme.headlineMedium?.copyWith(
                                        fontWeight: FontWeight.w900,
                                        color: colorScheme.onSurface,
                                        height: 1.2,
                                      ),
                                    ),
                                  ),
                                  if (_currentListing.cashPrice != null && _currentListing.cashPrice! > 0)
                                    Container(
                                      margin: const EdgeInsets.only(left: 16),
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: colorScheme.primaryContainer,
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Text(
                                        '\$${_currentListing.cashPrice}',
                                        style: textTheme.titleLarge?.copyWith(
                                          color: colorScheme.onPrimaryContainer,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 24),

                              // Sustainability Score Card
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [const Color(0xFF10B981).withOpacity(0.1), const Color(0xFF34D399).withOpacity(0.05)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: const Color(0xFF10B981).withOpacity(0.2)),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: const BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.eco_rounded, color: Color(0xFF10B981), size: 24),
                                    ),
                                    const SizedBox(width: 16),
                                    const Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Eco-Impact',
                                            style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF065F46)),
                                          ),
                                          Text(
                                            'Trading this item saves ~12kg of CO2 vs buying new.',
                                            style: TextStyle(fontSize: 12, color: Color(0xFF064E3B)),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 32),
                              
                              // Seller Info Block
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.5)),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(color: colorScheme.primary.withOpacity(0.5)),
                                      ),
                                      child: CircleAvatar(
                                        radius: 24,
                                        backgroundColor: colorScheme.surfaceContainerHighest,
                                        backgroundImage: _currentListing.ownerAvatar != null
                                            ? CachedNetworkImageProvider(_currentListing.ownerAvatar!)
                                            : null,
                                        child: _currentListing.ownerAvatar == null
                                            ? Text(
                                                (_currentListing.ownerUsername ?? 'U').substring(0, 1).toUpperCase(),
                                                style: TextStyle(
                                                  color: colorScheme.primary,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 18,
                                                ),
                                              )
                                            : null,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Text(
                                                _currentListing.ownerUsername ?? 'User',
                                                style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                              ),
                                              const SizedBox(width: 4),
                                              Icon(Icons.verified_rounded, color: Colors.blue.shade400, size: 16),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Icon(Icons.star_rounded, color: Colors.amber.shade500, size: 16),
                                              const SizedBox(width: 4),
                                              Text(
                                                '${_currentListing.ownerRating} ',
                                                style: textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
                                              ),
                                              Text(
                                                '(${_currentListing.ownerReviews} reviews)',
                                                style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.chat_bubble_outline_rounded, color: colorScheme.primary),
                                      style: IconButton.styleFrom(
                                        backgroundColor: colorScheme.surface,
                                      ),
                                      onPressed: () {
                                         Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => ChatScreen(
                                              tradeId: _currentListing.id,
                                              recipientId: _currentListing.userId,
                                              recipientName: _currentListing.ownerUsername,
                                              recipientAvatar: _currentListing.ownerAvatar,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              
                              const SizedBox(height: 32),
                              if (_currentListing.exchangeItem != null && _currentListing.exchangeItem!.isNotEmpty) ...[
                                Text(
                                  'Looking For',
                                  style: textTheme.titleMedium?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        colorScheme.secondaryContainer.withOpacity(0.5),
                                        colorScheme.surface,
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: colorScheme.secondary.withOpacity(0.2)),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: colorScheme.secondary.withOpacity(0.1),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(Icons.swap_horiz_rounded, color: colorScheme.secondary),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Text(
                                          _currentListing.exchangeItem!,
                                          style: textTheme.titleMedium?.copyWith(
                                            color: colorScheme.secondary,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 32),
                              ],
                              Text(
                                'Description',
                                style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _currentListing.description ?? 'No description provided.',
                                style: textTheme.bodyLarge?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                  height: 1.6,
                                ),
                              ),

                              const SizedBox(height: 32),
                              // Amazon-like Reviews Section
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Customer Reviews',
                                    style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  if (_currentListing.reviews.isNotEmpty)
                                    Row(
                                      children: [
                                        Icon(Icons.star, color: Colors.amber, size: 20),
                                        const SizedBox(width: 4),
                                        Text(
                                          _currentListing.averageRating.toStringAsFixed(1),
                                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              if (_currentListing.reviews.isEmpty)
                                Text('No reviews yet. Be the first!', style: TextStyle(color: colorScheme.onSurfaceVariant))
                              else
                                ..._currentListing.reviews.map((review) => _buildReviewItem(review)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
          ),

          // Improved Bottom Bar - Amazon Style
          if (!isOwner)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _addToCart(context),
                        child: Text('Add to Cart', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(color: Colors.grey[300]!),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                           Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => CheckoutScreen()),
                          );
                        },
                        child: Text('Buy Now', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFFFF9900), // Amazon Orange
                          padding: EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            HapticFeedback.mediumImpact();
                            _showMakeOfferModal(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorScheme.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 0,
                          ),
                          child: const Text('Make Offer', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildChip(BuildContext context, {required String label, required Color color, required IconData icon, bool isOutline = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isOutline ? Colors.transparent : color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isOutline ? color.withOpacity(0.5) : Colors.transparent,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  void _showMakeOfferModal(BuildContext context) {
    // ... existing modal code, updated to use theme ...
    final priceController = TextEditingController();
    final itemController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          final theme = Theme.of(context);
          final colorScheme = theme.colorScheme;
          
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 24,
              right: 24,
              top: 32,
            ),
            child: Form(
              key: formKey,
              child: Builder(builder: (context) {
                final tType = _currentListing.tradeType?.toLowerCase() ?? '';
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Make an Offer', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                        IconButton(
                          icon: const Icon(Icons.close), 
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('Propose a price or an item to trade for this listing.', style: TextStyle(color: colorScheme.onSurfaceVariant)),
                    const SizedBox(height: 32),
                    if (tType.contains('sale') || tType.contains('cash') || tType == 'both') ...[
                      TextFormField(
                        controller: priceController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        style: TextStyle(color: colorScheme.onSurface),
                        decoration: InputDecoration(
                          labelText: 'Offer Price (\$)',
                          prefixIcon: Icon(Icons.attach_money, color: colorScheme.primary),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                          filled: true,
                          fillColor: colorScheme.surfaceContainerHighest.withOpacity(0.3),
                        ),
                        validator: (value) {
                          if ((tType.contains('sale') || tType.contains('cash')) && (value == null || value.isEmpty)) {
                            return 'Please enter a price';
                          }
                          if (value != null && value.isNotEmpty && double.tryParse(value) == null) {
                            return 'Please enter a valid number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                    ],
                    // ... Bundle selection items would go here, styling updated similarly ...
                    if (tType.contains('trade') || tType.contains('barter') || tType == 'both') ...[
                       TextFormField(
                        controller: itemController,
                        maxLines: 2,
                        style: TextStyle(color: colorScheme.onSurface),
                        decoration: InputDecoration(
                          labelText: 'Trading Bundle Items',
                          hintText: 'Describe items you want to trade...',
                          prefixIcon: Icon(Icons.inventory_2_outlined, color: colorScheme.primary),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                          filled: true,
                          fillColor: colorScheme.surfaceContainerHighest.withOpacity(0.3),
                        ),
                        validator: (value) {
                          if ((tType.contains('trade') || tType.contains('barter')) && (value == null || value.isEmpty)) {
                            return 'Please describe your offer';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 32),
                    ],
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isSubmitting ? null : () async {
                          if (formKey.currentState!.validate()) {
                            if (tType == 'both' && priceController.text.isEmpty && itemController.text.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please offer a price or an item.')));
                              return;
                            }
                            setModalState(() => isSubmitting = true);
                            try {
                              await _offerService.makeOffer(
                                _currentListing.id,
                                offeredPrice: priceController.text.isNotEmpty ? double.parse(priceController.text) : null,
                                offeredItem: itemController.text.isNotEmpty ? itemController.text : null,
                              );
                              if (context.mounted) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text('Offer sent successfully!'),
                                    backgroundColor: colorScheme.primary,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                              }
                            } finally {
                              if (mounted) setModalState(() => isSubmitting = false);
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: colorScheme.primary,
                          foregroundColor: colorScheme.onPrimary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                        child: isSubmitting 
                          ? SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2, color: colorScheme.onPrimary))
                          : const Text('Submit Offer', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                );
              }),
            ),
          );
        },
      ),
    );
  }

  Widget _buildReviewItem(Review review) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(radius: 12, child: Text(review.username?[0] ?? 'U')),
              const SizedBox(width: 8),
              Text(review.username ?? 'Anonymous', style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: List.generate(5, (index) => Icon(
              Icons.star,
              size: 14,
              color: index < review.rating ? Colors.amber : Colors.grey[300],
            )),
          ),
          if (review.comment != null) ...[
            const SizedBox(height: 4),
            Text(review.comment!),
          ],
          const Divider(),
        ],
      ),
    );
  }

  Future<void> _addToCart(BuildContext context) async {
    try {
      await _cartService.addToCart(_currentListing.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Added to Cart!'),
            action: SnackBarAction(
              label: 'View Cart',
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => CartScreen())),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error adding to cart: $e')));
      }
    }
  }

  void _showDeleteDialog(BuildContext context, ListingService listingService) {
    final colorScheme = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colorScheme.surface,
        title: Text('Delete Listing', style: TextStyle(color: colorScheme.onSurface)),
        content: Text('Are you sure you want to delete this listing? This action cannot be undone.', style: TextStyle(color: colorScheme.onSurfaceVariant)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: colorScheme.primary)),
          ),
          TextButton(
            onPressed: () async {
              try {
                await listingService.deleteListing(_currentListing.id);
                if (context.mounted) {
                  Navigator.pop(context);
                  Navigator.pop(context, true);
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error deleting listing: $e')),
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: colorScheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
