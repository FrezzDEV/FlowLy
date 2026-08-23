import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:line_icons/line_icons.dart';
import '../../methods/get_time_ago.dart';
import '../../methods/snackbar.dart';
import '../../utils/loading.dart';

class AddToPlaylist extends StatelessWidget {
  final String name;
  final String fullname;
  final String username;
  final String cover;
  final String track;
  final String id;
  const AddToPlaylist({
    super.key,
    required this.name,
    required this.fullname,
    required this.username,
    required this.cover,
    required this.track,
    required this.id,
  });

  @override
  Widget build(BuildContext context) {
    final con = TextEditingController();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Add to Playlist",
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        backgroundColor: Colors.black,
      ),
      body: ListView(
        children: [
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: MaterialButton(
                  color: Colors.lightGreenAccent[700],
                  minWidth: MediaQuery.of(context).size.width * .7,
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (dialogContext) {
                        return AlertDialog(
                          backgroundColor: Colors.grey.shade900,
                          title: const Text(
                            "Give your collection a name.",
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                          content: TextField(
                            controller: con,
                            cursorColor: Colors.lightGreen,
                            style: const TextStyle(color: Colors.white, fontSize: 24),
                            autofocus: true,
                            decoration: const InputDecoration(
                              focusedBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: Colors.lightGreen, width: 2),
                              ),
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(dialogContext),
                              child: const Text(
                                "CANCEL",
                                style: TextStyle(color: Colors.white, fontSize: 15),
                              ),
                            ),
                            TextButton(
                              onPressed: () async {
                                final playlistName = con.text.trim();
                                if (playlistName.isEmpty) {
                                  dialogContext.showErrorSnackBar(message: "Please enter a name");
                                  return;
                                }

                                final playlistsBox = Hive.box('playlists');
                                if (await Hive.boxExists(playlistName)) {
                                  if (!dialogContext.mounted) return;
                                  dialogContext.showErrorSnackBar(
                                    message: "Playlist already exists",
                                  );
                                  return;
                                }

                                await playlistsBox.add({
                                  "name": playlistName,
                                  "coverImage": cover,
                                  "created": DateTime.now().toIso8601String(),
                                });
                                final playlistBox = await Hive.openBox(playlistName);
                                await playlistBox.put(name, {
                                  "songname": name,
                                  "fullname": fullname,
                                  "username": username,
                                  "cover": cover,
                                  "track": track,
                                  "id": id,
                                });

                                if (!dialogContext.mounted) return;
                                dialogContext.showSnackBar(
                                  message: "Song added to playlist.",
                                );
                                Navigator.pop(dialogContext);
                                Navigator.of(dialogContext).pop();
                                Navigator.of(dialogContext).pop();
                              },
                              child: Text(
                                "CREATE AND ADD",
                                style: TextStyle(color: Colors.lightGreen[700], fontSize: 15),
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  },
                  child: const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      "Create a new Playlist",
                      style: TextStyle(color: Colors.black, fontSize: 16),
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (Hive.box('playlists').isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16),
              child: Text(
                "Your playlists",
                style: Theme.of(context).textTheme.headlineMedium!.copyWith(fontSize: 18),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: Hive.box('playlists').length,
              itemBuilder: (context, i) {
                final playlists = Hive.box('playlists').getAt(i) as Map;
                return ListTile(
                  contentPadding: const EdgeInsets.all(6),
                  onTap: () async {
                    final playlistName = playlists['name'].toString();
                    await Hive.openBox(playlistName);
                    final playlistBox = Hive.box(playlistName);
                    await playlistBox.put(name, {
                      "songname": name,
                      "fullname": fullname,
                      "username": username,
                      "cover": cover,
                      "track": track,
                    });
                    if (!context.mounted) return;
                    context.showSnackBar(message: "Song added to playlist.");
                    Navigator.pop(context);
                    Navigator.of(context).pop();
                  },
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(5),
                    child: CachedNetworkImage(
                      imageUrl: playlists['coverImage'],
                      width: 50,
                      height: 50,
                      maxHeightDiskCache: 80,
                      maxWidthDiskCache: 80,
                      memCacheHeight: (80 * MediaQuery.of(context).devicePixelRatio).round(),
                      memCacheWidth: (80 * MediaQuery.of(context).devicePixelRatio).round(),
                      placeholder: (context, u) => const LoadingImage(
                        icon: Icon(LineIcons.user),
                      ),
                      fit: BoxFit.cover,
                    ),
                  ),
                  title: Text(
                    playlists['name'],
                    style: const TextStyle(color: Colors.white),
                  ),
                  subtitle: Text(
                    "Created By you ${"".displayTimeAgoFromTimestamp(playlists['created'])}",
                    style: const TextStyle(color: Colors.grey),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
