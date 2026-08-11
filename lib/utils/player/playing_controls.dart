import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:line_icons/line_icons.dart';

import '../../controllers/main_controller.dart';

class PlayingControls extends StatefulWidget {
  final bool isPlaying;
  final LoopModeType? loopMode;
  final bool isPlaylist;
  final MainController con;
  final VoidCallback? onPrevious;
  final VoidCallback onPlay;
  final VoidCallback? onNext;
  final VoidCallback? toggleLoop;
  final VoidCallback? onStop;

  const PlayingControls({
    super.key,
    required this.isPlaying,
    this.loopMode,
    this.isPlaylist = false,
    required this.con,
    this.onPrevious,
    required this.onPlay,
    this.onNext,
    this.toggleLoop,
    this.onStop,
  });

  @override
  State<PlayingControls> createState() => _PlayingControlsState();
}

class _PlayingControlsState extends State<PlayingControls> {
  @override
  Widget build(BuildContext context) {
    final shuffled = widget.con.isShuffled;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            padding: EdgeInsets.zero,
            onPressed: widget.isPlaylist ? widget.con.toggleShuffle : null,
            icon: Icon(
              LineIcons.random,
              color: shuffled ? Colors.green : Colors.white,
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: widget.isPlaylist ? widget.onPrevious : null,
                icon: const Icon(Icons.skip_previous,
                    size: 40, color: Colors.white),
              ),
              SizedBox(
                height: 80,
                width: 120,
                child: IconButton(
                  onPressed: widget.onPlay,
                  icon: Icon(
                    widget.isPlaying
                        ? CupertinoIcons.pause_circle_fill
                        : CupertinoIcons.play_circle_fill,
                    size: 80,
                    color: Colors.white,
                  ),
                ),
              ),
              IconButton(
                onPressed: widget.isPlaylist ? widget.onNext : null,
                icon: const Icon(Icons.skip_next,
                    size: 40, color: Colors.white),
              ),
            ],
          ),
          IconButton(
            padding: EdgeInsets.zero,
            onPressed: widget.toggleLoop,
            icon: Icon(
              widget.loopMode == LoopModeType.none
                  ? CupertinoIcons.arrow_2_circlepath
                  : widget.loopMode == LoopModeType.one
                      ? CupertinoIcons.repeat_1
                      : CupertinoIcons.arrow_2_circlepath,
              color: widget.loopMode == LoopModeType.none
                  ? Colors.grey
                  : Colors.white,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }
}
