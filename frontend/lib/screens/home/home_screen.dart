import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import '../../constants.dart';
import '../../models/product.dart';
import '../details/details_screen.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:carousel_slider/carousel_slider.dart';
import '../../utils/app_haptics.dart';
import 'components/categorries.dart';
import 'components/item_card.dart';
import '../../services/api_service.dart';
import '../../services/update_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  late Future<List<Product>> _productsFuture;

  // Aurora animation
  late AnimationController _auroraController;
  late Animation<double> _auroraAnim;

  @override
  void initState() {
    super.initState();
    _productsFuture = _apiService.getListings();

    _auroraController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);

    _auroraAnim = CurvedAnimation(
      parent: _auroraController,
      curve: Curves.easeInOut,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      UpdateService.checkForUpdates(context);
    });
  }

  @override
  void dispose() {
    _auroraController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: AppBar(
              backgroundColor: Colors.black.withValues(alpha: 0.15),
              elevation: 0,
              leading: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: kSurfaceColor.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08)),
                ),
                child: IconButton(
                  icon: SvgPicture.asset("assets/icons/back.svg",
                      colorFilter: const ColorFilter.mode(
                          kTextColor, BlendMode.srcIn)),
                  onPressed: () {},
                ),
              ),
              title: const Text(
                'Baterpoint',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  letterSpacing: 0.5,
                ),
              ),
              centerTitle: true,
              actions: [
                _AppBarIconBtn(
                  icon: SvgPicture.asset("assets/icons/search.svg",
                      colorFilter: const ColorFilter.mode(
                          kTextColor, BlendMode.srcIn)),
                  onTap: () {},
                ),
                _AppBarIconBtn(
                  icon: SvgPicture.asset("assets/icons/cart.svg",
                      colorFilter: const ColorFilter.mode(
                          kTextColor, BlendMode.srcIn)),
                  onTap: () {},
                ),
                const SizedBox(width: 8),
              ],
            ),
          ),
        ),
      ),
      body: AnimatedBuilder(
        animation: _auroraAnim,
        builder: (context, child) {
          return Stack(
            children: [
              // Aurora background blobs
              Positioned(
                top: -80,
                left: -60 + (_auroraAnim.value * 40),
                child: _AuroraBlob(
                  color: kPrimaryColor,
                  size: 280,
                  opacity: 0.18 + (_auroraAnim.value * 0.06),
                ),
              ),
              Positioned(
                top: 140,
                right: -80 + (_auroraAnim.value * -30),
                child: _AuroraBlob(
                  color: kGradientAccent,
                  size: 220,
                  opacity: 0.12 + (_auroraAnim.value * 0.05),
                ),
              ),
              Positioned(
                bottom: 200,
                left: 20 + (_auroraAnim.value * 20),
                child: _AuroraBlob(
                  color: kBarterColor,
                  size: 160,
                  opacity: 0.08 + (_auroraAnim.value * 0.04),
                ),
              ),
              // Actual content
              child!,
            ],
          );
        },
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: kDefaultPaddin),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Explore Trades",
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall!
                          .copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "Discover, swap, and trade anything",
                      style: TextStyle(
                          color: kTextLightColor, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Featured Carousel
              CarouselSlider(
                options: CarouselOptions(
                  height: 180.0,
                  autoPlay: true,
                  enlargeCenterPage: true,
                  autoPlayCurve: Curves.fastOutSlowIn,
                  enableInfiniteScroll: true,
                  autoPlayAnimationDuration:
                      const Duration(milliseconds: 800),
                  viewportFraction: 0.88,
                ),
                items: [
                  _buildFeaturedCard(
                    "🔥 Hot Electronics",
                    "Trade your old phone for a MacBook Pro",
                    kPrimaryColor,
                    kGradientAccent,
                    Icons.devices_rounded,
                  ),
                  _buildFeaturedCard(
                    "✨ Trending Furniture",
                    "Minimalist pieces available now",
                    kBarterColor,
                    kAuroraGreen,
                    Icons.chair_rounded,
                  ),
                  _buildFeaturedCard(
                    "🚗 Vehicle Swap",
                    "Find your next ride through barter",
                    kCurrencyColor,
                    kGradientAccent,
                    Icons.directions_car_rounded,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Category chips
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
              const SizedBox(height: 8),
              // Product grid
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: kDefaultPaddin),
                  child: FutureBuilder<List<Product>>(
                    future: _productsFuture,
                    builder: (context, snapshot) {
                      bool isLoading = snapshot.connectionState ==
                          ConnectionState.waiting;

                      if (snapshot.hasError) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error_outline,
                                  color: kErrorColor, size: 48),
                              const SizedBox(height: 16),
                              Text('Failed to load trades',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium),
                              TextButton(
                                onPressed: () => setState(() =>
                                    _productsFuture =
                                        _apiService.getListings()),
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        );
                      }

                      final productsList = isLoading
                          ? List.generate(
                              6,
                              (index) => Product(
                                    id: index,
                                    title: "Loading Item",
                                    description: "Loading...",
                                    price: 0,
                                    size: 0,
                                    image: "assets/images/bag_1.png",
                                    color: kSurfaceColor,
                                  ))
                          : snapshot.data ?? [];

                      if (!isLoading && productsList.isEmpty) {
                        return const Center(
                          child: Text('No trades found.',
                              style:
                                  TextStyle(color: kTextLightColor)),
                        );
                      }

                      return Skeletonizer(
                        enabled: isLoading,
                        child: RefreshIndicator(
                          color: kPrimaryColor,
                          backgroundColor: kSurfaceColor,
                          onRefresh: () async {
                            AppHaptics.light();
                            setState(() {
                              _productsFuture =
                                  _apiService.getListings();
                            });
                          },
                          child: GridView.builder(
                            itemCount: productsList.length,
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: kDefaultPaddin,
                              crossAxisSpacing: kDefaultPaddin,
                              childAspectRatio: 0.8,
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
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeaturedCard(String title, String subtitle,
      Color colorA, Color colorB, IconData icon) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorA.withValues(alpha: 0.85),
            colorB.withValues(alpha: 0.6)
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: colorA.withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          children: [
            // Decorative circle
            Positioned(
              right: -30,
              top: -30,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
            ),
            Positioned(
              right: 20,
              bottom: -20,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.05),
                ),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(22.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon,
                        color: Colors.white, size: 20),
                  ),
                  const Spacer(),
                  Text(title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.2,
                      )),
                  const SizedBox(height: 4),
                  Text(subtitle,
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 12)),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text("Explore",
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600)),
                        SizedBox(width: 4),
                        Icon(Icons.arrow_forward_rounded,
                            color: Colors.white, size: 14),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AppBarIconBtn extends StatelessWidget {
  final Widget icon;
  final VoidCallback onTap;
  const _AppBarIconBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: kSurfaceColor.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
          border:
              Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: icon,
      ),
    );
  }
}

class _AuroraBlob extends StatelessWidget {
  final Color color;
  final double size;
  final double opacity;
  const _AuroraBlob(
      {required this.color, required this.size, required this.opacity});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: opacity),
      ),
      child: ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
        child: Container(color: Colors.transparent),
      ),
    );
  }
}
