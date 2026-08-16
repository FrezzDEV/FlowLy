import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

import 'player_sheet_controller.dart';
import 'player_sheet_layout.dart';

class PlayerSheet extends StatefulWidget {
  const PlayerSheet({
    super.key,
    required this.cover,
    required this.title,
    this.artist,
    required this.isPlaying,
    required this.onPlayPause,
    this.onNext,
    this.onPrevious,
    this.onLike,
    this.onComment,
    this.onDownload,
    this.onMore,
    this.onLyrics,
    this.onRelated,
    this.onUpNext,
    this.onClose,
    this.isLiked = false,
    this.bottomOffset = 0,
    this.progressValue = 0,
    this.duration = Duration.zero,
    this.position = Duration.zero,
    this.onSeek,
    this.expandThreshold = 0.5,
    this.velocityThreshold = 900,
  });

  final ImageProvider cover;
  final String title;
  final String? artist;
  final bool isPlaying;
  final bool isLiked;
  final VoidCallback onPlayPause;
  final VoidCallback? onNext;
  final VoidCallback? onPrevious;
  final VoidCallback? onLike;
  final VoidCallback? onComment;
  final VoidCallback? onDownload;
  final VoidCallback? onMore;
  final VoidCallback? onLyrics;
  final VoidCallback? onRelated;
  final VoidCallback? onUpNext;
  final VoidCallback? onClose;
  final double bottomOffset;
  final double progressValue;
  final Duration duration;
  final Duration position;
  final ValueChanged<Duration>? onSeek;
  final double expandThreshold;
  final double velocityThreshold;

  @override
  State<PlayerSheet> createState() => _PlayerSheetState();
}

