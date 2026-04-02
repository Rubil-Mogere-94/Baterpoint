import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../utils/app_haptics.dart';
import '../../../constants.dart';

class Categories extends StatefulWidget {
  final Function(String) onCategorySelected;
  const Categories({super.key, required this.onCategorySelected});

  @override
  State<Categories> createState() => _CategoriesState();
}

const _categoryData = [
  {"label": "All Trades", "icon": Icons.grid_view_rounded},
  {"label": "Electronics", "icon": Icons.devices_rounded},
  {"label": "Furniture", "icon": Icons.chair_rounded},
  {"label": "Vehicles", "icon": Icons.directions_car_rounded},
  {"label": "Services", "icon": Icons.handshake_rounded},
];

class _CategoriesState extends State<Categories> {
  int selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: kDefaultPaddin),
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
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
        margin: const EdgeInsets.only(right: 10),
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 16 : 14,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          color: isSelected
              ? kPrimaryColor.withValues(alpha: 0.25)
              : kSurfaceColor.withValues(alpha: 0.5),
          border: Border.all(
            color: isSelected
                ? kPrimaryColor.withValues(alpha: 0.8)
                : Colors.white.withValues(alpha: 0.07),
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: kGlowColor.withValues(alpha: 0.35),
                    blurRadius: 12,
                    spreadRadius: 0,
                  )
                ]
              : [],
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
                fontWeight:
                    isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? kTextColor : kTextLightColor,
              ),
            ),
          ],
        ),
      )
          .animate(key: ValueKey(index))
          .fadeIn(delay: (index * 60).ms, duration: 300.ms)
          .slideX(begin: 0.2, end: 0, curve: Curves.easeOutCubic),
    );
  }
}
