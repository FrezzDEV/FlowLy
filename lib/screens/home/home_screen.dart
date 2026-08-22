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
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(22),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTestPlayerTap,
          child: Container(
            height: 220,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF424242), Color(0xFF161616)],
              ),
            ),
            padding: const EdgeInsets.all(22),
            child: Stack(
              children: [
                const Positioned(
                  top: 0,
                  right: 0,
                  child: Icon(
                    Icons.graphic_eq_rounded,
                    color: Colors.white24,
                    size: 72,
                  ),
                ),
                const Positioned(
                  top: 0,
                  left: 0,
                  child: Icon(
                    Icons.music_note_rounded,
                    color: Colors.white70,
                    size: 34,
                  ),
                ),
                const Positioned(
                  left: 0,
                  right: 0,
                  bottom: 66,
                  child: Text(
                    'Midnight Flow',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      height: 1.0,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const Positioned(
                  left: 0,
                  right: 0,
                  bottom: 36,
                  child: Text(
                    'FlowLy Test Artist',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
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
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
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
            onPressed: () {},
            icon: const Icon(
              Icons.notifications_none_rounded,
              color: Colors.white,
              size: 27,
            ),
          ),
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
      child: Text(title, style: Theme.of(context).textTheme.headlineSmall),
    );
  }
}
