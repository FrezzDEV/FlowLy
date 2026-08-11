import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../controllers/main_controller.dart';
import 'loading.dart';

class PlayWidget extends StatelessWidget {
  final MainController con;
  final void Function()? onTap;

  const PlayWidget({
    super.key,
    required this.con,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final ratio = MediaQuery.of(context).devicePixelRatio;

    return AnimatedBuilder(
      animation: con,
      builder: (context, child) {
        final song = con.currentSong;
        if (song == null) return const SizedBox.shrink();

        return GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black12, width: 0.5),
              borderRadius: BorderRadius.circular(6),
              boxShadow: kElevationToShadow[9],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Stack(
                children: [
                  CachedNetworkImage(
                    imageUrl: song.coverImageUrl ?? '',
                    width: double.infinity,
                    height: 48,
                    memCacheHeight: (70 * ratio).round(),
                    memCacheWidth: (70 * ratio).round(),
                    progressIndicatorBuilder: (_, __, ___) =>
                        const LoadingImage(),
                    fit: BoxFit.cover,
                  ),
                  BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 4,
                        horizontal: 8,
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(3),
                            child: CachedNetworkImage(
                              imageUrl: song.coverImageUrl ?? '',
                              width: 40,
                              height: 40,
                              fit: BoxFit.cover,
                              progressIndicatorBuilder: (_, __, ___) =>
                                  const LoadingImage(),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  song.songname ?? '',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.bodyLarge,
                                ),
                                Text(
                                  song.name ?? '',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            padding: EdgeInsets.zero,
                            onPressed: con.playOrPause,
                            icon: Icon(
                              con.isPlaying ? Icons.pause : Icons.play_arrow,
                              color: Colors.white,
                              size: 36,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
