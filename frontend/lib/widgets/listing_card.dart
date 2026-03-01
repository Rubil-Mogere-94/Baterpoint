import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/listing.dart';
import '../providers/auth_provider.dart';
import '../screens/listing_detail_screen.dart';

class ListingCard extends StatelessWidget {
  final Listing listing;

  const ListingCard({super.key, required this.listing});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.5)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ListingDetailScreen(listing: listing),
                ),
              );
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
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
                                    color: colorScheme.surfaceContainerHighest,
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: colorScheme.primary,
                                      ),
                                    ),
                                  ),
                                  errorWidget: (context, url, error) => Container(
                                    color: colorScheme.surfaceContainerHighest,
                                    child: Icon(Icons.broken_image, color: colorScheme.onSurfaceVariant),
                                  ),
                                )
                              : Container(
                                  color: colorScheme.surfaceContainerHighest,
                                  child: Icon(Icons.image_not_supported, color: colorScheme.onSurfaceVariant),
                                ),
                        ),
                      ),
                      // Gradient overlay
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.2),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 12,
                        right: 12,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.white.withOpacity(0.2)),
                              ),
                              child: Text(
                                listing.category.toUpperCase(),
                                style: textTheme.labelSmall?.copyWith(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 12,
                        left: 12,
                        child: Consumer<AuthProvider>(
                          builder: (context, auth, _) {
                            if (!auth.isAuthenticated) return const SizedBox.shrink();
                            final isFavorite = auth.favoriteIds.contains(listing.id);
                            return GestureDetector(
                              onTap: () {
                                auth.toggleFavorite(listing.id);
                              },
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.25),
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                                    ),
                                    child: Icon(
                                      isFavorite ? Icons.favorite_rounded : Icons.favorite_outline_rounded,
                                      color: isFavorite ? const Color(0xFFEF4444) : Colors.white,
                                      size: 20,
                                    ),
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
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        listing.title,
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      if (listing.cashPrice != null && listing.cashPrice! > 0)
                        Text(
                          '\$${listing.cashPrice}',
                          style: textTheme.titleLarge?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                      if (listing.exchangeItem != null && listing.exchangeItem!.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(Icons.swap_horiz_rounded, size: 16, color: colorScheme.secondary),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                listing.exchangeItem!,
                                style: textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(1),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: colorScheme.primary.withOpacity(0.2)),
                            ),
                            child: CircleAvatar(
                              radius: 12,
                              backgroundColor: colorScheme.surfaceContainerHighest,
                              backgroundImage: listing.ownerAvatar != null 
                                ? CachedNetworkImageProvider(listing.ownerAvatar!)
                                : null,
                              child: listing.ownerAvatar == null
                                ? Text(
                                    (listing.ownerUsername ?? 'U')[0].toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: colorScheme.primary,
                                    ),
                                  )
                                : null,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              listing.ownerUsername ?? 'Unknown',
                              style: textTheme.labelMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Icon(Icons.star_rounded, size: 14, color: Colors.amber.shade500),
                          const SizedBox(width: 2),
                          Text(
                            listing.ownerRating.toStringAsFixed(1),
                            style: textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
