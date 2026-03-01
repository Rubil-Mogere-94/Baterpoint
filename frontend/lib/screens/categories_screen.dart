import 'package:flutter/material.dart';

class CategoriesScreen extends StatelessWidget {
  CategoriesScreen({super.key});

  // Example list spanning various e-commerce and trade categories
  final List<Map<String, dynamic>> _categories = [
    {'name': 'Electronics', 'icon': Icons.devices_rounded, 'color': Colors.blue},
    {'name': 'Vehicles', 'icon': Icons.directions_car_rounded, 'color': Colors.red},
    {'name': 'Real Estate', 'icon': Icons.house_rounded, 'color': Colors.brown},
    {'name': 'Fashion', 'icon': Icons.checkroom_rounded, 'color': Colors.pink},
    {'name': 'Home & Garden', 'icon': Icons.deck_rounded, 'color': Colors.green},
    {'name': 'Sports & Outdoors', 'icon': Icons.sports_basketball_rounded, 'color': Colors.orange},
    {'name': 'Toys & Games', 'icon': Icons.toys_rounded, 'color': Colors.purple},
    {'name': 'Collectibles', 'icon': Icons.diamond_rounded, 'color': Colors.amber},
    {'name': 'Books & Media', 'icon': Icons.menu_book_rounded, 'color': Colors.teal},
    {'name': 'Services', 'icon': Icons.handyman_rounded, 'color': Colors.indigo},
    {'name': 'Pet Supplies', 'icon': Icons.pets_rounded, 'color': Colors.cyan},
    {'name': 'Other', 'icon': Icons.category_rounded, 'color': Colors.grey},
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('All Categories'),
        centerTitle: true,
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 0.85,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final Color bgColor = category['color'];
          
          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                // In a future update, this would navigate to a filtered ExploreScreen
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Browsing ${category['name']} coming soon!')),
                );
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: theme.dividerColor.withOpacity(0.5)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: bgColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        category['icon'],
                        color: bgColor,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        category['name'],
                        textAlign: TextAlign.center,
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
