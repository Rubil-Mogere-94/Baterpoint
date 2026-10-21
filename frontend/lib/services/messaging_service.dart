import 'dart:convert';
import 'package:http/http.dart' as http;

class BarterPhrase {
  final String english;
  final String swahili;
  final String icon;

  const BarterPhrase({
    required this.english,
    required this.swahili,
    required this.icon,
  });

  String formatBilingual() => '$english\n[Kiswahili: $swahili]';
}

class TranslationResult {
  final String original;
  final String translated;
  final String sourceLang; // 'en' or 'sw'
  final String targetLang; // 'sw' or 'en'

  const TranslationResult({
    required this.original,
    required this.translated,
    required this.sourceLang,
    required this.targetLang,
  });

  String get sourceLabel => sourceLang == 'sw' ? 'Kiswahili 🇰🇪' : 'English 🇬🇧';
  String get targetLabel => targetLang == 'sw' ? 'Kiswahili 🇰🇪' : 'English 🇬🇧';
}

class MessagingService {
  static const String _ntfyBase = 'https://ntfy.sh';
  static const String _purgoMalumUrl = 'https://www.purgomalum.com/service/json';
  static const String _myMemoryUrl = 'https://api.mymemory.translated.net/get';
  static const String _qrBaseUrl = 'https://api.qrserver.com/v1/create-qr-code';

  static final Map<String, String> _translationCache = {};

  /// Common trade barter phrases curated in English and Kiswahili.
  static const List<BarterPhrase> quickBarterPhrases = [
    BarterPhrase(
      english: "Are you open to a barter trade?",
      swahili: "Je, unakubali kubadilishana bidhaa?",
      icon: "🤝",
    ),
    BarterPhrase(
      english: "What is your best cash price?",
      swahili: "Bei yako ya mwisho ya pesa ni ngapi?",
      icon: "💰",
    ),
    BarterPhrase(
      english: "Where can we meet for safe handover?",
      swahili: "Tukutane wapi kwa makabidhiano salama?",
      icon: "📍",
    ),
    BarterPhrase(
      english: "Are you available to swap today?",
      swahili: "Unapatikana leo kwa ajili ya kubadilishana?",
      icon: "⏱️",
    ),
    BarterPhrase(
      english: "I can top up with extra cash.",
      swahili: "Naweza kuongeza pesa taslimu kidogo.",
      icon: "💵",
    ),
    BarterPhrase(
      english: "Is the item still in good condition?",
      swahili: "Je, bidhaa bado iko katika hali nzuri?",
      icon: "✨",
    ),
  ];

  static const Set<String> _swahiliKeywords = {
    'habari', 'jambo', 'sawa', 'asante', 'shukrani', 'bei', 'shilingi', 'pesa',
    'kubadilishana', 'badilishana', 'badili', 'kubadili', 'wapi', 'leo', 'kesho',
    'hapana', 'ndio', 'gani', 'yangu', 'yako', 'kwa', 'katika', 'naomba',
    'tafadhali', 'vipi', 'mambo', 'simu', 'ngapi', 'ongeza', 'karibu', 'makabidhiano',
    'bidhaa', 'hali', 'nzuri', 'nipo', 'niko', 'hapa', 'tuonane', 'duka', 'soko'
  };

  /// Detects whether text is likely Kiswahili ('sw') or English ('en').
  static String detectLanguage(String text) {
    final words = text
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s]'), '')
        .split(RegExp(r'\s+'));
    for (final word in words) {
      if (_swahiliKeywords.contains(word)) {
        return 'sw';
      }
    }
    return 'en';
  }

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
      // Fallback to original text if offline
    }
    return text;
  }

  /// Smart translation between English and Kiswahili using MyMemory API.
  /// If [forcedTargetLang] is provided, translates to that language.
  /// Otherwise automatically detects language and toggles (en -> sw, sw -> en).
  static Future<TranslationResult?> smartTranslate({
    required String text,
    String? forcedTargetLang,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return null;

    final detected = detectLanguage(trimmed);
    final targetLang = forcedTargetLang ?? (detected == 'sw' ? 'en' : 'sw');
    final sourceLang = targetLang == 'en' ? 'sw' : 'en';

    final cacheKey = '$sourceLang|$targetLang|$trimmed';
    if (_translationCache.containsKey(cacheKey)) {
      return TranslationResult(
        original: trimmed,
        translated: _translationCache[cacheKey]!,
        sourceLang: sourceLang,
        targetLang: targetLang,
      );
    }

    try {
      final uri = Uri.parse(
        '$_myMemoryUrl?q=${Uri.encodeComponent(trimmed)}&langpair=$sourceLang|$targetLang',
      );
      final response = await http.get(uri).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map && decoded['responseData'] is Map) {
          final translated = decoded['responseData']['translatedText'];
          if (translated != null && translated.toString().trim().isNotEmpty) {
            final resultText = translated.toString();
            _translationCache[cacheKey] = resultText;
            return TranslationResult(
              original: trimmed,
              translated: resultText,
              sourceLang: sourceLang,
              targetLang: targetLang,
            );
          }
        }
      }
    } catch (_) {}

    return null;
  }

  /// Backward-compatible translate method.
  static Future<String?> translate({
    required String text,
    String from = 'sw',
    String to = 'en',
  }) async {
    final res = await smartTranslate(text: text, forcedTargetLang: to);
    return res?.translated;
  }

  /// Generates a QR code image URL for in-person barter handover verification.
  static String getHandoverQrUrl(String tradeOrListingId, {int size = 260}) {
    final payload = 'baterpoint-handover-$tradeOrListingId';
    return '$_qrBaseUrl/?size=${size}x$size&data=${Uri.encodeComponent(payload)}&color=176B57&bgcolor=FFFFFF';
  }
}
