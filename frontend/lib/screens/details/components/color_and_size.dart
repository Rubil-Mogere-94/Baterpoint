import 'package:flutter/material.dart';
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
    {"label": "Excellent", "color": Color(0xFF10B981)},
    {"label": "Good", "color": Color(0xFF3B82F6)},
    {"label": "Fair", "color": Color(0xFFF59E0B)},
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Condition chips header
        Row(
          children: [
            Text(
              "Condition",
              style: Theme.of(context)
                  .textTheme
                  .titleSmall!
                  .copyWith(fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            Text(
              "${_selectedCondition + 1}/${_conditions.length}",
              style: TextStyle(
                color: kTextLightColor,
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: List.generate(_conditions.length, (i) {
            final label = _conditions[i]["label"] as String;
            final color = _conditions[i]["color"] as Color;
            final isSelected = _selectedCondition == i;
            return GestureDetector(
              onTap: () => setState(() => _selectedCondition = i),
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? color.withValues(alpha: 0.12)
                      : kCardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? color.withValues(alpha: 0.5)
                        : kBorderColor,
                    width: isSelected ? 2 : 1,
                  ),
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
              ),
            );
          }),
        ),
        const SizedBox(height: 24),
        // Tags
        Row(
          children: [
            Text(
              "Tags",
              style: Theme.of(context)
                  .textTheme
                  .titleSmall!
                  .copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _tagsForProduct(widget.product)
              .map(
                (tag) => Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: kSurfaceColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: kBorderColor),
                  ),
                  child: Text(
                    tag,
                    style: const TextStyle(
                        color: kTextLightColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w500),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  List<String> _tagsForProduct(Product product) {
    final tags = <String>[];
    if (product.acceptsBarter) tags.add("Barter");
    if (product.acceptsCurrency) tags.add("Sale");
    if (product.barterPreference != null) tags.add("Trade Wanted");
    tags.add("Verified");
    return tags;
  }
}