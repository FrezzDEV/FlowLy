import 'package:flutter/material.dart';
import 'package:flutter_sliding_box/flutter_sliding_box.dart';

import '../controllers/main_controller.dart';

class DraggableView extends StatefulWidget {
  final MainController con;
  final VoidCallback? onOpenPlayer;
  final ValueChanged<bool>? onOpenStateChanged;

  const DraggableView({
    super.key,
    required this.con,
    this.onOpenPlayer,
    this.onOpenStateChanged,
  });

  @override
  DraggableViewState createState() => DraggableViewState();
}

class DraggableViewState extends State<DraggableView> {
  final BoxController _boxController = BoxController();

  @override
  void dispose() {
    _boxController.dispose();
    super.dispose();
  }

  Future<void> open() async {
    if (!_boxController.isAttached) return;
    await _boxController.showBox();
    await Future<void>.delayed(Duration.zero);
    widget.onOpenStateChanged?.call(true);
    await _boxController.openBox();
  }

  Future<void> close() async {
    if (!_boxController.isAttached) return;
    await _boxController.closeBox();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.con,
      builder: (context, _) {
        final song = widget.con.currentSong;
        if (song == null) return const SizedBox.shrink();

        final screenHeight = MediaQuery.sizeOf(context).height;
        final topPadding = MediaQuery.paddingOf(context).top;

        return SlidingBox(
          controller: _boxController,
          minHeight: 1,
          maxHeight: screenHeight - topPadding,
          collapsed: true,
          draggable: true,
          draggableIconVisible: false,
          animationCurve: Curves.easeOutCubic,
          animationDuration: const Duration(milliseconds: 240),
          color: const Color(0xFF151515),
          onBoxOpen: () => widget.onOpenStateChanged?.call(true),
          onBoxClose: () async {
            widget.onOpenStateChanged?.call(false);
            await _boxController.hideBox();
          },
          backdrop: Backdrop(
            fading: true,
            overlay: true,
            overlayOpacity: 0.42,
            color: const Color(0xFF111111),
          ),
          body: _ExpandedPlayer(
            con: widget.con,
            onClose: close,
            onOpenPlayer: widget.onOpenPlayer,
          ),
        );
      },
    );
  }
}

class MiniPlayer extends StatefulWidget {
  final MainController con;
  final VoidCallback onTap;

  const MiniPlayer({
    super.key,
    required this.con,
    required this.onTap,
  });

  @override
  State<MiniPlayer> createState() => _MiniPlayerState();
}

