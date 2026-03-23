import 'package:flutter/material.dart';
import 'dart:ui';
import '../constants/ui_constants.dart';
import '../widgets/holographic_background.dart';

import 'smart_match_screen.dart';
import 'explore_screen.dart';
import 'home_screen.dart';
import 'profile_screen.dart';
import '../widgets/create_listing_modal.dart';

import 'package:flutter_vibrate/flutter_vibrate.dart';
import 'package:baterpoint/utils/app_haptics.dart';

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
    const Center(child: Text('Create Placeholder')), // Center item logic will handle this
    const ExploreScreen(),
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
                      _buildCreateButton(colorScheme),
                      _buildNavItem(3, Icons.explore_rounded, Icons.explore_outlined, 'Explore'),
                      _buildNavItem(4, Icons.person_rounded, Icons.person_outline_rounded, 'Profile'),
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
          AppHaptics.feedback(FeedbackType.selection);
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

  Widget _buildCreateButton(ColorScheme colorScheme) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          AppHaptics.feedback(FeedbackType.medium);
          _showCreateModal(context);
        },
        child: Container(
          height: 48,
          width: 48,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [colorScheme.primary, colorScheme.secondary],
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: colorScheme.primary.withOpacity(0.3),
                blurRadius: 12,
                spreadRadius: 2,
              )
            ],
          ),
          child: const Icon(Icons.add_rounded, color: Colors.white, size: 32),
        ),
      ),
    );
  }

  void _showCreateModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const CreateListingModal(),
    );
  }
}
