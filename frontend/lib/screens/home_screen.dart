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
import 'package:skeletonizer/skeletonizer.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:page_transition/page_transition.dart';
import '../widgets/listing_card.dart';
import '../constants/ui_constants.dart';
import '../providers/connectivity_provider.dart';
import 'listing_detail_screen.dart';
import 'notifications_screen.dart';
import 'explore_screen.dart';
import 'package:provider/provider.dart';

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
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverAppBar(
              floating: true,
              pinned: true,
              snap: false,
              backgroundColor: colorScheme.surface.withOpacity(0.8),
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              expandedHeight: 70,
              flexibleSpace: Column(
                children: [
                   Consumer<ConnectivityProvider>(
                    builder: (context, connectivity, _) {
                      if (connectivity.isOffline) {
                        return Container(
                          width: double.infinity,
                          color: colorScheme.errorContainer,
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.wifi_off_rounded, size: 14, color: colorScheme.onErrorContainer),
                              const SizedBox(width: 8),
                              Text(
                                'YOU ARE OFFLINE',
                                style: textTheme.labelSmall?.copyWith(
                                  color: colorScheme.onErrorContainer,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ],
                          ),
                        ).animate().slideY(begin: -1, end: 0);
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                  ClipRRect(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                      child: FlexibleSpaceBar(
                        background: Container(color: Colors.transparent),
                      ),
                    ),
                  ),
                ],
              ),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [colorScheme.primary, colorScheme.secondary],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: AppRadius.roundedMD,
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.primary.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.handshake_rounded, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Text(
                    'Baterpoint',
                    style: textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: colorScheme.onSurface,
                      letterSpacing: -1.0,
                    ),
                  ),
                ],
              ),
              actions: [
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withOpacity(0.4),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: Icon(Icons.notifications_none_rounded, color: colorScheme.onSurface, size: 26),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const NotificationsScreen()),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 8),
              ],
            ),
            
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(AppPadding.md, AppPadding.md, AppPadding.md, AppPadding.lg),
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ExploreScreen()),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: AppRadius.roundedXL,
                      border: Border.all(color: colorScheme.outline.withOpacity(0.1)),
                      boxShadow: AppShadows.soft,
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.search_rounded, color: colorScheme.primary, size: 22),
                        const SizedBox(width: 14),
                        Text(
                          'Find your next treasure...',
                          style: textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant.withOpacity(0.7),
                            fontWeight: FontWeight.w500,
                            fontSize: 15,
                          ),
                        ),
                        const Spacer(),
                        Icon(Icons.tune_rounded, color: colorScheme.onSurfaceVariant.withOpacity(0.5), size: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: FutureBuilder<List<Listing>>(
                future: _trendingListingsFuture,
                builder: (context, snapshot) {
                  final isLoading = snapshot.connectionState == ConnectionState.waiting;
                  final listings = isLoading 
                    ? List.generate(3, (_) => Listing.skeleton())
                    : snapshot.data ?? [];
                  
                  if (!isLoading && listings.isEmpty) return const SizedBox.shrink();
                  
                  final heroListings = listings.where((l) => l.imageUrl != null || isLoading).take(5).toList();
                  if (heroListings.isEmpty) return const SizedBox.shrink();

                  return Skeletonizer(
                    enabled: isLoading,
                    child: CarouselSlider(
                    options: CarouselOptions(
                      height: 210.0,
                      autoPlay: true,
                      enlargeCenterPage: true,
                      viewportFraction: 0.92,
                      aspectRatio: 16/9,
                      initialPage: 0,
                      autoPlayInterval: const Duration(seconds: 7),
                      autoPlayCurve: Curves.fastOutSlowIn,
                    ),
                    items: heroListings.map((listing) {
                      return Builder(
                        builder: (BuildContext context) {
                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => ListingDetailScreen(listing: listing)),
                              );
                            },
                            child: Container(
                              width: MediaQuery.of(context).size.width,
                              margin: const EdgeInsets.symmetric(horizontal: 4.0),
                              decoration: BoxDecoration(
                                borderRadius: AppRadius.roundedXXL,
                                image: DecorationImage(
                                  image: CachedNetworkImageProvider(listing.imageUrl!),
                                  fit: BoxFit.cover,
                                ),
                                boxShadow: AppShadows.medium,
                              ),
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: AppRadius.roundedXXL,
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [Colors.transparent, Colors.black.withOpacity(0.8)],
                                    stops: const [0.4, 1.0],
                                  ),
                                ),
                                padding: const EdgeInsets.all(AppPadding.lg),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: colorScheme.primary,
                                        borderRadius: AppRadius.roundedSM,
                                      ),
                                      child: Text(
                                        listing.tradeType?.toUpperCase() ?? '',
                                        style: textTheme.labelSmall?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 1.0,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      listing.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: textTheme.headlineSmall?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      listing.category,
                                      style: textTheme.bodySmall?.copyWith(
                                        color: Colors.white.withOpacity(0.8),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    }).toList(),
                  ),
                  );
                },
              ),
            ),
            
            const SliverToBoxAdapter(child: SizedBox(height: AppPadding.xl)),
            
            // Deal of the Hour
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppPadding.md),
                child: FutureBuilder<Deal>(
                  future: _dealFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Skeletonizer(
                        enabled: true,
                        child: Container(
                          height: 140,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: AppRadius.roundedXXL,
                          ),
                        ),
                      );
                    } else if (snapshot.hasError) {
                      return const SizedBox.shrink();
                    }
                    
                    final deal = snapshot.data!;
                    final minutes = _dealRemaining.inMinutes % 60;
                    final seconds = _dealRemaining.inSeconds % 60;
                    
                    return Container(
                      padding: const EdgeInsets.all(AppPadding.lg),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [colorScheme.primary, colorScheme.tertiary],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: AppRadius.roundedXXL,
                        boxShadow: [
                          BoxShadow(
                            color: colorScheme.primary.withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.15),
                                    borderRadius: AppRadius.roundedSM,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.bolt_rounded, color: Colors.amber, size: 16),
                                      const SizedBox(width: 6),
                                      Text(
                                        'FLASH DEAL',
                                        style: textTheme.labelSmall?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 1.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  '${deal.discountPercentage}% OFF',
                                  style: textTheme.headlineMedium?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    height: 1.0,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  deal.listing.title,
                                  style: textTheme.bodyMedium?.copyWith(
                                    color: Colors.white.withOpacity(0.9),
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    const Icon(Icons.timer_outlined, color: Colors.white70, size: 14),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Ends in ${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontFamily: 'monospace',
                                        fontWeight: FontWeight.w900,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Column(
                            children: [
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: AppRadius.roundedXL,
                                  image: deal.listing.imageUrl != null 
                                    ? DecorationImage(
                                        image: CachedNetworkImageProvider(deal.listing.imageUrl!),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                                ),
                              ),
                              const SizedBox(height: 12),
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => ListingDetailScreen(listing: deal.listing)),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: colorScheme.primary,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  shape: RoundedRectangleBorder(borderRadius: AppRadius.roundedMD),
                                ),
                                child: const Text('View Deal', style: TextStyle(fontWeight: FontWeight.w900)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: AppPadding.xl)),
            
            // Daily Quests
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppPadding.md),
                child: FutureBuilder<List<UserQuest>>(
                  future: _questsFuture,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData || snapshot.data!.isEmpty) return const SizedBox.shrink();
                    
                    final activeQuests = snapshot.data!.where((q) => !q.completed).toList();
                    if (activeQuests.isEmpty) return const SizedBox.shrink();
                    
                    final currentQuest = activeQuests.first;
                    final progress = currentQuest.progress / currentQuest.quest.goalValue;
                    
                    return Container(
                      padding: const EdgeInsets.all(AppPadding.lg),
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        borderRadius: AppRadius.roundedXXL,
                        border: Border.all(color: colorScheme.outline.withOpacity(0.1)),
                        boxShadow: AppShadows.soft,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: colorScheme.secondary.withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(Icons.auto_awesome_rounded, color: colorScheme.secondary, size: 20),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Daily Quest',
                                    style: textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w900,
                                      color: colorScheme.onSurface,
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: colorScheme.primaryContainer.withOpacity(0.5),
                                  borderRadius: AppRadius.roundedSM,
                                ),
                                child: Text(
                                  '+${currentQuest.quest.pointsReward} XP',
                                  style: textTheme.labelSmall?.copyWith(
                                    color: colorScheme.primary,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Text(
                            currentQuest.quest.title,
                            style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            currentQuest.quest.description,
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant.withOpacity(0.7),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(
                                child: Stack(
                                  children: [
                                    Container(
                                      height: 10,
                                      decoration: BoxDecoration(
                                        color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
                                        borderRadius: AppRadius.roundedXS,
                                      ),
                                    ),
                                    AnimatedFractionallySizedBox(
                                      duration: AppAnimations.slow,
                                      widthFactor: progress.clamp(0.0, 1.0),
                                      child: Container(
                                        height: 10,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [colorScheme.primary, colorScheme.primary.withOpacity(0.7)],
                                          ),
                                          borderRadius: AppRadius.roundedXS,
                                          boxShadow: [
                                            BoxShadow(
                                              color: colorScheme.primary.withOpacity(0.2),
                                              blurRadius: 4,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Text(
                                '${(progress * 100).toInt()}%',
                                style: textTheme.labelMedium?.copyWith(
                                  fontWeight: FontWeight.w900,
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
                                          shape: RoundedRectangleBorder(borderRadius: AppRadius.roundedMD),
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
                                  elevation: 4,
                                  shadowColor: colorScheme.primary.withOpacity(0.3),
                                  shape: RoundedRectangleBorder(borderRadius: AppRadius.roundedMD),
                                ),
                                child: const Text('Claim Reward', style: TextStyle(fontWeight: FontWeight.w900)),
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

            const SliverToBoxAdapter(child: SizedBox(height: AppPadding.xl)),

            // (Removed Mock Featured Artisans)

            // Trending Section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppPadding.md),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Trending Now', style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
                        Text('Items getting the most attention', style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant)),
                      ],
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          PageTransition(
                            type: PageTransitionType.fade,
                            child: const ExploreScreen(),
                          ),
                        );
                      },
                      child: Text('See All', style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.w800)),
                    ),
                  ],
                ),
              ),
            ),
            
            SliverToBoxAdapter(
              child: SizedBox(
                height: 310, 
                child: FutureBuilder<List<Listing>>(
                  future: _trendingListingsFuture,
                  builder: (context, snapshot) {
                    final isLoading = snapshot.connectionState == ConnectionState.waiting;
                    
                    if (!isLoading && (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty)) {
                      return Center(child: Text('No trending items found.', style: textTheme.bodyMedium));
                    }

                    final listings = isLoading 
                      ? List.generate(5, (_) => Listing.skeleton())
                      : snapshot.data!;
 
                    final trending = List<Listing>.from(listings)
                      ..sort((a, b) => b.viewCount.compareTo(a.viewCount));
                    final topTrending = trending.take(5).toList();
 
                    return Skeletonizer(
                      enabled: isLoading,
                      child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: AppPadding.md),
                      itemCount: topTrending.length,
                      itemBuilder: (context, index) {
                        return SizedBox(
                          width: 230,
                          child: Padding(
                            padding: const EdgeInsets.only(right: 16.0, top: 12.0, bottom: 20.0), 
                            child: ListingCard(
                              listing: topTrending[index],
                            ),
                          ),
                        );
                      },
                    ),
                    );
                  },
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: AppPadding.lg)),

            // (Removed Mock Recent Activity)

            const SliverToBoxAdapter(child: SizedBox(height: AppPadding.xl)),
            
            // Recommended Section Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppPadding.md),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Picked for You', style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
                        Text('Based on your interests', style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant)),
                      ],
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          PageTransition(
                            type: PageTransitionType.fade,
                            child: const ExploreScreen(),
                          ),
                        );
                      },
                      child: Text('See All', style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.w800)),
                    ),
                  ],
                ),
              ),
            ),
            
            // Recommended Grid
            FutureBuilder<List<Listing>>(
              future: _recommendationsFuture,
              builder: (context, snapshot) {
                final isLoading = snapshot.connectionState == ConnectionState.waiting;
                
                if (!isLoading && (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty)) {
                  return SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(AppPadding.xxl),
                        child: Text('No recommendations found.', style: textTheme.bodyMedium),
                      ),
                    ),
                  );
                }

                final listings = isLoading 
                  ? List.generate(4, (_) => Listing.skeleton())
                  : snapshot.data!;

                return SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: AppPadding.md, vertical: AppPadding.md),
                  sliver: Skeletonizer.sliver(
                    enabled: isLoading,
                    child: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.68,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: ListingCard(
                            listing: listings[index],
                          ),
                        );
                      },
                      childCount: listings.length,
                    ),
                    ),
                  ),
                );
              },
            ),
            
            const SliverToBoxAdapter(child: SizedBox(height: 100)), // Extra space for floating nav
          ],
        ),
      ),
    );
  }
}