class _MiniPlayerState extends State<MiniPlayer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _playPause;

  @override
  void initState() {
    super.initState();
    _playPause = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 170),
      value: widget.con.isPlaying ? 1 : 0,
    );
  }

  @override
  void dispose() {
    _playPause.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.con,
      builder: (context, _) {
        final song = widget.con.currentSong;
        if (song == null) return const SizedBox.shrink();

        final isPlaying = widget.con.isPlaying;
        if (isPlaying && _playPause.status != AnimationStatus.completed) {
          _playPause.forward();
        } else if (!isPlaying && _playPause.status != AnimationStatus.dismissed) {
          _playPause.reverse();
        }

        return Material(
          color: const Color(0xFF161616),
          child: InkWell(
            onTap: widget.onTap,
            child: SafeArea(
              top: false,
              child: SizedBox(
                height: 62,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: _CoverThumbnail(imageUrl: song.coverImageUrl),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
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
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              song.name ?? 'FlowLy',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFFB8B8B8),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _MiniControl(
                        icon: Icons.skip_previous_rounded,
                        onTap: widget.con.songs.length > 1
                            ? widget.con.previous
                            : null,
                      ),
                      IconButton(
                        tooltip: isPlaying ? 'Pause' : 'Play',
                        onPressed: widget.con.playOrPause,
                        icon: SizedBox(
                          width: 28,
                          height: 28,
                          child: AnimatedIcon(
                            icon: AnimatedIcons.play_pause,
                            progress: _playPause,
                            color: Colors.white,
                            size: 25,
                          ),
                        ),
                      ),
                      _MiniControl(
                        icon: Icons.skip_next_rounded,
                        onTap: widget.con.songs.length > 1
                            ? widget.con.next
                            : null,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _MiniControl extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _MiniControl({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      constraints: const BoxConstraints.tightFor(width: 36, height: 44),
      padding: EdgeInsets.zero,
      onPressed: onTap,
      icon: Icon(
        icon,
        color: onTap == null ? Colors.white24 : Colors.white,
        size: 25,
      ),
    );
  }
}

class _CoverThumbnail extends StatelessWidget {
  final String? imageUrl;

  const _CoverThumbnail({this.imageUrl});

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return const SizedBox.square(
        dimension: 44,
        child: ColoredBox(
          color: Color(0xFF252525),
          child: Icon(Icons.music_note_rounded, color: Colors.white54),
        ),
      );
    }

    return Image.network(
      imageUrl!,
      width: 44,
      height: 44,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => const SizedBox.square(
        dimension: 44,
        child: ColoredBox(
          color: Color(0xFF252525),
          child: Icon(Icons.music_note_rounded, color: Colors.white54),
        ),
      ),
    );
  }
}

class _ExpandedPlayer extends StatelessWidget {
  final MainController con;
  final VoidCallback onClose;
  final VoidCallback? onOpenPlayer;

  const _ExpandedPlayer({
    required this.con,
    required this.onClose,
    this.onOpenPlayer,
  });

  @override
  Widget build(BuildContext context) {
    final song = con.currentSong;
    if (song == null) return const SizedBox.shrink();

    return Material(
      color: const Color(0xFF151515),
      child: SafeArea(
        bottom: false,
        child: ListView(
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
          children: [
            Center(
              child: Container(
                width: 42,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.white38,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                IconButton(
                  tooltip: 'Close',
                  onPressed: onClose,
                  icon: const Icon(
                    Icons.keyboard_arrow_down,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                if (onOpenPlayer != null)
                  IconButton(
                    tooltip: 'Open full player',
                    onPressed: onOpenPlayer,
                    icon: const Icon(Icons.open_in_full, color: Colors.white),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: _FallbackArtwork(
                  title: song.songname ?? 'Track',
                  artist: song.name ?? 'FlowLy',
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              song.songname ?? '',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w800,
                height: 1.05,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              song.name ?? 'FlowLy',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFFBFBFBF),
                fontSize: 17,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 20),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: Colors.white,
                inactiveTrackColor: Colors.white24,
                thumbColor: Colors.white,
                overlayColor: Colors.transparent,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                trackHeight: 4,
              ),
              child: Slider(
                value: con.duration.inMilliseconds <= 0
                    ? 0
                    : (con.position.inMilliseconds /
                            con.duration.inMilliseconds)
                        .clamp(0.0, 1.0),
                onChanged: con.duration.inMilliseconds <= 0
                    ? null
                    : (value) => con.seek(
                          Duration(
                            milliseconds:
                                (con.duration.inMilliseconds * value).round(),
                          ),
                        ),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _format(con.position),
                  style: const TextStyle(color: Colors.white60),
                ),
                Text(
                  _format(con.duration),
                  style: const TextStyle(color: Colors.white60),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  onPressed: con.songs.length > 1 ? con.toggleShuffle : null,
                  icon: Icon(
                    Icons.shuffle,
                    color: con.isShuffled ? Colors.white : Colors.white54,
                  ),
                ),
                IconButton(
                  onPressed: con.songs.length > 1 ? con.previous : null,
                  icon: const Icon(
                    Icons.skip_previous_rounded,
                    color: Colors.white,
                    size: 36,
                  ),
                ),
                _LargePlayPauseButton(con: con),
                IconButton(
                  onPressed: con.songs.length > 1 ? con.next : null,
                  icon: const Icon(
                    Icons.skip_next_rounded,
                    color: Colors.white,
                    size: 36,
                  ),
                ),
                IconButton(
                  onPressed: con.toggleLoop,
                  icon: Icon(
                    con.loopMode == LoopModeType.one
                        ? Icons.repeat_one
                        : Icons.repeat,
                    color: con.loopMode == LoopModeType.none
                        ? Colors.white54
                        : Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _format(Duration value) {
    final total = value.inSeconds;
    final minutes = total ~/ 60;
    final seconds = total % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
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
      color: const Color(0xFF777777),
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

class _FallbackArtwork extends StatelessWidget {
  final String title;
  final String artist;

  const _FallbackArtwork({required this.title, required this.artist});

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 310,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF3E3E3E), Color(0xFF141414)],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.music_note_rounded, color: Colors.white70, size: 44),
            const Spacer(),
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w800,
                height: 1.05,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              artist,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
