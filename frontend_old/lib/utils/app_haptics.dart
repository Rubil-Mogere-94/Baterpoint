import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_vibrate/flutter_vibrate.dart';

class AppHaptics {
  /// Provides haptic feedback safely, ignoring unsupported platforms like Linux/Windows.
  static void feedback(FeedbackType type) {
    if (kIsWeb) return;
    if (Platform.isAndroid || Platform.isIOS) {
      Vibrate.feedback(type);
    }
  }

  static void light() => feedback(FeedbackType.light);
  static void medium() => feedback(FeedbackType.medium);
  static void heavy() => feedback(FeedbackType.heavy);
  static void selection() => feedback(FeedbackType.selection);
}
