#!/usr/bin/env python3
"""Apply a focused Barter Point Flutter UI refresh.

Run from the repository root, or pass the repository path as the first argument:
  python3 /path/to/apply_baterpoint_ui_patch.py [repo-root]

Creates timestamped backups before changing files. It changes presentation only:
brand colors, product cards, KES price display, and catalog grid breakpoints.
"""
from __future__ import annotations

import re
import shutil
import sys
from datetime import datetime
from pathlib import Path

ROOT = Path(sys.argv[1]).expanduser().resolve() if len(sys.argv) > 1 else Path.cwd().resolve()
FRONTEND = ROOT / "frontend" / "lib"

if not (ROOT / ".git").exists() or not (FRONTEND / "main.dart").is_file():
    raise SystemExit(
        f"Could not find a Baterpoint checkout at {ROOT}.\n"
        "Run from ~/Documents/Baterpoint or pass that path as an argument."
    )

files = {
    "constants.dart": FRONTEND / "constants.dart",
    "item_card.dart": FRONTEND / "screens/home/components/item_card.dart",
    "home_screen.dart": FRONTEND / "screens/home/home_screen.dart",
    "details_screen.dart": FRONTEND / "screens/details/details_screen.dart",
    "add_to_cart.dart": FRONTEND / "screens/details/components/add_to_cart.dart",
    "cart_screen.dart": FRONTEND / "screens/cart/cart_screen.dart",
    "create_listing_screen.dart": FRONTEND / "screens/listing/create_listing_screen.dart",
}

missing = [str(path.relative_to(ROOT)) for path in files.values() if not path.is_file()]
if missing:
    raise SystemExit("Required source files are missing:\n  - " + "\n  - ".join(missing))

original = {name: path.read_text(encoding="utf-8") for name, path in files.items()}
updated = dict(original)

# 1. Cohesive marketplace palette + one shared Kenyan-shilling formatter.
constants = original["constants.dart"]
if "String formatKes(" in constants:
    raise SystemExit("The shared KES formatter already exists. This patch may already be applied.")
updated["constants.dart"] = '''import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// Barter Point design system: calm, trustworthy greens with a warm cash accent.
const kTextColor = Color(0xFF182823);
const kTextLightColor = Color(0xFF64736D);
const kBackgroundColor = Color(0xFFF5F8F5);
const kPrimaryColor = Color(0xFF176B57);
const kSecondaryColor = Color(0xFF2F9B72);
const kBarterColor = Color(0xFF167A68);
const kCurrencyColor = Color(0xFF9A620D);
const kErrorColor = Color(0xFFB42318);
const kMessageColor = Color(0xFF218B70);

// Surface and divider tokens used across the Flutter app.
const kSurfaceColor = Color(0xFFFFFFFF);
const kCardColor = Color(0xFFFFFFFF);
const kBorderColor = Color(0xFFE0E8E2);
const kDividerColor = Color(0xFFEBF0EC);

const kDefaultPadding = 16.0
const kBaseUrl = "http://localhost:8000"
const kApiV1 = "/api/v1"

/// Formats marketplace prices using Kenyan shillings consistently.
String formatKes(num amount) => 'KSh ${NumberFormat('#,##0.##', 'en_KE').format(amount)}';
'''

# 2. Replace the compressed catalogue card with a clearer, responsive card.
updated["item_card.dart"] = r'''import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../constants.dart';
import '../../../models/product.dart'
import '../../../utils/app_haptics.dart'

class ItemCard extends StatelessWidget {
  const ItemCard({super.key, required this.product, required this.press})

  final Product product
  final VoidCallback press

  @override
  Widget build(BuildContext context) {
    final tradeLabel = product.acceptsBarter && product.acceptsCurrency
        ? 'BARTER + CASH'
        : product.acceptsBarter
            ? 'BARTER'
            : 'CASH'
    final tradeColor = product.acceptsBarter ? kBarterColor : kCurrencyColor

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      color: kSurfaceColor,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: kBorderColor),
      ),
      child: InkWell(
        onTap: () {
          AppHaptics.light()
          press()
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _productImage(),
                  Positioned(
                    top: 9,
                    left: 9,
                    right: 9,
                    child: Row(
                      children: [
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.96),
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(color: kBorderColor.withValues(alpha: 0.8)),
                            ),
                            child: Text(
                              tradeLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: tradeColor,
                                fontSize: 9,
                                letterSpacing: 0.35,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                        if (product.rating > 0) ...[
                          const SizedBox(width: 5),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.96),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.star_rounded, color: Color(0xFFE1A323), size: 13),
                                const SizedBox(width: 2),
                                Text(
                                  product.rating.toStringAsFixed(1),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: kTextColor,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(11, 10, 11, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      product.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: kTextColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        height: 1.22,
                      ),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            product.acceptsCurrency
                                ? formatKes(product.price)
                                : 'Open to exchange',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: product.acceptsCurrency ? kTextColor : kBarterColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          product.acceptsBarter && product.acceptsCurrency
                              ? Icons.swap_horiz_rounded
                              : product.acceptsBarter
                                  ? Icons.handshake_outlined
                                  : Icons.arrow_outward_rounded,
                          size: 16,
                          color: tradeColor,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    )
  }

  Widget _productImage() {
    final fallback = Container(
      color: kBackgroundColor,
      alignment: Alignment.center,
      child: const Icon(Icons.image_outlined, color: kTextLightColor, size: 34),
    )

    if (product.image.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: product.image,
        fit: BoxFit.cover,
        placeholder: (_, __) => Container(
          color: kBackgroundColor,
          alignment: Alignment.center,
          child: const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
        errorWidget: (_, __, ___) => fallback,
      )
    }

    return Image.asset(
      product.image,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => fallback,
    )
  }
}
'''

