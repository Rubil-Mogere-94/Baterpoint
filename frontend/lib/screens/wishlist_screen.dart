import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:ui';
import '../models/listing.dart';
import '../services/listing_service.dart';
import '../widgets/listing_card.dart';
import '../widgets/shimmer_loading.dart';
import '../constants/theme.dart';
import '../widgets/holographic_background.dart';

class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  final ListingService _listingService = ListingService();
  late Future<List<Listing>> _favoritesFuture;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  void _loadFavorites() {
    setState(() {
      _favoritesFuture = _listingService.fetchFavorites();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('My Wishlist', style: TextStyle(fontWeight: FontWeight.w900)),
        centerTitle: true,
      ),
      body: HolographicBackground(
        child: RefreshIndicator(
          onRefresh: () async => _loadFavorites(),
          child: FutureBuilder<List<Listing>>(
            future: _favoritesFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    const SliverToBoxAdapter(child: SizedBox(height: 110)),
                    SliverPadding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      sliver: SliverGrid(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 0.7,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => const ListingCardShimmer(),
                          childCount: 6,
                        ),
                      ),
                    ),
                  ],
                );
              }

              if (snapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: ClipRRect(
                      borderRadius: AppRadius.roundedXXL,
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                        child: Container(
                          padding: const EdgeInsets.all(AppSpacing.xl),
                          decoration: BoxDecoration(
                            color: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
                            borderRadius: AppRadius.roundedXXL,
                            border: Border.all(
                              color: Colors.redAccent.withOpacity(0.2),
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.error_outline_rounded,
                                  size: 52, color: Colors.redAccent),
                              const SizedBox(height: AppSpacing.md),
                              Text(
                                'Something went wrong',
                                style: theme.textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w800),
                              ),
                              const SizedBox(height: AppSpacing.md),
                              ElevatedButton(
                                onPressed: _loadFavorites,
                                child: const Text('Try Again'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: ClipRRect(
                      borderRadius: AppRadius.roundedXXL,
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                        child: Container(
                          padding: const EdgeInsets.all(AppSpacing.xl),
                          decoration: BoxDecoration(
                            color: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
                            borderRadius: AppRadius.roundedXXL,
                            border: Border.all(
                              color: (isDark ? Colors.white : Colors.black).withOpacity(0.08),
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.favorite_border_rounded,
                                size: 72,
                                color: Theme.of(context)
                                    .colorScheme
                                    .secondary
                                    .withOpacity(0.5),
                              ).animate().scale(
                                    curve: Curves.easeOutBack,
                                    duration: 600.ms,
                                  ),
                              const SizedBox(height: AppSpacing.md),
                              Text(
                                'Your wishlist is empty',
                                style: theme.textTheme.titleLarge
                                    ?.copyWith(fontWeight: FontWeight.w800),
                              ).animate().fadeIn(delay: 200.ms),
                              const SizedBox(height: AppSpacing.sm),
                              Text(
                                'Save items you love to see them here.',
                                style: theme.textTheme.bodyMedium
                                    ?.copyWith(color: Colors.grey),
                                textAlign: TextAlign.center,
                              ).animate().fadeIn(delay: 300.ms),
                              const SizedBox(height: AppSpacing.xl),
                              ElevatedButton.icon(
                                onPressed: () => Navigator.pop(context),
                                icon: const Icon(Icons.explore_rounded),
                                label: const Text('Browse Items'),
                              ).animate().fadeIn(delay: 400.ms)
                                  .slideY(begin: 0.2, end: 0, delay: 400.ms),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }

              final favorites = snapshot.data!;
              return CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  const SliverToBoxAdapter(child: SizedBox(height: 110)),

                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    sliver: SliverToBoxAdapter(
                      child: Row(
                        children: [
                          Icon(
                            Icons.favorite_rounded,
                            color: Theme.of(context).colorScheme.secondary,
                            size: 18,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            '${favorites.length} saved item${favorites.length == 1 ? '' : 's'}',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),

                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    sliver: SliverGrid(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.7,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          return ListingCard(listing: favorites[index])
                              .animate()
                              .fadeIn(
                                delay: Duration(milliseconds: 50 + (index * 40)),
                                duration: 400.ms,
                              )
                              .scale(
                                begin: const Offset(0.92, 0.92),
                                end: const Offset(1.0, 1.0),
                                delay: Duration(milliseconds: 50 + (index * 40)),
                                duration: 400.ms,
                                curve: Curves.easeOutBack,
                              );
                        },
                        childCount: favorites.length,
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
