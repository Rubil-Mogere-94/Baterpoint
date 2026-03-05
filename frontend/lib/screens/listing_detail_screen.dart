import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_vibrate/flutter_vibrate.dart';
import 'package:page_transition/page_transition.dart';
import 'dart:ui';
import '../widgets/modern_button.dart';
import '../models/listing.dart';
import '../providers/auth_provider.dart';
import '../services/listing_service.dart';

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
                      iconTheme: const IconThemeData(color: Colors.white),
                      actionsIconTheme: const IconThemeData(color: Colors.white),
                      leading: Container(
                        margin: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.3),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                          onPressed: () {
                            Vibrate.feedback(FeedbackType.light);
                            Navigator.pop(context, true);
                          },
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
                                    child: const Icon(Icons.broken_image, size: 64, color: Colors.grey),
                                  ),
                                )
                              : Container(
                                  color: colorScheme.surfaceContainerHighest,
                                  child: const Icon(Icons.image_not_supported, size: 64, color: Colors.grey),
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
                                  Vibrate.feedback(FeedbackType.light);
                                  final result = await Navigator.push(
                                    context,
                                    PageTransition(
                                      type: PageTransitionType.rightToLeftWithFade,
                                      child: EditListingScreen(listing: _currentListing),
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
                                onPressed: () {
                                  Vibrate.feedback(FeedbackType.medium);
                                  _showDeleteDialog(context, _listingService);
                                },
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
                                Vibrate.feedback(FeedbackType.light);
                                Navigator.push(
                                  context, 
                                  PageTransition(
                                    type: PageTransitionType.rightToLeftWithFade,
                                    child: const CartScreen(),
                                  ),
                                );
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
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.5)),
                                ),
                                child: Row(
                                  children: [
                                    CircleAvatar(
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
                                      onPressed: () {
                                         Vibrate.feedback(FeedbackType.light);
                                         Navigator.push(
                                          context,
                                          PageTransition(
                                            type: PageTransitionType.fade,
                                            child: ChatScreen(
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
                                      Icon(Icons.swap_horiz_rounded, color: colorScheme.secondary),
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
                                        const Icon(Icons.star, color: Colors.amber, size: 20),
                                        const SizedBox(width: 4),
                                        Text(
                                          _currentListing.averageRating.toStringAsFixed(1),
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                              if (!isOwner) ...[
                                const SizedBox(height: 12),
                                OutlinedButton.icon(
                                  onPressed: () => _showAddReviewDialog(context),
                                  icon: const Icon(Icons.rate_review_rounded),
                                  label: const Text('Write a Review'),
                                  style: OutlinedButton.styleFrom(
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                ),
                              ],
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
          if (!isOwner)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.fromLTRB(AppPadding.lg, 16, AppPadding.lg, MediaQuery.of(context).padding.bottom + 16),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  border: Border(top: BorderSide(color: colorScheme.outline.withOpacity(0.1))),
                  boxShadow: AppShadows.medium,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: ModernButton(
                        text: 'Add to Cart',
                        type: ModernButtonType.outlined,
                        onPressed: () => _addToCart(context),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ModernButton(
                        text: 'Buy Now',
                        onPressed: () {
                          Navigator.push(
                            context,
                            PageTransition(
                              type: PageTransitionType.bottomToTop,
                              child: CheckoutScreen(listing: _currentListing),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildReviewItem(Review review) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: AppRadius.roundedXL,
        border: Border.all(color: colorScheme.outline.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: colorScheme.primary.withOpacity(0.1),
                    child: Text(
                      (review.username?[0] ?? 'U').toUpperCase(),
                      style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.w900, fontSize: 12),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    review.username ?? 'Anonymous',
                    style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ],
              ),
              Row(
                children: List.generate(5, (index) => Icon(
                  index < review.rating ? Icons.star_rounded : Icons.star_border_rounded,
                  size: 14,
                  color: index < review.rating ? Colors.amber : colorScheme.outline,
                )),
              ),
            ],
          ),
          if (review.comment != null) ...[
            const SizedBox(height: 10),
            Text(
              review.comment!,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
          ],
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

  void _showAddReviewDialog(BuildContext context) {
    int rating = 5;
    final commentController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text('Write a Review', style: TextStyle(fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return IconButton(
                        icon: Icon(
                          index < rating ? Icons.star_rounded : Icons.star_border_rounded,
                          color: Colors.amber,
                          size: 32,
                        ),
                        onPressed: () => setState(() => rating = index + 1),
                      );
                    }),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: commentController,
                    decoration: InputDecoration(
                      labelText: 'Comment (Optional)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    maxLines: 3,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    try {
                      await _listingService.addReview(
                        listingId: _currentListing.id,
                        rating: rating,
                        comment: commentController.text,
                      );
                      if (context.mounted) {
                        Navigator.pop(context);
                        _refreshListing();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Review submitted successfully!')),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(e.toString())),
                        );
                      }
                    }
                  },
                  child: const Text('Submit', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          }
        );
      },
    );
  }
}
