from pathlib import Path
import re
import shutil
import subprocess

ROOT = Path(__file__).resolve().parents[1]
LIB = ROOT / "lib"

DIRECT = {
    "package:flowly/controllers/main_controller.dart": "package:flowly/features/player/domain/main_controller.dart",
    "package:flowly/models/song_model.dart": "package:flowly/domain/entities/song_model.dart",
    "package:flowly/models/user.dart": "package:flowly/domain/entities/user.dart",
    "package:flowly/models/user_model.dart": "package:flowly/domain/entities/user_model.dart",
    "package:flowly/models/catagory.dart": "package:flowly/data/models/catagory.dart",
    "package:flowly/models/loading_enum.dart": "package:flowly/data/models/loading_enum.dart",
}

# Replace legacy import path fragments no matter whether they are relative or package imports.
FRAGMENTS = {
    "controllers/main_controller.dart": "features/player/domain/main_controller.dart",
    "models/song_model.dart": "domain/entities/song_model.dart",
    "models/user.dart": "domain/entities/user.dart",
    "models/user_model.dart": "domain/entities/user_model.dart",
    "models/catagory.dart": "data/models/catagory.dart",
    "models/loading_enum.dart": "data/models/loading_enum.dart",
    "repositories/get_artists_data.dart": "data/repositories/get_artists_data.dart",
    "repositories/get_genre_data.dart": "data/repositories/get_genre_data.dart",
    "repositories/get_home_page.dart": "data/repositories/get_home_page.dart",
    "repositories/get_one_song.dart": "data/repositories/get_one_song.dart",
    "repositories/get_search_results.dart": "data/repositories/get_search_results.dart",
    "methods/get_greeting.dart": "core/utils/get_greeting.dart",
    "methods/get_response.dart": "core/utils/get_response.dart",
    "methods/get_time_ago.dart": "core/utils/get_time_ago.dart",
    "methods/log.dart": "core/utils/log.dart",
    "methods/snackbar.dart": "core/utils/snackbar.dart",
    "methods/string_methods.dart": "core/utils/string_methods.dart",
    "services/crash_reporting_service.dart": "core/crash_reporting/crash_reporting_service.dart",
    "services/flowly_api.dart": "core/network/flowly_api.dart",
    "services/global_gesture_service.dart": "core/gestures/global_gesture_service.dart",
    "services/notification_player_service.dart": "features/player/infrastructure/notification_player_service.dart",
    "services/secure_storage_service.dart": "core/storage/secure_storage_service.dart",
    "services/settings_service.dart": "core/storage/settings_service.dart",
    "utils/app_locale.dart": "app/localization/app_locale.dart",
    "utils/loading.dart": "shared/widgets/loading.dart",
    "utils/horizontal_songs_list.dart": "shared/widgets/horizontal_songs_list.dart",
    "utils/recent_search.dart": "shared/widgets/recent_search.dart",
    "utils/recent_users.dart": "shared/widgets/recent_users.dart",
    "utils/sliver_appbar.dart": "shared/widgets/sliver_appbar.dart",
    "utils/like_button/like_button.dart": "shared/widgets/like_button.dart",
    "utils/like_button/cubit/like_button_cubit.dart": "shared/widgets/like_button_cubit.dart",
    "utils/like_button/cubit/like_button_state.dart": "shared/widgets/like_button_state.dart",
    "utils/botttom_sheet_widget.dart": "features/player/presentation/botttom_sheet_widget.dart",
    "utils/draggable_view.dart": "features/player/presentation/draggable_view.dart",
    "utils/play_list.dart": "features/player/presentation/play_list.dart",
    "utils/player/playing_controls.dart": "features/player/presentation/playing_controls.dart",
    "utils/player/position_seek_widget.dart": "features/player/presentation/position_seek_widget.dart",
    "screens/home/home_screen.dart": "features/home/presentation/home_screen.dart",
    "screens/library/library.dart": "features/library/presentation/library.dart",
    "screens/profile/profile.dart": "features/profile/presentation/profile.dart",
    "screens/search_page/search_page.dart": "features/search/presentation/search_page.dart",
    "screens/search_results/search_result.dart": "features/search/presentation/search_result.dart",
    "screens/genre_page/genre_page.dart": "features/genres/presentation/genre_page.dart",
    "screens/genre_page/cubit/genre_cubit.dart": "features/genres/presentation/genre_cubit.dart",
    "screens/genre_page/cubit/genre_state.dart": "features/genres/presentation/genre_state.dart",
    "screens/liked_songs/liked_songs.dart": "features/liked_songs/presentation/liked_songs.dart",
    "screens/recently_played/recently_played_songs.dart": "features/recently_played/presentation/recently_played_songs.dart",
    "screens/playlist/playlist_songs.dart": "features/playlists/presentation/playlist_songs.dart",
    "screens/add_to_playlist/add_to_playlist.dart": "features/add_to_playlist/presentation/add_to_playlist.dart",
    "screens/artist_profile/artist_profile.dart": "features/artists/presentation/artist_profile.dart",
    "screens/artist_profile/cubit/artist_profile_cubit.dart": "features/artists/presentation/artist_profile_cubit.dart",
    "screens/artist_profile/cubit/artist_profile_state.dart": "features/artists/presentation/artist_profile_state.dart",
    "screens/welcome/welcome_page.dart": "features/onboarding/presentation/welcome_page.dart",
}

