import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../constants.dart';

class UpdateService {
  static const String _baseUrl = kBaseUrl;
  static const String _v1 = kApiV1;

  static Future<void> checkForUpdates(BuildContext context) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl$_v1/config/app_config'));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final bool forceUpdate = data['force_update'] ?? false;
        final String? message = data['hot_update_message'];
        
        // Show update dialog if there's a hot update message
        // Or if force update is required and version is outdated.
        // For demonstration, we simply show the hot update message if provided.
        if (message != null && message.isNotEmpty && context.mounted) {
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
                      const SnackBar(content: Text('Applying hot updates... (Simulated)')),
                    );
                  },
                  child: const Text('Apply Now', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          );
        }
      }
    } catch (e) {
      debugPrint("Failed to fetch hot updates: $e");
    }
  }
}
