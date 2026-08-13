import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../controllers/main_controller.dart';
import '../../models/song_model.dart';
import '../../utils/app_locale.dart';
import '../../utils/botttom_sheet_widget.dart';
import '../../utils/player/position_seek_widget.dart';

class PlayerRoute {
  static final ValueNotifier<bool> isOpenNotifier = ValueNotifier<bool>(false);

  static Future<void> open(BuildContext context, MainController con) async {
    if (isOpenNotifier.value || !context.mounted) return;
    isOpenNotifier.value = true;
    try {
      await Navigator.of(context, rootNavigator: true).push(
        PageRouteBuilder<void>(
          opaque: true,
          fullscreenDialog: true,
          transitionDuration: const Duration(milliseconds: 320),
          reverseTransitionDuration: const Duration(milliseconds: 260),
          pageBuilder: (_, __, ___) => CurrentPlayingSong(con: con),
          transitionsBuilder: (_, animation, __, child) {
            final curved = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
              reverseCurve: Curves.easeInCubic,
            );
            return SlideTransition(
              position: curved.drive(
                Tween<Offset>(
                  begin: const Offset(0, 1),
                  end: Offset.zero,
                ),
              ),
              child: child,
            );
          },
        ),
      );
    } finally {
      isOpenNotifier.value = false;
    }
  }

  static void markMinimized() => isOpenNotifier.value = false;
}

class CurrentPlayingSong extends StatefulWidget {
  final MainController con;

  const CurrentPlayingSong({super.key, required this.con});

  @override
  State<CurrentPlayingSong> createState() => _CurrentPlayingSongState();
}

class _CurrentPlayingSongState extends State<CurrentPlayingSong> {
  bool _liked = false;
  double? _dragStartY;

  void _minimize() {
    PlayerRoute.markMinimized();
    if (mounted) Navigator.of(context).pop();
  }

  void _handlePointerDown(PointerDownEvent event) {
    _dragStartY = event.position.dy;
  }

  void _handlePointerUp(PointerUpEvent event) {
    final startY = _dragStartY;
    _dragStartY = null;
    if (startY == null) return;
    final delta = event.position.dy - startY;
    if (startY <= 150 && delta >= 110) _minimize();
  }