RELATIVE_IMPORTS = {
    "../controllers/main_controller.dart": "package:flowly/features/player/domain/main_controller.dart",
    "../../controllers/main_controller.dart": "package:flowly/features/player/domain/main_controller.dart",
    "../../../controllers/main_controller.dart": "package:flowly/features/player/domain/main_controller.dart",
    "../models/song_model.dart": "package:flowly/domain/entities/song_model.dart",
    "../../models/song_model.dart": "package:flowly/domain/entities/song_model.dart",
    "../../../models/song_model.dart": "package:flowly/domain/entities/song_model.dart",
    "../models/user.dart": "package:flowly/domain/entities/user.dart",
    "../../models/user.dart": "package:flowly/domain/entities/user.dart",
    "../../../models/user.dart": "package:flowly/domain/entities/user.dart",
    "../models/user_model.dart": "package:flowly/domain/entities/user_model.dart",
    "../../models/user_model.dart": "package:flowly/domain/entities/user_model.dart",
    "../../../models/user_model.dart": "package:flowly/domain/entities/user_model.dart",
    "../models/catagory.dart": "package:flowly/data/models/catagory.dart",
    "../../models/catagory.dart": "package:flowly/data/models/catagory.dart",
    "../../../models/catagory.dart": "package:flowly/data/models/catagory.dart",
    "../models/loading_enum.dart": "package:flowly/data/models/loading_enum.dart",
    "../../models/loading_enum.dart": "package:flowly/data/models/loading_enum.dart",
    "../../../models/loading_enum.dart": "package:flowly/data/models/loading_enum.dart",
}


def target_for_fragment(path_fragment: str) -> str | None:
    if path_fragment in FRAGMENTS:
        return f"package:flowly/{FRAGMENTS[path_fragment]}"
    return None


