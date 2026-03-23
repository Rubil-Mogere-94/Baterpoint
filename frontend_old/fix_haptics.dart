import 'dart:io';

void main() {
  final dir = Directory('lib');
  final files = dir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'));

  for (final file in files) {
    if (file.path.contains('app_haptics.dart')) continue;

    String content = file.readAsStringSync();
    bool changed = false;

    if (content.contains('Vibrate.feedback')) {
      content = content.replaceAll('Vibrate.feedback', 'AppHaptics.feedback');
      changed = true;
    }

    if (changed) {
      if (!content.contains('package:baterpoint/utils/app_haptics.dart')) {
        // insert import after flutter_vibrate import
        content = content.replaceAll("import 'package:flutter_vibrate/flutter_vibrate.dart';", "import 'package:flutter_vibrate/flutter_vibrate.dart';\nimport 'package:baterpoint/utils/app_haptics.dart';");
      }
      file.writeAsStringSync(content);
      print('Updated ${file.path}');
    }
  }
}
