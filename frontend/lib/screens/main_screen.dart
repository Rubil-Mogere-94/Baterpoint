import 'package:flutter/material.dart';
import 'dart:ui';
import '../constants/ui_constants.dart';
import '../widgets/holographic_background.dart';

import 'smart_match_screen.dart';
import 'explore_screen.dart';
import 'home_screen.dart';
import 'inbox_screen.dart';
import 'forum_screen.dart';
import 'offers_screen.dart';
import 'profile_screen.dart';

import 'package:flutter_vibrate/flutter_vibrate.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const HomeScreen(),
    const SmartMatchScreen(),
    const ExploreScreen(),
    const InboxScreen(),
    const ForumScreen(),
    const OffersScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return HolographicBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent, // Let holographic background show through
        extendBody: true, // Allows the body to flow behind the bottom nav
        body: IndexedStack(
          index: _selectedIndex,
          children: _pages,
        ),
        bottomNavigationBar: SafeArea(
          child: Container(
            margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            height: 72,
            decoration: BoxDecoration(
              color: colorScheme.surface.withOpacity(0.65), // Increased transparency for bottom nav
              borderRadius: AppRadius.roundedXXL,
              border: Border.all(color: Colors.white.withOpacity(0.2)),
              boxShadow: AppShadows.medium,
            ),
            child: ClipRRect(
              borderRadius: AppRadius.roundedXXL,
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildNavItem(0, Icons.home_rounded, Icons.home_outlined, 'Home'),
                      _buildNavItem(1, Icons.auto_awesome_rounded, Icons.auto_awesome_outlined, 'Matches'),
                      _buildNavItem(2, Icons.explore_rounded, Icons.explore_outlined, 'Explore'),
                      _buildNavItem(3, Icons.chat_bubble_rounded, Icons.chat_bubble_outline_rounded, 'Inbox'),
                      _buildNavItem(4, Icons.forum_rounded, Icons.forum_outlined, 'Forum'),
                      _buildNavItem(5, Icons.local_offer_rounded, Icons.local_offer_outlined, 'Offers'),
                      _buildNavItem(6, Icons.person_rounded, Icons.person_outline_rounded, 'Profile'),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData activeIcon, IconData inactiveIcon, String label) {
    final isSelected = _selectedIndex == index;
    final colorScheme = Theme.of(context).colorScheme;

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          Vibrate.feedback(FeedbackType.selection);
          setState(() => _selectedIndex = index);
        },
        child: AnimatedContainer(
          duration: AppAnimations.fast,
          curve: AppAnimations.curve,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  AnimatedContainer(
                    duration: AppAnimations.fast,
                    width: isSelected ? 40 : 0,
                    height: isSelected ? 40 : 0,
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                      boxShadow: isSelected ? [
                        BoxShadow(
                          color: colorScheme.primary.withOpacity(0.2),
                          blurRadius: 10,
                          spreadRadius: 2,
                        )
                      ] : [],
                    ),
                  ),
                  Icon(
                    isSelected ? activeIcon : inactiveIcon,
                    color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant.withOpacity(0.5),
                    size: isSelected ? 24 : 22,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                  color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant.withOpacity(0.5),
                  letterSpacing: isSelected ? 0.2 : 0,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
