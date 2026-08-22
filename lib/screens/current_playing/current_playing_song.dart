import 'dart:ui' show lerpDouble;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../controllers/main_controller.dart';
import '../../models/song_model.dart';
import '../../utils/app_locale.dart';
import '../../utils/botttom_sheet_widget.dart';
import '../../utils/player/position_seek_widget.dart';

/// PlayerRoute now uses the same bottom-sheet style motion as Yt-music-Source:
/// the player grows from the mini-player position and can be dragged back down.
class PlayerRoute {
  static final ValueNotifier<bool> isOpenNotifier = ValueNotifier<bool>(false);

  static Future<void> open(BuildContext context, MainController con) async {
    if (isOpenNotifier.value || !context.mounted) return;
    isOpenNotifier.value = true;
    try {
      await Navigator.of(context, rootNavigator: true).push(
        PageRouteBuilder<void>(
          opaque: false,
          fullscreenDialog: true,
          transitionDuration: const Duration(milliseconds: 260),
          reverseTransitionDuration: const Duration(milliseconds: 220),
          pageBuilder: (_, __, ___) => CurrentPlayingSong(con: con),
          transitionsBuilder: (_, animation, __, child) => AnimatedBuilder(
            animation: animation,
            builder: (_, __) => child,
          ),
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

class _CurrentPlayingSongState extends State<CurrentPlayingSong>
    with SingleTickerProviderStateMixin {
  static const double _miniHeight = 64;
  static const double _miniMargin = 8;
  static const double _miniRadius = 14;

  late final AnimationController _motion;
  bool _liked = false;

  @override
  void initState() {
    super.initState();
    _motion = AnimationController(
      vsync: this,
      value: 0,
      duration: const Duration(milliseconds: 260),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _motion.animateTo(1, curve: Curves.easeOutCubic);
    });
  }

  @override
  void dispose() {
    _motion.dispose();
    super.dispose();
  }

  double _clamp(double value, double min, double max) =>
      value.clamp(min, max).toDouble();

  double _remap(double t, double start, double end) =>
      _clamp((t - start) / (end - start), 0, 1);

  void _animateTo(double target) {
    _motion.animateTo(
      target,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  void _onDragUpdate(DragUpdateDetails details) {
    final height = MediaQuery.sizeOf(context).height;
    final range = height - _miniHeight;
    if (range <= 0) return;
    final delta = details.primaryDelta ?? 0;
    _motion.value = _clamp(_motion.value - delta / range, 0, 1);
  }

  void _onDragEnd(DragEndDetails details) {
    const flingVelocity = 600.0;
    final velocity = details.primaryVelocity ?? 0;
    final target = velocity.abs() > flingVelocity
        ? (velocity < 0 ? 1.0 : 0.0)
        : (_motion.value > 0.5 ? 1.0 : 0.0);

    if (target == 0) {
      _minimize();
    } else {
      _animateTo(1);
    }
  }

  void _minimize() {
    _animateTo(0);
    Future<void>.delayed(const Duration(milliseconds: 220), () {
      if (mounted) {
        PlayerRoute.markMinimized();
        Navigator.of(context).pop();
      }
    });
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
            child: AnnotatedRegion<SystemUiOverlayStyle>(
              value: const SystemUiOverlayStyle(
                statusBarColor: Colors.transparent,
                statusBarIconBrightness: Brightness.light,
                systemNavigationBarColor: Colors.black,
                systemNavigationBarIconBrightness: Brightness.light,
              ),
              child: AnimatedBuilder(
                animation: _motion,
                builder: (context, _) {
                  final t = _motion.value;
                  final size = MediaQuery.sizeOf(context);
                  final cardHeight = lerpDouble(_miniHeight, size.height, t)!;
                  final cardMargin = lerpDouble(_miniMargin, 0, t)!;
                  final radius = lerpDouble(_miniRadius, 0, t)!;
                  final artSize = lerpDouble(44, size.width * .72, t)!;
                  final artTop = lerpDouble(10, 64, t)!;
                  final artLeft = lerpDouble(12, (size.width - artSize) / 2, t)!;
                  final artRadius = lerpDouble(8, 12, t)!;
                  final miniOpacity = 1 - _remap(t, 0, .3);
                  final expandedOpacity = _remap(t, .55, 1);

                  return Scaffold(
                    backgroundColor: Colors.transparent,
                    body: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onVerticalDragUpdate: _onDragUpdate,
                      onVerticalDragEnd: _onDragEnd,
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          width: size.width - cardMargin * 2,
                          height: cardHeight,
                          margin: EdgeInsets.symmetric(horizontal: cardMargin),
                          clipBehavior: Clip.antiAlias,
                          decoration: BoxDecoration(
                            color: Color.lerp(
                              const Color(0xFF1B1B1B),
                              const Color(0xFF111111),
                              t,
                            ),
                            borderRadius: BorderRadius.circular(radius),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(
                                  lerpDouble(.25, 0, t)!,
                                ),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Stack(
                            children: [
                              if (t > .35)
                                Positioned.fill(
                                  child: Opacity(
                                    opacity: expandedOpacity,
                                    child: _ExpandedPlayer(
                                      con: con,
                                      song: song,
                                      onMinimize: _minimize,
                                      onLike: () => _like(song),
                                      onMore: () => showModalBottomSheet<void>(
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
                                    ),
                                  ),
                                ),
                              Positioned(
                                top: artTop,
                                left: artLeft,
                                width: artSize,
                                height: artSize,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(artRadius),
                                  child: CachedNetworkImage(
                                    imageUrl: song.coverImageUrl ?? '',
                                    fit: BoxFit.cover,
                                    placeholder: (_, __) =>
                                        const ColoredBox(color: Color(0xFF252525)),
                                    errorWidget: (_, __, ___) =>
                                        const ColoredBox(color: Color(0xFF252525)),
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 0,
                                left: 68,
                                right: 56,
                                height: _miniHeight,
                                child: IgnorePointer(
                                  ignoring: t > .3,
                                  child: Opacity(
                                    opacity: miniOpacity,
                                    child: GestureDetector(
                                      onTap: () => _animateTo(1),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            song.songname ?? '',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          Text(
                                            song.name ?? 'FlowLy',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              color: Colors.white70,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                right: 8,
                                top: 0,
                                height: _miniHeight,
                                child: IgnorePointer(
                                  ignoring: t > .3,
                                  child: Opacity(
                                    opacity: miniOpacity,
                                    child: _RoundIconButton(
                                      icon: con.isPlaying
                                          ? Icons.pause
                                          : Icons.play_arrow,
                                      onTap: con.playOrPause,
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 8,
                                left: 0,
                                right: 0,
                                child: IgnorePointer(
                                  ignoring: t < .5,
                                  child: Opacity(
                                    opacity: _remap(t, .5, 1),
                                    child: Center(
                                      child: Container(
                                        width: 36,
                                        height: 4,
                                        decoration: BoxDecoration(
                                          color: Colors.white38,
                                          borderRadius: BorderRadius.circular(2),
                                        ),
                                      ),
                                    ),
                                  ),
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
}

class _ExpandedPlayer extends StatelessWidget {
  final MainController con;
  final dynamic song;
  final VoidCallback onMinimize;
  final VoidCallback onLike;
  final VoidCallback onMore;

  const _ExpandedPlayer({
    required this.con,
    required this.song,
    required this.onMinimize,
    required this.onLike,
    required this.onMore,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: onMinimize,
                      icon: const Icon(Icons.keyboard_arrow_down,
                          color: Colors.white, size: 29),
                    ),
                    IconButton(
                      onPressed: onMore,
                      icon: const Icon(Icons.more_vert,
                          color: Colors.white, size: 29),
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
                        song.name?.isNotEmpty == true ? song.name! : 'FlowLy',
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
                            onPressed: onLike,
                            icon: const Icon(Icons.thumb_up_alt_outlined,
                                color: Colors.white, size: 29),
                          ),
                          IconButton(
                            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(AppLocale.text(
                                  'Комментарии пока недоступны',
                                  'Comments are not available yet',
                                )),
                              ),
                            ),
                            icon: const Icon(Icons.chat_bubble_outline,
                                color: Colors.white, size: 29),
                          ),
                          const Spacer(),
                          IconButton(
                            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(AppLocale.text(
                                  'Скачивание временно отключено: серверный API ещё не готов.',
                                  'Downloads are temporarily disabled: the server API is not ready yet.',
                                )),
                              ),
                            ),
                            icon: const Icon(Icons.download_rounded,
                                color: Colors.white, size: 30),
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
            child: CachedNetworkImage(imageUrl: url, fit: BoxFit.cover),
          ),
        ),
        Container(color: Colors.black.withValues(alpha: 0.55)),
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
      aspectRatio: .98,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: CachedNetworkImage(
          imageUrl: imageUrl ?? '',
          fit: BoxFit.cover,
          placeholder: (_, __) => const ColoredBox(color: Color(0xFF1B1B1B)),
          errorWidget: (_, __, ___) => const ColoredBox(
            color: Color(0xFF151515),
            child: Icon(Icons.music_note, color: Colors.white54, size: 72),
          ),
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
            onPressed: con.songs.length > 1 ? con.toggleShuffle : null,
            icon: Icon(Icons.shuffle,
                color: con.isShuffled ? Colors.white : Colors.white54,
                size: 28),
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
                width: 82,
                height: 82,
                child: Icon(con.isPlaying ? Icons.pause : Icons.play_arrow,
                    color: Colors.white, size: 42),
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

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({required this.icon, this.onTap, this.size = 40});

  final IconData icon;
  final double size;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white12,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(icon, color: Colors.white, size: size * .55),
        ),
      ),
    );
  }
}
