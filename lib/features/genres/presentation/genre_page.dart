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
    return BlocProvider(
      create: (context) => GenreCubit()..getGenre(tag),
      child: BlocBuilder<GenreCubit, GenreState>(
        builder: (context, state) {
          if (state.status == LoadPage.loading) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          if (state.status == LoadPage.loaded) {
            final genreState = state;
            return _buildLoaded(context, genreState);
          }
          if (state.status == LoadPage.error) {
            return const Scaffold(body: Center(child: Text('Error', style: TextStyle(color: Colors.white))));
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildLoaded(BuildContext context, GenreState state) {
    // Preserve the existing genre UI; the explicit local state variable above
    // prevents nullable-flow analysis from treating the loaded state as null.
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            title: Text(state.tag?.name ?? tag.name ?? 'Genre'),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                'Artists',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
          ),
          SliverList.builder(
            itemCount: state.users.length,
            itemBuilder: (context, index) {
              final user = state.users[index];
              return ListTile(
                leading: user.avatar != null
                    ? CircleAvatar(backgroundImage: NetworkImage(user.avatar!))
                    : const CircleAvatar(child: Icon(Icons.person)),
                title: Text(user.username ?? ''),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => ArtistProfilePlaceholder(
                      username: user.username ?? '',
                      con: con,
                    ),
                  ),
                ),
              );
            },
          ),
          SliverToBoxAdapter(
            child: HorizontalSongsList(
              songs: state.songs,
              con: con,
              title: 'Popular',
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
    );
  }
}

class ArtistProfilePlaceholder extends StatelessWidget {
  final String username;
  final MainController con;
  const ArtistProfilePlaceholder({super.key, required this.username, required this.con});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(username)),
        body: Center(child: Text(username)),
      );
}
