import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flowly/features/player/domain/main_controller.dart';
import 'package:flowly/data/models/loading_enum.dart';
import 'package:flowly/shared/widgets/horizontal_songs_list.dart';
import 'package:flowly/shared/widgets/recent_users.dart';
import 'cubit/home_cubit.dart';

class HomeScreen extends StatelessWidget {
  final MainController con;
  final VoidCallback? onTestPlayerTap;
  const HomeScreen({super.key, required this.con, this.onTestPlayerTap});

  List<T> _take<T>(List<T> values, int start, [int? end]) {
    if (start >= values.length) return const [];
    final safeEnd = (end ?? values.length).clamp(start, values.length);
    return values.sublist(start, safeEnd);
  }

  Widget _testPlayerCard(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
        child: Align(
          alignment: Alignment.centerLeft,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onTestPlayerTap,
            child: Container(
              width: 156,
              height: 156,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF151515),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.music_note_rounded, color: Colors.white70, size: 30),
                  const Spacer(),
                  Text(
                    'Midnight Flow',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'FlowLy Test Artist',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

  Widget _content(BuildContext context, HomeState state) {
    final recentUsers = _take(state.users, 0, 6);
    final bestArtists = _take(state.users, 6, 16);
    final moreArtists = _take(state.users, 16);
    final popularSongs = _take(state.songs, 0, 10);
    final newReleases = _take(state.songs, 10, 20);
    return ListView(
      padding: const EdgeInsets.only(bottom: 180),
      children: [
        _testPlayerCard(context),
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
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) => BlocProvider(
        create: (_) => HomeCubit()..getUsers(),
        child: BlocBuilder<HomeCubit, HomeState>(
          builder: (context, state) {
            if (state.status == LoadPage.loading) {
              return const Scaffold(body: Center(child: CircularProgressIndicator()));
            }
            return _HomeScaffold(con: con, body: _content(context, state));
          },
        ),
      );
}

class _HomeScaffold extends StatelessWidget {
  final MainController con;
  final Widget body;
  const _HomeScaffold({required this.con, required this.body});
  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(child: Column(children: [const _FlowLyHeader(), Expanded(child: body)])),
      );
}

class _FlowLyHeader extends StatelessWidget {
  const _FlowLyHeader();
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 14, 14),
        child: Row(
          children: [
            const Icon(Icons.waves_rounded, color: Colors.white, size: 30),
            const SizedBox(width: 8),
            const Text(
              'FlowLy',
              style: TextStyle(color: Colors.white, fontSize: 32, height: 1, fontWeight: FontWeight.w800, letterSpacing: -1),
            ),
            const Spacer(),
            const Icon(Icons.notifications_none_rounded, color: Colors.white, size: 27),
            const SizedBox(width: 12),
            const CircleAvatar(radius: 18, backgroundImage: NetworkImage('https://i.pravatar.cc/200?img=12')),
          ],
        ),
      );
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Text(title, style: Theme.of(context).textTheme.headlineSmall),
      );
}
