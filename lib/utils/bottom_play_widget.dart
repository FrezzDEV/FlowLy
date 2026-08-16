import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../controllers/main_controller.dart';
import '../utils/app_locale.dart';
import 'botttom_sheet_widget.dart';
import 'loading.dart';
import 'player/position_seek_widget.dart';

/// Single global player surface.
///
/// Progress 0 = mini-player above the main navigation bar.
/// Progress 1 = full-screen player. The same widget instance is used for both
/// states, so no Navigator route is pushed when opening the player.
class BottomPlayWidget extends StatefulWidget {
  const BottomPlayWidget({
    super.key,
    required this.con,
    this.navBarHeight = 64,
  });

  final MainController con;
  final double navBarHeight;

  @override
  State<BottomPlayWidget> createState() => BottomPlayWidgetState();
}

class BottomPlayWidgetState extends State<BottomPlayWidget>
    with SingleTickerProviderStateMixin {
  static const double _miniHeight = 64;
  static const double _snapThreshold = 0.15;

  late final AnimationController _progress;
  bool _dragging = false;
  double _dragStartValue = 0;

  MainController get con => widget.con;

  @override
  void initState() {
    super.initState();
    _progress = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      lowerBound: 0,
      upperBound: 1,
      value: 0,
    );
  }

  void expand() {
    if (!mounted || con.currentSong == null) return;
    _progress.animateTo(1, curve: Curves.easeOutCubic);
  }

  void collapse() {
    if (!mounted) return;
    _progress.animateTo(0, curve: Curves.easeOutCubic);
  }

  void _onDragStart(DragStartDetails details) {
    _progress.stop();
    _dragging = true;
    _dragStartValue = _progress.value;
  }

  void _onDragUpdate(DragUpdateDetails details, double travel) {
    if (!_dragging || travel <= 0) return;
    final delta = details.primaryDelta ?? 0;
    _progress.value = (_progress.value - (delta / travel)).clamp(0.0, 1.0);
  }

  void _onDragEnd(DragEndDetails details) {
    if (!_dragging) return;
    _dragging = false;

    final velocity = details.primaryVelocity ?? 0;
    final fastUp = velocity < -700;
    final fastDown = velocity > 700;

    final target = fastUp
        ? 1.0
        : fastDown
            ? 0.0
            : _progress.value >= _snapThreshold
                ? 1.0
                : 0.0;

    _progress.animateTo(
      target,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  void _handleBack() => collapse();

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge(<Listenable>[_progress, con]),
      builder: (context, _) {
        final song = con.currentSong;
        if (song == null) return const SizedBox.shrink();

        final media = MediaQuery.of(context);
        final screen = media.size;
        final topSafe = media.padding.top;
        final bottomSafe = media.padding.bottom;
        final t = _progress.value.clamp(0.0, 1.0);
        final miniBottom = screen.height - widget.navBarHeight;
        final fullTop = topSafe;
        final top = lerpDouble(
          miniBottom - _miniHeight,
          fullTop,
          t,
        )!;
        final height = lerpDouble(
          _miniHeight,
          screen.height - fullTop,
          t,
        )!;
        final artworkSize = lerpDouble(
          48,
          (screen.width - 48).clamp(220.0, 440.0),
          Curves.easeOutCubic.transform(t),
        )!;
        final artworkLeft = lerpDouble(
          8,
          (screen.width - artworkSize) / 2,
          Curves.easeOutCubic.transform(t),
        )!;
        final artworkTop = lerpDouble(
          top + 8,
          fullTop + 70,
          Curves.easeOutCubic.transform(t),
        )!;
        final miniOpacity = (1 - _smoothstep(t, 0.0, 0.18)).clamp(0.0, 1.0);
        final fullOpacity = _smoothstep(t, 0.12, 0.55);
        final scrimOpacity = 0.56 * _smoothstep(t, 0.08, 0.72);
        final backgroundOpacity = _smoothstep(t, 0.0, 0.35);
        final surfaceRadius = lerpDouble(14, 0, t)!;
        final travel = (miniBottom - _miniHeight - fullTop).clamp(1.0, screen.height);

        return Stack(
          fit: StackFit.expand,
          children: [
            if (scrimOpacity > 0.001)
              Positioned.fill(
                child: IgnorePointer(
                  child: ColoredBox(
                    color: Colors.black.withValues(alpha: scrimOpacity),
                  ),
                ),
              ),
            Positioned(
              left: 0,
              right: 0,
              top: top,
              height: height,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onVerticalDragStart: _onDragStart,
                onVerticalDragUpdate: (details) =>
                    _onDragUpdate(details, travel),
                onVerticalDragEnd: _onDragEnd,
                child: ClipRRect(
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(surfaceRadius),
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    clipBehavior: Clip.none,
                    children: [
                      _PlayerBackdrop(
                        imageUrl: song.coverImageUrl,
                        opacity: backgroundOpacity,
                        blurSigma: lerpDouble(8, 30, t)!,
                      ),
                      const ColoredBox(color: Color(0xD9000000)),
                      if (t < 0.02)
                        Positioned.fill(
                          child: IgnorePointer(
                            ignoring: false,
                            child: GestureDetector(
                              behavior: HitTestBehavior.translucent,
                              onTap: expand,
                            ),
                          ),
                        ),
                      _Artwork(
                        imageUrl: song.coverImageUrl,
                        left: artworkLeft,
                        top: artworkTop - top,
                        size: artworkSize,
                      ),
                      Positioned(
                        left: lerpDouble(64, 24, t)!,
                        right: 64,
                        top: lerpDouble(19, artworkTop + artworkSize + 20, t)!,
                        child: IgnorePointer(
                          ignoring: miniOpacity < 0.02,
                          child: Opacity(
                            opacity: miniOpacity,
                            child: Text(
                              song.songname ?? '',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 24,
                        right: 24,
                        top: topSafe + 8 - top,
                        child: IgnorePointer(
                          ignoring: fullOpacity < 0.02,
                          child: Opacity(
                            opacity: fullOpacity,
                            child: _FullPlayerHeader(
                              onBack: _handleBack,
                              onMore: () => _showMore(context, song),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 20,
                        right: 20,
                        bottom: bottomSafe + 18,
                        child: IgnorePointer(
                          ignoring: fullOpacity < 0.02,
                          child: Opacity(
                            opacity: fullOpacity,
                            child: _FullPlayerControls(
                              con: con,
                              song: song,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 20,
                        right: 20,
                        top: artworkTop + artworkSize + 20 - top,
                        child: IgnorePointer(
                          ignoring: fullOpacity < 0.02,
                          child: Opacity(
                            opacity: fullOpacity,
                            child: _FullPlayerInfo(
                              con: con,
                              song: song,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        right: 6,
                        top: lerpDouble(8, ( _miniHeight - 48) / 2, t)!,
                        child: IgnorePointer(
                          ignoring: miniOpacity < 0.02,
                          child: Opacity(
                            opacity: miniOpacity,
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              onPressed: con.playOrPause,
                              icon: Icon(
                                con.isPlaying ? Icons.pause : Icons.play_arrow,
                                color: Colors.white,
                                size: 34,
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
          ],
        );
      },
    );
  }

  void _showMore(BuildContext context, dynamic song) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.black,
      builder: (_) => BottomSheetWidget(
        con: con,
        isNext: true,
        song: song,
      ),
    );
  }

  double _smoothstep(double value, double begin, double end) {
    if (end <= begin) return value >= end ? 1 : 0;
    final x = ((value - begin) / (end - begin)).clamp(0.0, 1.0);
    return x * x * (3 - 2 * x);
  }

  @override
  void dispose() {
    _progress.dispose();
    super.dispose();
  }
}

class _PlayerBackdrop extends StatelessWidget {
  const _PlayerBackdrop({
    required this.imageUrl,
    required this.opacity,
    required this.blurSigma,
  });

  final String? imageUrl;
  final double opacity;
  final double blurSigma;

  @override
  Widget build(BuildContext context) {
    if (opacity <= 0 || imageUrl?.isEmpty != false) {
      return const ColoredBox(color: Colors.black);
    }

    return Opacity(
      opacity: opacity,
      child: ImageFiltered(
        imageFilter: ImageFilter.blur(
          sigmaX: blurSigma,
          sigmaY: blurSigma,
        ),
        child: Transform.scale(
          scale: 1.12,
          child: CachedNetworkImage(
            imageUrl: imageUrl!,
            fit: BoxFit.cover,
            errorWidget: (_, __, ___) =>
                const ColoredBox(color: Colors.black),
          ),
        ),
      ),
    );
  }
}

class _Artwork extends StatelessWidget {
  const _Artwork({
    required this.imageUrl,
    required this.left,
    required this.top,
    required this.size,
  });

  final String? imageUrl;
  final double left;
  final double top;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: left,
      top: top,
      width: size,
      height: size,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size <= 60 ? 10 : 18),
        child: CachedNetworkImage(
          imageUrl: imageUrl ?? '',
          fit: BoxFit.cover,
          memCacheWidth: (size * MediaQuery.of(context).devicePixelRatio)
              .round()
              .clamp(128, 1400),
          memCacheHeight: (size * MediaQuery.of(context).devicePixelRatio)
              .round()
              .clamp(128, 1400),
          placeholder: (_, __) => const LoadingImage(),
          errorWidget: (_, __, ___) => const ColoredBox(
            color: Color(0xFF151515),
            child: Center(
              child: Icon(Icons.music_note, color: Colors.white54, size: 48),
            ),
          ),
        ),
      ),
    );
  }
}

class _FullPlayerHeader extends StatelessWidget {
  const _FullPlayerHeader({required this.onBack, required this.onMore});

  final VoidCallback onBack;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          onPressed: onBack,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Colors.white,
            size: 32,
          ),
        ),
        IconButton(
          onPressed: onMore,
          icon: const Icon(Icons.more_vert, color: Colors.white, size: 29),
        ),
      ],
    );
  }
}

class _FullPlayerInfo extends StatelessWidget {
  const _FullPlayerInfo({required this.con, required this.song});

  final MainController con;
  final dynamic song;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
        const SizedBox(height: 8),
        Row(
          children: [
            IconButton(
              onPressed: () => con.addToFavorite(
                name: song.songname ?? '',
                fullname: song.name ?? '',
                username: song.userid ?? '',
                cover: song.coverImageUrl ?? '',
                track: song.trackid ?? '',
              ),
              icon: const Icon(
                Icons.thumb_up_alt_outlined,
                color: Colors.white,
                size: 29,
              ),
            ),
            IconButton(
              onPressed: () => _message(context, 'Комментарии пока недоступны'),
              icon: const Icon(
                Icons.chat_bubble_outline,
                color: Colors.white,
                size: 29,
              ),
            ),
            const Spacer(),
            IconButton(
              onPressed: () => _message(context, 'Скачивание временно отключено'),
              icon: const Icon(
                Icons.download_rounded,
                color: Colors.white,
                size: 30,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        PositionSeekWidget(
          currentPosition: con.position,
          duration: con.duration,
          seekTo: con.seek,
        ),
      ],
    );
  }

  void _message(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocale.text(message, message))),
    );
  }
}

class _FullPlayerControls extends StatelessWidget {
  const _FullPlayerControls({required this.con, required this.song});

  final MainController con;
  final dynamic song;

  @override
  Widget build(BuildContext context) {
    final canSkip = con.songs.length > 1;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              onPressed: canSkip ? con.toggleShuffle : null,
              icon: Icon(
                Icons.shuffle,
                color: con.isShuffled ? Colors.white : Colors.white54,
                size: 28,
              ),
            ),
            IconButton(
              onPressed: canSkip ? con.previous : null,
              icon: const Icon(Icons.skip_previous, color: Colors.white, size: 42),
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
              onPressed: canSkip ? con.next : null,
              icon: const Icon(Icons.skip_next, color: Colors.white, size: 42),
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
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            TextButton.icon(
              onPressed: () => _message(context, AppLocale.text('Далее', 'Up next')),
              icon: const Icon(Icons.queue_music_rounded, color: Colors.white70),
              label: const Text('UP NEXT', style: TextStyle(color: Colors.white70)),
            ),
            TextButton.icon(
              onPressed: () => _message(context, AppLocale.text('Текст пока недоступен', 'Lyrics are not available yet')),
              icon: const Icon(Icons.lyrics_outlined, color: Colors.white70),
              label: const Text('LYRICS', style: TextStyle(color: Colors.white70)),
            ),
            TextButton.icon(
              onPressed: () => _message(context, AppLocale.text('Похожие треки пока недоступны', 'Related tracks are not available yet')),
              icon: const Icon(Icons.graphic_eq_rounded, color: Colors.white70),
              label: const Text('RELATED', style: TextStyle(color: Colors.white70)),
            ),
          ],
        ),
      ],
    );
  }

  void _message(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

/// Backwards-compatible name for older callers. The app shell now uses
/// [BottomPlayWidget] directly and does not push a full-player route.
class PlayWidget extends StatelessWidget {
  const PlayWidget({super.key, required this.con, this.onTap});

  final MainController con;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 64,
      child: BottomPlayWidget(con: con),
    );
  }
}
