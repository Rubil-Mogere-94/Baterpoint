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
      'title': 'Eco-Friendly Focus',
      'description': 'Every trade saves CO2. Track your environmental impact straight from your dashboard.',
      'image': 'https://images.unsplash.com/photo-1542601906990-b4d3fb778b09?q=80&w=2013&auto=format&fit=crop',
    },
    {
      'title': 'Awesome Rewards',
      'description': 'Earn tokens for trading, use them in the loyalty shop, and become a Baterpoint VIP.',
      'image': 'https://images.unsplash.com/photo-1511512578047-dfb367046420?q=80&w=2071&auto=format&fit=crop',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
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
                      ),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.4),
                            Colors.black.withOpacity(0.9),
                          ],
                          stops: const [0.0, 0.4, 1.0],
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 48.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            data['title']!,
                            style: theme.textTheme.displaySmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              height: 1.1,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            data['description']!,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: Colors.white.withOpacity(0.8),
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 120),
                        ],
                      ),
                    ),
                  );
                },
              );
            }).toList(),
          ),
          
          Positioned(
            bottom: 48,
            left: 24,
            right: 24,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: onboardingData.asMap().entries.map((entry) {
                    return GestureDetector(
                      onTap: () => _controller.animateToPage(entry.key),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: _currentIndex == entry.key ? 24.0 : 8.0,
                        height: 8.0,
                        margin: const EdgeInsets.symmetric(horizontal: 4.0),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4.0),
                          color: _currentIndex == entry.key
                              ? theme.colorScheme.primary
                              : Colors.white.withOpacity(0.5),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                if (_currentIndex == onboardingData.length - 1)
                  ElevatedButton(
                    onPressed: () {
                      context.read<AuthProvider>().completeOnboarding();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                    child: const Text('Get Started', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  )
                else
                  IconButton(
                    onPressed: () => _controller.nextPage(),
                    icon: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.2),
                      padding: const EdgeInsets.all(16),
                    ),
                  ),
              ],
            ),
          ),
          
          if (_currentIndex < onboardingData.length - 1)
            Positioned(
              top: 60,
              right: 24,
              child: TextButton(
                onPressed: () {
                  context.read<AuthProvider>().completeOnboarding();
                },
                child: const Text(
                  'Skip',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
