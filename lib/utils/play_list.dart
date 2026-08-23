import 'package:flutter/material.dart';

import '../controllers/main_controller.dart';
import '../models/song_model.dart';
import 'like_button/like_button.dart';

class PlayListWidget extends StatefulWidget {
  final MainController con;
  final List<SongModel> songs;

  const PlayListWidget({
    super.key,
    required this.con,
    required this.songs,
  });

  @override
  State<PlayListWidget> createState() => _PlayListWidgetState();
}

class _PlayListWidgetState extends State<PlayListWidget> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          'Queue',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        actions: [
          if (widget.songs.isNotEmpty)
            IconButton(
              tooltip: 'Clear queue',
              onPressed: () async {
                await widget.con.stop();
                widget.songs.clear();
                setState(() {});
              },
              icon: const Icon(Icons.clear_all),
            ),
        ],
      ),
      body: widget.songs.isEmpty
          ? const Center(
              child: Text('Queue is empty',
                  style: TextStyle(color: Colors.grey)),
            )
          : ReorderableListView.builder(
              itemCount: widget.songs.length,
              onReorder: (oldIndex, newIndex) {
                setState(() {
                  if (newIndex > oldIndex) newIndex--;
                  widget.con.changeIndex(newIndex, oldIndex);
                });
              },
              itemBuilder: (context, index) {
                final song = widget.songs[index];
                return ListTile(
                  key: ValueKey('${song.songid}-$index'),
                  leading: Text(
                    '${index + 1}',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  title: Text(
                    song.songname ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white),
                  ),
                  subtitle: Text(
                    song.name ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.grey),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      LikeButton(
                        id: song.songid ?? '',
                        isIcon: true,
                        cover: song.coverImageUrl ?? '',
                        fullname: song.name ?? '',
                        name: song.songname ?? '',
                        track: song.trackid ?? '',
                        username: song.userid ?? '',
                      ),
                      IconButton(
                        tooltip: 'Play',
                        onPressed: () =>
                            widget.con.setPlaylist(widget.songs, startIndex: index),
                        icon: const Icon(Icons.play_arrow, color: Colors.white),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
