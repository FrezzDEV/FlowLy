import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../../controllers/main_controller.dart';
import '../../models/song_model.dart';
import '../../utils/botttom_sheet_widget.dart';
import '../../utils/loading.dart';
import '../../utils/play_list.dart';
import '../../utils/player/position_seek_widget.dart';

class CurrentPlayingSong extends StatefulWidget {
  final MainController con;

  const CurrentPlayingSong({
    super.key,
    required this.con,
  });

  @override
  State<CurrentPlayingSong> createState() => _CurrentPlayingSongState();
}

class _CurrentPlayingSongState extends State<CurrentPlayingSong> {
  bool _videoMode = false;
  bool _thumbUp = false;
  bool _thumbDown = false;

  @override
  Widget build(BuildContext context) {
    final con = widget.con;

    return AnimatedBuilder(
      animation: con,
      builder: (context, child) {
        final song = con.currentSong;
        if (song == null) return const SizedBox.shrink();

        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: const SystemUiOverlayStyle(
            statusBarColor: Color(0xFF535353),
            statusBarIconBrightness: Brightness.light,
            systemNavigationBarColor: Color(0xFF535353),
            systemNavigationBarIconBrightness: Brightness.light,
          ),
          child: Scaffold(
            backgroundColor: const Color(0xFF535353),
            body: SafeArea(
              child: Column(
                children: [
                  _TopBar(
                    videoMode: _videoMode,
                    onBack: () => Navigator.pop(context),
                    onModeChanged: (video) {
                      setState(() => _videoMode = video);
                    },
                    onMore: () {
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
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const ClampingScrollPhysics(),
                      child: Column(
                        children: [
                          const SizedBox(height: 26),
                          _ArtworkPanel(
                            imageUrl: song.coverImageUrl,
                            videoMode: _videoMode,
                            onCast: () => _showMessage(context, 'Cast пока недоступен'),
                            onFullscreen: () => _showMessage(context, 'Плеер уже открыт на весь экран'),
                            onShare: () => _copyToClipboard(context, song.songname ?? 'FlowLy'),
                            onDownload: () => launchUrlString(song.trackid ?? ''),
                            onQueue: () {
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
                            onRadio: () {
                              if (con.songs.length > 1) {
                                con.toggleShuffle();
                                con.next();
                              } else {
                                _showMessage(context, 'В очереди пока нет других треков');
                              }
                            },
                          ),
                          const SizedBox(height: 22),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 36),
                            child: Row(
                              children: [
                                IconButton(
                                  onPressed: () {
                                    setState(() {
                                      _thumbDown = !_thumbDown;
                                      if (_thumbDown) _thumbUp = false;
                                    });
                                  },
                                  icon: Icon(
                                    Icons.thumb_down_alt_outlined,
                                    color: _thumbDown ? Colors.white : Colors.white70,
                                    size: 30,
                                  ),
                                ),
                                Expanded(
                                  child: Column(
                                    children: [
                                      Text(
                                        song.songname ?? '',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 25,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        song.name ?? 'FlowLy',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          color: Color(0xFFBDBDBD),
                                          fontSize: 18,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  onPressed: () {
                                    if (song.trackid != null && song.trackid!.isNotEmpty) {
                                      con.addToFavorite(
                                        name: song.songname ?? '',
                                        fullname: song.name ?? '',
                                        username: song.userid ?? '',
                                        cover: song.coverImageUrl ?? '',
                                        track: song.trackid ?? '',
                                      );
                                    }
                                    setState(() {
                                      _thumbUp = !_thumbUp;
                                      if (_thumbUp) _thumbDown = false;
                                    });
                                  },
                                  icon: Icon(
                                    Icons.thumb_up_alt,
                                    color: _thumbUp ? Colors.white : Colors.white,
                                    size: 31,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 18),
                            child: PositionSeekWidget(
                              currentPosition: con.position,
                              duration: con.duration,
                              seekTo: con.seek,
                            ),
                          ),
                          const SizedBox(height: 4),
                          _ControlRow(con: con),
                          const SizedBox(height: 22),
                        ],
                      ),
                    ),
                  ),
                  const _BottomTabs(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _copyToClipboard(BuildContext context, String value) {
    Clipboard.setData(ClipboardData(text: value));
    _showMessage(context, 'Название трека скопировано');
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final bool videoMode;
  final VoidCallback onBack;
  final ValueChanged<bool> onModeChanged;
  final VoidCallback onMore;

  const _TopBar({
    required this.videoMode,
    required this.onBack,
    required this.onModeChanged,
    required this.onMore,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 27),
          ),
          Expanded(
            child: Center(
              child: Container(
                width: 158,
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => onModeChanged(false),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          decoration: BoxDecoration(
                            color: videoMode ? Colors.transparent : const Color(0xFF686868),
                            borderRadius: BorderRadius.circular(28),
                          ),
                          alignment: Alignment.center,
                          child: const Text(
                            'Song',
                            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => onModeChanged(true),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          decoration: BoxDecoration(
                            color: videoMode ? const Color(0xFF686868) : Colors.transparent,
                            borderRadius: BorderRadius.circular(28),
                          ),
                          alignment: Alignment.center,
                          child: const Text(
                            'Video',
                            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          IconButton(
            onPressed: onMore,
            icon: const Icon(Icons.more_vert, color: Colors.white, size: 30),
          ),
        ],
      ),
    );
  }
}

class _ArtworkPanel extends StatelessWidget {
  final String? imageUrl;
  final bool videoMode;
  final VoidCallback onCast;
  final VoidCallback onFullscreen;
  final VoidCallback onShare;
  final VoidCallback onDownload;
  final VoidCallback onQueue;
  final VoidCallback onRadio;

  const _ArtworkPanel({
    required this.imageUrl,
    required this.videoMode,
    required this.onCast,
    required this.onFullscreen,
    required this.onShare,
    required this.onDownload,
    required this.onQueue,
    required this.onRadio,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: AspectRatio(
        aspectRatio: 0.82,
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: CachedNetworkImage(
                imageUrl: imageUrl ?? '',
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => Container(
                  color: const Color(0xFF151515),
                  child: const Icon(Icons.music_note, color: Colors.white54, size: 64),
                ),
                placeholder: (_, __) => Container(color: const Color(0xFF1B1B1B)),
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Color(0xEE000000)],
                    stops: [0.45, 1],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 18,
              right: 18,
              child: _CircleButton(icon: Icons.cast_outlined, onTap: onCast),
            ),
            Positioned(
              bottom: 26,
              left: 22,
              right: 22,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _CircleButton(icon: Icons.ios_share_outlined, onTap: onShare),
                  _CircleButton(icon: Icons.download_for_offline_rounded, onTap: onDownload),
                  _CircleButton(icon: Icons.playlist_add, onTap: onQueue),
                  _CircleButton(icon: Icons.radio_outlined, onTap: onRadio),
                ],
              ),
            ),
            Positioned(
              bottom: 14,
              right: 12,
              child: IconButton(
                onPressed: onFullscreen,
                icon: const Icon(Icons.fullscreen, color: Colors.white, size: 28),
              ),
            ),
            if (videoMode)
              Positioned.fill(
                child: Container(
                  color: const Color(0x55000000),
                  alignment: Alignment.center,
                  child: const Text(
                    'Video mode',
                    style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF686868),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: const SizedBox(
          width: 62,
          height: 62,
          child: Icon(Icons.circle, color: Colors.transparent),
        ),
      ),
    );
  }
}

class _ControlRow extends StatelessWidget {
  final MainController con;

  const _ControlRow({required this.con});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 36),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: con.songs.length > 1 ? con.toggleShuffle : null,
            icon: Icon(Icons.shuffle, color: con.isShuffled ? Colors.white : Colors.white54, size: 28),
          ),
          IconButton(
            onPressed: con.songs.length > 1 ? con.previous : null,
            icon: const Icon(Icons.skip_previous, color: Colors.white, size: 38),
          ),
          Material(
            color: const Color(0xFF777777),
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: con.playOrPause,
              child: SizedBox(
                width: 86,
                height: 86,
                child: Icon(
                  con.isPlaying ? Icons.pause : Icons.play_arrow,
                  color: Colors.white,
                  size: 42,
                ),
              ),
            ),
          ),
          IconButton(
            onPressed: con.songs.length > 1 ? con.next : null,
            icon: const Icon(Icons.skip_next, color: Colors.white, size: 38),
          ),
          IconButton(
            onPressed: con.toggleLoop,
            icon: Icon(
              con.loopMode == LoopModeType.one ? Icons.repeat_one : Icons.repeat,
              color: con.loopMode == LoopModeType.none ? Colors.white54 : Colors.white,
              size: 28,
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomTabs extends StatelessWidget {
  const _BottomTabs();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(28, 10, 28, 16),
      decoration: const BoxDecoration(
        color: Color(0xFF606060),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(18),
          topRight: Radius.circular(18),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: const [
          _BottomTabLabel('UP NEXT'),
          _BottomTabLabel('LYRICS'),
          _BottomTabLabel('RELATED'),
        ],
      ),
    );
  }
}

class _BottomTabLabel extends StatelessWidget {
  final String text;
  const _BottomTabLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xFFBDBDBD),
        fontSize: 17,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}
