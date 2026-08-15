import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

class AppLocale {
  static const supportedLanguageCodes = <String>['ru', 'en', 'es', 'de', 'fr', 'tr'];

  static final ValueNotifier<String> language = ValueNotifier<String>('ru');

  static Future<void> init() async {
    final value = Hive.box('profile').get('language', defaultValue: 'ru') as String?;
    language.value = supportedLanguageCodes.contains(value) ? value! : 'ru';
  }

  static Future<void> setLanguage(String value) async {
    final next = supportedLanguageCodes.contains(value) ? value : 'ru';
    language.value = next;
    await Hive.box('profile').put('language', next);
  }

  static bool get isEnglish => language.value == 'en';

  static String get languageName => languageLabel(language.value);

  static String languageLabel(String code) {
    switch (code) {
      case 'ru':
        return 'Русский';
      case 'en':
        return 'English';
      case 'es':
        return 'Español';
      case 'de':
        return 'Deutsch';
      case 'fr':
        return 'Français';
      case 'tr':
        return 'Türkçe';
      default:
        return code.toUpperCase();
    }
  }

  static String translate(Map<String, String> values) {
    return values[language.value] ?? values['en'] ?? values['ru'] ?? values.values.first;
  }

  static String text(String ru, String en) => language.value == 'en' ? en : ru;
}
