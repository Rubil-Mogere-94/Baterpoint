import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/story.dart';
import '../constants/ui_constants.dart';

class StoryViewScreen extends StatefulWidget {
  final List<Story> stories;
  final int initialIndex;

  const StoryViewScreen({
    super.key,
    required this.stories,
    this.initialIndex = 0,
  });

  @override
  State<StoryViewScreen> createState() => _StoryViewScreenState();
}

class _StoryViewScreenState extends State<StoryViewScreen> with SingleTickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _animController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
    _animController = AnimationController(vsync: this);

    _loadStory(story: widget.stories[_currentIndex], animateToPage: false);

    _animController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _animController.stop();
        _animController.reset();
        setState(() {
          if (_currentIndex + 1 < widget.stories.length) {
            _currentIndex += 1;
            _loadStory(story: widget.stories[_currentIndex]);
          } else {
            Navigator.of(context).pop();
          }
        });
      }
    });
  }

  void _loadStory({required Story story, bool animateToPage = true}) {
    _animController.stop();
    _animController.reset();
    _animController.duration = const Duration(seconds: 5);
    _animController.forward();

    if (animateToPage) {
      _pageController.animateToPage(
        _currentIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final story = widget.stories[_currentIndex];

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTapDown: (details) => _onTapDown(details, story),
        onVerticalDragEnd: (details) => Navigator.of(context).pop(),
        child: Stack(
          children: [
            PageView.builder(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.stories.length,
              itemBuilder: (context, index) {
                final s = widget.stories[index];
                return AnimatedBuilder(
                  animation: _pageController,
                  builder: (context, child) {
                    double value = 1.0;
                    if (_pageController.position.haveDimensions) {
                      value = _pageController.page! - index;
                      value = (1 - (value.abs() * 0.1)).clamp(0.0, 1.0);
                    }
                    return Center(
                      child: Transform.scale(
                        scale: value,
                        child: child,
                      ),
                    );
                  },
                  child: CachedNetworkImage(
                    imageUrl: s.contentUrl ?? 'https://picsum.photos/seed/${s.id}/1080/1920',
                    fit: BoxFit.cover,
                    placeholder: (context, url) => const Center(child: CircularProgressIndicator(color: Colors.white24)),
                  ),
                );
              },
            ),
            
            // Progress Bar
            Positioned(
              top: 50,
              left: 10,
              right: 10,
              child: Row(
                children: widget.stories.asMap().entries.map((entry) {
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: _ProgressBar(
                        animController: _animController,
                        position: entry.key,
                        currentIndex: _currentIndex,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
 
            // Header Info
            Positioned(
              top: 70,
              left: 15,
              right: 15,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: Colors.white.withOpacity(0.12)),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 4),
                        CircleAvatar(
                          radius: 16,
                          backgroundImage: CachedNetworkImageProvider(story.avatarUrl),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          story.username,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.5),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '• 2h',
                          style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                        const Spacer(),
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          icon: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                        const SizedBox(width: 4),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onTapDown(TapDownDetails details, Story story) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double dx = details.globalPosition.dx;

    if (dx < screenWidth / 3) {
      setState(() {
        if (_currentIndex - 1 >= 0) {
          _currentIndex -= 1;
          _loadStory(story: widget.stories[_currentIndex]);
        }
      });
    } else if (dx > 2 * screenWidth / 3) {
      setState(() {
        if (_currentIndex + 1 < widget.stories.length) {
          _currentIndex += 1;
          _loadStory(story: widget.stories[_currentIndex]);
        } else {
          Navigator.of(context).pop();
        }
      });
    }
  }
}

class _ProgressBar extends StatelessWidget {
  final AnimationController animController;
  final int position;
  final int currentIndex;

  const _ProgressBar({
    required this.animController,
    required this.position,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            _buildContainer(
              constraints.maxWidth,
              currentIndex > position ? Colors.white : Colors.white.withOpacity(0.3),
            ),
            if (currentIndex == position)
              AnimatedBuilder(
                animation: animController,
                builder: (context, child) {
                  return _buildContainer(
                    constraints.maxWidth * animController.value,
                    Colors.white,
                  );
                },
              ),
          ],
        );
      },
    );
  }

  Container _buildContainer(double width, Color color) {
    return Container(
      height: 3.5,
      width: width,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(3.0),
        boxShadow: color == Colors.white ? [
          BoxShadow(color: Colors.white.withOpacity(0.4), blurRadius: 4, spreadRadius: 1),
        ] : [],
      ),
    );
  }
}
