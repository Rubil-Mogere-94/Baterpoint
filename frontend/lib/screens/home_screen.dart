import 'dart:async';
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/listing.dart';
import '../models/deal.dart';
import '../models/quest.dart';
import '../services/listing_service.dart';
import '../services/quest_service.dart';
import '../widgets/listing_card.dart';
import 'listing_detail_screen.dart';
import 'notifications_screen.dart';
import 'explore_screen.dart';
import '../widgets/shimmer_loading.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ListingService _listingService = ListingService();
  final QuestService _questService = QuestService();
  late Future<List<Listing>> _trendingListingsFuture;
  late Future<List<Listing>> _recommendationsFuture;
  late Future<List<UserQuest>> _questsFuture;
  late Future<Deal> _dealFuture;
  Timer? _dealTimer;
  Duration _dealRemaining = Duration.zero;

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
      _trendingListingsFuture = _listingService.fetchListings(sortBy: 'view_count', order: 'desc', limit: 10);
      _recommendationsFuture = _listingService.fetchRecommendations(limit: 10).catchError((e) {
        debugPrint('Recommendations error: $e');
        return _listingService.fetchListings(sortBy: 'created_at', order: 'desc', limit: 10);
      });
      _questsFuture = _questService.fetchQuests().catchError((e) {
        debugPrint('Quests error: $e');
        return <UserQuest>[];
      });
      _dealFuture = _listingService.fetchDealOfTheHour();
    });
    
    _dealFuture.then((deal) {
      if (mounted) {
        setState(() {
          _dealRemaining = deal.endTime.difference(DateTime.now());
        });
        _dealTimer?.cancel();
        _dealTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          if (mounted) {
            setState(() {
              _dealRemaining = deal.endTime.difference(DateTime.now());
              if (_dealRemaining.isNegative) {
                _dealRemaining = Duration.zero;
                timer.cancel();
                _fetchData();
              }
            });
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _dealTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.shopping_bag_rounded, color: theme.colorScheme.primary, size: 24),
            ),
            const SizedBox(width: 12),
            const Text('Baterpoint', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded, color: Colors.black87),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const NotificationsScreen()),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _fetchData(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search Bar
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ExploreScreen()),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.search_rounded, color: Colors.grey.shade600),
                        const SizedBox(width: 12),
                        Text('Search for items, categories...', style: TextStyle(color: Colors.grey.shade500, fontSize: 15)),
                      ],
                    ),
                  ),
                ),
              ),

              // Hero Promo Carousel
              CarouselSlider(
                options: CarouselOptions(
                  height: 180.0,
                  autoPlay: true,
                  enlargeCenterPage: true,
                  viewportFraction: 0.92,
                  aspectRatio: 2.0,
                  initialPage: 0,
                  autoPlayInterval: const Duration(seconds: 5),
                ),
                items: promoImages.asMap().entries.map((entry) {
                  final index = entry.key;
                  final imageUrl = entry.value;
                  final labels = ['Flash Sale!', 'New Arrivals', 'Premium Deals'];
                  
                  return Builder(
                    builder: (BuildContext context) {
                      return Container(
                        width: MediaQuery.of(context).size.width,
                        margin: const EdgeInsets.symmetric(vertical: 4.0),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          image: DecorationImage(
                            image: CachedNetworkImageProvider(imageUrl),
                            fit: BoxFit.cover,
                            colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.2), BlendMode.darken),
                          ),
                        ),
                        child: Stack(
                          children: [
                            Positioned(
                              bottom: 20,
                              left: 20,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.amber.shade700,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Text(
                                      'LIMITED TIME',
                                      style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    labels[index % labels.length],
                                    style: theme.textTheme.headlineSmall?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                }).toList(),
              ),
              
              const SizedBox(height: 24),
              
              // Daily Deals / Special Offer Section (Dynamic)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: FutureBuilder<Deal>(
                  future: _dealFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const ShimmerLoading.rectangular(height: 100);
                    } else if (snapshot.hasError) {
                      return const SizedBox.shrink();
                    }
                    
                    final deal = snapshot.data!;
                    final minutes = _dealRemaining.inMinutes % 60;
                    final seconds = _dealRemaining.inSeconds % 60;
                    
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.indigo.shade700, Colors.blue.shade600],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6)),
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Icon(Icons.bolt_rounded, color: Colors.amber, size: 20),
                                    SizedBox(width: 4),
                                    Text(
                                      'DEAL OF THE HOUR',
                                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.2),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${deal.discountPercentage}% OFF on ${deal.listing.title}',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Ends in ${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
                                  style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => ListingDetailScreen(listing: deal.listing)),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.indigo.shade700,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              elevation: 0,
                            ),
                            child: const Text('Grab It', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    );
                  }
                ),
              ),

              const SizedBox(height: 24),
              
              // Daily Quests Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: FutureBuilder<List<UserQuest>>(
                  future: _questsFuture,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData || snapshot.data!.isEmpty) return const SizedBox.shrink();
                    
                    final activeQuests = snapshot.data!.where((q) => !q.completed).toList();
                    if (activeQuests.isEmpty) return const SizedBox.shrink();
                    
                    final currentQuest = activeQuests.first;
                    final progress = currentQuest.progress / currentQuest.quest.goalValue;
                    
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.green.shade100),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.stars_rounded, color: Colors.green.shade700, size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Daily Quest',
                                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green.shade800, fontSize: 15),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade600,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '+${currentQuest.quest.pointsReward} pts',
                                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(currentQuest.quest.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 4),
                          Text(currentQuest.quest.description, style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: LinearProgressIndicator(
                                    value: progress,
                                    backgroundColor: Colors.white,
                                    color: Colors.green.shade600,
                                    minHeight: 10,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                '${currentQuest.progress}/${currentQuest.quest.goalValue}',
                                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green.shade800),
                              ),
                            ],
                          ),
                          if (currentQuest.progress >= currentQuest.quest.goalValue) ...[
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () async {
                                  try {
                                    final result = await _questService.claimReward(currentQuest.id);
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Reward Claimed! ${result['points_awarded']} points added.'),
                                          backgroundColor: Colors.green.shade700,
                                        ),
                                      );
                                      _fetchData();
                                    }
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text(e.toString())),
                                      );
                                    }
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green.shade600,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  elevation: 0,
                                ),
                                child: const Text('Claim Reward', style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 32),

              // Featured Artisans
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Top Traders', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                    TextButton(onPressed: () {}, child: const Text('View All')),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 110,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: 6,
                  itemBuilder: (context, index) {
                    final names = ['Alice', 'Bob', 'Charlie', 'Diana', 'Ethan', 'Fiona'];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10.0),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: theme.colorScheme.primary, width: 2),
                            ),
                            child: CircleAvatar(
                              radius: 30,
                              backgroundColor: Colors.grey.shade200,
                              backgroundImage: CachedNetworkImageProvider('https://i.pravatar.cc/150?u=$index'),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(names[index % names.length], style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    );
                  },
                ),
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
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const ExploreScreen()),
                        );
                      },
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
                      return ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 12.0),
                        itemCount: 5,
                        itemBuilder: (context, index) => const SizedBox(
                          width: 200,
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 4.0),
                            child: ListingCardShimmer(),
                          ),
                        ),
                      );
                    } else if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(child: Text('No trending items found.'));
                    }
 
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
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),

              const SizedBox(height: 24),

              // Recent Activity Feed
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text('Recent Activity', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 16),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: 3,
                itemBuilder: (context, index) {
                  final actions = ['swapped a Camera', 'listed a Mountain Bike', 'completed a Quest'];
                  final times = ['2 mins ago', '15 mins ago', '1 hour ago'];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12.0),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: Colors.grey.shade200,
                          backgroundImage: CachedNetworkImageProvider('https://i.pravatar.cc/150?u=${index + 10}'),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              RichText(
                                text: TextSpan(
                                  style: theme.textTheme.bodyMedium?.copyWith(color: Colors.black87),
                                  children: [
                                    TextSpan(text: 'User${index + 101} ', style: const TextStyle(fontWeight: FontWeight.bold)),
                                    TextSpan(text: actions[index % actions.length]),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(times[index % times.length], style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(height: 24),
              
              // Recommended Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Picked for You', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const ExploreScreen()),
                        );
                      },
                      child: const Text('See All'),
                    ),
                  ],
                ),
              ),
              
              FutureBuilder<List<Listing>>(
                future: _recommendationsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
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
                      itemCount: 4,
                      itemBuilder: (context, index) => const ListingCardShimmer(),
                    );
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
