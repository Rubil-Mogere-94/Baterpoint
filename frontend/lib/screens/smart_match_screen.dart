import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_vibrate/flutter_vibrate.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../constants/ui_constants.dart';
import '../widgets/modern_button.dart';
import '../models/match.dart' as model;
import '../services/listing_service.dart';

class SmartMatchScreen extends StatefulWidget {
  const SmartMatchScreen({super.key});

  @override
  State<SmartMatchScreen> createState() => _SmartMatchScreenState();
}

class _SmartMatchScreenState extends State<SmartMatchScreen> {
  final ListingService _listingService = ListingService();
  List<model.Match> _matches = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchMatches();
  }

  Future<void> _fetchMatches() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final matches = await _listingService.fetchSmartMatches();
      if (mounted) {
        setState(() {
          _matches = matches;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Stack(
        children: [
          // Background Gradient blobs for premium feel
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colorScheme.primary.withValues(alpha: 0.05),
              ),
            ).animate().fadeIn(duration: 1000.ms).scale(begin: const Offset(0.8, 0.8)),
          ),
          
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverAppBar(
                expandedHeight: 140,
                floating: false,
                pinned: true,
                stretch: true,
                backgroundColor: colorScheme.surface.withValues(alpha: 0.8),
                flexibleSpace: FlexibleSpaceBar(
                  stretchModes: const [StretchMode.blurBackground, StretchMode.zoomBackground],
                  titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
                  title: Text(
                    'Smart Matches',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: colorScheme.onSurface,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                actions: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: IconButton(
                      icon: const Icon(Icons.refresh_rounded),
                      onPressed: _fetchMatches,
                    ),
                  ),
                ],
              ),
              
              if (_isLoading)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: colorScheme.primary.withValues(alpha: 0.1), width: 2),
                              ),
                            ),
                            ...List.generate(3, (index) => 
                              Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: colorScheme.primary.withValues(alpha: 0.1),
                                ),
                              ).animate(onPlay: (controller) => controller.repeat())
                               .scale(begin: const Offset(0.5, 0.5), end: const Offset(1.5, 1.5), duration: (2000 + index * 400).ms, curve: Curves.easeOut)
                               .fadeIn(duration: 500.ms)
                               .fadeOut(delay: 1500.ms, duration: 500.ms)
                            ),
                            Icon(Icons.auto_awesome_rounded, size: 40, color: colorScheme.primary)
                                .animate(onPlay: (controller) => controller.repeat())
                                .shimmer(duration: 2000.ms),
                          ],
                        ),
                        const SizedBox(height: 32),
                        Text(
                          'Scanning for perfect trades...',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary,
                          ),
                        ).animate(onPlay: (controller) => controller.repeat(reverse: true))
                         .fadeIn(duration: 800.ms),
                        const SizedBox(height: 8),
                        Text(
                          'Our AI is analyzing thousands of items',
                          style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                )
              else if (_errorMessage != null)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline_rounded, size: 48, color: colorScheme.error),
                        const SizedBox(height: 16),
                        Text('Something went wrong', style: theme.textTheme.titleMedium),
                        const SizedBox(height: 8),
                        Text(_errorMessage!, style: theme.textTheme.bodySmall),
                        const SizedBox(height: 24),
                        ModernButton(text: 'Retry', onPressed: _fetchMatches),
                      ],
                    ),
                  ),
                )
              else if (_matches.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(40),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.auto_awesome_rounded, size: 64, color: colorScheme.primary.withValues(alpha: 0.2)),
                          const SizedBox(height: 24),
                          Text('No matches yet', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 12),
                          Text(
                            'Try favoriting more items or adding your own listings to find perfect trade opportunities.',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    child: ClipRRect(
                      borderRadius: AppRadius.roundedXL,
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                colorScheme.primary.withValues(alpha: 0.9), 
                                colorScheme.secondary.withValues(alpha: 0.8)
                              ],
                            ),
                            borderRadius: AppRadius.roundedXL,
                            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                            boxShadow: [
                              BoxShadow(
                                color: colorScheme.primary.withValues(alpha: 0.3),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.stars_rounded, color: Colors.white, size: 28)
                                  .animate(onPlay: (controller) => controller.repeat())
                                  .shimmer(duration: 2000.ms),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Elite Matching Active",
                                      style: theme.textTheme.titleSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      "Analyzing ${ _matches.length} high-probability trades specifically for you.",
                                      style: theme.textTheme.bodySmall?.copyWith(color: Colors.white.withValues(alpha: 0.9)),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ).animate().slideY(begin: 0.1, end: 0, duration: 600.ms, curve: Curves.easeOutCubic).fadeIn(),
                  ),
                ),

                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      return _buildPremiumMatchCard(context, _matches[index], index);
                    },
                    childCount: _matches.length,
                  ),
                ),
              ],
              
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumMatchCard(BuildContext context, model.Match match, int index) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isHighScore = match.matchScore >= 90;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Stack(
        children: [
          if (isHighScore)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: AppRadius.roundedXXL,
                  border: Border.all(color: colorScheme.secondary.withValues(alpha: 0.4), width: 2),
                ),
              ).animate(onPlay: (controller) => controller.repeat(reverse: true))
               .blur(begin: const Offset(0, 0), end: const Offset(4, 4), duration: 1500.ms)
               .fadeIn(duration: 1500.ms),
            ),
          
          ClipRRect(
            borderRadius: AppRadius.roundedXXL,
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                decoration: BoxDecoration(
                  color: colorScheme.surface.withValues(alpha: 0.7),
                  borderRadius: AppRadius.roundedXXL,
                  border: Border.all(
                    color: isHighScore 
                        ? colorScheme.secondary.withValues(alpha: 0.3) 
                        : colorScheme.primary.withValues(alpha: 0.1), 
                    width: 1.5
                  ),
                ),
                child: Column(
                  children: [
                    // Header with Match Score
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          _buildScoreBadge(match.matchScore, colorScheme, theme),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              match.reason,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurface,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const Divider(height: 1, indent: 20, endIndent: 20),
                    
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildMatchItem(match.userItem.title, match.userItem.imageUrl, "Your Item", colorScheme, theme),
                          
                          Column(
                            children: [
                              Icon(
                                isHighScore ? Icons.bolt_rounded : Icons.swap_horizontal_circle_rounded, 
                                size: 40, 
                                color: isHighScore ? colorScheme.secondary : colorScheme.primary
                              ).animate(onPlay: (controller) => controller.repeat())
                               .shimmer(duration: 2000.ms, color: Colors.white.withValues(alpha: 0.5)),
                              const SizedBox(height: 4),
                              Container(
                                height: 2,
                                width: 30,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: isHighScore 
                                      ? [colorScheme.secondary, colorScheme.primary] 
                                      : [colorScheme.primary, colorScheme.secondary]
                                  ),
                                ),
                              ),
                            ],
                          ),
                          
                          _buildMatchItem(
                            match.targetItem.title, 
                            match.targetItem.imageUrl, 
                            match.partner.username, 
                            colorScheme, 
                            theme,
                            avatarUrl: match.partner.avatarUrl,
                          ),
                        ],
                      ),
                    ),
                    
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                      child: ModernButton(
                        text: 'Negotiate Trade',
                        onPressed: () {
                          Vibrate.feedback(FeedbackType.medium);
                          // Navigation logic would go here
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    ).animate(delay: (index * 150).ms)
     .slideY(begin: 0.3, end: 0, duration: 800.ms, curve: Curves.easeOutQuint)
     .fadeIn(duration: 800.ms);
  }

  Widget _buildMatchItem(String title, String? imageUrl, String subtitle, ColorScheme colorScheme, ThemeData theme, {String? avatarUrl}) {
    return Expanded(
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [colorScheme.surfaceContainerHighest, colorScheme.surface],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.shadow.withValues(alpha: 0.1),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: ClipOval(
                    child: imageUrl != null 
                      ? CachedNetworkImage(
                          imageUrl: imageUrl, 
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(color: colorScheme.surfaceContainerHighest),
                        )
                      : Container(color: colorScheme.primaryContainer),
                  ),
                ),
              ),
              if (avatarUrl != null)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      shape: BoxShape.circle,
                      boxShadow: AppShadows.soft,
                    ),
                    child: CircleAvatar(
                      radius: 14,
                      backgroundImage: CachedNetworkImageProvider(avatarUrl),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w900, letterSpacing: -0.2),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            subtitle.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.primary, 
              fontWeight: FontWeight.w900,
              fontSize: 9,
              letterSpacing: 1.0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreBadge(int score, ColorScheme colorScheme, ThemeData theme) {
    final isHighScore = score >= 90;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: (isHighScore ? colorScheme.secondary : colorScheme.primary).withValues(alpha: 0.1),
        borderRadius: AppRadius.roundedSM,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isHighScore ? Icons.bolt_rounded : Icons.flash_on_rounded, 
            size: 14, 
            color: isHighScore ? colorScheme.secondary : colorScheme.primary
          ),
          const SizedBox(width: 4),
          Text(
            '$score% MATCH',
            style: theme.textTheme.labelSmall?.copyWith(
              color: isHighScore ? colorScheme.secondary : colorScheme.primary,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchCardPlaceholder() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Container(
        height: 250,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: AppRadius.roundedXXL,
        ),
      ),
    );
  }
}
