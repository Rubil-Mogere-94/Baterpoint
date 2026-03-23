import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../utils/app_haptics.dart';


import '../../../constants.dart';

// We need satefull widget for our categories

class Categories extends StatefulWidget {
  final Function(String) onCategorySelected;
  const Categories({super.key, required this.onCategorySelected});

  @override
  State<Categories> createState() => _CategoriesState();
}


class _CategoriesState extends State<Categories> {
  List<String> categories = ["All Trades", "Electronics", "Furniture", "Vehicles", "Services"];
  // By default our first item will be selected
  int selectedIndex = 0;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: kDefaultPaddin),
      child: SizedBox(
        height: 25,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: categories.length,
          itemBuilder: (context, index) => buildCategory(index),
        ),
      ),
    );
  }

  Widget buildCategory(int index) {
    return GestureDetector(
      onTap: () {
        AppHaptics.light();
        setState(() {
          selectedIndex = index;
        });
        widget.onCategorySelected(categories[index]);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: kDefaultPaddin),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              categories[index],
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: selectedIndex == index ? kTextColor : kTextLightColor,
              ),
            ),
            if (selectedIndex == index) 
              Container(
                margin: const EdgeInsets.only(
                  top: kDefaultPaddin / 8,
                ), //top padding 5
                height: 2,
                width: 30,
                color: kPrimaryColor,
              ).animate().fadeIn().moveX(begin: -10, end: 0, curve: Curves.easeOutBack)
            else 
              const SizedBox(height: 2 + kDefaultPaddin / 8),

          ],
        ),
      ),
    );
  }
}
