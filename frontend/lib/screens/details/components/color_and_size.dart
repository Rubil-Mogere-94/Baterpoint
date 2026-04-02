import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../constants.dart';
import '../../../models/product.dart';

class ColorAndSize extends StatefulWidget {
  const ColorAndSize({super.key, required this.product});
  final Product product;

  @override
  State<ColorAndSize> createState() => _ColorAndSizeState();
}

class _ColorAndSizeState extends State<ColorAndSize> {
  int _selectedCondition = 0;

  static const _conditions = [
    {"label": "Excellent", "color": kBarterColor},
    {"label": "Good", "color": kCurrencyColor},
    {"label": "Fair", "color": Color(0xFFFFC107)},
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Condition chips
        const Text(
          "Condition",
          style: TextStyle(color: kTextLightColor, fontSize: 13),
        ),
        const SizedBox(height: 8),
        Row(
          children: List.generate(_conditions.length, (i) {
            final label = _conditions[i]["label"] as String;
            final color = _conditions[i]["color"] as Color;
            final isSelected = _selectedCondition == i;
            return GestureDetector(
              onTap: () => setState(() => _selectedCondition = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.only(right: 10),
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: isSelected
                      ? color.withValues(alpha: 0.2)
                      : kSurfaceColor.withValues(alpha: 0.6),
                  border: Border.all(
                    color: isSelected
                        ? color.withValues(alpha: 0.85)
                        : Colors.white.withValues(alpha: 0.08),
                    width: 1.5,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                              color: color.withValues(alpha: 0.3),
                              blurRadius: 10)
                        ]
                      : [],
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? color : kTextLightColor,
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.normal,
                    fontSize: 13,
                  ),
                ),
              ).animate().fadeIn(delay: (i * 80).ms),
            );
          }),
        ),

        const SizedBox(height: 16),

        // Trade category tags
        const Text(
          "Category Tags",
          style: TextStyle(color: kTextLightColor, fontSize: 13),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: _tagsForProduct(widget.product)
              .asMap()
              .entries
              .map(
                (entry) => Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: kPrimaryColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: kPrimaryColor.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    entry.value,
                    style: const TextStyle(
                        color: kPrimaryColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w600),
                  ),
                ).animate().fadeIn(delay: (entry.key * 60).ms),
              )
              .toList(),
        ),
      ],
    );
  }

  List<String> _tagsForProduct(Product product) {
    final tags = <String>[];
    if (product.acceptsBarter) tags.add("Barter OK");
    if (product.acceptsCurrency) tags.add("Buy Now");
    if (product.barterPreference != null) tags.add("Trade Wanted");
    tags.add("Verified");
    return tags;
  }
}
