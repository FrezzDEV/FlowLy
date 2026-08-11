import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../controllers/main_controller.dart';
import '../../models/loading_enum.dart';
import '../../utils/horizontal_songs_list.dart';
import '../../utils/recent_users.dart';
import 'cubit/home_cubit.dart';

class HomeScreen extends StatelessWidget {
  final MainController con;

  const HomeScreen({
    super.key,
    required this.con,
  });

  List<T> _take<T>(List<T> values, int start, [int? end]) {
    if (start >= values.length) return const [];
    final safeEnd = (end ?? values.length).clamp(start, values.length);
    return values.sublist(start, safeEnd);
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => HomeCubit()..getUsers(),
      child: BlocBuilder<HomeCubit, HomeState>(
        builder: (context, state) {
          if (state.status == LoadPage.loading) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          if (state.status == LoadPage.loaded) {
            final recentUsers = _take(state.users, 0, 6);
            final bestArtists = _take(state.users, 6, 16);
            final moreArtists = _take(state.users, 16);
            final popularSongs = _take(state.songs, 0, 10);
            final newReleases = _take(state.songs, 10, 20);

            if (state.users.isEmpty && state.songs.isEmpty) {
              return _HomeScaffold(
                con: con,
                body: _EmptyHome(
                  message: 'No recommendations are available yet.',
                  onRetry: () => context.read<HomeCubit>().getUsers(),
                ),
              );
            }

            return _HomeScaffold(
              con: con,
              body: ListView(
                padding: const EdgeInsets.only(bottom: 100),
                children: [
                  if (recentUsers.isNotEmpty) ...[
                    RecentUsers(con: con, users: recentUsers),
                    const SizedBox(height: 12),
                  ],
                  if (popularSongs.isNotEmpty) ...[
                    const _SectionTitle(title: 'Popular Hits'),
                    HorizontalSongList(con: con, songs: popularSongs),
                    const SizedBox(height: 12),
                  ],
                  if (bestArtists.isNotEmpty) ...[
                    const _SectionTitle(title: 'Best Picks For You'),
                    HorizontalArtistList(con: con, users: bestArtists),
                    const SizedBox(height: 12),
                  ],
                  if (newReleases.isNotEmpty) ...[
                    const _SectionTitle(title: 'New Releases'),
                    HorizontalSongList(con: con, songs: newReleases),
                    const SizedBox(height: 12),
                  ],
                  if (moreArtists.isNotEmpty) ...[
                    const _SectionTitle(title: 'You might also like'),
                    HorizontalArtistList(con: con, users: moreArtists),
                    const SizedBox(height: 12),
                  ],
                ],
              ),
            );
          }

          if (state.status == LoadPage.error) {
            return _HomeScaffold(
              con: con,
              body: _EmptyHome(
                message:
                    'Unable to load recommendations.\n\n${state.errorMessage ?? 'Unknown error.'}',
                onRetry: () => context.read<HomeCubit>().getUsers(),
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _HomeScaffold extends StatelessWidget {
  final MainController con;
  final Widget body;

  const _HomeScaffold({
    required this.con,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const _FlowLyHeader(),
            Expanded(child: body),
          ],
        ),
      ),
    );
  }
}

class _FlowLyHeader extends StatelessWidget {
  const _FlowLyHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 14, 14),
      child: Row(
        children: [
          const Icon(Icons.waves_rounded, color: Colors.white, size: 30),
          const SizedBox(width: 8),
          const Text(
            'FlowLy',
            style: TextStyle(
              color: Colors.white,
              fontSize: 32,
              height: 1.0,
              fontWeight: FontWeight.w800,
              letterSpacing: -1.0,
            ),
          ),
          const Spacer(),
          IconButton(
            tooltip: 'Notifications',
            onPressed: () {},
            icon: const Icon(
              Icons.notifications_none_rounded,
              color: Colors.white,
              size: 27,
            ),
          ),
          const SizedBox(width: 2),
          const CircleAvatar(
            radius: 18,
            backgroundImage: NetworkImage('https://i.pravatar.cc/200?img=12'),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.headlineSmall,
      ),
    );
  }
}

class _EmptyHome extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _EmptyHome({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, size: 56, color: Colors.white54),
            const SizedBox(height: 16),
            const Text(
              'Home is unavailable',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 22, color: Colors.white),
            ),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white60),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF7C3AED),
                foregroundColor: Colors.white,
              ),
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