class _PlayerSheetState extends State<PlayerSheet>
    with SingleTickerProviderStateMixin {
  late final PlayerSheetController controller;
  late final AnimationController snapController;
  bool _closing = false;

  @override
  void initState() {
    super.initState();
    controller = PlayerSheetController(
      expandThreshold: widget.expandThreshold,
      velocityThreshold: widget.velocityThreshold,
    );
    snapController = AnimationController(vsync: this);
    snapController.addListener(() {
      controller.setProgress(snapController.value);
    });
  }

  Future<void> _snapTo(bool expanded) async {
    final target = expanded ? 1.0 : 0.0;
    snapController.stop();
    snapController.value = controller.progress;
    await snapController.animateWith(
      SpringSimulation(
        const SpringDescription(
          mass: 1.0,
          stiffness: 360.0,
          damping: 34.0,
        ),
        controller.progress,
        target,
        0,
      ),
    );
    controller.setProgress(target);
    if (!expanded && !_closing && mounted) {
      _closing = true;
      widget.onClose?.call();
    }
  }

  @override
  void dispose() {
    snapController.dispose();
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final media = MediaQuery.of(context);

        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onVerticalDragStart: (details) {
            snapController.stop();
            _closing = false;
            controller.beginDrag(details.globalPosition.dy);
          },
          onVerticalDragUpdate: (details) {
            controller.updateDrag(
              globalY: details.globalPosition.dy,
              availableHeight: constraints.maxHeight,
            );
          },
          onVerticalDragEnd: (details) {
            final expanded = controller.endDrag(
              velocityY: details.primaryVelocity ?? 0,
            );
            _snapTo(expanded);
          },
          child: AnimatedBuilder(
            animation: controller,
            builder: (context, _) {
              final layout = PlayerSheetLayout(
                progress: controller.progress,
                screenSize: constraints.biggest,
                topSafeArea: media.padding.top,
                bottomSafeArea: media.padding.bottom,
                bottomOffset: widget.bottomOffset,
              );

              return Stack(
                fit: StackFit.expand,
                children: [
                  if (layout.scrimOpacity > 0)
                    IgnorePointer(
                      child: ColoredBox(
                        color: Colors.black.withValues(
                          alpha: layout.scrimOpacity,
                        ),
                      ),
                    ),
                  _sheet(layout),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _sheet(PlayerSheetLayout layout) {
    return Positioned(
      left: 0,
      right: 0,
      top: layout.sheetTop,
      height: layout.sheetHeight,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFF101010),
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(layout.lerp(14, 0)),
          ),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            RepaintBoundary(child: _artwork(layout)),
            _miniContent(layout),
            _expandedContent(layout),
            if (layout.p > 0.85) _dragHandle(layout),
          ],
        ),
      ),
    );
  }

  Widget _artwork(PlayerSheetLayout layout) {
    final cacheSize = (layout.expandedArtworkSize * 2).round().clamp(256, 1600);

    return Positioned(
      left: layout.artworkLeft,
      top: layout.artworkTop,
      width: layout.artworkSize,
      height: layout.artworkSize,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(layout.artworkRadius),
        child: Image(
          image: widget.cover,
          fit: BoxFit.cover,
          cacheWidth: cacheSize,
          cacheHeight: cacheSize,
          filterQuality: FilterQuality.low,
        ),
      ),
    );
  }

  Widget _miniContent(PlayerSheetLayout layout) {
    return Positioned(
      left: layout.miniTitleLeft,
      right: layout.miniControlsRight,
      top: 0,
      bottom: 0,
      child: IgnorePointer(
        ignoring: layout.miniOpacity < 0.01,
        child: Opacity(
          opacity: layout.miniOpacity,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  widget.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                onPressed: widget.onPlayPause,
                icon: Icon(
                  widget.isPlaying ? Icons.pause : Icons.play_arrow,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _expandedContent(PlayerSheetLayout layout) {
    return Positioned.fill(
      child: IgnorePointer(
        ignoring: layout.expandedOpacity < 0.01,
        child: Opacity(
          opacity: layout.expandedOpacity,
          child: Stack(
            children: [
              Positioned(
                left: 24,
                right: 24,
                top: layout.fullContentTop,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      widget.title,
                      maxLines: 2,
                      textAlign: TextAlign.left,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        height: 1.1,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (widget.artist?.isNotEmpty == true) ...[
                      const SizedBox(height: 6),
                      Text(
                        widget.artist!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFFC9C9C9),
                          fontSize: 17,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    _actionRow(),
                    const SizedBox(height: 8),
                    _progressBar(),
                    const SizedBox(height: 12),
                    _controls(),
                    const SizedBox(height: 12),
                    _secondaryTabs(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _actionRow() {
    return Row(
      children: [
        _actionButton(
          icon: widget.isLiked
              ? Icons.thumb_up_alt
              : Icons.thumb_up_alt_outlined,
          onPressed: widget.onLike,
        ),
        _actionButton(
          icon: Icons.chat_bubble_outline,
          onPressed: widget.onComment,
        ),
        const Spacer(),
        _actionButton(
          icon: Icons.download_rounded,
          onPressed: widget.onDownload,
        ),
        _actionButton(
          icon: Icons.more_vert,
          onPressed: widget.onMore,
        ),
      ],
    );
  }

  Widget _actionButton({
    required IconData icon,
    required VoidCallback? onPressed,
  }) {
    return IconButton(
      padding: const EdgeInsets.all(8),
      visualDensity: VisualDensity.compact,
      onPressed: onPressed,
      icon: Icon(icon, color: Colors.white, size: 27),
    );
  }

  Widget _controls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        IconButton(
          onPressed: widget.onPrevious,
          icon: const Icon(Icons.skip_previous, size: 40),
          color: Colors.white,
        ),
        Material(
          color: const Color(0xFF777777),
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: widget.onPlayPause,
            child: SizedBox(
              width: 82,
              height: 82,
              child: Icon(
                widget.isPlaying
                    ? Icons.pause
                    : Icons.play_arrow,
                color: Colors.white,
                size: 44,
              ),
            ),
          ),
        ),
        IconButton(
          onPressed: widget.onNext,
          icon: const Icon(Icons.skip_next, size: 40),
          color: Colors.white,
        ),
      ],
    );
  }

  Widget _secondaryTabs() {
    return Row(
      children: [
        Expanded(
          child: _textAction(
            'UP NEXT',
            Icons.queue_music_rounded,
            widget.onUpNext,
          ),
        ),
        Expanded(
          child: _textAction(
            'LYRICS',
            Icons.lyrics_outlined,
            widget.onLyrics,
          ),
        ),
        Expanded(
          child: _textAction(
            'RELATED',
            Icons.graphic_eq_rounded,
            widget.onRelated,
          ),
        ),
      ],
    );
  }

  Widget _textAction(
    String label,
    IconData icon,
    VoidCallback? onPressed,
  ) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18, color: Colors.white70),
      label: Text(
        label,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 8),
      ),
    );
  }

  Widget _progressBar() {
    final durationMs = widget.duration.inMilliseconds;
    final positionMs = widget.position.inMilliseconds;
    final value = durationMs <= 0
        ? widget.progressValue.clamp(0.0, 1.0)
        : (positionMs / durationMs).clamp(0.0, 1.0);

    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          children: [
            GestureDetector(
              onTapDown: widget.onSeek == null || durationMs <= 0
                  ? null
                  : (details) {
                      final fraction =
                          (details.localPosition.dx / constraints.maxWidth)
                              .clamp(0.0, 1.0);
                      widget.onSeek!(Duration(
                        milliseconds: (durationMs * fraction).round(),
                      ));
                    },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  minHeight: 4,
                  value: value,
                  backgroundColor: const Color(0xFF3A3A3A),
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 7),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_format(widget.position),
                    style: const TextStyle(color: Colors.white70, fontSize: 12)),
                Text(_format(widget.duration),
                    style: const TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _dragHandle(PlayerSheetLayout layout) {
    return Positioned(
      top: 10,
      left: (layout.screenSize.width - 38) / 2,
      child: Container(
        width: 38,
        height: 4,
        decoration: BoxDecoration(
          color: Colors.white24,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  String _format(Duration value) {
    final totalSeconds = value.inSeconds.clamp(0, 1 << 30);
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}
