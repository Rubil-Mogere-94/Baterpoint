import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../constants/ui_constants.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _currentIndex = 0;
  final CarouselSliderController _controller = CarouselSliderController();

  final List<Map<String, String>> onboardingData = [
    {
      'title': 'Trade the Future',
      'description': 'Exchange your unneeded items for things you actually want. Sustainable, simple, secure.',
      'image': 'https://images.unsplash.com/photo-1542291026-7eec264c27ff?q=80&w=2070&auto=format&fit=crop',
    },
    {
      'title': 'Curated Excellence',
      'description': 'Discover premium, authenticated items from a community of trusted traders.',
      'image': 'https://images.unsplash.com/photo-1556906781-9a412961c28c?q=80&w=1974&auto=format&fit=crop', // Premium sneakers/streetwear vibe
    },
    {
      'title': 'Zero Compromise',
      'description': 'Elevate your lifestyle without the retail markup. Join the exclusive trading network.',
      'image': 'https://images.unsplash.com/photo-1511512578047-dfb367046420?q=80&w=2071&auto=format&fit=crop', // Gaming/Tech vibe
    },
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: Colors.black, // Force black background to ensure images blend perfectly
      body: Stack(
        children: [
          CarouselSlider(
            carouselController: _controller,
            options: CarouselOptions(
              height: MediaQuery.of(context).size.height,
              viewportFraction: 1.0,
              enlargeCenterPage: false,
              enableInfiniteScroll: false,
              onPageChanged: (index, reason) {
                setState(() {
                  _currentIndex = index;
                });
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
                          Colors.black.withOpacity(0.2), 
                          BlendMode.darken
                        ),
                      ),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withOpacity(0.1),
                            Colors.black.withOpacity(0.4),
                            Colors.black.withOpacity(0.95),
                          ],
                          stops: const [0.0, 0.5, 1.0],
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 48.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            data['title']!,
                            style: theme.textTheme.displayMedium?.copyWith(
                              color: Colors.white,
                              letterSpacing: -1.0,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            data['description']!,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: Colors.white.withOpacity(0.85),
                              fontWeight: FontWeight.w400,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 140), // Space for bottom controls
                        ],
                      ),
                    ),
                  );
                },
              );
            }).toList(),
          ),
          
          // Bottom Controls Layer
          Positioned(
            bottom: 48,
            left: 24,
            right: 24,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Pagination Indicator
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: onboardingData.asMap().entries.map((entry) {
                    return GestureDetector(
                      onTap: () => _controller.animateToPage(entry.key),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOutCubic,
                        width: _currentIndex == entry.key ? 32.0 : 8.0,
                        height: 8.0,
                        margin: const EdgeInsets.symmetric(horizontal: 4.0),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4.0),
                          color: _currentIndex == entry.key
                              ? Colors.white
                              : Colors.white.withOpacity(0.3),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 32),
                
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
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                      ),
                      child: const Text(
                        'Enter Baterpoint', 
                        style: TextStyle(
                          fontWeight: FontWeight.w800, 
                          fontSize: 16,
                          letterSpacing: 0.5,
                        )
                      ),
                    ),
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
                          foregroundColor: Colors.white.withOpacity(0.7),
                        ),
                        child: const Text('Skip', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                      ),
                      IconButton(
                        onPressed: () => _controller.nextPage(
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.easeInOutCubic,
                        ),
                        icon: const Icon(Icons.arrow_forward_rounded, color: Colors.black),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white,
                          padding: const EdgeInsets.all(16),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