def rewrite_imports(text: str) -> str:
    for old, new in RELATIVE_IMPORTS.items():
        text = text.replace(f"'{old}'", f"'{new}'")
        text = text.replace(f'"{old}"', f'"{new}"')

    # Convert imports containing legacy fragments into package imports.
    for old_fragment, new_path in sorted(FRAGMENTS.items(), key=lambda x: -len(x[0])):
        pattern = re.compile(r"import\s+(['\"])([^'\"]*" + re.escape(old_fragment) + r")\1\s*;")
        text = pattern.sub(lambda m: f"import 'package:flowly/{new_path}';", text)

    # Fix common sibling feature imports after flattening paths.
    replacements = {
        "../home/home_screen.dart": "package:flowly/features/home/presentation/home_screen.dart",
        "../library/library.dart": "package:flowly/features/library/presentation/library.dart",
        "../profile/profile.dart": "package:flowly/features/profile/presentation/profile.dart",
        "../search_page/search_page.dart": "package:flowly/features/search/presentation/search_page.dart",
        "../search_results/search_result.dart": "package:flowly/features/search/presentation/search_result.dart",
        "../genre_page/genre_page.dart": "package:flowly/features/genres/presentation/genre_page.dart",
        "../liked_songs/liked_songs.dart": "package:flowly/features/liked_songs/presentation/liked_songs.dart",
        "../recently_played/recently_played_songs.dart": "package:flowly/features/recently_played/presentation/recently_played_songs.dart",
        "../playlist/playlist_songs.dart": "package:flowly/features/playlists/presentation/playlist_songs.dart",
        "../add_to_playlist/add_to_playlist.dart": "package:flowly/features/add_to_playlist/presentation/add_to_playlist.dart",
        "../artist_profile/artist_profile.dart": "package:flowly/features/artists/presentation/artist_profile.dart",
        "../../utils/botttom_sheet_widget.dart": "package:flowly/features/player/presentation/botttom_sheet_widget.dart",
        "../utils/botttom_sheet_widget.dart": "package:flowly/features/player/presentation/botttom_sheet_widget.dart",
        "../../utils/horizontal_songs_list.dart": "package:flowly/shared/widgets/horizontal_songs_list.dart",
        "../utils/horizontal_songs_list.dart": "package:flowly/shared/widgets/horizontal_songs_list.dart",
        "../../utils/loading.dart": "package:flowly/shared/widgets/loading.dart",
        "../utils/loading.dart": "package:flowly/shared/widgets/loading.dart",
        "../utils/app_locale.dart": "package:flowly/app/localization/app_locale.dart",
        "../../utils/app_locale.dart": "package:flowly/app/localization/app_locale.dart",
    }
    for old, new in replacements.items():
        text = text.replace(f"'{old}'", f"'{new}'")
        text = text.replace(f'"{old}"', f'"{new}"')

    # Deduplicate imports introduced by multiple replacements.
    lines = text.splitlines()
    seen: set[str] = set()
    out: list[str] = []
    for line in lines:
        if line.startswith('import ') and line in seen:
            continue
        if line.startswith('import '):
            seen.add(line)
        out.append(line)
    return "\n".join(out) + ("\n" if text.endswith("\n") else "")


def main() -> None:
    for file in LIB.rglob("*.dart"):
        text = file.read_text(encoding="utf-8")
        rewritten = rewrite_imports(text)
        if rewritten != text:
            file.write_text(rewritten, encoding="utf-8")

    # Remove legacy implementation trees only after all Dart imports were rewritten.
    legacy_dirs = ["controllers", "models", "repositories", "screens", "services", "methods", "utils", "api"]
    for dirname in legacy_dirs:
        target = LIB / dirname
        if target.exists():
            shutil.rmtree(target)

    # Make the clean migration self-validating.
    bad = []
    for file in LIB.rglob("*.dart"):
        text = file.read_text(encoding="utf-8")
        if any(fragment in text for fragment in ["lib/controllers", "lib/models", "lib/repositories", "lib/screens", "lib/services", "lib/methods", "lib/utils", "lib/api"]):
            bad.append(str(file))
    if bad:
        raise SystemExit("Legacy imports remain in: " + ", ".join(bad))

    subprocess.run(["flutter", "analyze", "--no-fatal-infos"], cwd=ROOT, check=True)
    subprocess.run(["git", "config", "user.name", "github-actions[bot]"], cwd=ROOT, check=True)
    subprocess.run(["git", "config", "user.email", "41898282+github-actions[bot]@users.noreply.github.com"], cwd=ROOT, check=True)
    subprocess.run(["git", "add", "lib"], cwd=ROOT, check=True)
    subprocess.run(["git", "rm", "tool/migrate_architecture.py", ".github/workflows/migrate-architecture.yml"], cwd=ROOT, check=True)
    result = subprocess.run(["git", "status", "--porcelain"], cwd=ROOT, check=True, capture_output=True, text=True)
    if not result.stdout.strip():
        return
    subprocess.run(["git", "commit", "-m", "Complete migration to FlowLy-v2 architecture"], cwd=ROOT, check=True)
    subprocess.run(["git", "push", "origin", "HEAD:main"], cwd=ROOT, check=True)


if __name__ == "__main__":
    main()
