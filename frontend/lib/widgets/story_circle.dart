import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/story.dart';
import '../constants/ui_constants.dart';

class StoryCircle extends StatelessWidget {
  final Story story;
  final VoidCallback? onTap;

  const StoryCircle({
    super.key,
    required this.story,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: story.isUnseen
                  ? const LinearGradient(
                      colors: [
                        Color(0xFF833AB4), // Purple
                        Color(0xFFF77737), // Orange
                        Color(0xFFE1306C), // Pink
                      ],
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                    )
                  : LinearGradient(
                      colors: [
                        colorScheme.outline.withOpacity(0.2),
                        colorScheme.outline.withOpacity(0.2),
                      ],
                    ),
            ),
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: const BoxDecoration(
                color: Colors.black, // Dark mode background
                shape: BoxShape.circle,
              ),
              child: CircleAvatar(
                radius: 30,
                backgroundImage: CachedNetworkImageProvider(story.avatarUrl),
                backgroundColor: colorScheme.surface,
              ),
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: 75,
            child: Text(
              story.username,
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 11,
                fontWeight: story.isUnseen ? FontWeight.bold : FontWeight.normal,
                color: story.isUnseen ? colorScheme.onSurface : colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
