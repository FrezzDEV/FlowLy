import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:line_icons/line_icons.dart';
import '../../controllers/main_controller.dart';
import '../../methods/get_time_ago.dart';
import '../../methods/snackbar.dart';
import '../liked_songs/liked_songs.dart';
import '../playlist/playlist_songs.dart';
import '../recently_played/recently_played_songs.dart';
import '../../utils/loading.dart';

class Library extends StatelessWidget {
  final MainController con;
  const Library({super.key, required this.con});

  static Route<void> _noAnimationRoute(Widget page) => PageRouteBuilder<void>(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      );

  @override
  Widget build(BuildContext context) {
    final devicePexelRatio = MediaQuery.of(context).devicePixelRatio;
    return Scaffold(
      appBar: const LibraryAppBar(),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            _LibraryItem(
              title: 'Liked Songs',
              subtitle: '${Hive.box('liked').length} Songs',
              color: Colors.blue,
              icon: CupertinoIcons.heart_fill,
              onTap: () => Navigator.push(context, _noAnimationRoute(LikedSongs(con: con))),
            ),
            _LibraryItem(
              title: 'Recently played',
              subtitle: '${Hive.box('RecentlyPlayed').length} Songs',
              color: Colors.green,
              icon: CupertinoIcons.arrow_counterclockwise,
              onTap: () => Navigator.push(context, _noAnimationRoute(RecentlyPlayedSongs(con: con))),
            ),
            ValueListenableBuilder(
              valueListenable: Hive.box('downloads').listenable(),
              builder: (context, Box box, child) => _LibraryItem(
                title: 'Downloads',
                subtitle: '${box.length} Songs',
                color: const Color(0xFF7C3AED),
                icon: CupertinoIcons.arrow_down_to_line,
                onTap: () => Navigator.push(context, _noAnimationRoute(DownloadsPage(con: con))),
              ),
            ),
            ValueListenableBuilder(
              valueListenable: Hive.box('playlists').listenable(),
              builder: (context, Box<dynamic> box, child) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (box.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                        child: Text('Your playlists', style: Theme.of(context).textTheme.headlineMedium!.copyWith(fontSize: 18)),
                      ),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: box.length,
                      itemBuilder: (context, i) {
                        final playlists = box.getAt(i);
                        return Dismissible(
                          key: Key(playlists['name'].toString()),
                          onDismissed: (_) {
                            box.deleteAt(i);
                            context.showSnackBar(message: 'Deleted playlist.');
                          },
                          direction: DismissDirection.endToStart,
                          background: Container(alignment: Alignment.centerRight, child: const Padding(padding: EdgeInsets.all(20), child: Icon(CupertinoIcons.delete, color: Colors.white))),
                          child: InkWell(
                            onTap: () => Navigator.push(context, _noAnimationRoute(PlaylistSongs(con: con, name: playlists['name'], coverImage: playlists['coverImage']))),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                              child: Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(5),
                                    child: CachedNetworkImage(
                                      imageUrl: playlists['coverImage'], width: 60, height: 60,
                                      memCacheHeight: (70 * devicePexelRatio).round(), memCacheWidth: (70 * devicePexelRatio).round(),
                                      maxHeightDiskCache: (70 * devicePexelRatio).round(), maxWidthDiskCache: (70 * devicePexelRatio).round(),
                                      placeholder: (context, u) => const LoadingImage(icon: Icon(LineIcons.user)), fit: BoxFit.cover,
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(10),
                                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                      Text(playlists['name'], style: const TextStyle(color: Colors.white, fontSize: 16)),
                                      const SizedBox(height: 4),
                                      Text('Created by you ${''.displayTimeAgoFromTimestamp(playlists['created'])}', style: const TextStyle(color: Colors.grey)),
                                    ]),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _LibraryItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;
  const _LibraryItem({required this.title, required this.subtitle, required this.color, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        child: Row(children: [
          ClipRRect(borderRadius: BorderRadius.circular(5), child: Container(width: 60, height: 60, color: color, child: Center(child: Icon(icon, color: Colors.white)))),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(color: Colors.white, fontSize: 16)),
              const SizedBox(height: 5),
              Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 14)),
            ]),
          ),
        ]),
      ),
    );
  }
}

class DownloadsPage extends StatelessWidget {
  final MainController con;
  const DownloadsPage({super.key, required this.con});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Downloads'), backgroundColor: Colors.black),
      body: ValueListenableBuilder(
        valueListenable: Hive.box('downloads').listenable(),
        builder: (context, Box box, child) {
          if (box.isEmpty) {
            return const Center(child: Text('No downloads yet', style: TextStyle(color: Colors.white54)));
          }
          return ListView.builder(
            itemCount: box.length,
            itemBuilder: (context, index) {
              final item = box.getAt(index);
              return ListTile(
                title: Text(item['songname'] ?? 'Unknown', style: const TextStyle(color: Colors.white)),
                subtitle: Text(item['name'] ?? '', style: const TextStyle(color: Colors.white54)),
              );
            },
          );
        },
      ),
    );
  }
}

class LibraryAppBar extends StatelessWidget implements PreferredSizeWidget {
  const LibraryAppBar({super.key});
  @override
  Widget build(BuildContext context) => Container(
        color: Colors.black,
        child: const SafeArea(
          child: Align(alignment: Alignment.centerLeft, child: Padding(padding: EdgeInsets.fromLTRB(20, 18, 20, 14), child: Text('Your Library', style: TextStyle(color: Colors.white, fontSize: 32, height: 1, fontWeight: FontWeight.w800, letterSpacing: -1)))),
        ),
      );
  @override
  Size get preferredSize => const Size.fromHeight(64);
}
