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
          case 'download':
            await controller.downloadCurrent();
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
          'previous',
          'Назад',
          cancelNotification: false,
        ),
        AndroidNotificationAction(
          'play_pause',
          controller.isPlaying ? 'Пауза' : 'Продолжить',
          cancelNotification: false,
        ),
        const AndroidNotificationAction(
          'next',
          'Вперёд',
          cancelNotification: false,
        ),
        const AndroidNotificationAction(
          'like',
          'Лайк',
          cancelNotification: false,
        ),
        const AndroidNotificationAction(
          'download',
          'Скачать',
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
