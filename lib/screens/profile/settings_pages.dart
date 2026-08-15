import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../utils/app_locale.dart';

class PlaybackSettingsPage extends StatefulWidget {
  const PlaybackSettingsPage({super.key});
  @override State<PlaybackSettingsPage> createState() => _PlaybackSettingsPageState();
}

class _PlaybackSettingsPageState extends State<PlaybackSettingsPage> {
  late bool autoplay;
  late bool gapless;
  late String repeat;
  late String quality;
  late double crossfade;
  Box<dynamic> get box => Hive.box('profile');

  @override void initState() {
    super.initState();
    autoplay = box.get('playbackAutoplay', defaultValue: true) as bool;
    gapless = box.get('playbackGapless', defaultValue: true) as bool;
    repeat = box.get('playbackRepeat', defaultValue: 'off') as String;
    quality = box.get('playbackQuality', defaultValue: 'standard') as String;
    crossfade = (box.get('playbackCrossfade', defaultValue: 0.0) as num).toDouble();
  }

  Future<void> put(String key, Object value, VoidCallback update) async {
    await box.put(key, value);
    if (mounted) setState(update);
  }

  @override Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.black,
    appBar: AppBar(backgroundColor: Colors.black, foregroundColor: Colors.white, title: Text(AppLocale.text('Воспроизведение', 'Playback'))),
    body: ListView(padding: const EdgeInsets.all(20), children: [
      _Toggle('Автовоспроизведение', 'Autoplay', autoplay, (v) => put('playbackAutoplay', v, () => autoplay = v)),
      _Toggle('Gapless playback', 'Gapless playback', gapless, (v) => put('playbackGapless', v, () => gapless = v)),
      _Choice('Повтор', 'Repeat', repeat, const {'off': 'Выключен', 'all': 'Очередь', 'one': 'Трек'}, (v) => put('playbackRepeat', v, () => repeat = v)),
      _Choice('Качество', 'Quality', quality, const {'standard': 'Стандарт', 'high': 'Высокое', 'maximum': 'Максимальное'}, (v) => put('playbackQuality', v, () => quality = v)),
      Container(
        margin: const EdgeInsets.only(top: 10),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
        decoration: BoxDecoration(color: const Color(0xFF101010), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFF292929))),
        child: Column(children: [
          Row(children: [const Expanded(child: Text('Crossfade', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700))), Text('${crossfade.toStringAsFixed(0)} s', style: const TextStyle(color: Color(0xFF858585)))]),
          Slider(value: crossfade.clamp(0.0, 12.0), min: 0, max: 12, divisions: 12, activeColor: Colors.white, onChanged: (v) => put('playbackCrossfade', v, () => crossfade = v)),
        ]),
      ),
    ]),
  );
}

class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({super.key});
  @override State<NotificationSettingsPage> createState() => _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage> {
  late bool music;
  late bool downloads;
  late bool updates;
  Box<dynamic> get box => Hive.box('profile');
  @override void initState() { super.initState(); music = box.get('notifyMusic', defaultValue: true) as bool; downloads = box.get('notifyDownloads', defaultValue: true) as bool; updates = box.get('notifyUpdates', defaultValue: true) as bool; }
  Future<void> toggle(String key, bool value, VoidCallback update) async { await box.put(key, value); if (mounted) setState(update); }
  @override Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.black,
    appBar: AppBar(backgroundColor: Colors.black, foregroundColor: Colors.white, title: Text(AppLocale.text('Уведомления', 'Notifications'))),
    body: ListView(padding: const EdgeInsets.all(20), children: [
      _Toggle('Музыка', 'Music', music, (v) => toggle('notifyMusic', v, () => music = v)),
      _Toggle('Загрузки', 'Downloads', downloads, (v) => toggle('notifyDownloads', v, () => downloads = v)),
      _Toggle('Обновления', 'Updates', updates, (v) => toggle('notifyUpdates', v, () => updates = v)),
    ]),
  );
}

class SupportSettingsPage extends StatelessWidget {
  const SupportSettingsPage({super.key});
  @override Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.black,
    appBar: AppBar(backgroundColor: Colors.black, foregroundColor: Colors.white, title: Text(AppLocale.text('Поддержка', 'Support'))),
    body: ListView(padding: const EdgeInsets.all(20), children: [
      _Info('FAQ', AppLocale.text('Ответы на частые вопросы', 'Frequently asked questions')),
      _Info(AppLocale.text('Сообщить об ошибке', 'Report a bug'), AppLocale.text('Форма обратной связи для диагностики', 'Diagnostic feedback form')),
      _Info(AppLocale.text('Обратная связь', 'Feedback'), AppLocale.text('Связаться с командой FlowLy', 'Contact the FlowLy team')),
    ]),
  );
}

class _Toggle extends StatelessWidget {
  final String ru;
  final String en;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _Toggle(this.ru, this.en, this.value, this.onChanged);
  @override Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
    decoration: BoxDecoration(color: const Color(0xFF101010), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFF292929))),
    child: Row(children: [Expanded(child: Text(AppLocale.text(ru, en), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700))), Switch(value: value, onChanged: onChanged)]),
  );
}

class _Choice extends StatelessWidget {
  final String ru;
  final String en;
  final String value;
  final Map<String, String> items;
  final ValueChanged<String> onChanged;
  const _Choice(this.ru, this.en, this.value, this.items, this.onChanged);
  @override Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(top: 10),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
    decoration: BoxDecoration(color: const Color(0xFF101010), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFF292929))),
    child: Row(children: [Expanded(child: Text(AppLocale.text(ru, en), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700))), DropdownButton<String>(value: value, dropdownColor: const Color(0xFF181818), underline: const SizedBox.shrink(), style: const TextStyle(color: Colors.white), items: items.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(), onChanged: (v) { if (v != null) onChanged(v); })]),
  );
}

class _Info extends StatelessWidget {
  final String title;
  final String subtitle;
  const _Info(this.title, this.subtitle);
  @override Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: const Color(0xFF101010), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFF292929))),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)), const SizedBox(height: 5), Text(subtitle, style: const TextStyle(color: Color(0xFF858585)))]),
  );
}
