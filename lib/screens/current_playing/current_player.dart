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

class CurrentPlayer extends StatelessWidget {
  final MainController con;

  const CurrentPlayer({
    super.key,
    required this.con,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: con,
      builder: (context, child) {
        final song = con.currentSong;
        if (song == null) return const SizedBox.shrink();
        final ratio = MediaQuery.of(context).devicePixelRatio;

        return Container(
          color: Colors.black,
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_ios,
                          color: Colors.white),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          const Text('NOW PLAYING',
                              style: TextStyle(color: Colors.white)),
                          Text(song.name ?? '',
                              style: const TextStyle(color: Colors.grey)),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          backgroundColor: Colors.black,
                          builder: (_) => BottomSheetWidget(
                            con: con,
                            isNext: true,
                            song: song,
                          ),
                        );
                      },
                      icon: const Icon(Icons.more_vert, color: Colors.white),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 26),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: CachedNetworkImage(
                      imageUrl: song.coverImageUrl ?? '',
                      fit: BoxFit.cover,
                      memCacheHeight: (400 * ratio).round(),
                      memCacheWidth: (400 * ratio).round(),
                      progressIndicatorBuilder: (_, __, ___) =>
                          const LoadingImage(
                        icon: Icon(LineIcons.compactDisc, size: 120),
                      ),
                    ),
                  ),
                ),
                Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(song.songname ?? '',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineSmall),
                                Text(song.name ?? '',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyLarge
                                        ?.copyWith(color: Colors.grey)),
                              ],
                            ),
                          ),
                          LikeButton(
                            name: song.songname ?? '',
                            fullname: song.name ?? '',
                            username: song.userid ?? '',
                            id: song.songid ?? '',
                            track: song.trackid ?? '',
                            isIcon: false,
                            cover: song.coverImageUrl ?? '',
                          ),
                        ],
                      ),
                    ),
                    PositionSeekWidget(
                      currentPosition: con.position,
                      duration: con.duration,
                      seekTo: con.seek,
                    ),
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          onPressed: () =>
                              launchUrlString(song.trackid ?? ''),
                          icon: const Icon(Icons.download_sharp,
                              color: Colors.grey),
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
                          icon: const Icon(CupertinoIcons.music_note_list,
                              color: Colors.grey),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
