import 'package:flutter/material.dart';

import '../../controllers/main_controller.dart';
import 'current_playing_song.dart';

class CurrentPlayer extends StatelessWidget {
  final MainController con;

  const CurrentPlayer({
    super.key,
    required this.con,
  });

  @override
  Widget build(BuildContext context) {
    return CurrentPlayingSong(con: con);
  }
}
