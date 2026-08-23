import 'dart:math';
import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

import 'package:flowly/features/player/domain/main_controller.dart';
import 'package:flowly/domain/entities/song_model.dart';
import 'package:flowly/domain/entities/user_model.dart';

double _appTopBarHeight = 60;

class MyDelegate extends SliverPersistentHeaderDelegate {
  final UserModel user;
  final MainController con;
  final List<SongModel> songs;

  MyDelegate({
    required this.user,
    required this.con,
    required this.songs,
  });

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final shrinkPercentage =
        min(1.0, shrinkOffset / (maxExtent - minExtent)).toDouble();

    return Stack(
      fit: StackFit.expand,
      children: [
        Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  CachedNetworkImage(
                    imageUrl: user.avatar ?? '',
                    width: double.infinity,
                    height: 400,
                    fit: BoxFit.cover,
                  ),
                  BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
                    child: const SizedBox.expand(),
                  ),
                  Opacity(
                    opacity: 1 - shrinkPercentage,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.center,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withValues(alpha: .5),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              height: 70,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.black, Colors.transparent],
                ),
              ),
            ),
          ],
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SizedBox(
            height: _appTopBarHeight + 35,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                ),
                Expanded(
                  child: Opacity(
                    opacity: shrinkPercentage,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 14),
                      child: Text(
                        user.name ?? '',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Colors.white,
                            ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          bottom: 70,
          left: 0,
          right: 0,
          child: Opacity(
            opacity: max(1 - shrinkPercentage * 6, 0),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                user.name ?? '',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      color: Colors.white,
                      fontSize: 48,
                    ),
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 10,
          right: 10,
          child: AnimatedBuilder(
            animation: con,
            builder: (context, child) {
              final currentIds = con.songs.map((s) => s.songid).toList();
              final targetIds = songs.map((s) => s.songid).toList();
              final isSame = const ListEquality().equals(currentIds, targetIds);
              return FloatingActionButton(
                backgroundColor: Colors.white,
                onPressed: () {
                  if (isSame) {
                    con.playOrPause();
                  } else {
                    con.setPlaylist(songs, startIndex: 0);
                  }
                },
                child: Icon(
                  isSame && con.isPlaying ? Icons.pause : Icons.play_arrow,
                  color: Colors.black,
                  size: 32,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  double get maxExtent => 400;

  @override
  double get minExtent => 110;

  @override
  bool shouldRebuild(covariant MyDelegate oldDelegate) =>
      oldDelegate.user != user || oldDelegate.con != con ||
      !const ListEquality<SongModel>().equals(oldDelegate.songs, songs);
}
