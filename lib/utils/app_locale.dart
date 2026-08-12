import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

class AppLocale {
  static final ValueNotifier<String> language = ValueNotifier<String>('ru');

  static Future<void> init() async {
    final value = Hive.box('profile').get('language', defaultValue: 'ru');
    language.value = value == 'en' ? 'en' : 'ru';
  }

  static Future<void> setLanguage(String value) async {
    final next = value == 'en' ? 'en' : 'ru';
    language.value = next;
    await Hive.box('profile').put('language', next);
  }

  static bool get isEnglish => language.value == 'en';

  static String text(String ru, String en) => isEnglish ? en : ru;
}
