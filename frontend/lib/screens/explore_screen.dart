import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:flutter_vibrate/flutter_vibrate.dart';
import 'package:page_transition/page_transition.dart';
import 'dart:ui';
import '../models/listing.dart';
import '../services/listing_service.dart';
import '../screens/listing_detail_screen.dart';
import '../constants/ui_constants.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final ListingService _listingService = ListingService();
  late PageController _pageController;
  late Future<List<Listing>> _exploreFeedFuture;
  String _selectedCategory = 'All';
  final List<String> _categories = ['All', 'Fashion', 'Electronics', 'Home', 'Collectibles', 'Books'];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _exploreFeedFuture = _listingService.fetchListings(limit: 20);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () {
            Vibrate.feedback(FeedbackType.light);
            Navigator.maybePop(context);
          },
        ),
        title: const Text(
          'Discover',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.15),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.tune_rounded, color: Colors.white),
                    onPressed: () => _showFilterSheet(context),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          FutureBuilder<List<Listing>>(
            future: _exploreFeedFuture,
            builder: (context, snapshot) {
              final isLoading = snapshot.connectionState == ConnectionState.waiting;
              if (!isLoading && snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.white)));
              } else if (!isLoading && (!snapshot.hasData || snapshot.data!.isEmpty)) {
                return const Center(child: Text('No items to explore.', style: TextStyle(color: Colors.white)));
              }

              final listings = isLoading 
                  ? List.generate(3, (_) => Listing.skeleton())
                  : snapshot.data!.where((l) => _selectedCategory == 'All' || l.category.toLowerCase() == _selectedCategory.toLowerCase()).toList();

              if (listings.isEmpty && !isLoading) {
                return Center(child: Text('No $_selectedCategory items found.', style: const TextStyle(color: Colors.white)));
              }

              return Skeletonizer(
                enabled: isLoading,
                child: PageView.builder(
                  controller: _pageController,
                  scrollDirection: Axis.vertical,
                  itemCount: listings.length,
                  itemBuilder: (context, index) {
                    return _ExploreItemPage(listing: listings[index]);
                  },
                ),
              );
            },
          ),
          
          // Category Slider
          Positioned(
            top: MediaQuery.of(context).padding.top + kToolbarHeight + 10,
            left: 0,
            right: 0,
            child: SizedBox(
              height: 40,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
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
                        setState(() {
                          _selectedCategory = cat;
                        });
                      },
                      child: ClipRRect(
                        borderRadius: AppRadius.roundedSM,
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected ? Theme.of(context).colorScheme.primary : Colors.white.withOpacity(0.1),
                              borderRadius: AppRadius.roundedSM,
                              border: Border.all(color: Colors.white.withOpacity(0.2)),
                            ),
                            child: Text(
                              cat,
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                                fontSize: 13,
                              ),
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
        ],
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
          Text('Sort By', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              FilterChip(label: const Text('Recent'), onSelected: (_) {}, selected: true),
              FilterChip(label: const Text('Popular'), onSelected: (_) {}),
              FilterChip(label: const Text('High Price'), onSelected: (_) {}),
              FilterChip(label: const Text('Low Price'), onSelected: (_) {}),
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

class _ExploreItemPage extends StatelessWidget {
  final Listing listing;

  const _ExploreItemPage({required this.listing});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Full Screen Image
        GestureDetector(
          onTap: () {
            Vibrate.feedback(FeedbackType.light);
            Navigator.push(
              context,
              PageTransition(
                type: PageTransitionType.fade,
                child: ListingDetailScreen(listing: listing),
              ),
            );
          },
          child: listing.imageUrl != null
              ? CachedNetworkImage(
                  imageUrl: listing.imageUrl!,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(color: Colors.grey[900]),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.grey[900],
                    child: const Icon(Icons.broken_image_rounded, color: Colors.white54, size: 48),
                  ),
                )
              : Container(
                  color: Colors.grey[900],
                  child: const Icon(Icons.image_not_supported_rounded, color: Colors.white54, size: 48),
                ),
        ),

        // Multi-stop Gradient Overlay
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.4),
                Colors.transparent,
                Colors.transparent,
                Colors.black.withOpacity(0.85),
              ],
              stops: const [0.0, 0.3, 0.5, 1.0],
            ),
          ),
        ),

        // Content
        Positioned(
          bottom: 110,
          left: 20,
          right: 90,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Category pill
              ClipRRect(
                borderRadius: AppRadius.roundedSM,
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: AppRadius.roundedSM,
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                    ),
                    child: Text(
                      listing.category.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundImage: listing.ownerAvatar != null
                        ? CachedNetworkImageProvider(listing.ownerAvatar!)
                        : null,
                    backgroundColor: Colors.white24,
                    child: listing.ownerAvatar == null
                        ? const Icon(Icons.person_rounded, size: 14, color: Colors.white)
                        : null,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    listing.ownerUsername ?? 'Unknown Trader',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      shadows: [Shadow(color: Colors.black54, blurRadius: 6)],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                listing.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                  shadows: [Shadow(color: Colors.black54, blurRadius: 10)],
                ),
              ),
              const SizedBox(height: 8),
              if (listing.cashPrice != null)
                Text(
                  '\$${listing.cashPrice}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    shadows: [Shadow(color: Colors.black54, blurRadius: 10)],
                  ),
                ),
            ],
          ),
        ),

        // Side Actions
        Positioned(
          bottom: 110,
          right: 12,
          child: Column(
            children: [
              _SideActionButton(icon: Icons.favorite_border_rounded, label: 'Save', onTap: () {}),
              const SizedBox(height: 20),
              _SideActionButton(icon: Icons.chat_bubble_outline_rounded, label: 'Chat', onTap: () {}),
              const SizedBox(height: 20),
              _SideActionButton(icon: Icons.share_rounded, label: 'Share', onTap: () {}),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () {
                  Vibrate.feedback(FeedbackType.medium);
                  Navigator.push(
                    context,
                    PageTransition(
                      type: PageTransitionType.fade,
                      child: ListingDetailScreen(listing: listing),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Theme.of(context).colorScheme.primary,
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
        ),

        // Swipe indicator
        Positioned(
          bottom: 60,
          left: 0,
          right: 0,
          child: Center(
            child: Column(
              children: [
                Icon(Icons.keyboard_arrow_up_rounded, color: Colors.white.withOpacity(0.7), size: 24),
                Text(
                  'Swipe for more',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SideActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SideActionButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Vibrate.feedback(FeedbackType.light);
        onTap();
      },
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.15),
                  border: Border.all(color: Colors.white.withOpacity(0.25)),
                ),
                child: Icon(icon, color: Colors.white, size: 26),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
            ),
          ),
        ],
      ),
    );
  }
}
