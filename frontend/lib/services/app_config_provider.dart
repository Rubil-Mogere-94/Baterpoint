import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../constants.dart';

class AppConfigProvider extends ChangeNotifier {
  static const String _baseUrl = kBaseUrl;
  static const String _v1 = kApiV1;

  Map<String, dynamic> _featureFlags = {
    // Defaults, incase backend is unreachable
    "show_featured_carousel": true,
    "show_aurora_bg": true,
    "enable_ai_valuator": true,
  };

  Map<String, dynamic> get featureFlags => _featureFlags;

  bool get showFeaturedCarousel => _featureFlags["show_featured_carousel"] ?? true;
  bool get showAuroraBg => _featureFlags["show_aurora_bg"] ?? true;
  bool get showHolographicCards => _featureFlags["show_holographic_cards"] ?? false;
  bool get enableAiValuator => _featureFlags["enable_ai_valuator"] ?? false;
  bool get isMaintenanceMode => _featureFlags["maintenance_mode"] ?? false;

  Future<void> fetchConfig(BuildContext context) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl$_v1/config/app_config'));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _featureFlags = data['feature_flags'] ?? _featureFlags;
        
        final bool forceUpdate = data['force_update'] ?? false;
        final String? message = data['hot_update_message'];
        
        // Notify listeners so UI redraws with new flags
        notifyListeners();

        // Show update dialog if there's a hot update message
        if (message != null && message.isNotEmpty && context.mounted) {
          _showHotUpdateDialog(context, message, forceUpdate);
        }
      }
    } catch (e) {
      debugPrint("Failed to fetch hot updates: $e");
    }
  }

  void _showHotUpdateDialog(BuildContext context, String message, bool forceUpdate) {
    showDialog(
      context: context,
      barrierDismissible: !forceUpdate,
      builder: (ctx) => AlertDialog(
        backgroundColor: kSurfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('✨ Hot Update Available', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(
          message,
          style: const TextStyle(color: kTextLightColor),
        ),
        actions: [
          if (!forceUpdate)
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Later', style: TextStyle(color: kTextLightColor)),
            ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimaryColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Features synced dynamically! (Server-Driven)')),
              );
            },
            child: const Text('Apply Now', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
