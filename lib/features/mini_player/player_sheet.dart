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
  final VoidCallback onPlayPause;
  final VoidCallback? onNext;
  final VoidCallback? onPrevious;
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

  void _snapTo(bool expanded) {
    final target = expanded ? 1.0 : 0.0;
    snapController.stop();
    snapController.value = controller.progress;
    snapController.animateWith(
      SpringSimulation(
        const SpringDescription(
          mass: 1,
          stiffness: 420,
          damping: 36,
        ),
        controller.progress,
        target,
        0,
      ),
    );
  }

  void _handleTap() {
    if (controller.progress < 0.2) {
      _snapTo(true);
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
        final layout = PlayerSheetLayout(
          progress: controller.progress,
          screenSize: constraints.biggest,
          topSafeArea: media.padding.top,
          bottomSafeArea: media.padding.bottom,
        );

        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: _handleTap,
          onVerticalDragStart: (details) {
            snapController.stop();
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
            builder: (context, _) => Stack(
              fit: StackFit.expand,
              clipBehavior: Clip.none,
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
            ),
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
            top: Radius.circular(layout.lerp(12, 0)),
          ),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            _artwork(layout),
            _miniContent(layout),
            _expandedContent(layout),
            if (layout.p > 0.85) _dragHandle(layout),
          ],
        ),
      ),
    );
  }

  Widget _artwork(PlayerSheetLayout layout) {
    return Positioned(
      left: layout.artworkLeft,
      top: layout.artworkTop,
      width: layout.artworkSize,
      height: layout.artworkSize,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(layout.artworkRadius),
        child: Image(image: widget.cover, fit: BoxFit.cover),
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
                  children: [
                    Text(
                      widget.title,
                      maxLines: 2,
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 27,
                        height: 1.1,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (widget.artist?.isNotEmpty == true) ...[
                      const SizedBox(height: 8),
                      Text(
                        widget.artist!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Positioned(
                left: 24,
                right: 24,
                bottom: layout.progressBottom,
                child: _progressBar(),
              ),
              Positioned(
                left: 20,
                right: 20,
                bottom: layout.controlsBottom,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      onPressed: widget.onPrevious,
                      icon: const Icon(Icons.skip_previous, size: 38),
                      color: Colors.white,
                    ),
                    IconButton(
                      onPressed: widget.onPlayPause,
                      icon: Icon(
                        widget.isPlaying
                            ? Icons.pause_circle_filled
                            : Icons.play_circle_filled,
                        size: 76,
                        color: Colors.white,
                      ),
                    ),
                    IconButton(
                      onPressed: widget.onNext,
                      icon: const Icon(Icons.skip_next, size: 38),
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _progressBar() {
    final duration = widget.duration.inMilliseconds;
    final position = widget.position.inMilliseconds;
    final value = duration <= 0
        ? widget.progressValue.clamp(0.0, 1.0)
        : (position / duration).clamp(0.0, 1.0);

    return Column(
      children: [
        GestureDetector(
          onTapDown: widget.onSeek == null
              ? null
              : (details) {
                  final render = context.findRenderObject();
                  if (render is! RenderBox || render.size.width <= 0) return;
                  final fraction =
                      (details.localPosition.dx / render.size.width)
                          .clamp(0.0, 1.0);
                  if (duration > 0) {
                    widget.onSeek!(Duration(
                      milliseconds: (duration * fraction).round(),
                    ));
                  }
                },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              minHeight: 4,
              value: value,
              backgroundColor: const Color(0xFF3A3A3A),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        ),
        const SizedBox(height: 8),
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
  }

  Widget _dragHandle(PlayerSheetLayout layout) {
    return Positioned(
      top: 10,
      left: (layout.screenSize.width - 38) / 2,
      child: Semantics(
        label: 'Player drag handle',
        child: Container(
          width: 38,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.white24,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }

  String _format(Duration value) {
    final seconds = value.inSeconds;
    final minutes = seconds ~/ 60;
    final remainder = seconds % 60;
    return '$minutes:${remainder.toString().padLeft(2, '0')}';
  }
}
