import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:line_icons/line_icons.dart';

import '../../controllers/main_controller.dart';

enum _PlayerAction { shuffle, previous, play, next, repeat }

class PlayingControls extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final shuffled = con.isShuffled;
    final activeLoop = loopMode == LoopModeType.one || loopMode == LoopModeType.all;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _controlButton(
            icon: LineIcons.random,
            enabled: isPlaylist,
            color: shuffled ? Colors.white : Colors.white,
            onPressed: isPlaylist ? con.toggleShuffle : null,
          ),
          _controlButton(
            icon: Icons.skip_previous,
            size: 40,
            enabled: isPlaylist,
            onPressed: isPlaylist ? onPrevious : null,
          ),
          SizedBox(
            width: 92,
            height: 92,
            child: IconButton(
              padding: EdgeInsets.zero,
              onPressed: onPlay,
              icon: Icon(
                isPlaying
                    ? CupertinoIcons.pause_circle_fill
                    : CupertinoIcons.play_circle_fill,
                color: Colors.white,
                size: 84,
              ),
            ),
          ),
          _controlButton(
            icon: Icons.skip_next,
            size: 40,
            enabled: isPlaylist,
            onPressed: isPlaylist ? onNext : null,
          ),
          _controlButton(
            icon: loopMode == LoopModeType.one
                ? CupertinoIcons.repeat_1
                : CupertinoIcons.arrow_2_circlepath,
            enabled: toggleLoop != null,
            color: activeLoop ? Colors.white : const Color(0xFF777777),
            onPressed: toggleLoop,
          ),
        ],
      ),
    );
  }

  Widget _controlButton({
    required IconData icon,
    required VoidCallback? onPressed,
    bool enabled = true,
    double size = 25,
    Color color = Colors.white,
  }) {
    return SizedBox(
      width: 48,
      height: 56,
      child: IconButton(
        padding: EdgeInsets.zero,
        onPressed: enabled ? onPressed : null,
        icon: Icon(
          icon,
          size: size,
          color: enabled ? color : const Color(0xFF777777),
        ),
      ),
    );
  }
}
