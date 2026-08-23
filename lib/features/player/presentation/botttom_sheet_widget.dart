import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher_string.dart';

import 'package:flowly/features/player/domain/main_controller.dart';
import 'package:flowly/core/utils/snackbar.dart';
import 'package:flowly/domain/entities/song_model.dart';
import 'package:flowly/features/add_to_playlist/presentation/add_to_playlist.dart';
import 'package:flowly/shared/widgets/like_button.dart';
import 'package:flowly/shared/widgets/loading.dart';

class BottomSheetWidget extends StatelessWidget {
  final MainController con;
  final bool? isNext;
  final SongModel song;

  const BottomSheetWidget({
    super.key,
    required this.con,
    this.isNext,
    required this.song,
  });

  @override
  Widget build(BuildContext context) {
    final ratio = MediaQuery.of(context).devicePixelRatio;

    return SafeArea(
      child: Container(
        color: Colors.black,
        padding: const EdgeInsets.only(bottom: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 24),
            SizedBox(
              width: 160,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: song.coverImageUrl ?? '',
                  fit: BoxFit.cover,
                  memCacheHeight: (300 * ratio).round(),
                  memCacheWidth: (300 * ratio).round(),
                  progressIndicatorBuilder: (_, __, ___) => const LoadingImage(),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(song.songname ?? '', textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 4),
            Text(song.name ?? '', textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey)),
            const SizedBox(height: 12),
            LikeButton(
              id: song.songid ?? '',
              isIcon: true,
              cover: song.coverImageUrl ?? '',
              fullname: song.name ?? '',
              name: song.songname ?? '',
              track: song.trackid ?? '',
              username: song.userid ?? '',
            ),
            if (isNext == null)
              ListTile(
                onTap: () {
                  final current = con.currentIndex;
                  con.insertToPlaylist(current + 1, song);
                  context.showSnackBar(message: 'Added to Queue');
                  Navigator.pop(context);
                },
                leading: const Icon(CupertinoIcons.play_arrow, color: Colors.grey),
                title: Text('Play Next', style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontSize: 20, color: Colors.white)),
              ),
            ListTile(
              onTap: () {
                con.addToPlaylist(song);
                context.showSnackBar(message: 'Added to Queue');
                Navigator.pop(context);
              },
              leading: const Icon(Icons.playlist_add, color: Colors.grey),
              title: Text('Add To queue', style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontSize: 20, color: Colors.white)),
            ),
            ListTile(
              onTap: () {
                Navigator.push(
                  context,
                  CupertinoPageRoute(
                    builder: (_) => AddToPlaylist(
                      id: song.songid ?? '',
                      cover: song.coverImageUrl ?? '',
                      fullname: song.name ?? '',
                      name: song.songname ?? '',
                      track: song.trackid ?? '',
                      username: song.userid ?? '',
                    ),
                  ),
                );
              },
              leading: const Icon(CupertinoIcons.music_albums, color: Colors.grey),
              title: Text('Add to Playlist', style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontSize: 20, color: Colors.white)),
            ),
            ListTile(
              onTap: () => launchUrlString(song.trackid ?? ''),
              leading: const Icon(Icons.download, color: Colors.grey),
              title: Text('Download', style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontSize: 20, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
