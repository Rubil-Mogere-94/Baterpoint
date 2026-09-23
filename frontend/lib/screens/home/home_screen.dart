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
  // int _carouselIndex = 0;

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
        title: const Text('Baterpoint'),
        centerTitle: true,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.shopping_cart_rounded),
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
                    // Greeting
                    Text(
                      "Welcome Back",
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall!
                          .copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Discover trades you'll love",
                      style: Theme.of(context)
                          .textTheme
                          .bodyLarge!
                          .copyWith(color: kTextLightColor),
                    ),
                    const SizedBox(height: 20),
                    // Featured Carousel (Server-Driven)
                    if (config.showFeaturedCarousel) ...[
                      _buildFeaturedCarousel(),
                      const SizedBox(height: 24),
                    ],
                    // Categories header
                    Text(
                      "Categories",
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge!
                          .copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),
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
                    const SizedBox(height: 24),
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
                    const SizedBox(height: 16),
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
                          crossAxisCount: 2,
                          mainAxisSpacing: kDefaultPadding,
                          crossAxisSpacing: kDefaultPadding,
                          childAspectRatio: 0.72,
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
        height: 160,
        autoPlay: true,
        enlargeCenterPage: true,
        autoPlayCurve: Curves.easeInOut,
        enableInfiniteScroll: true,
        autoPlayAnimationDuration: const Duration(milliseconds: 600),
        viewportFraction: 0.88,
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
                Icon(Icons.compare_arrows_rounded,
                    color: Colors.white, size: 28),
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