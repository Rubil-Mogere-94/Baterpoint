import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:page_transition/page_transition.dart';
import 'package:flutter_vibrate/flutter_vibrate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:ui';
import '../models/listing.dart';
import '../providers/auth_provider.dart';
import 'package:provider/provider.dart';
import '../screens/listing_detail_screen.dart';
import '../constants/ui_constants.dart';
import '../constants/theme.dart';

class ListingCard extends StatelessWidget {
  final Listing listing;

  const ListingCard({super.key, required this.listing});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.04) : Colors.white.withOpacity(0.8),
        borderRadius: AppRadius.roundedXL,
        boxShadow: isDark ? [] : AppShadows.soft,
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.12) : theme.colorScheme.outline.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: AppRadius.roundedXL,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
            onTap: () async {
              Vibrate.feedback(FeedbackType.light);
              await Navigator.push(
                context,
                PageTransition(
                  type: PageTransitionType.fade,
                  child: ListingDetailScreen(listing: listing),
                ),
              );
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 12,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: Hero(
                          tag: 'listing_image_${listing.id}',
                          child: listing.imageUrl != null
                              ? CachedNetworkImage(
                                  imageUrl: listing.imageUrl!,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Container(
                                    color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
                                  ),
                                  errorWidget: (context, url, error) => Container(
                                    color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
                                    child: Icon(Icons.broken_image_rounded, color: colorScheme.onSurfaceVariant.withOpacity(0.3)),
                                  ),
                                )
                              : Container(
                                  color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
                                  child: Icon(Icons.image_not_supported_rounded, color: colorScheme.onSurfaceVariant.withOpacity(0.3)),
                                ),
                        ),
                      ),
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withOpacity(0.02),
                                Colors.transparent,
                                Colors.black.withOpacity(0.2),
                              ],
                              stops: const [0.0, 0.6, 1.0],
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 10,
                        right: 10,
                        child: ClipRRect(
                          borderRadius: AppRadius.roundedSM,
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.white.withOpacity(0.25),
                                    Colors.white.withOpacity(0.05),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: AppRadius.roundedSM,
                                border: Border.all(color: Colors.white.withOpacity(0.3)),
                              ),
                              child: Text(
                                listing.category.toUpperCase(),
                                style: textTheme.labelSmall?.copyWith(
                                  fontSize: 8,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: 1.2,
                                  shadows: [
                                    Shadow(color: Colors.black.withOpacity(0.2), blurRadius: 4, offset: const Offset(0, 2)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ).animate().fadeIn(delay: 400.ms).slideX(begin: 0.2),
                      Positioned(
                        bottom: 8,
                        left: 8,
                        child: Consumer<AuthProvider>(
                          builder: (context, auth, _) {
                            if (!auth.isAuthenticated) return const SizedBox.shrink();
                            final isFavorite = auth.favoriteIds.contains(listing.id);
                            return GestureDetector(
                              onTap: () {
                                auth.toggleFavorite(listing.id);
                              },
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.25),
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white.withOpacity(0.3)),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.1),
                                          blurRadius: 4,
                                        )
                                      ],
                                    ),
                                    child: Icon(
                                      isFavorite ? Icons.favorite_rounded : Icons.favorite_outline_rounded,
                                      color: isFavorite ? const Color(0xFFEF4444) : Colors.white,
                                      size: 18,
                                    ).animate(target: isFavorite ? 1 : 0)
                                     .scale(begin: const Offset(1, 1), end: const Offset(1.3, 1.3), duration: 200.ms, curve: Curves.easeOutBack)
                                     .then().scale(begin: const Offset(1.3, 1.3), end: const Offset(1, 1), duration: 150.ms),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 9,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          listing.title,
                          style: textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: colorScheme.onSurface,
                            fontSize: 14,
                            height: 1.2,
                            letterSpacing: -0.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const Spacer(),
                        if (listing.cashPrice != null && listing.cashPrice! > 0)
                          Text(
                            '\$${listing.cashPrice}',
                            style: textTheme.titleMedium?.copyWith(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.8,
                            ),
                          ),
                        if (listing.exchangeItem != null && listing.exchangeItem!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.swap_horiz_rounded, size: 14, color: AppColors.secondary),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  listing.exchangeItem!,
                                  style: textTheme.labelSmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant.withOpacity(0.7),
                                    fontWeight: FontWeight.w700,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(1.5),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: colorScheme.primary.withOpacity(0.08)),
                              ),
                              child: CircleAvatar(
                                radius: 10,
                                backgroundColor: colorScheme.surfaceContainerHighest,
                                backgroundImage: listing.ownerAvatar != null 
                                  ? CachedNetworkImageProvider(listing.ownerAvatar!)
                                  : null,
                                child: listing.ownerAvatar == null
                                  ? Text(
                                      (listing.ownerUsername ?? 'U')[0].toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 8,
                                        fontWeight: FontWeight.w900,
                                        color: colorScheme.primary,
                                      ),
                                    )
                                  : null,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                listing.ownerUsername ?? 'Trader',
                                style: textTheme.labelSmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const Icon(Icons.star_rounded, size: 12, color: Colors.amber),
                            const SizedBox(width: 2),
                            Text(
                              listing.ownerRating.toStringAsFixed(1),
                              style: textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w900, fontSize: 10),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, curve: Curves.easeOutQuad);
  }
}