  @override
  Widget build(BuildContext context) {
    final con = widget.con;

    return ValueListenableBuilder<String>(
      valueListenable: AppLocale.language,
      builder: (context, _, __) => AnimatedBuilder(
        animation: con,
        builder: (context, child) {
          final song = con.currentSong;
          if (song == null) return const SizedBox.shrink();

          return PopScope<void>(
            onPopInvokedWithResult: (didPop, result) {
              if (didPop) PlayerRoute.markMinimized();
            },
            child: Listener(
              onPointerDown: _handlePointerDown,
              onPointerUp: _handlePointerUp,
              child: AnnotatedRegion<SystemUiOverlayStyle>(
                value: const SystemUiOverlayStyle(
                  statusBarColor: Colors.transparent,
                  statusBarIconBrightness: Brightness.light,
                  systemNavigationBarColor: Colors.black,
                  systemNavigationBarIconBrightness: Brightness.light,
                ),
                child: Scaffold(
                  backgroundColor: const Color(0xFF111111),
                  body: Stack(
                    fit: StackFit.expand,
                    children: [
                      _BlurredArtworkBackground(imageUrl: song.coverImageUrl),
                      SafeArea(
                        bottom: false,
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  IconButton(
                                    tooltip: AppLocale.text('Назад', 'Back'),
                                    onPressed: _minimize,
                                    icon: const Icon(
                                      Icons.arrow_back_ios_new,
                                      color: Colors.white,
                                      size: 25,
                                    ),
                                  ),
                                  IconButton(
                                    tooltip: AppLocale.text('Еще', 'More'),
                                    onPressed: () => showModalBottomSheet<void>(
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
                                    ),
                                    icon: const Icon(
                                      Icons.more_vert,
                                      color: Colors.white,
                                      size: 29,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: SingleChildScrollView(
                                physics: const ClampingScrollPhysics(),
                                padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    _Artwork(imageUrl: song.coverImageUrl),
                                    const SizedBox(height: 20),
                                    Text(
                                      song.songname ?? '',
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 28,
                                        height: 1.05,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      song.name?.isNotEmpty == true
                                          ? song.name!
                                          : 'FlowLy',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Color(0xFFC9C9C9),
                                        fontSize: 18,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Row(
                                      children: [
                                        IconButton(
                                          tooltip: AppLocale.text('Нравится', 'Like'),
                                          onPressed: () => _like(song),
                                          icon: Icon(
                                            _liked
                                                ? Icons.thumb_up_alt
                                                : Icons.thumb_up_alt_outlined,
                                            color: Colors.white,
                                            size: 29,
                                          ),
                                        ),
                                        IconButton(
                                          tooltip: AppLocale.text(
                                            'Комментарии',
                                            'Comments',
                                          ),
                                          onPressed: () => _showMessage(
                                            AppLocale.text(
                                              'Комментарии пока недоступны',
                                              'Comments are not available yet',
                                            ),
                                          ),
                                          icon: const Icon(
                                            Icons.chat_bubble_outline,
                                            color: Colors.white,
                                            size: 29,
                                          ),
                                        ),
                                        const Spacer(),
                                        IconButton(
                                          tooltip: AppLocale.text('Скачать', 'Download'),
                                          onPressed: _downloadUnavailable,
                                          icon: const Icon(
                                            Icons.download_rounded,
                                            color: Colors.white,
                                            size: 30,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    PositionSeekWidget(
                                      currentPosition: con.position,
                                      duration: con.duration,
                                      seekTo: con.seek,
                                    ),
                                    const SizedBox(height: 14),
                                    _ControlRow(con: con),
                                    const SizedBox(height: 18),
                                    const _BottomTabs(),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _like(dynamic song) {
    if (song.trackid != null && song.trackid!.isNotEmpty) {
      widget.con.addToFavorite(
        name: song.songname ?? '',
        fullname: song.name ?? '',
        username: song.userid ?? '',
        cover: song.coverImageUrl ?? '',
        track: song.trackid ?? '',
      );
    }
    setState(() => _liked = !_liked);
  }

  void _downloadUnavailable() {
    _showMessage(
      AppLocale.text(
        'Скачивание временно отключено: серверный API ещё не готов.',
        'Downloads are temporarily disabled: the server API is not ready yet.',
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

class _BlurredArtworkBackground extends StatelessWidget {
  final String? imageUrl;

  const _BlurredArtworkBackground({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    final url = imageUrl ?? '';
    if (url.isEmpty) return Container(color: const Color(0xFF111111));

    return Stack(
      fit: StackFit.expand,
      children: [
        ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          child: Transform.scale(
            scale: 1.14,
            child: CachedNetworkImage(
              imageUrl: url,
              fit: BoxFit.cover,
              alignment: Alignment.center,
              errorWidget: (_, __, ___) => Container(
                color: const Color(0xFF111111),
              ),
            ),
          ),
        ),
        Container(color: Colors.black.withValues(alpha: 0.55)),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0x22111111),
                Color(0x66111111),
                Color(0x99111111),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Artwork extends StatelessWidget {
  final String? imageUrl;

  const _Artwork({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 0.98,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          fit: StackFit.expand,
          children: [
            CachedNetworkImage(
              imageUrl: imageUrl ?? '',
              fit: BoxFit.cover,
              placeholder: (_, __) =>
                  Container(color: const Color(0xFF1B1B1B)),
              errorWidget: (_, __, ___) => Container(
                color: const Color(0xFF151515),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.music_note,
                  color: Colors.white54,
                  size: 72,
                ),
              ),
            ),
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Color(0xB0000000)],
                    stops: [0.62, 1],
                  ),
                ),
              ),
            ),
          ],
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
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            tooltip: 'Shuffle',
            onPressed: con.songs.length > 1 ? con.toggleShuffle : null,
            icon: Icon(
              Icons.shuffle,
              color: con.isShuffled ? Colors.white : Colors.white54,
              size: 28,
            ),
          ),
          IconButton(
            tooltip: 'Previous',
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
                width: 82,
                height: 82,
                child: Icon(
                  con.isPlaying ? Icons.pause : Icons.play_arrow,
                  color: Colors.white,
                  size: 42,
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Next',
            onPressed: con.songs.length > 1 ? con.next : null,
            icon: const Icon(Icons.skip_next, color: Colors.white, size: 38),
          ),
          IconButton(
            tooltip: 'Repeat',
            onPressed: con.toggleLoop,
            icon: Icon(
              con.loopMode == LoopModeType.one ? Icons.repeat_one : Icons.repeat,
              color: con.loopMode == LoopModeType.none
                  ? Colors.white54
                  : Colors.white,
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _BottomTabLabel(AppLocale.text('ДАЛЕЕ', 'UP NEXT')),
          _BottomTabLabel(AppLocale.text('ТЕКСТ', 'LYRICS')),
          _BottomTabLabel(AppLocale.text('ПОХОЖИЕ', 'RELATED')),
        ],
      ),
    );
  }
}

class _BottomTabLabel extends StatelessWidget {
  final String text;

  const _BottomTabLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
          color: Color(0xFFD0D0D0),
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      );
}
