import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/story.dart';

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
              boxShadow: story.isUnseen ? [
                BoxShadow(color: const Color(0xFFE1306C).withOpacity(0.3), blurRadius: 10, spreadRadius: 1),
              ] : [],
            ),
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: story.isUnseen
                    ? const LinearGradient(
                        colors: [
                          Color(0xFF833AB4),
                          Color(0xFFF77737),
                          Color(0xFFE1306C),
                          Color(0xFF833AB4),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : LinearGradient(
                        colors: [
                          colorScheme.outline.withOpacity(0.2),
                          colorScheme.outline.withOpacity(0.2),
                        ],
                      ),
              ),
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: Colors.black,
                  shape: BoxShape.circle,
                ),
                child: CircleAvatar(
                  radius: 30,
                  backgroundImage: CachedNetworkImageProvider(story.avatarUrl),
                  backgroundColor: colorScheme.surface,
                ),
              ),
            ).animate(onPlay: (controller) => controller.repeat(), target: story.isUnseen ? 1 : 0)
             .rotate(duration: 3.seconds, curve: Curves.linear),
          ),
          const SizedBox(height: 8),
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
    ).animate().scale(
      begin: const Offset(0.9, 0.9),
      duration: 400.ms,
      curve: Curves.easeOutBack,
    );
  }
}
