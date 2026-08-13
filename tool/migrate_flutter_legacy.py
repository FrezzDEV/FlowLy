from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]

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
        # Remove the settings item that was explicitly requested to disappear.
        text = re.sub(
            r'\s*_SettingsRow\(\s*icon: Icons\.text_fields_outlined,.*?\n\s*\),',
            '',
            text,
            flags=re.S,
        )
        # Give the main settings rows real destinations instead of inert tiles.
        replacements = {
            "icon: Icons.play_arrow_outlined,\n                  title: AppLocale.text('Воспроизведение', 'Playback'),": "icon: Icons.play_circle_outline,\n                  title: AppLocale.text('Воспроизведение', 'Playback'),",
            "icon: Icons.download_outlined,\n                  title: AppLocale.text('Скачивание', 'Downloads'),": "icon: Icons.file_download_outlined,\n                  title: AppLocale.text('Скачивание', 'Downloads'),",
            "icon: Icons.notifications_none,\n                  title: AppLocale.text('Уведомления', 'Notifications'),": "icon: Icons.notifications_none_outlined,\n                  title: AppLocale.text('Уведомления', 'Notifications'),",
            "icon: Icons.headset_mic_outlined,\n                  title: AppLocale.text('Поддержка', 'Support'),": "icon: Icons.support_agent_outlined,\n                  title: AppLocale.text('Поддержка', 'Support'),",
        }
        for old, new in replacements.items():
            text = text.replace(old, new)
        text = text.replace(
            "subtitle: AppLocale.text(\n                    'Качество звука, кроссфейд, EQ',\n                    'Audio quality, crossfade, EQ',\n                  ),\n                ),",
            "subtitle: AppLocale.text('Качество, повтор, crossfade, EQ', 'Quality, repeat, crossfade, EQ'),\n                  onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const _PlaybackSettingsPage())),\n                ),",
        )
        text = text.replace(
            "subtitle: AppLocale.text(\n                    'Музыка и обновления',\n                    'Music and updates',\n                  ),\n                ),",
            "subtitle: AppLocale.text('Музыка, загрузки и обновления', 'Music, downloads and updates'),\n                  onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const _NotificationSettingsPage())),\n                ),",
        )
        text = text.replace(
            "subtitle: AppLocale.text(\n                    'Помощь и обратная связь',\n                    'Help and feedback',\n                  ),\n                ),",
            "subtitle: AppLocale.text('Помощь и обратная связь', 'Help and feedback'),\n                  onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const _SupportSettingsPage())),\n                ),",
        )

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
