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
import '../widgets/modern_button.dart';
import '../widgets/holographic_background.dart';
import '../constants/ui_constants.dart';
import '../constants/theme.dart';
import '../providers/connectivity_provider.dart';
import 'listing_detail_screen.dart';
import 'notifications_screen.dart';
import 'explore_screen.dart';
import 'ai_valuator_screen.dart';
import 'inbox_screen.dart';
import 'forum_screen.dart';
import 'package:provider/provider.dart';
import '../models/story.dart';
import '../widgets/story_circle.dart';
import '../widgets/heart_animation.dart';
import 'story_view_screen.dart';
import 'package:flutter_vibrate/flutter_vibrate.dart';
import 'package:baterpoint/utils/app_haptics.dart';

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
  bool _showHeart = false;
  final int _activeHeartIndex = -1;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  void _fetchData() {
    setState(() {
      _trendingListingsFuture = _listingService.fetchListings(sortBy: 'view_count', order: 'desc', limit: 10);
      _recommendationsFuture = _listingService.fetchRecommendations(limit: 10).catchError((e) {
        return _listingService.fetchListings(sortBy: 'created_at', order: 'desc', limit: 10);
      });
      _questsFuture = _questService.fetchQuests().catchError((e) => <UserQuest>[]);
      _dealFuture = _listingService.fetchDealOfTheHour();
    });
    
    _dealFuture.then((deal) {
      if (mounted) {
        setState(() => _dealRemaining = deal.endTime.difference(DateTime.now()));
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
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          const HolographicBackground(),
          RefreshIndicator(
            onRefresh: () async => _fetchData(),
            color: colorScheme.primary,
            edgeOffset: 100,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                _buildAppBar(context, colorScheme, textTheme),
                
                // AI Valuator CTA
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: _buildAiValuatorCard(colorScheme, textTheme),
                  ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.1),
                ),
                
                // Search Bar Placeholder
                _buildSearchBar(colorScheme, textTheme),

                // Stories Bar
                SliverToBoxAdapter(
                  child: _buildStoryBar(),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 12)),

                // Featured Carousel
                SliverToBoxAdapter(
                  child: _buildTrendingCarousel(),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 32)),

                // Deal of the Hour
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _buildDealCard(colorScheme, textTheme),
                  ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 32)),

                // Daily Quest
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _buildQuestCard(colorScheme, textTheme),
                  ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 32)),

                // Discover Title
                _buildSectionHeader('Discover Feed', 'Swipe through verified listings', textTheme),

                // Main Feed (PageView)
                _buildMainFeed(colorScheme, textTheme),

                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, ColorScheme colorScheme, TextTheme textTheme) {
    return SliverAppBar(
      floating: true,
      pinned: true,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      expandedHeight: 80,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [colorScheme.primary, colorScheme.secondary]),
              borderRadius: AppRadius.roundedMD,
              boxShadow: [BoxShadow(color: colorScheme.primary.withOpacity(0.3), blurRadius: 10)],
            ),
            child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Text(
            'Baterpoint',
            style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900, letterSpacing: -1.0),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.forum_outlined, color: colorScheme.onSurface, size: 24),
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ForumScreen())),
        ),
        IconButton(
          icon: Icon(Icons.chat_bubble_outline_rounded, color: colorScheme.onSurface, size: 24),
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const InboxScreen())),
        ),
        IconButton(
          icon: Icon(Icons.notifications_none_rounded, color: colorScheme.onSurface, size: 26),
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const NotificationsScreen())),
        ),
        const SizedBox(width: 8),
      ],
      flexibleSpace: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(color: Colors.transparent),
        ),
      ),
    );
  }

  Widget _buildAiValuatorCard(ColorScheme colorScheme, TextTheme textTheme) {
    return InkWell(
      onTap: () => Navigator.push(context, PageTransition(type: PageTransitionType.bottomToTop, child: const AiValuatorScreen())),
      borderRadius: AppRadius.roundedXXL,
      child: ClipRRect(
        borderRadius: AppRadius.roundedXXL,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [colorScheme.primary.withOpacity(0.8), colorScheme.secondary.withOpacity(0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: AppRadius.roundedXXL,
              boxShadow: [BoxShadow(color: colorScheme.primary.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 5))],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
                  child: const Icon(Icons.document_scanner_rounded, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('AI Treasure Scan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)),
                      Text('Discover your item\'s hidden value instantly', style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 12)),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white70, size: 14),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar(ColorScheme colorScheme, TextTheme textTheme) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: InkWell(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ExploreScreen())),
          borderRadius: AppRadius.roundedXL,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: colorScheme.surface.withOpacity(0.4),
              borderRadius: AppRadius.roundedXL,
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Icon(Icons.search_rounded, color: colorScheme.primary, size: 20),
                const SizedBox(width: 12),
                Text('Search listings...', style: TextStyle(color: colorScheme.onSurfaceVariant.withOpacity(0.6))),
                const Spacer(),
                Icon(Icons.tune_rounded, color: colorScheme.onSurfaceVariant.withOpacity(0.4), size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTrendingCarousel() {
    return FutureBuilder<List<Listing>>(
      future: _trendingListingsFuture,
      builder: (context, snapshot) {
        final isLoading = snapshot.connectionState == ConnectionState.waiting;
        final listings = isLoading ? List.generate(3, (_) => Listing.skeleton()) : snapshot.data ?? [];
        if (!isLoading && listings.isEmpty) return const SizedBox.shrink();

        return Skeletonizer(
          enabled: isLoading,
          child: CarouselSlider(
            options: CarouselOptions(
              height: 220,
              autoPlay: true,
              enlargeCenterPage: true,
              viewportFraction: 0.9,
              autoPlayInterval: const Duration(seconds: 6),
            ),
            items: listings.take(5).map((l) => _buildCarouselItem(l)).toList(),
          ),
        );
      },
    );
  }

  Widget _buildCarouselItem(Listing listing) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ListingDetailScreen(listing: listing))),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 5),
        decoration: BoxDecoration(
          borderRadius: AppRadius.roundedXXL,
          image: listing.imageUrl != null ? DecorationImage(image: CachedNetworkImageProvider(listing.imageUrl!), fit: BoxFit.cover) : null,
          boxShadow: AppShadows.medium,
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: AppRadius.roundedXXL,
            gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black.withOpacity(0.8)]),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(listing.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18), maxLines: 1),
              Text(listing.category, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDealCard(ColorScheme colorScheme, TextTheme textTheme) {
    return FutureBuilder<Deal>(
      future: _dealFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        final deal = snapshot.data!;
        final minutes = _dealRemaining.inMinutes % 60;
        final seconds = _dealRemaining.inSeconds % 60;

        return ClipRRect(
          borderRadius: AppRadius.roundedXXL,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [colorScheme.tertiary.withOpacity(0.8), colorScheme.primary.withOpacity(0.8)]),
                borderRadius: AppRadius.roundedXXL,
                border: Border.all(color: Colors.white.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('LIMITED TIME DEAL', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1.5)),
                        const SizedBox(height: 8),
                        Text('${deal.discountPercentage}% OFF', style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900)),
                        Text(deal.listing.title, style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13, fontWeight: FontWeight.w600), maxLines: 1),
                        const SizedBox(height: 12),
                        Text('${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')} LEFT', style: const TextStyle(color: Colors.white, fontFamily: 'monospace', fontWeight: FontWeight.w900)),
                      ],
                    ),
                  ),
                  Container(
                    width: 70, height: 70,
                    decoration: BoxDecoration(
                      borderRadius: AppRadius.roundedXL,
                      image: deal.listing.imageUrl != null ? DecorationImage(image: CachedNetworkImageProvider(deal.listing.imageUrl!), fit: BoxFit.cover) : null,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuestCard(ColorScheme colorScheme, TextTheme textTheme) {
    return FutureBuilder<List<UserQuest>>(
      future: _questsFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) return const SizedBox.shrink();
        final quest = snapshot.data!.first;
        final progress = (quest.progress / quest.quest.goalValue).clamp(0.0, 1.0);

        return ClipRRect(
          borderRadius: AppRadius.roundedXXL,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colorScheme.surface.withOpacity(0.4),
                borderRadius: AppRadius.roundedXXL,
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('ACTIVE QUEST', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 10, color: Colors.blueGrey)),
                      Text('+${quest.quest.pointsReward} XP', style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.w900, fontSize: 10)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(quest.quest.title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(value: progress, minHeight: 8, backgroundColor: colorScheme.outline.withOpacity(0.1), color: colorScheme.primary),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMainFeed(ColorScheme colorScheme, TextTheme textTheme) {
    return SliverToBoxAdapter(
      child: SizedBox(
        height: 500,
        child: FutureBuilder<List<Listing>>(
          future: _trendingListingsFuture,
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
            return PageView.builder(
              scrollDirection: Axis.vertical,
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) => _buildFeedItem(snapshot.data![index]),
            );
          },
        ),
      ),
    );
  }

  void _showActionHint(String action) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$action functionality coming soon!'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        backgroundColor: Colors.white12,
      ),
    );
  }

  Widget _buildFeedItem(Listing listing) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.white.withOpacity(0.7),
        borderRadius: AppRadius.roundedXXL,
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.12) : Colors.black.withOpacity(0.05),
          width: 1,
        ),
        boxShadow: isDark ? [] : [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: ClipRRect(
        borderRadius: AppRadius.roundedXXL,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundImage: listing.ownerAvatar != null ? CachedNetworkImageProvider(listing.ownerAvatar!) : null,
                      child: listing.ownerAvatar == null ? const Icon(Icons.person, size: 16) : null,
                    ),
                    const SizedBox(width: 10),
                    Text(listing.ownerUsername ?? 'Trader', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const Spacer(),
                    const Icon(Icons.more_horiz, color: Colors.grey, size: 20),
                  ],
                ),
              ),
              
              // Image Area
              GestureDetector(
                onDoubleTap: () {
                  AppHaptics.feedback(FeedbackType.heavy);
                  setState(() => _showHeart = true);
                },
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      listing.imageUrl != null 
                        ? CachedNetworkImage(imageUrl: listing.imageUrl!, fit: BoxFit.cover) 
                        : Container(color: Colors.grey[900]),
                      
                      HeartAnimation(
                        isVisible: _showHeart,
                        onCompleted: () => setState(() => _showHeart = false),
                      ),
                    ],
                  ),
                ),
              ),

              // Action Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  children: [
                    IconButton(icon: const Icon(Icons.favorite_border_rounded, size: 26), onPressed: () => _showActionHint('Like')),
                    IconButton(icon: const Icon(Icons.chat_bubble_outline_rounded, size: 24), onPressed: () => _showActionHint('Comment')),
                    IconButton(icon: const Icon(Icons.send_rounded, size: 24), onPressed: () => _showActionHint('Share')),
                    const Spacer(),
                    IconButton(icon: const Icon(Icons.bookmark_border_rounded, size: 26), onPressed: () => _showActionHint('Save')),
                  ],
                ),
              ),

              // Info
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: RichText(
                            text: TextSpan(
                              style: Theme.of(context).textTheme.bodyMedium,
                              children: [
                                TextSpan(
                                  text: listing.ownerUsername ?? 'Trader',
                                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
                                ),
                                const TextSpan(text: '  '),
                                TextSpan(
                                  text: listing.title,
                                  style: TextStyle(
                                    color: isDark ? Colors.white.withOpacity(0.9) : Colors.black87,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
                        borderRadius: AppRadius.roundedSM,
                      ),
                      child: Text(
                        listing.category.toUpperCase(),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle, TextTheme textTheme) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
            Text(subtitle, style: textTheme.bodySmall?.copyWith(color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildStoryBar() {
    final stories = Story.getMockStories();
    return SizedBox(
      height: 110,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: stories.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: StoryCircle(
              story: stories[index],
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => StoryViewScreen(stories: stories, initialIndex: index),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
