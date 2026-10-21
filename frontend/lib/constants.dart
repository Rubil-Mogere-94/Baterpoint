import 'package:flutter/material.dart';
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

const kDefaultPadding = 16.0;
const kBaseUrl = "http://localhost:8000";
const kApiV1 = "/api/v1";
const kMockStoreUrl = "https://fake-store-api.mock.beeceptor.com";
const kDummyJsonUrl = "https://dummyjson.com";

/// Formats marketplace prices using Kenyan shillings consistently.
String formatKes(num amount) =>
    'KSh ${NumberFormat('#,##0.##', 'en_KE').format(amount)}';
