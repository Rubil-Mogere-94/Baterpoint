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
        // Condition selector header
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
        // Tags/Badges
        Row(
          children: [
            Text(
              "Details",
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
          children: _buildProductTags(),
        ),
        const SizedBox(height: 16),
        // Trust signals
        Row(
          children: [
            Text(
              "Trust & Safety",
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
          children: _buildTrustSignals(),
        ),
      ],
    );
  }

  List<Widget> _buildProductTags() {
    final List<String> tags = [];
    if (product.acceptsBarter) tags.add("Barter OK");
    if (product.acceptsCurrency) tags.add("Buy Now");
    if (product.condition != null && product.condition!.isNotEmpty)
      tags.add(product.condition!);
    if (product.reviewCount > 0) tags.add("${product.reviewCount} reviews");
    tags.add("Verified");

    return tags
        .map((tag) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
        ))
        .toList();
  }

  List<Widget> _buildTrustSignals() {
    final List<Widget> signals = [];
    signals.add(
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: kSurfaceColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: kBorderColor),
        ),
        child: const Row(
          children: [
            Icon(Icons.check_circle_rounded,
                color: Color(0xFF10B981), size: 16),
            SizedBox(width: 8),
            Text("Identity Verified",
                style: TextStyle(color: kTextColor, fontSize: 12)),
          ],
        ),
      ),
    );

    signals.add(
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: kSurfaceColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: kBorderColor),
        ),
        child: const Row(
          children: [
            Icon(Icons.shield_rounded,
                color: kPrimaryColor, size: 16),
            SizedBox(width: 8),
            Text("Secure Trade",
                style: TextStyle(color: kTextColor, fontSize: 12)),
          ],
        ),
      ),
    );

    signals.add(
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: kSurfaceColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: kBorderColor),
        ),
        child: const Row(
          children: [
            Icon(Icons.history_rounded,
                color: kTextLightColor, size: 16),
            SizedBox(width: 8),
            Text("Member since 2024",
                style: TextStyle(color: kTextColor, fontSize: 12)),
          ],
        ),
      ),
    );

    return signals;
  }
}