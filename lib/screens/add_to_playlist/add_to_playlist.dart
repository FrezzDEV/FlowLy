import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_styled_toast/flutter_styled_toast.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../utils/extensions.dart';

class AddToPlaylist extends StatelessWidget {
  final String name;
  final String fullname;
  final String username;
  final String cover;
  final String track;
  final String? id;

  const AddToPlaylist({
    super.key,
    required this.name,
    required this.fullname,
    required this.username,
    required this.cover,
    required this.track,
    this.id,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      shrinkWrap: true,
      children: [
        ListTile(
          title: const Text('Create a new Playlist'),
          onTap: () => _showCreatePlaylistDialog(context),
        ),
        if (Hive.box('playlists').isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            child: Text(
              'Your playlists',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 18),
            ),
          ),
        Padding(
          padding: const EdgeInsets.all(10),
          child: ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: Hive.box('playlists').length,
            itemBuilder: (context, index) {
              final playlist = Hive.box('playlists').getAt(index);
              if (playlist is! Map) return const SizedBox.shrink();
              final playlistName = playlist['name']?.toString();
              if (playlistName == null || playlistName.isEmpty) {
                return const SizedBox.shrink();
              }
              return ListTile(
                contentPadding: const EdgeInsets.all(6),
                onTap: () => _addToExistingPlaylist(context, playlistName),
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: CachedNetworkImage(
                    imageUrl: playlist['coverImage']?.toString() ?? '',
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                  ),
                ),
                title: Text(playlistName),
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _showCreatePlaylistDialog(BuildContext context) async {
    final controller = TextEditingController();
    try {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text('Create a new Playlist'),
            content: TextField(
              controller: controller,
              autofocus: true,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(hintText: 'Playlist name'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('CANCEL'),
              ),
              TextButton(
                onPressed: () async {
                  final playlistName = controller.text.trim();
                  if (playlistName.isEmpty) {
                    dialogContext.showErrorSnackBar(message: 'Please enter a name');
                    return;
                  }
                  if (await Hive.boxExists(playlistName)) {
                    if (!dialogContext.mounted) return;
                    dialogContext.showErrorSnackBar(message: 'Playlist already exists');
                    return;
                  }
                  final playlistsBox = Hive.box('playlists');
                  await playlistsBox.add({
                    'name': playlistName,
                    'coverImage': cover,
                    'created': DateTime.now().toIso8601String(),
                  });
                  final playlistBox = await Hive.openBox(playlistName);
                  await playlistBox.put(name, {
                    'songname': name,
                    'fullname': fullname,
                    'username': username,
                    'cover': cover,
                    'track': track,
                    'id': id,
                  });
                  if (!dialogContext.mounted) return;
                  Navigator.pop(dialogContext);
                  dialogContext.showSnackBar(message: 'Song added to playlist.');
                },
                child: const Text('CREATE AND ADD'),
              ),
            ],
          );
        },
      );
    } finally {
      controller.dispose();
    }
  }

  Future<void> _addToExistingPlaylist(BuildContext context, String playlistName) async {
    final playlistBox = await Hive.openBox(playlistName);
    await playlistBox.put(name, {
      'songname': name,
      'fullname': fullname,
      'username': username,
      'cover': cover,
      'track': track,
    });
    if (!context.mounted) return;
    context.showSnackBar(message: 'Song added to playlist.');
    Navigator.pop(context);
  }
}
