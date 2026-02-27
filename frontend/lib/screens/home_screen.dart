import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import '../models/listing.dart';
import '../services/listing_service.dart';
import '../widgets/listing_card.dart';
import 'listing_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ListingService _listingService = ListingService();
  late Future<List<Listing>> _trendingListingsFuture;
  late Future<List<Listing>> _recentListingsFuture;

  final List<String> promoImages = [
    'https://images.unsplash.com/photo-1607082348824-0a96f2a4b9da?q=80&w=2070&auto=format&fit=crop',
    'https://images.unsplash.com/photo-1542291026-7eec264c27ff?q=80&w=2070&auto=format&fit=crop',
    'https://images.unsplash.com/photo-1528698827591-e19ccd7bc23d?q=80&w=2076&auto=format&fit=crop',
  ];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  void _fetchData() {
    setState(() {
      // Temporarily use getListings for both until we add a specific trending endpoint, 
      // but ideally trending would sort by view_count on the backend.
      _trendingListingsFuture = _listingService.getListings(skip: 0, limit: 10);
      _recentListingsFuture = _listingService.getListings(skip: 0, limit: 10);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.shopping_bag_rounded, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            const Text('Baterpoint', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.search_rounded),
            onPressed: () {},
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _fetchData(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero Promo Carousel
              CarouselSlider(
                options: CarouselOptions(
                  height: 200.0,
                  autoPlay: true,
                  enlargeCenterPage: true,
                  viewportFraction: 0.9,
                  aspectRatio: 2.0,
                  initialPage: 0,
                  autoPlayInterval: const Duration(seconds: 4),
                ),
                items: promoImages.map((imageUrl) {
                  return Builder(
                    builder: (BuildContext context) {
                      return Container(
                        width: MediaQuery.of(context).size.width,
                        margin: const EdgeInsets.symmetric(horizontal: 5.0, vertical: 8.0),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          image: DecorationImage(
                            image: NetworkImage(imageUrl),
                            fit: BoxFit.cover,
                            colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.3), BlendMode.darken),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            )
                          ]
                        ),
                        child: Align(
                          alignment: Alignment.bottomLeft,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text(
                              'Special Offers',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                }).toList(),
              ),
              
              const SizedBox(height: 24),
              
              // Trending Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Trending Now', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                    TextButton(
                      onPressed: () {},
                      child: const Text('See All'),
                    ),
                  ],
                ),
              ),
              
              SizedBox(
                height: 280,
                child: FutureBuilder<List<Listing>>(
                  future: _trendingListingsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(child: Text('No trending items found.'));
                    }

                    // Sort by viewCount locally just for display purposes
                    final trending = List<Listing>.from(snapshot.data!)
                      ..sort((a, b) => b.viewCount.compareTo(a.viewCount));
                    final topTrending = trending.take(5).toList();

                    return ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 12.0),
                      itemCount: topTrending.length,
                      itemBuilder: (context, index) {
                        return SizedBox(
                          width: 200,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4.0),
                            child: ListingCard(
                              listing: topTrending[index],
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ListingDetailScreen(listing: topTrending[index]),
                                  ),
                                );
                              },
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),

              const SizedBox(height: 16),
              
              // Recent Items Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Recommended for You', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                    TextButton(
                      onPressed: () {},
                      child: const Text('See All'),
                    ),
                  ],
                ),
              ),
              
              FutureBuilder<List<Listing>>(
                future: _recentListingsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()));
                  } else if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Padding(padding: EdgeInsets.all(32), child: Text('No recommendations found.')));
                  }

                  return GridView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.7,
                    ),
                    itemCount: snapshot.data!.length,
                    itemBuilder: (context, index) {
                      return ListingCard(
                        listing: snapshot.data![index],
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ListingDetailScreen(listing: snapshot.data![index]),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
