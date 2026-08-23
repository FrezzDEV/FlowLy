import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flowly/features/player/domain/main_controller.dart';
import 'package:flowly/data/models/loading_enum.dart';
import 'package:flowly/features/player/presentation/botttom_sheet_widget.dart';
import 'package:flowly/shared/widgets/loading.dart';
import 'package:flowly/shared/widgets/sliver_appbar.dart';
import 'artist_profile_cubit.dart';

class ArtistProfile extends StatelessWidget {
  final String username;
  final MainController con;
  const ArtistProfile({super.key, required this.username, required this.con});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ArtistProfileCubit()..getUser(username),
      child: BlocBuilder<ArtistProfileCubit, ArtistProfileState>(
        builder: (context, state) {
          if (state.status == LoadPage.loading) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          if (state.status == LoadPage.loaded) {
            final profileState = state;
            return Scaffold(
              extendBody: true,
              body: CustomScrollView(
                slivers: [
                  SliverPersistentHeader(
                    delegate: MyDelegate(
                      user: profileState.user,
                      con: con,
                      songs: profileState.songs,
                    ),
                    pinned: true,
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text('Popular', style: Theme.of(context).textTheme.headlineSmall),
                    ),
                  ),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) {
                        final song = profileState.songs[i];
                        final isPlaying = con.currentSong?.songname == song.songname;
                        return InkWell(
                          onTap: () => context.read<ArtistProfileCubit>().playSongs(con, i),
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
                                          maxHeightDiskCache: 100,
                                          maxWidthDiskCache: 100,
                                          memCacheHeight: (50 * MediaQuery.of(context).devicePixelRatio).round(),
                                          memCacheWidth: (50 * MediaQuery.of(context).devicePixelRatio).round(),
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
                                              Text(
                                                song.songname!,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                                      color: isPlaying ? Colors.lightGreenAccent[700] : Colors.white,
                                                    ),
                                              ),
                                              const SizedBox(height: 5),
                                              Text(
                                                song.duration!,
                                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey),
                                              ),
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
                      childCount: profileState.songs.length,
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
