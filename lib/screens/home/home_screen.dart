import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../controllers/main_controller.dart';
import '../../models/loading_enum.dart';
import '../../utils/horizontal_songs_list.dart';
import '../../utils/recent_users.dart';
import 'cubit/home_cubit.dart';

class HomeScreen extends StatelessWidget {
  final MainController con;
  final VoidCallback? onTestPlayerTap;

  const HomeScreen({
    super.key,
    required this.con,
    this.onTestPlayerTap,
  });

  List<T> _take<T>(List<T> values, int start, [int? end]) {
    if (start >= values.length) return const [];
    final safeEnd = (end ?? values.length).clamp(start, values.length);
    return values.sublist(start, safeEnd);
  }

  Widget _testPlayerCard() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
      child: Material(
        color: const Color(0xFF151515),
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTestPlayerTap,
          child: SizedBox(
            height: 220,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  'https://images.unsplash.com/photo-1516450360452-9312f5e86fc7?auto=format&fit=crop&w=1200&q=85',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const ColoredBox(
                    color: Color(0xFF242424),
                    child: Center(
                      child: Icon(
                        Icons.music_note_rounded,
                        color: Colors.white54,
                        size: 64,
                      ),
                    ),
                  ),
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.05),
                        Colors.black.withOpacity(0.78),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: 18,
                  right: 18,
                  bottom: 16,
                  child: Row(
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Тестовый трек',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Нажми на обложку — откроется большой плеер',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Material(
                        color: Colors.white,
                        shape: const CircleBorder(),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: const Icon(
                            Icons.play_arrow_rounded,
                            color: Colors.black,
                            size: 28,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _content(BuildContext context, HomeState state) {
    final recentUsers = _take(state.users, 0, 6);
    final bestArtists = _take(state.users, 6, 16);
    final moreArtists = _take(state.users, 16);
    final popularSongs = _take(state.songs, 0, 10);
    final newReleases = _take(state.songs, 10, 20);

    return ListView(
      padding: const EdgeInsets.only(bottom: 100),
      children: [
        _testPlayerCard(),
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
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => HomeCubit()..getUsers(),
      child: BlocBuilder<HomeCubit, HomeState>(
        builder: (context, state) {
          if (state.status == LoadPage.loading) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }

          return _HomeScaffold(
            con: con,
            body: _content(context, state),
          );
        },
      ),
    );
  }
}

class _HomeScaffold extends StatelessWidget {
  final MainController con;
  final Widget body;
  const _HomeScaffold({required this.con, required this.body});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [const _FlowLyHeader(), Expanded(child: body)],
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
          const Text('FlowLy', style: TextStyle(color: Colors.white, fontSize: 32, height: 1.0, fontWeight: FontWeight.w800, letterSpacing: -1.0)),
          const Spacer(),
          IconButton(onPressed: () {}, icon: const Icon(Icons.notifications_none_rounded, color: Colors.white, size: 27)),
          const CircleAvatar(radius: 18, backgroundImage: NetworkImage('https://i.pravatar.cc/200?img=12')),
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
      child: Text(title, style: Theme.of(context).textTheme.headlineSmall),
    );
  }
}
