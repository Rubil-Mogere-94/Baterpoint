import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import '../../constants.dart';

import '../../models/product.dart';
import '../details/details_screen.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:carousel_slider/carousel_slider.dart';
import '../../utils/app_haptics.dart';
import 'components/categorries.dart';
import 'dart:ui';


import 'components/item_card.dart';

import '../../services/api_service.dart';

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
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: AppBar(
              backgroundColor: Colors.black.withValues(alpha: 0.1),
              elevation: 0,
              leading: IconButton(
                icon: SvgPicture.asset("assets/icons/back.svg", colorFilter: const ColorFilter.mode(kTextColor, BlendMode.srcIn)),
                onPressed: () {},
              ),
              actions: <Widget>[
                IconButton(
                  icon: SvgPicture.asset(
                    "assets/icons/search.svg",
                    colorFilter: const ColorFilter.mode(kTextColor, BlendMode.srcIn),
                  ),
                  onPressed: () {},
                ),
                IconButton(
                  icon: SvgPicture.asset(
                    "assets/icons/cart.svg",
                    colorFilter: const ColorFilter.mode(kTextColor, BlendMode.srcIn),
                  ),
                  onPressed: () {},
                ),
                const SizedBox(width: kDefaultPaddin / 2)
              ],
            ),
          ),
        ),
      ),

      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: kDefaultPaddin),
            child: Text(
              "Explore Trades",
              style: Theme.of(context)
                  .textTheme
                  .titleLarge!
                  .copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 15),
          CarouselSlider(
            options: CarouselOptions(
              height: 150.0,
              autoPlay: true,
              enlargeCenterPage: true,
              aspectRatio: 16/9,
              autoPlayCurve: Curves.fastOutSlowIn,
              enableInfiniteScroll: true,
              autoPlayAnimationDuration: const Duration(milliseconds: 800),
              viewportFraction: 0.85,
            ),
            items: [
              _buildFeaturedCard("New Electronics Trade", "Trade your old phone for a MacBook Pro", kBarterColor),
              _buildFeaturedCard("Trending Furniture", "Minimalist pieces available now", kPrimaryColor),
            ],
          ),
          Categories(

            onCategorySelected: (category) {
              setState(() {
                _productsFuture = _apiService.getListings(
                  category: category == "All Trades" ? null : category,
                );
              });
            },
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: kDefaultPaddin),
              child: FutureBuilder<List<Product>>(
                future: _productsFuture,
                builder: (context, snapshot) {
                  bool isLoading = snapshot.connectionState == ConnectionState.waiting;
                  
                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline, color: kErrorColor, size: 48),
                          const SizedBox(height: 16),
                          Text('Failed to load trades', style: Theme.of(context).textTheme.titleMedium),
                          TextButton(
                            onPressed: () => setState(() => _productsFuture = _apiService.getListings()),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    );
                  }

                  final productsList = isLoading 
                    ? List.generate(6, (index) => Product(
                        id: index,
                        title: "Loading Item",
                        description: "Loading description...",
                        price: 0,
                        size: 0,
                        image: "assets/images/bag_1.png",
                        color: Colors.grey[800]!,
                      ))
                    : snapshot.data ?? [];

                  if (!isLoading && productsList.isEmpty) {
                    return const Center(child: Text('No trades found.', style: TextStyle(color: kTextLightColor)));
                  }

                  return Skeletonizer(
                    enabled: isLoading,
                    child: RefreshIndicator(
                      onRefresh: () async {
                        AppHaptics.light();
                        setState(() {
                          _productsFuture = _apiService.getListings();
                        });
                      },
                      child: GridView.builder(
                        itemCount: productsList.length,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: kDefaultPaddin,
                          crossAxisSpacing: kDefaultPaddin,
                          childAspectRatio: 0.75,
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
    );
  }

  Widget _buildFeaturedCard(String title, String subtitle, Color color) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.8), color.withValues(alpha: 0.4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            Text(subtitle, style: const TextStyle(color: Colors.white70, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}


