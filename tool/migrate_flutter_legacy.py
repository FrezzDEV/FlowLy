from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]

EXTRA_SETTINGS = r'''

class _PlaybackSettingsPage extends StatefulWidget {
  const _PlaybackSettingsPage();
  @override State<_PlaybackSettingsPage> createState() => _PlaybackSettingsPageState();
}

class _PlaybackSettingsPageState extends State<_PlaybackSettingsPage> {
  late bool autoplay;
  late bool gapless;
  late String repeat;
  late String quality;
  late double crossfade;

  @override
  void initState() {
    super.initState();
    final box = Hive.box('profile');
    autoplay = box.get('playbackAutoplay', defaultValue: true) as bool;
    gapless = box.get('playbackGapless', defaultValue: true) as bool;
    repeat = box.get('playbackRepeat', defaultValue: 'off') as String;
    quality = box.get('playbackQuality', defaultValue: 'standard') as String;
    crossfade = (box.get('playbackCrossfade', defaultValue: 0.0) as num).toDouble();
  }

  @override
  Widget build(BuildContext context) {
    final box = Hive.box('profile');
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: Colors.black, foregroundColor: Colors.white, title: Text(AppLocale.text('Воспроизведение', 'Playback'))),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        _PlaybackSettingSwitch(title: AppLocale.text('Автовоспроизведение', 'Autoplay'), value: autoplay, onChanged: (v) { box.put('playbackAutoplay', v); setState(() => autoplay = v); }),
        const SizedBox(height: 10),
        _PlaybackSettingSwitch(title: 'Gapless playback', value: gapless, onChanged: (v) { box.put('playbackGapless', v); setState(() => gapless = v); }),
        const SizedBox(height: 10),
        _PlaybackSettingChoice(title: AppLocale.text('Повтор', 'Repeat'), value: repeat, items: const {'off': 'Выключен', 'all': 'Очередь', 'one': 'Трек'}, onChanged: (v) { box.put('playbackRepeat', v); setState(() => repeat = v); }),
        const SizedBox(height: 10),
        _PlaybackSettingChoice(title: AppLocale.text('Качество', 'Quality'), value: quality, items: const {'standard': 'Стандарт', 'high': 'Высокое', 'maximum': 'Максимальное'}, onChanged: (v) { box.put('playbackQuality', v); setState(() => quality = v); }),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
          decoration: BoxDecoration(color: const Color(0xFF101010), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFF292929))),
          child: Column(children: [
            Row(children: [Expanded(child: Text('Crossfade', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700))), Text('${crossfade.toStringAsFixed(0)} s', style: const TextStyle(color: Color(0xFF858585)))]),
            Slider(value: crossfade.clamp(0, 12), min: 0, max: 12, divisions: 12, activeColor: Colors.white, onChanged: (v) { box.put('playbackCrossfade', v); setState(() => crossfade = v); }),
          ]),
        ),
        const SizedBox(height: 10),
        _SettingsRow(icon: Icons.tune_outlined, title: 'EQ', subtitle: AppLocale.text('Панель эквалайзера готова для подключения к AudioService', 'Equalizer UI is ready for AudioService integration'), onTap: () {}),
      ]),
    );
  }
}

class _PlaybackSettingSwitch extends StatelessWidget {
  final String title; final bool value; final ValueChanged<bool> onChanged;
  const _PlaybackSettingSwitch({required this.title, required this.value, required this.onChanged});
  @override Widget build(BuildContext context) => _SettingsRow(icon: Icons.play_circle_outline, title: title, subtitle: '', onTap: () => onChanged(!value));
}

class _PlaybackSettingChoice extends StatelessWidget {
  final String title; final String value; final Map<String, String> items; final ValueChanged<String> onChanged;
  const _PlaybackSettingChoice({required this.title, required this.value, required this.items, required this.onChanged});
  @override Widget build(BuildContext context) => Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4), decoration: BoxDecoration(color: const Color(0xFF101010), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFF292929))), child: Row(children: [Expanded(child: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700))), DropdownButton<String>(value: value, dropdownColor: const Color(0xFF181818), underline: const SizedBox.shrink(), style: const TextStyle(color: Colors.white), items: items.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(), onChanged: (v) { if (v != null) onChanged(v); })]));
}

class _NotificationSettingsPage extends StatefulWidget {
  const _NotificationSettingsPage();
  @override State<_NotificationSettingsPage> createState() => _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<_NotificationSettingsPage> {
  late bool music; late bool downloads; late bool updates;
  @override void initState() { super.initState(); final box = Hive.box('profile'); music = box.get('notifyMusic', defaultValue: true) as bool; downloads = box.get('notifyDownloads', defaultValue: true) as bool; updates = box.get('notifyUpdates', defaultValue: true) as bool; }
  @override Widget build(BuildContext context) { final box = Hive.box('profile'); return Scaffold(backgroundColor: Colors.black, appBar: AppBar(backgroundColor: Colors.black, foregroundColor: Colors.white, title: Text(AppLocale.text('Уведомления', 'Notifications'))), body: ListView(padding: const EdgeInsets.all(20), children: [
    _SettingsRow(icon: Icons.music_note_outlined, title: AppLocale.text('Музыка', 'Music'), subtitle: '', onTap: () { final v = !music; box.put('notifyMusic', v); setState(() => music = v); }),
    _SettingsRow(icon: Icons.download_outlined, title: AppLocale.text('Загрузки', 'Downloads'), subtitle: '', onTap: () { final v = !downloads; box.put('notifyDownloads', v); setState(() => downloads = v); }),
    _SettingsRow(icon: Icons.system_update_outlined, title: AppLocale.text('Обновления', 'Updates'), subtitle: '', onTap: () { final v = !updates; box.put('notifyUpdates', v); setState(() => updates = v); }),
  ])); }
}

class _SupportSettingsPage extends StatelessWidget {
  const _SupportSettingsPage();
  @override Widget build(BuildContext context) => Scaffold(backgroundColor: Colors.black, appBar: AppBar(backgroundColor: Colors.black, foregroundColor: Colors.white, title: Text(AppLocale.text('Поддержка', 'Support')),
    body: ListView(padding: const EdgeInsets.all(20), children: [
      _SettingsRow(icon: Icons.help_outline, title: 'FAQ', subtitle: AppLocale.text('Ответы на частые вопросы', 'Frequently asked questions')),
      const SizedBox(height: 10),
      _SettingsRow(icon: Icons.bug_report_outlined, title: AppLocale.text('Сообщить об ошибке', 'Report a bug'), subtitle: AppLocale.text('Подготовленная форма обратной связи', 'Prepared feedback form')),
      const SizedBox(height: 10),
      _SettingsRow(icon: Icons.chat_bubble_outline, title: AppLocale.text('Обратная связь', 'Feedback'), subtitle: AppLocale.text('Связаться с командой FlowLy', 'Contact the FlowLy team')),
    ]));
}
'''

