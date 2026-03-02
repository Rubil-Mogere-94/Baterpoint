import 'package:flutter/material.dart';

class AppPadding {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
}

class AppRadius {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 24.0;
  static const double xxl = 32.0;
  
  static BorderRadius roundedXS = BorderRadius.circular(xs);
  static BorderRadius roundedSM = BorderRadius.circular(sm);
  static BorderRadius roundedMD = BorderRadius.circular(md);
  static BorderRadius roundedLG = BorderRadius.circular(lg);
  static BorderRadius roundedXL = BorderRadius.circular(xl);
  static BorderRadius roundedXXL = BorderRadius.circular(xxl);
}

class AppShadows {
  static List<BoxShadow> soft = [
    BoxShadow(
      color: Colors.black.withOpacity(0.03),
      blurRadius: 10,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> medium = [
    BoxShadow(
      color: Colors.black.withOpacity(0.08),
      blurRadius: 20,
      offset: const Offset(0, 10),
    ),
  ];

  static List<BoxShadow> glass = [
    BoxShadow(
      color: Colors.black.withOpacity(0.1),
      blurRadius: 25,
      spreadRadius: -5,
    ),
  ];
}

class AppAnimations {
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration medium = Duration(milliseconds: 400);
  static const Duration slow = Duration(milliseconds: 800);
  
  static const Curve curve = Curves.easeInOutQuart;
}