# Helper for safe, explicit replacements.
def replace_once(text: str, old: str, new: str, label: str) -> str:
    count = text.count(old)
    if count != 1:
        raise RuntimeError(f"Expected exactly one anchor in {label}, found {count}: {old!r}")
    return text.replace(old, new, 1)

# 3. Make the marketplace usable on phones and localise prices to KES.
home = updated["home_screen.dart"]
home = replace_once(
    home,
    "crossAxisCount: MediaQuery.sizeOf(context).width < 380\n                              ? 2\n                              : MediaQuery.sizeOf(context).width < 760\n                                  ? 3\n                                  : 4,",
    "crossAxisCount: MediaQuery.sizeOf(context).width < 600\n                              ? 2\n                              : MediaQuery.sizeOf(context).width < 1000\n                                  ? 3\n                                  : 4,",
    "home_screen.dart responsive grid",
)
home = replace_once(home, "childAspectRatio: 0.68,", "childAspectRatio: 0.62,", "home_screen.dart card ratio")
home = replace_once(
    home,
    "? Text('\\$${product.price}', style: const TextStyle(fontWeight: FontWeight.w600))",
    "? Text(formatKes(product.price), style: const TextStyle(fontWeight: FontWeight.w700, color: kTextColor))",
    "home_screen.dart search result price",
)
updated["home_screen.dart"] = home

# 4. Details, cart, offers, and listing forms all use one consistent KES format.
details = updated["details_screen.dart"]
details = replace_once(details, "'\\$${product.price}',", "formatKes(product.price),", "details_screen.dart price")
updated["details_screen.dart"] = details

add_to_cart = updated["add_to_cart.dart"]
add_to_cart = replace_once(
    add_to_cart,
    "decoration: const InputDecoration(labelText: 'Cash offer (optional)', prefixText: '\\$ '),",
    "decoration: const InputDecoration(labelText: 'Cash offer (optional)', prefixText: 'KSh '),",
    "add_to_cart.dart offer currency",
)
add_to_cart = replace_once(
    add_to_cart,
    r"label: 'Add · \$${product.price}',",
    "label: 'Add · ${formatKes(product.price)}',",
    "add_to_cart.dart add button price",
)
updated["add_to_cart.dart"] = add_to_cart

cart = updated["cart_screen.dart"]
cart = replace_once(
    cart,
    "subtitle: Text('$quantity × \\$${price.toStringAsFixed(2)}'),",
    "subtitle: Text('$quantity × ${formatKes(price)}'),",
    "cart_screen.dart item price",
)
cart = replace_once(
    cart,
    "Text('\$${total.toStringAsFixed(2)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),",
    "Text(formatKes(total), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: kTextColor)),",
    "cart_screen.dart subtotal",
)
updated["cart_screen.dart"] = cart

listing = updated["create_listing_screen.dart"]
listing = replace_once(
    listing,
    "decoration: const InputDecoration(labelText: 'Cash price', prefixText: '\\$ ', helperText: 'Use the currency configured for your marketplace.'),",
    "decoration: const InputDecoration(labelText: 'Cash price (KES)', prefixText: 'KSh ', helperText: 'Enter the amount in Kenyan shillings.'),",
    "create_listing_screen.dart price field",
)
updated["create_listing_screen.dart"] = listing

# Ensure all intended modifications really differ before touching the checkout.
changes = [name for name in files if updated[name] != original[name]]
if not changes:
    raise SystemExit("No changes were produced; the patch may already be applied.")

backup_dir = Path.home() / ".cache" / "baterpoint-ui-patch-backups" / f"ui-refresh-{datetime.now().strftime('%Y%m%d-%H%M%S')}"
backup_dir.mkdir(parents=True, exist_ok=False)
for name in changes:
    target = files[name]
    backup_target = backup_dir / target.relative_to(ROOT)
    backup_target.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(target, backup_target)

try:
    for name in changes:
        files[name].write_text(updated[name], encoding="utf-8")
except Exception:
    # Restore any already-written files if an unexpected filesystem error occurs.
    for name in changes:
        backup_target = backup_dir / files[name].relative_to(ROOT)
        if backup_target.exists():
            shutil.copy2(backup_target, files[name])
    raise

print("Barter Point UI refresh applied successfully.\n")
print("Changed files:")
for name in changes:
    print(f"  - {files[name].relative_to(ROOT)}")
print(f"\nBackups saved outside the repo to: {backup_dir}")
print("\nNext steps:")
print("  cd frontend")
print("  dart format lib/constants.dart lib/screens/home/components/item_card.dart lib/screens/home/home_screen.dart lib/screens/details/details_screen.dart lib/screens/details/components/add_to_cart.dart lib/screens/cart/cart_screen.dart lib/screens/listing/create_listing_screen.dart")
print("  flutter analyze")
print("  flutter run -d linux")