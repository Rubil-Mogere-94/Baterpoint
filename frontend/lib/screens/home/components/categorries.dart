import 'package:flutter/material.dart';
import '../../../utils/app_haptics.dart';
import '../../../constants.dart';

class Categories extends StatefulWidget {
  final Function(String) onCategorySelected;
  const Categories({super.key, required this.onCategorySelected});

  @override
  State<Categories> createState() => _CategoriesState();
}

const _categoryData = [
  {"label": "All", "icon": Icons.grid_view_rounded},
  {"label": "Electronics", "icon": Icons.devices_rounded},
  {"label": "Furniture", "icon": Icons.chair_rounded},
  {"label": "Vehicles", "icon": Icons.directions_car_rounded},
  {"label": "Services", "icon": Icons.handshake_rounded},
];class _CategoriesState extends State<Categories> {
  int selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 0),
        itemCount: _categoryData.length,
        itemBuilder: (context, index) => _buildChip(index),
      ),
    );
  }

  Widget _buildChip(int index) {
    final isSelected = selectedIndex == index;
    final label = _categoryData[index]["label"] as String;
    final icon = _categoryData[index]["icon"] as IconData;

    return GestureDetector(
      onTap: () {
        AppHaptics.light();
        setState(() => selectedIndex = index);
        widget.onCategorySelected(label);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 8),
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 20 : 14,
          vertical: isSelected ? 8 : 6,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: isSelected
              ? kPrimaryColor.withValues(alpha: 0.12)
              : kCardColor,
          border: Border.all(
            color: isSelected
                ? kPrimaryColor.withValues(alpha: 0.5)
                : kBorderColor,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? kPrimaryColor : kTextLightColor,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? kPrimaryColor : kTextLightColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}