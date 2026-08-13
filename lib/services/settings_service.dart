import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

class SettingsService {
  SettingsService._();
  static const _boxName = 'app_settings';

  static Future<void> init() async {
    if (!Hive.isBoxOpen(_boxName)) {
      await Hive.openBox<dynamic>(_boxName);
    }
  }

  static Box<dynamic> get _box => Hive.box<dynamic>(_boxName);

  static bool get swipeNavigationEnabled =>
      (_box.get('swipe_navigation_enabled', defaultValue: true) as bool?) ?? true;

  static Future<void> setSwipeNavigationEnabled(bool value) =>
      _box.put('swipe_navigation_enabled', value);

  static String get downloadQuality =>
      (_box.get('download_quality', defaultValue: 'high') as String?) ?? 'high';

  static Future<void> setDownloadQuality(String value) =>
      _box.put('download_quality', value);

  static bool get downloadWifiOnly =>
      (_box.get('download_wifi_only', defaultValue: true) as bool?) ?? true;

  static Future<void> setDownloadWifiOnly(bool value) =>
      _box.put('download_wifi_only', value);

  static bool get autoplay =>
      (_box.get('autoplay', defaultValue: true) as bool?) ?? true;

  static Future<void> setAutoplay(bool value) => _box.put('autoplay', value);

  static double get crossfadeSeconds =>
      ((_box.get('crossfade_seconds', defaultValue: 0.0) as num?) ?? 0).toDouble();

  static Future<void> setCrossfadeSeconds(double value) =>
      _box.put('crossfade_seconds', value.clamp(0, 12));

  static bool get notificationMusic =>
      (_box.get('notification_music', defaultValue: true) as bool?) ?? true;

  static Future<void> setNotificationMusic(bool value) =>
      _box.put('notification_music', value);

  static bool get notificationUpdates =>
      (_box.get('notification_updates', defaultValue: true) as bool?) ?? true;

  static Future<void> setNotificationUpdates(bool value) =>
      _box.put('notification_updates', value);

  static bool get notificationDownloads =>
      (_box.get('notification_downloads', defaultValue: true) as bool?) ?? true;

  static Future<void> setNotificationDownloads(bool value) =>
      _box.put('notification_downloads', value);

  static ValueListenable<Box<dynamic>> get listenable => _box.listenable();
}
