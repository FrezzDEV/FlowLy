import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../controllers/main_controller.dart';

class DraggableView extends StatefulWidget {
  final MainController con;
  final ValueChanged<bool>? onOpenStateChanged;

  const DraggableView({
    super.key,
    required this.con,
    this.onOpenStateChanged,
  });

  @override
  State<DraggableView> createState() => DraggableViewState();
}

class DraggableViewState extends State<DraggableView>
    with SingleTickerProviderStateMixin {
  static const double _miniHeight = 64;
  static const double _miniMargin = 8;
  static const double _miniRadius = 14;
  static const double _navBarHeight = 64;

  late final AnimationController _progress;

  @override
  void initState() {
    super.initState();
    _progress = AnimationController(vsync: this, value: 0);
  }

  @override
  void dispose() {
    _progress.dispose();
    super.dispose();
  }

  Future<void> open() async {
    if (!mounted || widget.con.currentSong == null) return;
    widget.onOpenStateChanged?.call(true);
    await _progress.animateTo(
      1,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> close() async {
    if (!mounted) return;
    await _progress.animateTo(
      0,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
    widget.onOpenStateChanged?.call(false);
  }

  void _onDragUpdate(DragUpdateDetails details) {
    final range = MediaQuery.sizeOf(context).height - _miniHeight;
    if (range <= 0) {
      return;
    }
    _progress.value = (_progress.value -
            (details.primaryDelta ?? 0) / range)
        .clamp(0.0, 1.0);
  }

  Future<void> _onDragEnd(DragEndDetails details) async {
    final velocity = details.primaryVelocity ?? 0;
    final target = velocity.abs() > 600
        ? (velocity < 0 ? 1.0 : 0.0)
        : (_progress.value > 0.5 ? 1.0 : 0.0);

    if (target == 1) {
      await open();
    } else {
      await close();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_progress, widget.con]),
      builder: (context, _) {
        final song = widget.con.currentSong;
        if (song == null) {
          return const SizedBox.shrink();
        }

        final size = MediaQuery.sizeOf(context);
        final t = _progress.value;
        final artSize = lerpDouble(44, size.width * 0.60, t)!;
        final artTop = lerpDouble(10, 56, t)!;
        final artLeft = lerpDouble(12, (size.width - artSize) / 2, t)!;
        final cardWidth = size.width -
            lerpDouble(_miniMargin * 2, 0, t)!;
        final cardHeight = lerpDouble(_miniHeight, size.height, t)!;
        final cardRadius = lerpDouble(_miniRadius, 0, t)!;
        final miniOpacity = 1 - _remap(t, 0, 0.3);
        final expandedOpacity = _remap(t, 0.5, 1);
        final bottomMargin =
            lerpDouble(_navBarHeight + 8, 0, t)!;
        final font = Theme.of(context).textTheme;

        return Align(
          alignment: Alignment.bottomCenter,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onVerticalDragUpdate: _onDragUpdate,
            onVerticalDragEnd: _onDragEnd,
            child: Container(
              width: cardWidth,
              height: cardHeight,
              margin: EdgeInsets.only(bottom: bottomMargin),
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: Color.lerp(
                  const Color(0xFF191919),
                  const Color(0xFF0B0B0B),
                  t,
                ),
                borderRadius: BorderRadius.circular(cardRadius),
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: artTop,
                    left: artLeft,
                    width: artSize,
                    height: artSize,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: _DemoArtwork(
                        title: song.songname ?? 'Track',
                        artist: song.name ?? 'FlowLy',
                        showText: t < 0.5,
                      ),
                    ),
                  ),
                  Positioned(
                    left: 66,
                    right: 160,
                    top: 0,
                    height: _miniHeight,
                    child: Opacity(
                      opacity: miniOpacity,
                      child: IgnorePointer(
                        ignoring: t > 0.3,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: open,
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  song.songname ?? 'Track',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: font.bodyMedium?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  song.name ?? 'FlowLy',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: font.bodySmall?.copyWith(
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 104,
                    top: 0,
                    height: _miniHeight,
                    child: Opacity(
                      opacity: miniOpacity,
                      child: _ActionButton(
                        icon: Icons.skip_previous_rounded,
                        onTap: widget.con.songs.length > 1
                            ? widget.con.previous
                            : null,
                      ),
                    ),
                  ),
                  Positioned(
                    right: 56,
                    top: 0,
                    height: _miniHeight,
                    child: Opacity(
                      opacity: miniOpacity,
                      child: _ActionButton(
                        icon: widget.con.isPlaying
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        onTap: widget.con.playOrPause,
                      ),
                    ),
                  ),
                  Positioned(
                    right: 8,
                    top: 0,
                    height: _miniHeight,
                    child: Opacity(
                      opacity: miniOpacity,
                      child: _ActionButton(
                        icon: Icons.skip_next_rounded,
                        onTap: widget.con.songs.length > 1
                            ? widget.con.next
                            : null,
                      ),
                    ),
                  ),
                  Positioned(
                    top: artTop + artSize + 28,
                    left: 22,
                    right: 22,
                    child: IgnorePointer(
                      ignoring: t < 0.5,
                      child: Opacity(
                        opacity: expandedOpacity,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        song.songname ?? 'Track',
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: font.headlineSmall?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        song.name ?? 'FlowLy',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: font.bodyMedium?.copyWith(
                                          color: Colors.white70,
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                _ActionButton(
                                  icon: widget.con.isFavorite
                                      ? Icons.favorite_rounded
                                      : Icons.favorite_border_rounded,
                                  onTap: widget.con.toggleFavoriteCurrent,
                                ),
                                _ActionButton(
                                  icon: Icons.download_rounded,
                                  onTap: widget.con.downloadCurrent,
                                ),
                              ],
                            ),
                            const SizedBox(height: 52),
                            SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                activeTrackColor: Colors.white,
                                inactiveTrackColor: Colors.white24,
                                thumbColor: Colors.white,
                                overlayColor: Colors.transparent,
                                trackHeight: 4,
                              ),
                              child: Slider(
                                value: widget.con.duration.inMilliseconds == 0
                                    ? 0
                                    : (widget.con.position.inMilliseconds /
                                            widget.con.duration.inMilliseconds)
                                        .clamp(0.0, 1.0),
                                onChanged: (value) {
                                  widget.con.seek(
                                    Duration(
                                      milliseconds:
                                          (widget.con.duration.inMilliseconds *
                                                  value)
                                              .round(),
                                    ),
                                  );
                                },
                              ),
                            ),
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _format(widget.con.position),
                                  style: const TextStyle(
                                    color: Colors.white60,
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  _format(widget.con.duration),
                                  style: const TextStyle(
                                    color: Colors.white60,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 34),
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceEvenly,
                              children: [
                                _ActionButton(
                                  icon: Icons.skip_previous_rounded,
                                  size: 48,
                                  onTap: widget.con.songs.length > 1
                                      ? widget.con.previous
                                      : null,
                                ),
                                _LargePlayPauseButton(con: widget.con),
                                _ActionButton(
                                  icon: Icons.skip_next_rounded,
                                  size: 48,
                                  onTap: widget.con.songs.length > 1
                                      ? widget.con.next
                                      : null,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: IgnorePointer(
                      ignoring: t < 0.5,
                      child: Opacity(
                        opacity: expandedOpacity,
                        child: _ActionButton(
                          icon: Icons.keyboard_arrow_down_rounded,
                          onTap: close,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  double _remap(double value, double start, double end) {
    return ((value - start) / (end - start)).clamp(0.0, 1.0).toDouble();
  }

  static String _format(Duration value) {
    return '${value.inMinutes}:${(value.inSeconds % 60).toString().padLeft(2, '0')}';
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final double size;

  const _ActionButton({
    required this.icon,
    required this.onTap,
    this.size = 42,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        width: size,
        height: size,
        child: Center(
          child: Icon(
            icon,
            color: onTap == null ? Colors.white24 : Colors.white,
            size: size * 0.56,
          ),
        ),
      ),
    );
  }
}

class _LargePlayPauseButton extends StatefulWidget {
  final MainController con;

  const _LargePlayPauseButton({required this.con});

  @override
  State<_LargePlayPauseButton> createState() => _LargePlayPauseButtonState();
}

class _LargePlayPauseButtonState extends State<_LargePlayPauseButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
      value: widget.con.isPlaying ? 1 : 0,
    );
    widget.con.addListener(_sync);
  }

  void _sync() {
    if (!mounted) {
      return;
    }
    if (widget.con.isPlaying) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  void dispose() {
    widget.con.removeListener(_sync);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.con.playOrPause,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 76,
        height: 76,
        decoration: const BoxDecoration(
          color: Colors.white12,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Transform.translate(
          offset: const Offset(1.5, 0),
          child: SizedBox(
            width: 38,
            height: 38,
            child: Center(
              child: AnimatedIcon(
                icon: AnimatedIcons.play_pause,
                progress: _controller,
                color: Colors.white,
                size: 32,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DemoArtwork extends StatelessWidget {
  final String title;
  final String artist;
  final bool showText;

  const _DemoArtwork({
    required this.title,
    required this.artist,
    required this.showText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF292929),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.music_note_rounded,
            color: Colors.white70,
            size: 32,
          ),
          if (showText) ...[
            const Spacer(),
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              artist,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white70,
                  ),
            ),
          ],
        ],
      ),
    );
  }
}
