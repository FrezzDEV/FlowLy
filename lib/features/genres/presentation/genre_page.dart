import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flowly/features/player/domain/main_controller.dart';
import 'package:flowly/core/utils/string_methods.dart';
import 'package:flowly/data/models/catagory.dart';
import 'package:flowly/data/models/loading_enum.dart';
import 'genre_cubit.dart';
import 'package:flowly/features/player/presentation/botttom_sheet_widget.dart';
import 'package:flowly/shared/widgets/horizontal_songs_list.dart';
import 'package:flowly/shared/widgets/loading.dart';

class GenrePage extends StatelessWidget {
  final TagsModel tag;
  final MainController con;
  const GenrePage({super.key, required this.tag, required this.con});

  @override
  Widget build(BuildContext context) {
    final devicePexelRatio = MediaQuery.of(context).devicePixelRatio;
    final width = MediaQuery.of(context).size.width;
    return BlocProvider(
      create: (context) => GenreCubit()..init(tag.tag),
      child: BlocBuilder<GenreCubit, GenreState>(
        builder: (context, state) {
          if (state.status == LoadPage.loading) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          if (state.status == LoadPage.loaded) {
            return Scaffold(
              body: CustomScrollView(
                slivers: [
                  SliverAppBar(
                    pinned: true,
                    expandedHeight: 200,
                    backgroundColor: Colors.black,
                    flexibleSpace: FlexibleSpaceBar(
                      centerTitle: true,
                      collapseMode: CollapseMode.pin,
                      background: ClipRRect(
                        child: Stack(
                          children: [
                            CachedNetworkImage(
                              imageUrl: tag.image,
                              height: 200,
                              memCacheHeight: (200 * devicePexelRatio).round(),
                              memCacheWidth: (width * devicePexelRatio).round(),
                              maxHeightDiskCache: (200 * devicePexelRatio).round(),
                              maxWidthDiskCache: (width * devicePexelRatio).round(),
                              width: width,
                              fit: BoxFit.cover,
                            ),
                            BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.bottomCenter,
                                    end: Alignment.center,
                                    colors: [Colors.black, Colors.black.withValues(alpha: 0.5)],
                                  ),
                                ),
                                height: 250,
                                width: width,
                              ),
                            ),
                          ],
                        ),
                      ),
                      title: Text(tag.tag.toTitleCase(), style: Theme.of(context).textTheme.headlineSmall),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                      child: Text('Best Artists', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontSize: 18)),
                    ),
                  ),
                  SliverToBoxAdapter(child: HorizontalArtistList(con: con, users: state.users)),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                      child: Text('${tag.tag.toTitleCase()} Songs', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontSize: 18)),
                    ),
                  ),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) {
                        final song = state.songs[i];
                        final isPlaying = con.currentSong?.songname == song.songname;
                        return InkWell(
                          onTap: () => context.read<GenreCubit>().playSongs(con, i),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Flexible(
                                  child: Row(
                                    children: [
                                      Text('${i + 1}', style: const TextStyle(fontSize: 16, color: Colors.white)),
                                      const SizedBox(width: 16),
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(3),
                                        child: CachedNetworkImage(
                                          imageUrl: song.coverImageUrl!,
                                          width: 50,
                                          height: 50,
                                          memCacheHeight: (50 * devicePexelRatio).round(),
                                          memCacheWidth: (50 * devicePexelRatio).round(),
                                          maxHeightDiskCache: (50 * devicePexelRatio).round(),
                                          maxWidthDiskCache: (50 * devicePexelRatio).round(),
                                          progressIndicatorBuilder: (context, url, progress) => const LoadingImage(),
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                      Flexible(
                                        child: Padding(
                                          padding: const EdgeInsets.all(8),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(song.songname!, maxLines: 1, style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: isPlaying ? Colors.lightGreenAccent[700] : Colors.white, overflow: TextOverflow.ellipsis)),
                                              const SizedBox(height: 5),
                                              Text(song.duration!, style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey)),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  onPressed: () => showModalBottomSheet(
                                    useRootNavigator: true,
                                    isScrollControlled: true,
                                    elevation: 100,
                                    backgroundColor: Colors.black38,
                                    context: context,
                                    builder: (_) => BottomSheetWidget(con: con, song: song),
                                  ),
                                  icon: const Icon(Icons.more_vert, color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      childCount: state.songs.length,
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 150)),
                ],
              ),
            );
          }
          if (state.status == LoadPage.error) {
            return const Scaffold(body: Center(child: Text('Error', style: TextStyle(color: Colors.white))));
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}
