from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]
changed_any = False

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
        # Remove the settings item explicitly requested to disappear.
        text = re.sub(r'\s*_SettingsRow\(\s*icon: Icons\.text_fields_outlined,.*?\n\s*\),', '', text, flags=re.S)
        # Modernize the two settings icons without changing existing navigation.
        text = text.replace('icon: Icons.play_arrow_outlined,', 'icon: Icons.play_circle_outline,', 1)
        text = text.replace('icon: Icons.download_outlined,', 'icon: Icons.file_download_outlined,', 1)
        text = text.replace('icon: Icons.headset_mic_outlined,', 'icon: Icons.support_agent_outlined,', 1)

    if text != original:
        path.write_text(text, encoding='utf-8')
        changed_any = True

# Bump the app version only when this migration actually changes source files.
pubspec = ROOT / 'pubspec.yaml'
if changed_any and pubspec.exists():
    value = pubspec.read_text(encoding='utf-8')
    match = re.search(r'^version:\s*(\d+)\.(\d+)\.(\d+)\+(\d+)$', value, re.M)
    if match:
        major, minor, patch, build = map(int, match.groups())
        value = re.sub(r'^version:.*$', f'version: {major}.{minor}.{patch + 1}+{build + 1}', value, flags=re.M)
        pubspec.write_text(value, encoding='utf-8')
