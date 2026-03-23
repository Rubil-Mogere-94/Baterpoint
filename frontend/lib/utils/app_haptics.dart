import 'package:flutter/services.dart';
import 'package:flutter_vibrate/flutter_vibrate.dart';

class AppHaptics {
  static Future<void> light() async {
    if (await Vibrate.canVibrate) {
      Vibrate.feedback(FeedbackType.light);
    } else {
      HapticFeedback.lightImpact();
    }
  }

  static Future<void> medium() async {
    if (await Vibrate.canVibrate) {
      Vibrate.feedback(FeedbackType.medium);
    } else {
      HapticFeedback.mediumImpact();
    }
  }

  static Future<void> heavy() async {
    if (await Vibrate.canVibrate) {
      Vibrate.feedback(FeedbackType.heavy);
    } else {
      HapticFeedback.heavyImpact();
    }
  }

  static Future<void> success() async {
    if (await Vibrate.canVibrate) {
      Vibrate.feedback(FeedbackType.success);
    }
  }

  static Future<void> error() async {
    if (await Vibrate.canVibrate) {
      Vibrate.feedback(FeedbackType.error);
    }
  }
}
