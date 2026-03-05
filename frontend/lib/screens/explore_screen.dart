import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
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
  final PageController _pageController = PageController();
  late Future<List<Listing>> _exploreFeedFuture;

  @override
  void initState() {
    super.initState();
    _exploreFeedFuture = _listingService.fetchListings(limit: 20); // Fetch a feed of items
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
        title: const Text('Discover', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(icon: const Icon(Icons.search, color: Colors.white), onPressed: () {}),
        ],
      ),
      body: FutureBuilder<List<Listing>>(
        future: _exploreFeedFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.white));
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.white)));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No items to explore.', style: TextStyle(color: Colors.white)));
          }

          final listings = snapshot.data!;

          return PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.vertical,
            itemCount: listings.length,
            itemBuilder: (context, index) {
              return _ExploreItemPage(listing: listings[index]);
            },
          );
        },
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
             Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ListingDetailScreen(listing: listing),
                ),
              );
          },
          child: listing.imageUrl != null
              ? CachedNetworkImage(
                  imageUrl: listing.imageUrl!,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(color: Colors.grey[900]),
                  errorWidget: (context, url, error) => Container(color: Colors.grey[900], child: const Icon(Icons.error, color: Colors.white)),
                )
              : Container(color: Colors.grey[900], child: const Icon(Icons.image_not_supported, color: Colors.white)),
        ),

        // Gradient Overlay
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.3),
                Colors.transparent,
                Colors.black.withOpacity(0.8),
              ],
              stops: const [0.0, 0.6, 1.0],
            ),
          ),
        ),

        // Content
        Positioned(
          bottom: 100, // Adjusted for bottom nav
          left: 20,
          right: 80, // Space for side actions
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                ),
                child: Text(
                  listing.category.toUpperCase(),
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
              Row(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundImage: listing.ownerAvatar != null ? CachedNetworkImageProvider(listing.ownerAvatar!) : null,
                    child: listing.ownerAvatar == null ? const Icon(Icons.person, size: 14) : null,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    listing.ownerUsername ?? 'Unknown Trader',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                listing.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  shadows: [Shadow(color: Colors.black54, blurRadius: 10)],
                ),
              ),
              const SizedBox(height: 8),
              if (listing.cashPrice != null)
                Text(
                  '\$${listing.cashPrice}',
                  style: const TextStyle(
                    color: Colors.greenAccent,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    shadows: [Shadow(color: Colors.black54, blurRadius: 10)],
                  ),
                ),

            ],
          ),
        ),

        // Side Actions
        Positioned(
          bottom: 100,
          right: 10,
          child: Column(
            children: [
              _SideActionButton(icon: Icons.favorite_border_rounded, label: 'Save', onTap: () {}),
              const SizedBox(height: 20),
              _SideActionButton(icon: Icons.comment_rounded, label: 'Chat', onTap: () {}),
              const SizedBox(height: 20),
              _SideActionButton(icon: Icons.share_rounded, label: 'Share', onTap: () {}),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () {
                   Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ListingDetailScreen(listing: listing),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Theme.of(context).primaryColor,
                    boxShadow: [BoxShadow(color: Theme.of(context).primaryColor.withOpacity(0.5), blurRadius: 10)],
                  ),
                  child: const Icon(Icons.arrow_forward_rounded, color: Colors.white),
                ),
              ),
            ],
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
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black.withOpacity(0.4),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