for path in ROOT.rglob('*.dart'):
    if any(part in {'.dart_tool', 'build'} for part in path.parts):
        continue
    text = path.read_text(encoding='utf-8')
    original = text
    text = text.replace('package:spotify_clone/', 'package:flowly/')
    text = re.sub(r'\.headline4\b', '.headlineMedium', text)
    text = re.sub(r'\.bodyText1\b', '.bodyLarge', text)
    text = re.sub(r'\.bodyText2\b', '.bodyMedium', text)
    text = re.sub(r'(?m)^(\s*)headline4\s*:', r'\1headlineMedium:', text)
    text = re.sub(r'(?m)^(\s*)bodyText1\s*:', r'\1bodyLarge:', text)
    text = re.sub(r'(?m)^(\s*)bodyText2\s*:', r'\1bodyMedium:', text)
    text = re.sub(r'\.withOpacity\(\s*([0-9.]+)\s*\)', r'.withValues(alpha: \1)', text)
    text = text.replace(': FileImage(File(_avatarPath!)),', ': FileImage(File(_avatarPath!)) as ImageProvider<Object>,')

    if path.as_posix().endswith('lib/screens/profile/profile.dart'):
        text = re.sub(r'\s*_SettingsRow\(\s*icon: Icons\.text_fields_outlined,.*?\n\s*\),', '', text, flags=re.S)
        text = text.replace("icon: Icons.play_arrow_outlined,", "icon: Icons.play_circle_outline,", 1)
        text = text.replace("icon: Icons.download_outlined,", "icon: Icons.file_download_outlined,", 1)
        text = text.replace("icon: Icons.notifications_none,", "icon: Icons.notifications_none_outlined,", 1)
        text = text.replace("icon: Icons.headset_mic_outlined,", "icon: Icons.support_agent_outlined,", 1)
        marker = 'class _SettingsGroup extends StatelessWidget {'
        if '_PlaybackSettingsPage extends StatefulWidget' not in text and marker in text:
            text = text.replace(marker, EXTRA_SETTINGS + '\n' + marker, 1)
        text = text.replace("subtitle: AppLocale.text(\n                    'Качество звука, кроссфейд, EQ',\n                    'Audio quality, crossfade, EQ',\n                  ),\n                ),", "subtitle: AppLocale.text('Качество, повтор, crossfade, EQ', 'Quality, repeat, crossfade, EQ'),\n                  onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const _PlaybackSettingsPage())),\n                ),")
        text = text.replace("subtitle: AppLocale.text(\n                    'Музыка и обновления',\n                    'Music and updates',\n                  ),\n                ),", "subtitle: AppLocale.text('Музыка, загрузки и обновления', 'Music, downloads and updates'),\n                  onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const _NotificationSettingsPage())),\n                ),")
        text = text.replace("subtitle: AppLocale.text(\n                    'Помощь и обратная связь',\n                    'Help and feedback',\n                  ),\n                ),", "subtitle: AppLocale.text('Помощь и обратная связь', 'Help and feedback'),\n                  onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const _SupportSettingsPage())),\n                ),")

    if text != original:
        path.write_text(text, encoding='utf-8')

pubspec = ROOT / 'pubspec.yaml'
if pubspec.exists():
    value = pubspec.read_text(encoding='utf-8')
    match = re.search(r'^version:\s*(\d+)\.(\d+)\.(\d+)\+(\d+)$', value, re.M)
    if match:
        major, minor, patch, build = map(int, match.groups())
        value = re.sub(r'^version:.*$', f'version: {major}.{minor}.{patch + 1}+{build + 1}', value, flags=re.M)
        pubspec.write_text(value, encoding='utf-8')
