import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../controllers/main_controller.dart';

class NotificationPlayerService {
  NotificationPlayerService._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static const int _id = 1001;

  static Future<void> initialize(MainController controller) async {
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    );
    await _plugin.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: (response) async {
        switch (response.actionId) {
          case 'download':
            await controller.downloadCurrent();
            break;
          case 'previous':
            await controller.previous();
            break;
          case 'play_pause':
            await controller.playOrPause();
            break;
          case 'next':
            await controller.next();
            break;
          case 'like':
            await controller.toggleFavoriteCurrent();
            break;
        }
        await show(controller);
      },
    );

    final android = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await android?.requestNotificationsPermission();
  }

  static Future<void> show(MainController controller) async {
    final song = controller.currentSong;
    if (song == null) {
      await hide();
      return;
    }

    final details = AndroidNotificationDetails(
      'flowly_player',
      'FlowLy Player',
      channelDescription: 'Music playback controls',
      importance: Importance.low,
      priority: Priority.low,
      ongoing: controller.isPlaying,
      autoCancel: false,
      showWhen: false,
      onlyAlertOnce: true,
      playSound: false,
      category: AndroidNotificationCategory.transport,
      styleInformation: const MediaStyleInformation(),
      actions: [
        const AndroidNotificationAction(
          'download',
          'Скачать',
          icon: DrawableResourceAndroidBitmap('ic_player_download'),
          cancelNotification: false,
        ),
        const AndroidNotificationAction(
          'previous',
          'Назад',
          icon: DrawableResourceAndroidBitmap('ic_player_previous'),
          cancelNotification: false,
        ),
        const AndroidNotificationAction(
          'play_pause',
          'Пауза',
          icon: DrawableResourceAndroidBitmap('ic_player_pause'),
          cancelNotification: false,
        ),
        const AndroidNotificationAction(
          'next',
          'Вперёд',
          icon: DrawableResourceAndroidBitmap('ic_player_next'),
          cancelNotification: false,
        ),
        const AndroidNotificationAction(
          'like',
          'Лайк',
          icon: DrawableResourceAndroidBitmap('ic_player_like'),
          cancelNotification: false,
        ),
      ],
    );

    await _plugin.show(
      id: _id,
      title: song.songname ?? 'FlowLy',
      body: song.name ?? 'FlowLy',
      notificationDetails: NotificationDetails(android: details),
    );
  }

  static Future<void> hide() => _plugin.cancel(id: _id);
}
