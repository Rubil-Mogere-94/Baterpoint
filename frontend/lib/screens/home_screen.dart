import 'dart:async';
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:ui';
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
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: RefreshIndicator(
        onRefresh: () async => _fetchData(),
        color: colorScheme.primary,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              floating: true,
              pinned: true,
              snap: false,
              backgroundColor: colorScheme.surface.withOpacity(0.9),
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              expandedHeight: 60,
              flexibleSpace: ClipRRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: FlexibleSpaceBar(
                    background: Container(color: Colors.transparent),
                  ),
                ),
              ),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [colorScheme.primary, colorScheme.secondary],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.shopping_bag_rounded, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Baterpoint',
                    style: textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: colorScheme.onSurface,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
              actions: [
                IconButton(
                  icon: Icon(Icons.notifications_outlined, color: colorScheme.onSurface),
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
            
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ExploreScreen()),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.search_rounded, color: colorScheme.onSurfaceVariant),
                        const SizedBox(width: 12),
                        Text(
                          'Search for items, categories...',
                          style: textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: CarouselSlider(
                options: CarouselOptions(
                  height: 200.0,
                  autoPlay: true,
                  enlargeCenterPage: true,
                  viewportFraction: 0.9,
                  aspectRatio: 16/9,
                  initialPage: 0,
                  autoPlayInterval: const Duration(seconds: 6),
                ),
                items: promoImages.asMap().entries.map((entry) {
                  final index = entry.key;
                  final imageUrl = entry.value;
                  final labels = ['Flash Sale!', 'New Arrivals', 'Premium Deals'];
                  
                  return Builder(
                    builder: (BuildContext context) {
                      return Container(
                        width: MediaQuery.of(context).size.width,
                        margin: const EdgeInsets.symmetric(horizontal: 5.0),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: colorScheme.shadow.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                          image: DecorationImage(
                            image: CachedNetworkImageProvider(imageUrl),
                            fit: BoxFit.cover,
                          ),
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Colors.transparent, Colors.black.withOpacity(0.6)],
                              stops: const [0.6, 1.0],
                            ),
                          ),
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: colorScheme.secondary,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'LIMITED TIME',
                                  style: textTheme.labelSmall?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                labels[index % labels.length],
                                style: textTheme.headlineSmall?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                }).toList(),
              ),
            ),
            
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
            
            // Deal of the Hour
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: FutureBuilder<Deal>(
                  future: _dealFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const ShimmerLoading.rectangular(height: 120);
                    } else if (snapshot.hasError) {
                      return const SizedBox.shrink();
                    }
                    
                    final deal = snapshot.data!;
                    final minutes = _dealRemaining.inMinutes % 60;
                    final seconds = _dealRemaining.inSeconds % 60;
                    
                    return Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [colorScheme.primary, colorScheme.tertiary],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: colorScheme.primary.withOpacity(0.3),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.bolt_rounded, color: Colors.amber, size: 16),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'DEAL OF THE HOUR',
                                      style: textTheme.labelSmall?.copyWith(
                                        color: Colors.white.withOpacity(0.9),
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  '${deal.discountPercentage}% OFF',
                                  style: textTheme.headlineMedium?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    height: 1.0,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  deal.listing.title,
                                  style: textTheme.bodyMedium?.copyWith(
                                    color: Colors.white.withOpacity(0.9),
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'Ends in ${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontFamily: 'monospace',
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => ListingDetailScreen(listing: deal.listing)),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Text(
                                'Grab It',
                                style: textTheme.labelLarge?.copyWith(
                                  color: colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 32)),
            
            // Daily Quests
            SliverToBoxAdapter(
              child: Padding(
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
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.5)),
                        boxShadow: [
                          BoxShadow(
                            color: colorScheme.shadow.withOpacity(0.05),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.stars_rounded, color: colorScheme.primary, size: 24),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Daily Quest',
                                    style: textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      color: colorScheme.onSurface,
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: colorScheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '+${currentQuest.quest.pointsReward} pts',
                                  style: textTheme.labelSmall?.copyWith(
                                    color: colorScheme.onPrimaryContainer,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            currentQuest.quest.title,
                            style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            currentQuest.quest.description,
                            style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: LinearProgressIndicator(
                                    value: progress,
                                    backgroundColor: colorScheme.surfaceContainerHighest,
                                    color: colorScheme.primary,
                                    minHeight: 8,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Text(
                                '${currentQuest.progress}/${currentQuest.quest.goalValue}',
                                style: textTheme.labelMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                          if (currentQuest.progress >= currentQuest.quest.goalValue) ...[
                            const SizedBox(height: 20),
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
                                          backgroundColor: colorScheme.primary,
                                          behavior: SnackBarBehavior.floating,
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
                                  backgroundColor: colorScheme.primary,
                                  foregroundColor: colorScheme.onPrimary,
                                  elevation: 0,
                                ),
                                child: const Text('Claim Reward'),
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 32)),

            // Featured Artisans
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Top Traders', style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                    TextButton(
                      onPressed: () {},
                      child: Text('View All', style: TextStyle(color: colorScheme.primary)),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: 6,
                  itemBuilder: (context, index) {
                    final names = ['Alice', 'Bob', 'Charlie', 'Diana', 'Ethan', 'Fiona'];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [colorScheme.secondary, colorScheme.primary],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: CircleAvatar(
                              radius: 32,
                              backgroundColor: colorScheme.surfaceContainerHighest,
                              backgroundImage: CachedNetworkImageProvider('https://i.pravatar.cc/150?u=$index'),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            names[index % names.length],
                            style: textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),

            // Trending Section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Trending Now', style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const ExploreScreen()),
                        );
                      },
                      child: Text('See All', style: TextStyle(color: colorScheme.primary)),
                    ),
                  ],
                ),
              ),
            ),
            
            SliverToBoxAdapter(
              child: SizedBox(
                height: 290, // Adjusted height for new card style
                child: FutureBuilder<List<Listing>>(
                  future: _trendingListingsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 12.0),
                        itemCount: 3,
                        itemBuilder: (context, index) => const SizedBox(
                          width: 210,
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8.0),
                            child: ListingCardShimmer(),
                          ),
                        ),
                      );
                    } else if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                      return Center(child: Text('No trending items found.', style: textTheme.bodyMedium));
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
                          width: 220,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0), // Added vertical padding for shadow
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
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),

            // Recent Activity Feed
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text('Recent Activity', style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 16)),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final actions = ['swapped a Camera', 'listed a Mountain Bike', 'completed a Quest'];
                  final times = ['2 mins ago', '15 mins ago', '1 hour ago'];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: colorScheme.surfaceContainerHighest,
                            backgroundImage: CachedNetworkImageProvider('https://i.pravatar.cc/150?u=${index + 10}'),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                RichText(
                                  text: TextSpan(
                                    style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface),
                                    children: [
                                      TextSpan(
                                        text: 'User${index + 101} ', 
                                        style: const TextStyle(fontWeight: FontWeight.bold)
                                      ),
                                      TextSpan(
                                        text: actions[index % actions.length],
                                        style: TextStyle(color: colorScheme.onSurfaceVariant),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  times[index % times.length],
                                  style: textTheme.labelSmall?.copyWith(color: colorScheme.outline),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                childCount: 3,
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 32)),
            
            // Recommended Section Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Picked for You', style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const ExploreScreen()),
                        );
                      },
                      child: Text('See All', style: TextStyle(color: colorScheme.primary)),
                    ),
                  ],
                ),
              ),
            ),
            
            // Recommended Grid
            FutureBuilder<List<Listing>>(
              future: _recommendationsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    sliver: SliverGrid(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 0.7,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => const ListingCardShimmer(),
                        childCount: 4,
                      ),
                    ),
                  );
                } else if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                  return SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Text('No recommendations found.', style: textTheme.bodyMedium),
                      ),
                    ),
                  );
                }

                return SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.7,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        return ListingCard(
                          listing: snapshot.data![index],
                        );
                      },
                      childCount: snapshot.data!.length,
                    ),
                  ),
                );
              },
            ),
            
            const SliverToBoxAdapter(child: SizedBox(height: 48)),
          ],
        ),
      ),
    );
  }
}
