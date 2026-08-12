import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:line_icons/line_icons.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../../controllers/main_controller.dart';
import '../../models/song_model.dart';
import '../../utils/botttom_sheet_widget.dart';
import '../../utils/like_button/like_button.dart';
import '../../utils/loading.dart';
import '../../utils/play_list.dart';
import '../../utils/player/playing_controls.dart';
import '../../utils/player/position_seek_widget.dart';

class CurrentPlayingSong extends StatelessWidget {
  final MainController con;

  const CurrentPlayingSong({
    super.key,
    required this.con,
  });

  @override
  Widget build(BuildContext context) {
    final ratio = MediaQuery.of(context).devicePixelRatio;

    return AnimatedBuilder(
      animation: con,
      builder: (context, child) {
        final song = con.currentSong;
        if (song == null) return const SizedBox.shrink();

        return Scaffold(
          backgroundColor: Colors.black,
          body: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(
                          Icons.arrow_back_ios,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const Expanded(
                        child: Column(
                          children: [
                            Text(
                              'NOW PLAYING',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 5),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.black,
                            builder: (_) => BottomSheetWidget(
                              con: con,
                              isNext: true,
                              song: SongModel(
                                songid: song.songid,
                                songname: song.songname,
                                userid: song.userid,
                                trackid: song.trackid,
                                duration: song.duration,
                                coverImageUrl: song.coverImageUrl,
                                name: song.name,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(
                          Icons.more_vert,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 46),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 46),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedNetworkImage(
                        imageUrl: song.coverImageUrl ?? '',
                        fit: BoxFit.cover,
                        memCacheHeight: (480 * ratio).round(),
                        memCacheWidth: (480 * ratio).round(),
                        progressIndicatorBuilder: (_, __, ___) =>
                            const LoadingImage(
                          icon: Icon(LineIcons.compactDisc, size: 120),
                        ),
                      ),
                    ),
                  ),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 36),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              song.songname ?? '',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 27,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              song.name ?? '',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFF8A8A8A),
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 14),
                      SizedBox(
                        width: 48,
                        height: 52,
                        child: Center(
                          child: LikeButton(
                            name: song.songname ?? '',
                            fullname: song.name ?? '',
                            username: song.userid ?? '',
                            id: song.songid ?? '',
                            track: song.trackid ?? '',
                            isIcon: false,
                            cover: song.coverImageUrl ?? '',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                PositionSeekWidget(
                  currentPosition: con.position,
                  duration: con.duration,
                  seekTo: con.seek,
                ),
                const SizedBox(height: 12),
                PlayingControls(
                  loopMode: con.loopMode,
                  isPlaying: con.isPlaying,
                  con: con,
                  isPlaylist: con.songs.length > 1,
                  onStop: con.stop,
                  toggleLoop: con.toggleLoop,
                  onPlay: con.playOrPause,
                  onNext: con.next,
                  onPrevious: con.previous,
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 36),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: () => launchUrlString(song.trackid ?? ''),
                        icon: const Icon(
                          Icons.download_outlined,
                          color: Color(0xFF8A8A8A),
                          size: 28,
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            CupertinoPageRoute(
                              builder: (_) => PlayListWidget(
                                songs: con.songs,
                                con: con,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(
                          CupertinoIcons.music_note_list,
                          color: Color(0xFF8A8A8A),
                          size: 27,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }
}
