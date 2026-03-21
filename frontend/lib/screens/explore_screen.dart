import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:flutter_vibrate/flutter_vibrate.dart';
import 'package:page_transition/page_transition.dart';
import 'dart:ui';
import '../models/listing.dart';
import '../services/listing_service.dart';
import '../services/cart_service.dart';
import '../screens/listing_detail_screen.dart';
import '../constants/ui_constants.dart';
import '../widgets/holographic_background.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final ListingService _listingService = ListingService();
  final CartService _cartService = CartService();
  late Future<List<Listing>> _exploreFeedFuture;
  String _selectedCategory = 'All';
  final List<String> _categories = ['All', 'Fashion', 'Electronics', 'Home', 'Collectibles', 'Books'];
  bool _isGridView = true; 
  String _sortBy = 'Position';

  @override
  void initState() {
    super.initState();
    _exploreFeedFuture = _listingService.fetchListings(limit: 50);
  }

  void _addToCart(Listing listing) async {
    Vibrate.feedback(FeedbackType.medium);
    try {
      await _cartService.addToCart(listing.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${listing.title} added to cart!'),
            backgroundColor: Colors.green.shade800,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add to cart: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return HolographicBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Standard E-commerce App Bar
            SliverAppBar(
              backgroundColor: Colors.transparent,
              expandedHeight: 120,
              pinned: true,
              flexibleSpace: ClipRRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: FlexibleSpaceBar(
                    titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
                    title: const Text(
                      'Catalog',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 24),
                    ),
                    background: Container(
                      color: theme.colorScheme.surface.withOpacity(0.5),
                    ),
                  ),
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.search_rounded, color: Colors.white),
                  onPressed: () {},
                ),
                IconButton(
                  icon: const Icon(Icons.shopping_cart_outlined, color: Colors.white),
                  onPressed: () {},
                ),
              ],
            ),
            
            // Category Filter Ribbon
            SliverToBoxAdapter(
              child: SizedBox(
                height: 60,
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  scrollDirection: Axis.horizontal,
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    final cat = _categories[index];
                    final isSelected = _selectedCategory == cat;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () {
                          Vibrate.feedback(FeedbackType.light);
                          setState(() => _selectedCategory = cat);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? theme.colorScheme.primary : theme.cardColor.withOpacity(0.4),
                            borderRadius: AppRadius.roundedMD,
                            border: Border.all(color: isSelected ? theme.colorScheme.primary : theme.dividerColor),
                          ),
                          child: Center(
                            child: Text(
                              cat,
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.white70,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            // Sorter and View Tools (nopCommerce style)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Sort By Dropdown
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: theme.cardColor.withOpacity(0.6),
                        borderRadius: AppRadius.roundedSM,
                        border: Border.all(color: theme.dividerColor),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          dropdownColor: theme.cardColor,
                          value: _sortBy,
                          icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                          items: ['Position', 'Name: A to Z', 'Name: Z to A', 'Price: Low to High', 'Price: High to Low']
                              .map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                          onChanged: (newValue) {
                            if (newValue != null) {
                              setState(() => _sortBy = newValue);
                            }
                          },
                        ),
                      ),
                    ),
                    
                    // View Toggles
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.grid_view_rounded, color: _isGridView ? theme.colorScheme.primary : Colors.white54),
                          onPressed: () => setState(() => _isGridView = true),
                        ),
                        IconButton(
                          icon: Icon(Icons.view_list_rounded, color: !_isGridView ? theme.colorScheme.primary : Colors.white54),
                          onPressed: () => setState(() => _isGridView = false),
                        ),
                        IconButton(
                          icon: const Icon(Icons.filter_list_rounded, color: Colors.white),
                          onPressed: () => _showFilterSheet(context),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Product Grid / List
            FutureBuilder<List<Listing>>(
              future: _exploreFeedFuture,
              builder: (context, snapshot) {
                final isLoading = snapshot.connectionState == ConnectionState.waiting;
                if (!isLoading && snapshot.hasError) {
                  return SliverToBoxAdapter(child: Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.white))));
                } 

                final List<Listing> listings = isLoading 
                    ? List.generate(6, (_) => Listing.skeleton())
                    : snapshot.data!.where((l) => _selectedCategory == 'All' || l.category.toLowerCase() == _selectedCategory.toLowerCase()).toList();

                if (listings.isEmpty && !isLoading) {
                  return SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Center(child: Text('No $_selectedCategory products found.', style: const TextStyle(color: Colors.white))),
                    ),
                  );
                }

                return Skeletonizer.sliver(
                  enabled: isLoading,
                  child: SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    sliver: _isGridView 
                      ? SliverGrid(
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.65,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 16,
                          ),
                          delegate: SliverChildBuilderDelegate(
                            (context, index) => _ProductGridBox(
                              listing: listings[index], 
                              onAddToCart: () => _addToCart(listings[index]),
                            ),
                            childCount: listings.length,
                          ),
                        )
                      : SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _ProductListBox(
                                listing: listings[index],
                                onAddToCart: () => _addToCart(listings[index]),
                              ),
                            ),
                            childCount: listings.length,
                          ),
                        ),
                  ),
                );
              },
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  void _showFilterSheet(BuildContext context) {
    Vibrate.feedback(FeedbackType.medium);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _SearchFilterSheet(),
    );
  }
}

