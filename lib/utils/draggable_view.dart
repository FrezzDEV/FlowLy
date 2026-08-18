import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sliding_box/flutter_sliding_box.dart';

import '../controllers/main_controller.dart';

class DraggableView extends StatefulWidget {
  final MainController con;
  final VoidCallback? onOpenPlayer;

  const DraggableView({
    super.key,
    required this.con,
    this.onOpenPlayer,
  });

  @override
  State<DraggableView> createState() => _DraggableViewState();
}

class _DraggableViewState extends State<DraggableView> {
  final BoxController _boxController = BoxController();

  @override
  void dispose() {
    _boxController.dispose();
    super.dispose();
  }

  void _toggle() {
    if (!_boxController.isAttached) return;
    if (_boxController.isBoxOpen) {
      _boxController.closeBox();
    } else {
      _boxController.openBox();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.con,
      builder: (context, _) {
        final song = widget.con.currentSong;
        if (song == null) return const SizedBox.shrink();

        final screenHeight = MediaQuery.of(context).size.height;
        final topPadding = MediaQuery.of(context).padding.top;

        return SlidingBox(
          controller: _boxController,
          minHeight: 62,
          maxHeight: screenHeight - topPadding,
          collapsed: true,
          draggable: true,
          draggableIconVisible: false,
          animationCurve: Curves.easeOutCubic,
          animationDuration: const Duration(milliseconds: 280),
          color: const Color(0xFF151515),
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(28),
          ),
          backdrop: Backdrop(
            fading: true,
            overlay: true,
            overlayOpacity: 0.42,
            color: const Color(0xFF111111),
          ),
          body: _ExpandedPlayer(
            con: widget.con,
            onClose: () => _boxController.closeBox(),
            onOpenPlayer: widget.onOpenPlayer,
          ),
          collapsedBody: _CollapsedPlayer(
            con: widget.con,
            onTap: _toggle,
          ),
        );
      },
    );
  }
}

class _CollapsedPlayer extends StatelessWidget {
  final MainController con;
  final VoidCallback onTap;

  const _CollapsedPlayer({
    required this.con,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final song = con.currentSong;
    if (song == null) return const SizedBox.shrink();

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Material(
        color: const Color(0xFF161616),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 62,
            child: Row(
              children: [
                const SizedBox(width: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: song.coverImageUrl ?? '',
                    width: 44,
                    height: 44,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => Container(
                      width: 44,
                      height: 44,
                      color: const Color(0xFF252525),
                      alignment: Alignment.center,
                      child: const Icon(Icons.music_note, color: Colors.white54),
                    ),
                  ),
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
                          fontSize: 15,
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
                IconButton(
                  tooltip: con.isPlaying ? 'Pause' : 'Play',
                  onPressed: con.playOrPause,
                  icon: Icon(
                    con.isPlaying ? Icons.pause : Icons.play_arrow,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                IconButton(
                  tooltip: 'Next',
                  onPressed: con.songs.length > 1 ? con.next : null,
                  icon: const Icon(Icons.skip_next, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 4),
              ],
            ),
          ),
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

    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
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
            const SizedBox(height: 12),
            Row(
              children: [
                IconButton(
                  tooltip: 'Close',
                  onPressed: onClose,
                  icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white),
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
            const SizedBox(height: 8),
            AspectRatio(
              aspectRatio: 1,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: CachedNetworkImage(
                  imageUrl: song.coverImageUrl ?? '',
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => Container(
                    color: const Color(0xFF202020),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.music_note,
                      color: Colors.white54,
                      size: 80,
                    ),
                  ),
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
            const SizedBox(height: 18),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
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
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_format(con.position), style: const TextStyle(color: Colors.white60)),
                Text(_format(con.duration), style: const TextStyle(color: Colors.white60)),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                  icon: const Icon(Icons.skip_previous, color: Colors.white, size: 36),
                ),
                Material(
                  color: const Color(0xFF777777),
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: con.playOrPause,
                    child: SizedBox(
                      width: 78,
                      height: 78,
                      child: Icon(
                        con.isPlaying ? Icons.pause : Icons.play_arrow,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: con.songs.length > 1 ? con.next : null,
                  icon: const Icon(Icons.skip_next, color: Colors.white, size: 36),
                ),
                IconButton(
                  onPressed: con.toggleLoop,
                  icon: Icon(
                    con.loopMode == LoopModeType.one ? Icons.repeat_one : Icons.repeat,
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
