import 'package:flutter/material.dart';
import '../../constants.dart';
import '../../models/product.dart';
import '../details/details_screen.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'components/categorries.dart';
import 'components/item_card.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';
import '../../services/app_config_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _apiService = ApiService();
  late Future<List<Product>> _productsFuture;

  @override
  void initState() {
    super.initState();
    _productsFuture = _apiService.getListings();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppConfigProvider>().fetchConfig(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    final config = context.watch<AppConfigProvider>();

    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [kPrimaryColor, kBarterColor],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.compare_arrows_rounded,
                  color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            const Text('Baterpoint'),
          ],
        ),
        centerTitle: true,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: kSurfaceColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.search_rounded),
            ),
            onPressed: () {},
          ),
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: kSurfaceColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.shopping_cart_rounded),
            ),
            onPressed: () {},
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {
            _productsFuture = _apiService.getListings();
          });
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.all(kDefaultPadding),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Hero Section
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            kPrimaryColor,
                            kPrimaryColor.withValues(alpha: 0.85),
                            kBarterColor.withValues(alpha: 0.7),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: kPrimaryColor.withValues(alpha: 0.3),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.auto_awesome,
                                    color: Colors.white, size: 20),
                              ),
                              const SizedBox(width: 10),
                              const Text(
                                "Trade Smarter",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Barter items, find deals, and trade with confidence.",
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.95),
                              fontSize: 12,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _ActionButton(
                                  icon: Icons.add_circle_outline,
                                  label: "List Item",
                                  onTap: () {},
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _ActionButton(
                                  icon: Icons.auto_awesome,
                                  label: "AI Valuator",
                                  onTap: () {},
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Stats Row - compact
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: kSurfaceColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: kBorderColor),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _StatItem(
                            icon: Icons.swap_horiz_rounded,
                            value: "2.4k",
                            label: "Trades",
                          ),
                          _StatItem(
                            icon: Icons.people_rounded,
                            value: "1.8k",
                            label: "Traders",
                          ),
                          _StatItem(
                            icon: Icons.check_circle_rounded,
                            value: "98%",
                            label: "Success",
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Featured Carousel (Server-Driven)
                    if (config.showFeaturedCarousel) ...[
                      _buildFeaturedCarousel(),
                      const SizedBox(height: 16),
                    ],
                    // Categories header
                    Text(
                      "Categories",
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge!
                          .copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Categories(
                      onCategorySelected: (category) {
                        setState(() {
                          _productsFuture = _apiService.getListings(
                            category:
                                category == "All Trades" ? null : category,
                          );
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    // Listings header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Available Trades",
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge!
                              .copyWith(fontWeight: FontWeight.w600),
                        ),
                        TextButton(
                          onPressed: () {},
                          child: const Text("See All"),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: kDefaultPadding),
              sliver: SliverToBoxAdapter(
                child: FutureBuilder<List<Product>>(
                  future: _productsFuture,
                  builder: (context, snapshot) {
                    bool isLoading =
                        snapshot.connectionState == ConnectionState.waiting;

                    if (snapshot.hasError) {
                      return Padding(
                        padding: const EdgeInsets.all(40),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline,
                                color: kErrorColor, size: 48),
                            const SizedBox(height: 16),
                            Text('Failed to load trades',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium),
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: () => setState(() =>
                                  _productsFuture = _apiService.getListings()),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      );
                    }

                    final productsList =
                        isLoading ? List.generate(6, (index) => Product(
                              id: index,
                              title: "Loading Item",
                              description: "Loading...",
                              price: 0,
                              size: 0,
                              image: "assets/images/placeholder.png",
                              color: kPrimaryColor.withValues(alpha: 0.2),
                            ))
                            : snapshot.data ?? [];

                    if (!isLoading && productsList.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.all(40),
                        child: Column(
                          children: [
                            Icon(Icons.inventory_2_rounded,
                                color: kTextLightColor, size: 48),
                            const SizedBox(height: 12),
                            Text('No trades found.',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyLarge),
                            const SizedBox(height: 8),
                            const Text(
                              'Be the first to list an item!',
                              style: TextStyle(
                                color: kTextLightColor,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return Skeletonizer(
                      enabled: isLoading,
                      child: GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: productsList.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
                          childAspectRatio: 0.6,
                        ),
                        itemBuilder: (context, index) => ItemCard(
                          product: productsList[index],
                          press: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DetailsScreen(
                                product: productsList[index],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturedCarousel() {
    return CarouselSlider(
      options: CarouselOptions(
        height: 140,
        autoPlay: true,
        enlargeCenterPage: true,
        autoPlayCurve: Curves.easeInOut,
        enableInfiniteScroll: true,
        autoPlayAnimationDuration: const Duration(milliseconds: 600),
        viewportFraction: 0.85,
        onPageChanged: (index, reason) {},
      ),
      items: [
        _buildFeaturedCard(
          "🔥 Hot Electronics",
          "Trade your old phone for a MacBook Pro",
          kPrimaryColor,
        ),
        _buildFeaturedCard(
          "✨ Trending Furniture",
          "Minimalist pieces available now",
          kSecondaryColor,
        ),
        _buildFeaturedCard(
          "🚗 Vehicle Swap",
          "Find your next ride through barter",
          kBarterColor,
        ),
      ],
    );
  }

  Widget _buildFeaturedCard(String title, String subtitle, Color color) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color,
            color.withValues(alpha: 0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.15),
              ),
            ),
          ),
          Positioned(
            right: 16,
            bottom: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                "Explore",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.compare_arrows_rounded,
                      color: Colors.white, size: 28),
                ),
                const SizedBox(height: 12),
                Text(title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    )),
                const SizedBox(height: 4),
                Text(subtitle,
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 20),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: kPrimaryColor,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: kPrimaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: kPrimaryColor, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: kTextColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: kTextLightColor,
          ),
        ),
      ],
    );
  }
}