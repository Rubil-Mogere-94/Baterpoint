import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../constants/ui_constants.dart';


class SmartMatchScreen extends StatefulWidget {
  const SmartMatchScreen({super.key});

  @override
  State<SmartMatchScreen> createState() => _SmartMatchScreenState();
}

class _SmartMatchScreenState extends State<SmartMatchScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<Map<String, dynamic>> _matches = [
    {
      'match_score': 98,
      'user_item': {'title': 'Vintage Camera', 'image': 'https://images.unsplash.com/photo-1516035069371-29a1b244cc32?q=80&w=1000'},
      'target_item': {'title': 'Electric Guitar', 'image': 'https://images.unsplash.com/photo-1550985543-f4423c9d7481?q=80&w=1000'},
      'partner': {'name': 'Alex', 'avatar': 'https://i.pravatar.cc/150?u=30', 'distance': '2.5 km'},
      'reason': 'Alex is looking for a Camera and has the Guitar you want.',
    },
    {
      'match_score': 85,
      'user_item': {'title': 'Mountain Bike', 'image': 'https://images.unsplash.com/photo-1576435728678-38d01d52e38b?q=80&w=1000'},
      'target_item': {'title': 'Gaming Console', 'image': 'https://images.unsplash.com/photo-1605901309584-818e25960b8f?q=80&w=1000'},
      'partner': {'name': 'Sarah', 'avatar': 'https://i.pravatar.cc/150?u=42', 'distance': '5.0 km'},
      'reason': 'High demand match in your area.',
    },
    {
      'match_score': 72,
      'user_item': {'title': 'Headphones', 'image': 'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?q=80&w=1000'},
      'target_item': {'title': 'Smart Watch', 'image': 'https://images.unsplash.com/photo-1523275335684-37898b6baf30?q=80&w=1000'},
      'partner': {'name': 'Mike', 'avatar': 'https://i.pravatar.cc/150?u=12', 'distance': '1.2 km'},
      'reason': 'Similar value items.',
    },
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            backgroundColor: colorScheme.surface,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
              title: Text(
                'Smart Matches',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: colorScheme.onSurface,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                    colors: [
                      colorScheme.primary.withOpacity(0.05),
                      colorScheme.surface,
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              Container(
                margin: const EdgeInsets.only(right: 16),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
                  borderRadius: AppRadius.roundedLG,
                ),
                child: IconButton(
                  icon: const Icon(Icons.tune_rounded),
                  onPressed: () {},
                ),
              ),
            ],
          ),
          
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(0.08),
                  borderRadius: AppRadius.roundedXL,
                  border: Border.all(color: colorScheme.primary.withOpacity(0.1)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.auto_awesome, color: colorScheme.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "We found ${ _matches.length} perfect trade opportunities based on your wishlist.",
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final match = _matches[index];
                return _buildMatchCard(context, match, index);
              },
              childCount: _matches.length,
            ),
          ),
          
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildMatchCard(BuildContext context, Map<String, dynamic> match, int index) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _controller,
            curve: Interval(index * 0.1, 1.0, curve: Curves.easeOutQuint),
          ),
        ),
        child: FadeTransition(
          opacity: Tween<double>(begin: 0, end: 1).animate(
            CurvedAnimation(
              parent: _controller,
              curve: Interval(index * 0.1, 1.0, curve: Curves.easeOut),
            ),
          ),
          child: Container(
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: AppRadius.roundedXXL,
              boxShadow: AppShadows.medium,
              border: Border.all(color: colorScheme.outline.withOpacity(0.05)),
            ),
            child: Column(
              children: [
                // Header with Match Score
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [colorScheme.primary, colorScheme.secondary],
                          ),
                          borderRadius: AppRadius.roundedSM,
                        ),
                        child: Text(
                          '${match['match_score']}% MATCH',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          match['reason'],
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      // Your Item
                      Expanded(
                        child: Column(
                          children: [
                            Text('YOU HAVE', style: theme.textTheme.labelSmall?.copyWith(color: colorScheme.outline)),
                            const SizedBox(height: 8),
                            _buildItemCircle(match['user_item']['image'], colorScheme),
                            const SizedBox(height: 8),
                            Text(
                              match['user_item']['title'],
                              style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                      
                      // Connector
                      SizedBox(
                        width: 60,
                        child: Column(
                          children: [
                            Icon(Icons.swap_horiz_rounded, size: 32, color: colorScheme.primary.withOpacity(0.5)),
                          ],
                        ),
                      ),
                      
                      // Their Item
                      Expanded(
                        child: Column(
                          children: [
                            Text('THEY HAVE', style: theme.textTheme.labelSmall?.copyWith(color: colorScheme.outline)),
                            const SizedBox(height: 8),
                            Stack(
                              clipBehavior: Clip.none,
                              children: [
                                _buildItemCircle(match['target_item']['image'], colorScheme),
                                Positioned(
                                  bottom: -5,
                                  right: -5,
                                  child: Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: BoxDecoration(
                                      color: colorScheme.surface,
                                      shape: BoxShape.circle,
                                    ),
                                    child: CircleAvatar(
                                      radius: 12,
                                      backgroundImage: CachedNetworkImageProvider(match['partner']['avatar']),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              match['target_item']['title'],
                              style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: Colors.white,
                        shadowColor: colorScheme.primary.withOpacity(0.4),
                        elevation: 4,
                      ),
                      child: const Text('Start Trade'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildItemCircle(String imageUrl, ColorScheme colorScheme) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(color: colorScheme.surface, width: 3),
      ),
      child: ClipOval(
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(color: colorScheme.surfaceContainerHighest),
        ),
      ),
    );
  }
}