// nopCommerce style Grid Box
class _ProductGridBox extends StatelessWidget {
  final Listing listing;
  final VoidCallback onAddToCart;

  const _ProductGridBox({required this.listing, required this.onAddToCart});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          PageTransition(type: PageTransitionType.fade, child: ListingDetailScreen(listing: listing)),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: theme.cardColor.withOpacity(0.8),
          borderRadius: AppRadius.roundedLG,
          border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 5,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  listing.imageUrl != null
                      ? CachedNetworkImage(
                          imageUrl: listing.imageUrl!,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(color: Colors.grey[900]),
                          errorWidget: (context, url, err) => Container(color: Colors.grey[900], child: const Icon(Icons.image)),
                        )
                      : Container(color: Colors.grey[900], child: const Icon(Icons.image, color: Colors.white54)),
                  // Wishlist overlay
                  Positioned(
                    top: 8, right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.black45),
                      child: const Icon(Icons.favorite_border, color: Colors.white, size: 18),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      listing.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Colors.white),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '\$${listing.cashPrice?.toStringAsFixed(2) ?? "0.00"}',
                          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: theme.colorScheme.primary),
                        ),
                        // Direct Add to Cart
                        GestureDetector(
                          onTap: onAddToCart,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              borderRadius: AppRadius.roundedSM,
                            ),
                            child: const Icon(Icons.shopping_cart, color: Colors.white, size: 16),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// nopCommerce style List Box
class _ProductListBox extends StatelessWidget {
  final Listing listing;
  final VoidCallback onAddToCart;

  const _ProductListBox({required this.listing, required this.onAddToCart});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          PageTransition(type: PageTransitionType.fade, child: ListingDetailScreen(listing: listing)),
        );
      },
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: theme.cardColor.withOpacity(0.8),
          borderRadius: AppRadius.roundedLG,
          border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Row(
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: listing.imageUrl != null
                  ? CachedNetworkImage(imageUrl: listing.imageUrl!, fit: BoxFit.cover)
                  : Container(color: Colors.grey[900], child: const Icon(Icons.image, color: Colors.white54)),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      listing.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: Colors.white),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      listing.category,
                      style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                    ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '\$${listing.cashPrice?.toStringAsFixed(2) ?? "0.00"}',
                          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: theme.colorScheme.primary),
                        ),
                        ElevatedButton.icon(
                          onPressed: onAddToCart,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.primary,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            minimumSize: Size.zero,
                          ),
                          icon: const Icon(Icons.shopping_cart, size: 16, color: Colors.white),
                          label: const Text('Add', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchFilterSheet extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text('Filters', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 24),
          // Specifications / Attributes (nopCommerce style)
          Text('Specifications', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              FilterChip(label: const Text('New'), onSelected: (_) {}, selected: true),
              FilterChip(label: const Text('Used'), onSelected: (_) {}),
              FilterChip(label: const Text('Free Shipping'), onSelected: (_) {}),
            ],
          ),
          const SizedBox(height: 24),
          Text('Price Range', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
          RangeSlider(
            values: const RangeValues(0, 1000),
            max: 5000,
            onChanged: (val) {},
            activeColor: theme.colorScheme.primary,
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Reset'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Apply'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
