import 'dart:convert';
import 'package:http/http.dart' as http;

class MessagingService {
  static const String _ntfyBase = 'https://ntfy.sh';
  static const String _purgoMalumUrl = 'https://www.purgomalum.com/service/json';
  static const String _myMemoryUrl = 'https://api.mymemory.translated.net/get';
  static const String _qrBaseUrl = 'https://api.qrserver.com/v1/create-qr-code';

  /// Sends a push alert via ntfy.sh without requiring Firebase or API keys.
  static Future<bool> sendNtfyAlert({
    required String topic,
    required String title,
    required String body,
    String priority = 'default',
    List<String> tags = const ['package', 'speech_balloon'],
  }) async {
    try {
      final cleanTopic = topic.trim().replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
      final uri = Uri.parse('$_ntfyBase/$cleanTopic');
      final response = await http
          .post(
            uri,
            headers: {
              'Title': title,
              'Priority': priority,
              'Tags': tags.join(','),
            },
            body: body,
          )
          .timeout(const Duration(seconds: 6));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Filters profanity and abusive words using PurgoMalum free API.
  static Future<String> filterProfanity(String text) async {
    if (text.trim().isEmpty) return text;
    try {
      final uri = Uri.parse('$_purgoMalumUrl?text=${Uri.encodeComponent(text)}');
      final response = await http.get(uri).timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map && decoded.containsKey('result')) {
          return decoded['result'].toString();
        }
      }
    } catch (_) {
      // Return original text if offline
    }
    return text;
  }

  /// Translates text between Swahili ('sw') and English ('en') using MyMemory API.
  static Future<String?> translate({
    required String text,
    String from = 'sw',
    String to = 'en',
  }) async {
    if (text.trim().isEmpty) return null;
    try {
      final langPair = '$from|$to';
      final uri = Uri.parse(
        '$_myMemoryUrl?q=${Uri.encodeComponent(text)}&langpair=$langPair',
      );
      final response = await http.get(uri).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map && decoded['responseData'] is Map) {
          final translated = decoded['responseData']['translatedText'];
          if (translated != null && translated.toString().trim().isNotEmpty) {
            return translated.toString();
          }
        }
      }
    } catch (_) {
      // Fall through on error
    }
    return null;
  }

  /// Generates a QR code image URL for in-person barter handover verification.
  static String getHandoverQrUrl(String tradeOrListingId, {int size = 260}) {
    final payload = 'baterpoint-handover-$tradeOrListingId';
    return '$_qrBaseUrl/?size=${size}x$size&data=${Uri.encodeComponent(payload)}&color=176B57&bgcolor=FFFFFF';
  }
}
