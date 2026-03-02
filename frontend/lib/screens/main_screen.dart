import 'package:flutter/material.dart';
import 'dart:ui';
import '../constants/ui_constants.dart';
import 'categories_screen.dart';
import 'explore_screen.dart';
import 'home_screen.dart';
import 'inbox_screen.dart';
import 'offers_screen.dart';
import 'profile_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const HomeScreen(),
    CategoriesScreen(),
    const ExploreScreen(),
    const InboxScreen(),
    const OffersScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
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
            color: colorScheme.surface.withOpacity(0.85),
            borderRadius: AppRadius.roundedXXL,
            border: Border.all(color: Colors.white.withOpacity(0.2)),
            boxShadow: AppShadows.medium,
          ),
          child: ClipRRect(
            borderRadius: AppRadius.roundedXXL,
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildNavItem(0, Icons.home_rounded, Icons.home_outlined, 'Home'),
                    _buildNavItem(1, Icons.grid_view_rounded, Icons.grid_view_outlined, 'Categories'),
                    _buildNavItem(2, Icons.explore_rounded, Icons.explore_outlined, 'Explore'),
                    _buildNavItem(3, Icons.chat_bubble_rounded, Icons.chat_bubble_outline_rounded, 'Inbox'),
                    _buildNavItem(4, Icons.local_offer_rounded, Icons.local_offer_outlined, 'Offers'),
                    _buildNavItem(5, Icons.person_rounded, Icons.person_outline_rounded, 'Profile'),
                  ],
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
        onTap: () => setState(() => _selectedIndex = index),
        child: AnimatedContainer(
          duration: AppAnimations.fast,
          curve: AppAnimations.curve,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: AppAnimations.fast,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isSelected ? colorScheme.primary.withOpacity(0.12) : Colors.transparent,
                  borderRadius: AppRadius.roundedMD,
                ),
                child: Icon(
                  isSelected ? activeIcon : inactiveIcon,
                  color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant.withOpacity(0.6),
                  size: isSelected ? 26 : 24,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                  color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant.withOpacity(0.6),
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
