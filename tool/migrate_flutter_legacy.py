from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]
changed_any = False

# Legacy relative imports inside files were valid before the feature-first move,
# but their old ../../ depth is no longer valid. Resolve them to the canonical
# architecture paths instead of preserving fragile relative imports.
IMPORT_REWRITES = {
    "controllers/main_controller.dart": "package:flowly/features/player/domain/main_controller.dart",
    "services/secure_storage_service.dart": "package:flowly/core/storage/secure_storage_service.dart",
    "services/settings_service.dart": "package:flowly/core/storage/settings_service.dart",
    "services/global_gesture_service.dart": "package:flowly/core/gestures/global_gesture_service.dart",
    "services/notification_player_service.dart": "package:flowly/features/player/infrastructure/notification_player_service.dart",
    "services/flowly_api.dart": "package:flowly/core/network/flowly_api.dart",
    "services/crash_reporting_service.dart": "package:flowly/core/crash_reporting/crash_reporting_service.dart",
    "methods/get_time_ago.dart": "package:flowly/core/utils/get_time_ago.dart",
    "methods/get_response.dart": "package:flowly/core/utils/get_response.dart",
    "methods/log.dart": "package:flowly/core/utils/log.dart",
    "methods/snackbar.dart": "package:flowly/core/utils/snackbar.dart",
    "methods/string_methods.dart": "package:flowly/core/utils/string_methods.dart",
    "utils/loading.dart": "package:flowly/shared/widgets/loading.dart",
    "utils/sliver_appbar.dart": "package:flowly/shared/widgets/sliver_appbar.dart",
    "utils/horizontal_songs_list.dart": "package:flowly/shared/widgets/horizontal_songs_list.dart",
    "utils/recent_search.dart": "package:flowly/shared/widgets/recent_search.dart",
    "utils/recent_users.dart": "package:flowly/shared/widgets/recent_users.dart",
    "utils/botttom_sheet_widget.dart": "package:flowly/features/player/presentation/botttom_sheet_widget.dart",
    "utils/draggable_view.dart": "package:flowly/features/player/presentation/draggable_view.dart",
    "utils/play_list.dart": "package:flowly/features/player/presentation/play_list.dart",
    "utils/player/playing_controls.dart": "package:flowly/features/player/presentation/playing_controls.dart",
    "utils/player/position_seek_widget.dart": "package:flowly/features/player/presentation/position_seek_widget.dart",
    "utils/like_button/like_button.dart": "package:flowly/shared/widgets/like_button.dart",
    "utils/like_button/cubit/like_button_cubit.dart": "package:flowly/shared/widgets/like_button_cubit.dart",
    "utils/like_button/cubit/like_button_state.dart": "package:flowly/shared/widgets/like_button_state.dart",
    "models/loading_enum.dart": "package:flowly/data/models/loading_enum.dart",
    "models/catagory.dart": "package:flowly/data/models/catagory.dart",
    "models/song_model.dart": "package:flowly/domain/entities/song_model.dart",
    "models/user.dart": "package:flowly/domain/entities/user.dart",
    "models/user_model.dart": "package:flowly/domain/entities/user_model.dart",
    "repositories/get_artists_data.dart": "package:flowly/data/repositories/get_artists_data.dart",
    "repositories/get_genre_data.dart": "package:flowly/data/repositories/get_genre_data.dart",
    "repositories/get_home_page.dart": "package:flowly/data/repositories/get_home_page.dart",
    "repositories/get_one_song.dart": "package:flowly/data/repositories/get_one_song.dart",
    "repositories/get_search_results.dart": "package:flowly/data/repositories/get_search_results.dart",
    "api/flowly_api.dart": "package:flowly/core/network/flowly_api.dart",
    "api/url.dart": "package:flowly/core/network/url.dart",
    "utils/app_locale.dart": "package:flowly/app/localization/app_locale.dart",
}

# Map old nested screen imports to their feature-first counterparts.
IMPORT_REWRITES.update({
    "screens/artist_profile/cubit/artist_profile_cubit.dart": "package:flowly/features/artists/presentation/artist_profile_cubit.dart",
    "screens/artist_profile/cubit/artist_profile_state.dart": "package:flowly/features/artists/presentation/artist_profile_state.dart",
    "screens/genre_page/cubit/genre_cubit.dart": "package:flowly/features/genres/presentation/genre_cubit.dart",
    "screens/genre_page/cubit/genre_state.dart": "package:flowly/features/genres/presentation/genre_state.dart",
    "screens/search_results/cubit/search_results_cubit.dart": "package:flowly/features/search/presentation/search_results_cubit.dart",
    "screens/search_results/cubit/search_results_state.dart": "package:flowly/features/search/presentation/search_results_state.dart",
    "screens/home/cubit/home_cubit.dart": "package:flowly/features/home/presentation/home_cubit.dart",
    "screens/home/cubit/home_state.dart": "package:flowly/features/home/presentation/home_state.dart",
})

for path in ROOT.rglob('*.dart'):
    if any(part in {'.dart_tool', 'build'} for part in path.parts):
        continue
    text = path.read_text(encoding='utf-8')
    original = text

    text = text.replace('package:spotify_clone/', 'package:flowly/')

    # Canonicalize any import URI that ends with one of the moved legacy paths.
    for legacy_suffix, new_uri in IMPORT_REWRITES.items():
        pattern = rf"import\s+['\"][^'\"]*{re.escape(legacy_suffix)}['\"]"
        text = re.sub(pattern, f"import '{new_uri}'", text)

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
        text = text.replace('icon: Icons.play_arrow_outlined,', 'icon: Icons.play_circle_outline,', 1)
        text = text.replace('icon: Icons.download_outlined,', 'icon: Icons.file_download_outlined,', 1)
        text = text.replace('icon: Icons.headset_mic_outlined,', 'icon: Icons.support_agent_outlined,', 1)

    if text != original:
        path.write_text(text, encoding='utf-8')
        changed_any = True

pubspec = ROOT / 'pubspec.yaml'
if changed_any and pubspec.exists():
    value = pubspec.read_text(encoding='utf-8')
    match = re.search(r'^version:\s*(\d+)\.(\d+)\.(\d+)\+(\d+)$', value, re.M)
    if match:
        major, minor, patch, build = map(int, match.groups())
        value = re.sub(r'^version:.*$', f'version: {major}.{minor}.{patch + 1}+{build + 1}', value, flags=re.M)
        pubspec.write_text(value, encoding='utf-8')
