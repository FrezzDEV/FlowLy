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

  bool get isOpen => _progress.value > 0.001;

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
    final height = MediaQuery.sizeOf(context).height;
    final range = height - _miniHeight;
    if (range <= 0) return;
    final delta = details.primaryDelta ?? 0;
    _progress.value = (_progress.value - delta / range).clamp(0.0, 1.0);
  }

  Future<void> _onDragEnd(DragEndDetails details) async {
    final velocity = details.primaryVelocity ?? 0;
    const flingVelocity = 600.0;
    final target = velocity.abs() > flingVelocity
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
        if (song == null) return const SizedBox.shrink();

        final size = MediaQuery.sizeOf(context);
        final screenWidth = size.width;
        final screenHeight = size.height;
        final t = _progress.value;

        final cardHeight = lerpDouble(_miniHeight, screenHeight, t)!;
        final cardMargin = lerpDouble(_miniMargin, 0, t)!;
        final cardRadius = lerpDouble(_miniRadius, 0, t)!;
        final artSize = lerpDouble(44, screenWidth * 0.72, t)!;
        final artTop = lerpDouble(10, 64, t)!;
        final artLeft = lerpDouble(12, (screenWidth - artSize) / 2, t)!;
        final artRadius = lerpDouble(8, 18, t)!;
        final miniOpacity = 1 - _remap(t, 0, 0.3);
        final expandedOpacity = _remap(t, 0.55, 1);
        final handleOpacity = _remap(t, 0.5, 1);
        final bottomMargin = lerpDouble(_navBarHeight + 8, 0, t)!;

        return Align(
          alignment: Alignment.bottomCenter,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onVerticalDragUpdate: _onDragUpdate,
            onVerticalDragEnd: _onDragEnd,
            child: Container(
              width: screenWidth - cardMargin * 2,
              height: cardHeight,
              margin: EdgeInsets.fromLTRB(
                cardMargin,
                0,
                cardMargin,
                bottomMargin,
              ),
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: Color.lerp(
                  const Color(0xFF191919),
                  const Color(0xFF0B0B0B),
                  t,
                ),
                borderRadius: BorderRadius.circular(cardRadius),
                boxShadow: [
                  if (t < 1)
                    BoxShadow(
                      color: Colors.black.withOpacity(0.32),
                      blurRadius: 16,
                      offset: const Offset(0, 5),
                    ),
                ],
              ),
              child: Stack(
                children: [
                  if (t > 0.001)
                    Positioned.fill(
                      child: Opacity(
                        opacity: _remap(t, 0.15, 0.65) * 0.58,
                        child: const ColoredBox(color: Colors.black),
                      ),
                    ),
                  Positioned(
                    top: 10,
                    left: 0,
                    right: 0,
                    child: Opacity(
                      opacity: handleOpacity,
                      child: const Center(
                        child: SizedBox(
                          width: 36,
                          height: 4,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: Colors.white38,
                              borderRadius: BorderRadius.all(
                                Radius.circular(2),
                              ),
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
                      child: _DemoArtwork(
                        title: song.songname ?? 'Track',
                        artist: song.name ?? 'FlowLy',
                      ),
                    ),
                  ),
                  Positioned(
                    top: 0,
                    left: 66,
                    right: 160,
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
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 2),
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
                  ),
                  Positioned(
                    right: 104,
                    top: 0,
                    height: _miniHeight,
                    child: Opacity(
                      opacity: miniOpacity,
                      child: _MiniButton(
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
                      child: _MiniButton(
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
                      child: _MiniButton(
                        icon: Icons.skip_next_rounded,
                        onTap: widget.con.songs.length > 1
                            ? widget.con.next
                            : null,
                      ),
                    ),
                  ),
                  Positioned(
                    top: artTop + artSize + 24,
                    left: 24,
                    right: 24,
                    child: IgnorePointer(
                      ignoring: t < 0.55,
                      child: Opacity(
                        opacity: expandedOpacity,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              song.songname ?? 'Track',
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              song.name ?? 'FlowLy',
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 28),
                            SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                activeTrackColor: Colors.white,
                                inactiveTrackColor: Colors.white24,
                                thumbColor: Colors.white,
                                overlayColor: Colors.transparent,
                                trackHeight: 4,
                              ),
                              child: Slider(
                                value: 0,
                                onChanged: (_) {},
                              ),
                            ),
                            const SizedBox(height: 18),
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceEvenly,
                              children: [
                                _LargeIconButton(
                                  icon: Icons.skip_previous_rounded,
                                  onTap: widget.con.songs.length > 1
                                      ? widget.con.previous
                                      : null,
                                ),
                                _LargePlayPauseButton(con: widget.con),
                                _LargeIconButton(
                                  icon: Icons.skip_next_rounded,
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
                      ignoring: t < 0.55,
                      child: Opacity(
                        opacity: expandedOpacity,
                        child: _MiniButton(
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
    if (end == start) return value >= end ? 1 : 0;
    return ((value - start) / (end - start)).clamp(0.0, 1.0).toDouble();
  }
}

class _MiniButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _MiniButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 48,
          height: 64,
          child: Center(
            child: Icon(
              icon,
              color: onTap == null ? Colors.white24 : Colors.white,
              size: 26,
            ),
          ),
        ),
      ),
    );
  }
}

class _LargeIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _LargeIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(
        icon,
        color: onTap == null ? Colors.white24 : Colors.white,
        size: 42,
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
      duration: const Duration(milliseconds: 170),
      value: widget.con.isPlaying ? 1 : 0,
    );
    widget.con.addListener(_sync);
  }

  void _sync() {
    if (!mounted) return;
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
    return Material(
      color: Colors.white12,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: widget.con.playOrPause,
        child: SizedBox(
          width: 78,
          height: 78,
          child: AnimatedIcon(
            icon: AnimatedIcons.play_pause,
            progress: _controller,
            color: Colors.white,
            size: 40,
          ),
        ),
      ),
    );
  }
}

class _DemoArtwork extends StatelessWidget {
  final String title;
  final String artist;

  const _DemoArtwork({required this.title, required this.artist});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF292929),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.music_note_rounded,
            color: Colors.white70,
            size: 36,
          ),
          const Spacer(),
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            artist,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
