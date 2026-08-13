from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]

for path in ROOT.rglob('*.dart'):
    if any(part in {'.dart_tool', 'build'} for part in path.parts):
        continue
    text = path.read_text(encoding='utf-8')
    original = text

    # The project was renamed from spotify_clone to flowly.
    text = text.replace('package:spotify_clone/', 'package:flowly/')

    # Flutter TextTheme renames.
    text = re.sub(r'\.headline4\b', '.headlineMedium', text)
    text = re.sub(r'\.bodyText1\b', '.bodyLarge', text)
    text = re.sub(r'\.bodyText2\b', '.bodyMedium', text)
    text = re.sub(r'(?m)^(\s*)headline4\s*:', r'\1headlineMedium:', text)
    text = re.sub(r'(?m)^(\s*)bodyText1\s*:', r'\1bodyLarge:', text)
    text = re.sub(r'(?m)^(\s*)bodyText2\s*:', r'\1bodyMedium:', text)

    # Flutter 3.27+ color API. This is intentionally limited to the simple
    # literal/constant opacity calls used by this legacy project.
    text = re.sub(r'\.withOpacity\(\s*([0-9.]+)\s*\)', r'.withValues(alpha: \1)', text)

    # Keep the profile avatar provider type explicit for Dart's conditional
    # expression type inference on current Flutter/Dart releases.
    text = text.replace(
        ': FileImage(File(_avatarPath!)),',
        ': FileImage(File(_avatarPath!)) as ImageProvider<Object>,',
    )

    if text != original:
        path.write_text(text, encoding='utf-8')
