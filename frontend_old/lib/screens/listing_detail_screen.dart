import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_vibrate/flutter_vibrate.dart';
import 'package:baterpoint/utils/app_haptics.dart';
import 'package:page_transition/page_transition.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:ui';
import '../widgets/modern_button.dart';
import '../widgets/holographic_background.dart';
import '../models/listing.dart';
import '../providers/auth_provider.dart';
import '../services/listing_service.dart';
import '../services/cart_service.dart';
import '../constants/ui_constants.dart';
import '../constants/theme.dart';
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
            content: Text('Failed to refresh: $e'),
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
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          const HolographicBackground(),
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverAppBar(
                expandedHeight: 450.0,
                pinned: true,
                stretch: true,
                backgroundColor: Colors.transparent,
                elevation: 0,
                leading: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  stretchModes: const [StretchMode.zoomBackground],
                  background: Hero(
                    tag: 'listing_image_${_currentListing.id}',
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        _currentListing.imageUrl != null
                            ? CachedNetworkImage(
                                imageUrl: _currentListing.imageUrl!,
                                fit: BoxFit.cover,
                              )
                            : Container(color: colorScheme.surface),
                        // Soft overlay for top legibility
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withOpacity(0.4),
                                Colors.transparent,
                                Colors.transparent,
                                Colors.black.withOpacity(0.4),
                              ],
                              stops: const [0.0, 0.2, 0.7, 1.0],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                actions: [
                  if (isOwner) ...[
                    _buildAppBarAction(Icons.edit, () async {
                      final result = await Navigator.push(
                        context,
                        PageTransition(
                          type: PageTransitionType.fade,
                          child: EditListingScreen(listing: _currentListing),
                        ),
                      );
                      if (result == true) _refreshListing();
                    }),
                    _buildAppBarAction(Icons.delete, () => _showDeleteDialog(context), isDestructive: true),
                  ] else ...[
                    _buildAppBarAction(Icons.favorite_border, () {}),
                    _buildAppBarAction(Icons.share, () {}),
                  ],
                  const SizedBox(width: 8),
                ],
              ),
              SliverToBoxAdapter(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 32, 24, 140),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header info
                        _buildCategoryBadge(colorScheme),
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
                                  height: 1.1,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ),
                            if (_currentListing.cashPrice != null && _currentListing.cashPrice! > 0)
                              _buildPriceTag(colorScheme, textTheme),
                          ],
                        ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.1),

                        const SizedBox(height: 16),
                        _buildTierPrices(colorScheme),

                        const SizedBox(height: 24),
                        _buildProductAttributes(colorScheme, textTheme),

                        const SizedBox(height: 24),
                        _buildEcoCard(),
                        
                        const SizedBox(height: 32),
                        _buildSectionTitle('Seller'),
                        const SizedBox(height: 16),
                        _buildSellerCard(colorScheme, textTheme),

                        if (_currentListing.exchangeItem != null && _currentListing.exchangeItem!.isNotEmpty) ...[
                          const SizedBox(height: 32),
                          _buildSectionTitle('Wants to Trade For'),
                          const SizedBox(height: 12),
                          _buildExchangeCard(colorScheme, textTheme),
                        ],

                        const SizedBox(height: 32),
                        _buildSectionTitle('Details'),
                        const SizedBox(height: 12),
                        Text(
                          _currentListing.description ?? 'No description provided.',
                          style: textTheme.bodyLarge?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            height: 1.6,
                          ),
                        ),

                        const SizedBox(height: 32),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildSectionTitle('Reviews'),
                            if (_currentListing.reviews.isNotEmpty)
                              _buildRatingChip(colorScheme),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (_currentListing.reviews.isEmpty)
                          Text('No reviews yet.', style: TextStyle(color: colorScheme.onSurfaceVariant))
                        else
                          ..._currentListing.reviews.map((r) => _buildReviewItem(r, colorScheme, textTheme)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          // Premium Glass Bottom Bar
          if (!isOwner)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildBottomBar(context, colorScheme),
            ),
        ],
      ),
    );
  }

  Widget _buildAppBarAction(IconData icon, VoidCallback onTap, {bool isDestructive = false}) {
    return Container(
      margin: const EdgeInsets.only(right: 8, top: 8, bottom: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(icon, color: isDestructive ? Colors.redAccent : Colors.white, size: 20),
        onPressed: () {
          AppHaptics.feedback(FeedbackType.light);
          onTap();
        },
      ),
    );
  }

  Widget _buildCategoryBadge(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: colorScheme.primary.withOpacity(0.2)),
      ),
      child: Text(
        _currentListing.category.toUpperCase(),
        style: TextStyle(
          color: colorScheme.primary,
          fontWeight: FontWeight.w900,
          fontSize: 10,
          letterSpacing: 1.2,
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.8, 0.8));
  }

  Widget _buildPriceTag(ColorScheme colorScheme, TextTheme textTheme) {
    return Container(
      margin: const EdgeInsets.only(left: 16),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colorScheme.primary, colorScheme.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: colorScheme.primary.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 5)),
        ],
      ),
      child: Text(
        '\$${_currentListing.cashPrice}',
        style: textTheme.titleLarge?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _buildEcoCard() {
    return ClipRRect(
      borderRadius: AppRadius.roundedXL,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF10B981).withOpacity(0.1),
            borderRadius: AppRadius.roundedXL,
            border: Border.all(color: const Color(0xFF10B981).withOpacity(0.2)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(color: Color(0xFF10B981), shape: BoxShape.circle),
                child: const Icon(Icons.eco_rounded, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Eco Impact', style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF10B981))),
                    SizedBox(height: 2),
                    Text(
                      'This trade saves ~12kg of CO2 emissions.',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1);
  }

  Widget _buildSellerCard(ColorScheme colorScheme, TextTheme textTheme) {
    return ClipRRect(
      borderRadius: AppRadius.roundedXL,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.surface.withOpacity(0.4),
            borderRadius: AppRadius.roundedXL,
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: colorScheme.primaryContainer,
                backgroundImage: _currentListing.ownerAvatar != null ? CachedNetworkImageProvider(_currentListing.ownerAvatar!) : null,
                child: _currentListing.ownerAvatar == null ? Text((_currentListing.ownerUsername ?? 'U')[0].toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold)) : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(_currentListing.ownerUsername ?? 'Trader', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
                        const SizedBox(width: 4),
                        Icon(Icons.verified_rounded, color: Colors.blue.shade400, size: 16),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                        const SizedBox(width: 4),
                        Text('${_currentListing.ownerRating} ', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
                        Text('(${_currentListing.ownerReviews} reviews)', style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: colorScheme.primary.withOpacity(0.1), shape: BoxShape.circle),
                  child: Icon(Icons.chat_bubble_outline_rounded, color: colorScheme.primary, size: 20),
                ),
                onPressed: () {
                  AppHaptics.feedback(FeedbackType.light);
                  Navigator.push(context, PageTransition(type: PageTransitionType.fade, child: ChatScreen(tradeId: _currentListing.id, recipientId: _currentListing.userId, recipientName: _currentListing.ownerUsername, recipientAvatar: _currentListing.ownerAvatar)));
                },
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1);
  }

  Widget _buildExchangeCard(ColorScheme colorScheme, TextTheme textTheme) {
    return ClipRRect(
      borderRadius: AppRadius.roundedXL,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [colorScheme.secondary.withOpacity(0.1), colorScheme.surface.withOpacity(0.05)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: AppRadius.roundedXL,
            border: Border.all(color: colorScheme.secondary.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              Icon(Icons.swap_horiz_rounded, color: colorScheme.secondary, size: 28),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  _currentListing.exchangeItem!,
                  style: textTheme.titleMedium?.copyWith(color: colorScheme.secondary, fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTierPrices(ColorScheme colorScheme) {
    if (_currentListing.cashPrice == null || _currentListing.cashPrice! <= 0) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildTierText('Buy 2+', '\$${(_currentListing.cashPrice! * 0.95).toStringAsFixed(2)}/ea', colorScheme),
          Container(width: 1, height: 30, color: colorScheme.outlineVariant),
          _buildTierText('Buy 5+', '\$${(_currentListing.cashPrice! * 0.90).toStringAsFixed(2)}/ea', colorScheme),
          Container(width: 1, height: 30, color: colorScheme.outlineVariant),
          _buildTierText('Buy 10+', '\$${(_currentListing.cashPrice! * 0.85).toStringAsFixed(2)}/ea', colorScheme),
        ],
      ),
    ).animate().fadeIn(delay: 100.ms);
  }

  Widget _buildTierText(String qty, String price, ColorScheme colorScheme) {
    return Column(
      children: [
        Text(qty, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
        Text(price, style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.w900)),
      ],
    );
  }

  Widget _buildProductAttributes(ColorScheme colorScheme, TextTheme textTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Specifications & Variants', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900, letterSpacing: -0.5)),
        const SizedBox(height: 16),
        // Size Dropdown
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colorScheme.outline.withOpacity(0.5)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: 'Large [+ \$5.00]',
              icon: const Icon(Icons.keyboard_arrow_down_rounded),
              items: ['Small', 'Medium', 'Large [+ \$5.00]', 'X-Large [+ \$10.00]']
                  .map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontWeight: FontWeight.w600))))
                  .toList(),
              onChanged: (_) {},
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Color Radio choices
        Text('Color', style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildColorOption(Colors.black, true, colorScheme),
            const SizedBox(width: 12),
            _buildColorOption(Colors.red.shade700, false, colorScheme),
            const SizedBox(width: 12),
            _buildColorOption(Colors.blue.shade800, false, colorScheme),
          ],
        ),
      ],
    ).animate().fadeIn(delay: 150.ms);
  }

  Widget _buildColorOption(Color color, bool isSelected, ColorScheme colorScheme) {
    return Container(
      width: 40, height: 40,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: isSelected ? colorScheme.primary : Colors.transparent, width: 3),
        boxShadow: [
          if (isSelected) BoxShadow(color: colorScheme.primary.withOpacity(0.4), blurRadius: 8, spreadRadius: 2),
        ]
      ),
      child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 20) : null,
    );
  }

  Widget _buildReviewItem(Review review, ColorScheme colorScheme, TextTheme textTheme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface.withOpacity(0.4),
        borderRadius: AppRadius.roundedXL,
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(review.username ?? 'Anonymous', style: const TextStyle(fontWeight: FontWeight.w900)),
              Row(children: List.generate(5, (i) => Icon(i < review.rating ? Icons.star_rounded : Icons.star_border_rounded, size: 14, color: i < review.rating ? Colors.amber : colorScheme.outline))),
            ],
          ),
          if (review.comment != null) ...[
            const SizedBox(height: 10),
            Text(review.comment!, style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant, height: 1.5)),
          ],
        ],
      ),
    );
  }

  Widget _buildRatingChip(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: Colors.amber.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
          const SizedBox(width: 4),
          Text(_currentListing.averageRating.toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: -0.5));
  }

  Widget _buildBottomBar(BuildContext context, ColorScheme colorScheme) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: EdgeInsets.fromLTRB(24, 20, 24, MediaQuery.of(context).padding.bottom + 20),
          decoration: BoxDecoration(
            color: colorScheme.surface.withOpacity(0.7),
            border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1))),
          ),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 56,
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(icon: const Icon(Icons.remove), onPressed: () {}),
                      const Text('1', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                      IconButton(icon: const Icon(Icons.add, color: Colors.green), onPressed: () {}),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: ModernButton(
                  text: 'Add to Cart',
                  onPressed: () => _addToCart(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _addToCart(BuildContext context) async {
    try {
      AppHaptics.feedback(FeedbackType.medium);
      await _cartService.addToCart(_currentListing.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Added to Cart!'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Theme.of(context).colorScheme.primary,
            shape: RoundedRectangleBorder(borderRadius: AppRadius.roundedMD),
            action: SnackBarAction(label: 'View', textColor: Colors.white, onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => CartScreen()))),
          ),
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete?'),
        content: const Text('Once deleted, this treasure is gone forever.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Keep')),
          TextButton(
            onPressed: () async {
              await _listingService.deleteListing(_currentListing.id);
              if (context.mounted) {
                Navigator.pop(context);
                Navigator.pop(context, true);
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }
}
