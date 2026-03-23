import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:ui';
import '../providers/auth_provider.dart';
import '../constants/theme.dart';
import '../widgets/holographic_background.dart';


class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  final CarouselSliderController _controller = CarouselSliderController();

  final List<Map<String, dynamic>> onboardingData = [
    {
      'title': 'Trade the Future',
      'description': 'Exchange your unneeded items for things you actually want. Sustainable, simple, secure.',
      'image': 'https://images.unsplash.com/photo-1542291026-7eec264c27ff?q=80&w=2070&auto=format&fit=crop',
      'icon': Icons.swap_horiz_rounded,
      'accentColor': Color(0xFF4F46E5),
    },
    {
      'title': 'Curated Excellence',
      'description': 'Discover premium, authenticated items from a community of trusted traders.',
      'image': 'https://images.unsplash.com/photo-1556906781-9a412961c28c?q=80&w=1974&auto=format&fit=crop',
      'icon': Icons.auto_awesome_rounded,
      'accentColor': Color(0xFF10B981),
    },
    {
      'title': 'Zero Compromise',
      'description': 'Elevate your lifestyle without the retail markup. Join the exclusive trading network.',
      'image': 'https://images.unsplash.com/photo-1511512578047-dfb367046420?q=80&w=2071&auto=format&fit=crop',
      'icon': Icons.workspace_premium_rounded,
      'accentColor': Color(0xFFEC4899),
    },
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accentColor = onboardingData[_currentIndex]['accentColor'] as Color;

    return Scaffold(
      backgroundColor: Colors.black,
      body: HolographicBackground(
        child: Stack(
          children: [
            // Fullscreen image carousel
            CarouselSlider(
              carouselController: _controller,
              options: CarouselOptions(
                height: MediaQuery.of(context).size.height,
                viewportFraction: 1.0,
                enlargeCenterPage: false,
                enableInfiniteScroll: false,
                onPageChanged: (index, reason) {
                  setState(() => _currentIndex = index);
                },
              ),
              items: onboardingData.map((data) {
                return Builder(
                  builder: (BuildContext context) {
                    return Container(
                      width: MediaQuery.of(context).size.width,
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: NetworkImage(data['image']!),
                          fit: BoxFit.cover,
                          colorFilter: ColorFilter.mode(
                            Colors.black.withOpacity(0.35),
                            BlendMode.darken,
                          ),
                        ),
                      ),
                    );
                  },
                );
              }).toList(),
            ),

            // Top gradient fade
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 180,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.black54, Colors.transparent],
                  ),
                ),
              ),
            ),

            // Bottom content glass panel
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: ClipRRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                  child: Container(
                    padding: EdgeInsets.fromLTRB(
                      28, 32, 28,
                      MediaQuery.of(context).padding.bottom + 32,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      border: Border(
                        top: BorderSide(color: Colors.white.withOpacity(0.12), width: 1),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Icon badge
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: accentColor.withOpacity(0.2),
                            borderRadius: AppRadius.roundedLG,
                            border: Border.all(color: accentColor.withOpacity(0.4)),
                          ),
                          child: Icon(
                            onboardingData[_currentIndex]['icon'] as IconData,
                            color: accentColor,
                            size: 22,
                          ),
                        ).animate(key: ValueKey(_currentIndex)).scale(begin: const Offset(0.5, 0.5), curve: Curves.easeOutBack, duration: 400.ms),
                        const SizedBox(height: 16),

                        // Title
                        Text(
                          onboardingData[_currentIndex]['title']!,
                          style: theme.textTheme.displayMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -1.0,
                          ),
                        ).animate(key: ValueKey('title_$_currentIndex')).fadeIn(duration: 400.ms).slideY(begin: 0.3, end: 0),

                        const SizedBox(height: 12),

                        // Description
                        Text(
                          onboardingData[_currentIndex]['description']!,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: Colors.white70,
                            fontWeight: FontWeight.w400,
                            height: 1.5,
                          ),
                        ).animate(key: ValueKey('desc_$_currentIndex')).fadeIn(delay: 100.ms, duration: 400.ms).slideY(begin: 0.3, end: 0),

                        const SizedBox(height: 32),

                        // Pagination Dots
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: onboardingData.asMap().entries.map((entry) {
                            final isActive = _currentIndex == entry.key;
                            return GestureDetector(
                              onTap: () => _controller.animateToPage(entry.key),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 350),
                                curve: Curves.easeOutCubic,
                                width: isActive ? 28.0 : 8.0,
                                height: 8.0,
                                margin: const EdgeInsets.symmetric(horizontal: 4.0),
                                decoration: BoxDecoration(
                                  borderRadius: AppRadius.roundedPill,
                                  color: isActive ? accentColor : Colors.white.withOpacity(0.3),
                                  boxShadow: isActive ? [
                                    BoxShadow(
                                      color: accentColor.withOpacity(0.5),
                                      blurRadius: 8,
                                    ),
                                  ] : null,
                                ),
                              ),
                            );
                          }).toList(),
                        ),

                        const SizedBox(height: 24),

                        // Action Buttons
                        if (_currentIndex == onboardingData.length - 1)
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: () {
                                context.read<AuthProvider>().completeOnboarding();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: accentColor,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: AppRadius.roundedPill),
                              ),
                              child: const Text(
                                'Enter Baterpoint',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ).animate().scale(curve: Curves.easeOutBack, duration: 500.ms),
                          )
                        else
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              TextButton(
                                onPressed: () {
                                  context.read<AuthProvider>().completeOnboarding();
                                },
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.white54,
                                ),
                                child: const Text(
                                  'Skip',
                                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                                ),
                              ),
                              GestureDetector(
                                onTap: () => _controller.nextPage(
                                  duration: const Duration(milliseconds: 500),
                                  curve: Curves.easeInOutCubic,
                                ),
                                child: AnimatedContainer(
                                  duration: 300.ms,
                                  padding: const EdgeInsets.all(18),
                                  decoration: BoxDecoration(
                                    color: accentColor,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: accentColor.withOpacity(0.4),
                                        blurRadius: 16,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                  child: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 22),
                                ),
                              ),
                            ],
                          ),
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
}
