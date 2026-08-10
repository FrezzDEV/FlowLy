import 'package:flutter/material.dart';

import 'models/track.dart';
import 'services/player_service.dart';
import 'services/theme_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final player = PlayerService();
  await player.initialize();
  final themes = ThemeService();
  await themes.load();
  runApp(FlowLyApp(player: player, themes: themes));
}

class FlowLyApp extends StatelessWidget {
  const FlowLyApp({super.key, required this.player, required this.themes});

  final PlayerService player;
  final ThemeService themes;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: themes,
      builder: (context, _) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'FlowLy',
        theme: ThemeData(
          brightness: Brightness.dark,
          useMaterial3: true,
          scaffoldBackgroundColor: themes.theme.background,
          colorScheme: ColorScheme.dark(
            primary: themes.theme.accent,
            onPrimary: themes.theme.accent.computeLuminance() > .5 ? Colors.black : Colors.white,
            surface: themes.theme.surface,
            onSurface: Colors.white,
          ),
          navigationBarTheme: NavigationBarThemeData(
            backgroundColor: themes.theme.background,
            indicatorColor: themes.theme.accent.withOpacity(.12),
            labelTextStyle: MaterialStateProperty.all(const TextStyle(fontWeight: FontWeight.w600)),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: themes.theme.surface.withOpacity(.9),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(themes.theme.radius),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        home: FlowLyShell(player: player, themes: themes),
      ),
    );
  }
}

class FlowLyShell extends StatefulWidget {
  const FlowLyShell({super.key, required this.player, required this.themes});

  final PlayerService player;
  final ThemeService themes;

  @override
  State<FlowLyShell> createState() => _FlowLyShellState();
}

class _FlowLyShellState extends State<FlowLyShell> {
  int tab = 0;

  void openPlayer() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PlayerScreen(player: widget.player, themes: widget.themes),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screens = <Widget>[
      HomeScreen(player: widget.player),
      SearchScreen(player: widget.player),
      LibraryScreen(player: widget.player),
      ProfileScreen(player: widget.player, themes: widget.themes),
    ];

    return Scaffold(
      body: SafeArea(child: IndexedStack(index: tab, children: screens)),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          MiniPlayer(player: widget.player, onTap: openPlayer),
          NavigationBar(
            selectedIndex: tab,
            onDestinationSelected: (value) => setState(() => tab = value),
            destinations: const [
              NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Главная'),
              NavigationDestination(icon: Icon(Icons.search), selectedIcon: Icon(Icons.search_rounded), label: 'Поиск'),
              NavigationDestination(icon: Icon(Icons.library_music_outlined), selectedIcon: Icon(Icons.library_music), label: 'Библиотека'),
              NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Профиль'),
            ],
          ),
        ],
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.player});

  final PlayerService player;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        const SliverPadding(
          padding: EdgeInsets.fromLTRB(20, 18, 20, 0),
          sliver: SliverToBoxAdapter(
            child: Text('FlowLy', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800)),
          ),
        ),
        const SliverPadding(
          padding: EdgeInsets.fromLTRB(20, 28, 20, 10),
          sliver: SliverToBoxAdapter(child: SectionTitle('Недавно прослушано')),
        ),
        SliverToBoxAdapter(
          child: SizedBox(
            height: 210,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: 4,
              separatorBuilder: (_, __) => const SizedBox(width: 14),
              itemBuilder: (_, i) => TrackCard(
                track: demoTracks[i],
                onTap: () => player.playTrack(demoTracks[i]),
              ),
            ),
          ),
        ),
        const SliverPadding(
          padding: EdgeInsets.fromLTRB(20, 28, 20, 10),
          sliver: SliverToBoxAdapter(child: SectionTitle('Для тебя')),
        ),
        SliverToBoxAdapter(
          child: SizedBox(
            height: 152,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: 4,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, i) => MoodCard(
                title: const ['Chill', 'Night Drive', 'Focus', 'Workout'][i],
                icon: const [Icons.nights_stay_outlined, Icons.route_outlined, Icons.center_focus_strong_outlined, Icons.bolt_outlined][i],
                color: const [0xFF53205E, 0xFF09264B, 0xFF0D5C4B, 0xFF3C1B55][i],
              ),
            ),
          ),
        ),
        const SliverPadding(
          padding: EdgeInsets.fromLTRB(20, 28, 20, 10),
          sliver: SliverToBoxAdapter(child: SectionTitle('Рекомендуем для тебя')),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (_, i) => TrackRow(
                track: demoTracks[i + 4],
                onTap: () => player.playTrack(demoTracks[i + 4]),
              ),
              childCount: 4,
            ),
          ),
        ),
        const SliverPadding(
          padding: EdgeInsets.fromLTRB(20, 28, 20, 10),
          sliver: SliverToBoxAdapter(child: SectionTitle('Популярные плейлисты')),
        ),
        SliverToBoxAdapter(
          child: SizedBox(
            height: 172,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: 4,
              separatorBuilder: (_, __) => const SizedBox(width: 14),
              itemBuilder: (_, i) => PlaylistCard(
                title: const ['Рассвет', 'Ночь', 'Лето', 'Дорога'][i],
                count: 120 - i * 17,
                index: i,
              ),
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 20)),
      ],
    );
  }
}

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key, required this.player});

  final PlayerService player;

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final query = TextEditingController();
  int filter = 0;

  @override
  void dispose() {
    query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = query.text.toLowerCase();
    final results = demoTracks.where((track) {
      return text.isEmpty || '${track.title} ${track.artist}'.toLowerCase().contains(text);
    }).toList();

    return CustomScrollView(
      slivers: [
        const SliverPadding(
          padding: EdgeInsets.fromLTRB(20, 22, 20, 18),
          sliver: SliverToBoxAdapter(child: Text('Поиск', style: TextStyle(fontSize: 36, fontWeight: FontWeight.w800))),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverToBoxAdapter(
            child: TextField(
              controller: query,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Трек, артист, альбом...',
                suffixIcon: Icon(Icons.tune),
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
          sliver: SliverToBoxAdapter(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['Треки', 'Альбомы', 'Артисты', 'Плейлисты'].asMap().entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: ChoiceChip(
                      label: Text(entry.value),
                      selected: filter == entry.key,
                      selectedColor: Colors.white,
                      labelStyle: TextStyle(color: filter == entry.key ? Colors.black : Colors.white),
                      onSelected: (_) => setState(() => filter = entry.key),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (_, i) => TrackRow(
                track: results[i],
                onTap: () => widget.player.playTrack(results[i]),
                trailing: const Icon(Icons.add_rounded),
              ),
              childCount: results.length,
            ),
          ),
        ),
      ],
    );
  }
}

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key, required this.player});

  final PlayerService player;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        const SliverPadding(
          padding: EdgeInsets.fromLTRB(20, 22, 20, 20),
          sliver: SliverToBoxAdapter(child: Text('Библиотека', style: TextStyle(fontSize: 36, fontWeight: FontWeight.w800))),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverToBoxAdapter(
            child: GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.55,
              children: const [
                LibraryTile(Icons.favorite_rounded, 'Любимые', '128 треков'),
                LibraryTile(Icons.queue_music_rounded, 'Плейлисты', '24'),
                LibraryTile(Icons.download_rounded, 'Скачанное', '312 треков'),
                LibraryTile(Icons.history_rounded, 'Недавние', '50 треков'),
              ],
            ),
          ),
        ),
        const SliverPadding(
          padding: EdgeInsets.fromLTRB(20, 28, 20, 10),
          sliver: SliverToBoxAdapter(child: Text('Плейлисты', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700))),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (_, i) => TrackRow(
                track: Track(
                  id: 'playlist-$i',
                  title: const ['Моя музыка', 'Chill Vibes', 'Топ 2024', 'Тренировка', 'В дороге', 'Грустное'][i],
                  artist: '${20 + i * 13} треков',
                  duration: Duration.zero,
                  audioUrl: demoTracks[i % demoTracks.length].audioUrl,
                  gradient: demoTracks[i % demoTracks.length].gradient,
                ),
                onTap: () => player.playTrack(demoTracks[i % demoTracks.length]),
              ),
              childCount: 6,
            ),
          ),
        ),
      ],
    );
  }
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key, required this.player, required this.themes});

  final PlayerService player;
  final ThemeService themes;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 30),
      children: [
        Row(
          children: [
            const CircleAvatar(radius: 32, backgroundColor: Color(0xFF252832), child: Icon(Icons.person, size: 34)),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Алекс', style: TextStyle(fontSize: 23, fontWeight: FontWeight.w700)),
                  Text('Персональный музыкальный профиль', style: TextStyle(color: Colors.white54)),
                ],
              ),
            ),
            IconButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SettingsScreen(player: player, themes: themes))),
              icon: const Icon(Icons.settings_outlined),
            ),
          ],
        ),
        const SizedBox(height: 26),
        const Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [Stat('24', 'Плейлисты'), Stat('128', 'Подписки'), Stat('56', 'Подписчики')]),
        const SizedBox(height: 30),
        const Text('Быстрые действия', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        ActionTile(Icons.palette_outlined, 'Темы', 'Настройте стиль FlowLy', () => Navigator.push(context, MaterialPageRoute(builder: (_) => ThemesScreen(themes: themes)))),
        ActionTile(Icons.import_export_rounded, 'Импорт музыки', 'Перенесите свою медиатеку', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ImportScreen()))),
        ActionTile(Icons.tune_rounded, 'Фильтры контента', 'Оригиналы, ремиксы и AI', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FiltersScreen()))),
        ActionTile(Icons.queue_music_rounded, 'Очередь', 'Управление следующим треком', () => Navigator.push(context, MaterialPageRoute(builder: (_) => QueueScreen(player: player)))),
        ActionTile(Icons.settings_outlined, 'Настройки', 'Воспроизведение, язык, приватность', () => Navigator.push(context, MaterialPageRoute(builder: (_) => SettingsScreen(player: player, themes: themes)))),
      ],
    );
  }
}

class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key, required this.player, required this.themes});

  final PlayerService player;
  final ThemeService themes;

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  bool shuffle = false;
  bool repeat = false;
  bool liked = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: StreamBuilder<int?>(
          stream: widget.player.player.currentIndexStream,
          builder: (context, _) {
            final track = widget.player.currentTrack;
            return StreamBuilder<bool>(
              stream: widget.player.player.playingStream,
              initialData: widget.player.player.playing,
              builder: (context, playingSnapshot) {
                final playing = playingSnapshot.data ?? false;
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(10, 4, 10, 0),
                      child: Row(
                        children: [
                          IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 30)),
                          const Expanded(child: Column(children: [Text('Сейчас играет', style: TextStyle(color: Colors.white54)), Text('Плейлист «Chill»', style: TextStyle(fontWeight: FontWeight.w700))])),
                          IconButton(onPressed: () {}, icon: const Icon(Icons.more_horiz)),
                        ],
                      ),
                    ),
                    Expanded(child: Padding(padding: const EdgeInsets.fromLTRB(20, 22, 20, 0), child: TrackArt(track: track, size: double.infinity, radius: 26))),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 22, 24, 0),
                      child: Row(
                        children: [
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(track.title, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800)), Text(track.artist, style: const TextStyle(fontSize: 18, color: Colors.white60))])),
                          IconButton(onPressed: () => setState(() => liked = !liked), icon: Icon(liked ? Icons.favorite : Icons.favorite_border, size: 31)),
                        ],
                      ),
                    ),
                    StreamBuilder<Duration>(
                      stream: widget.player.player.positionStream,
                      builder: (context, positionSnapshot) {
                        final position = positionSnapshot.data ?? Duration.zero;
                        final duration = widget.player.player.duration ?? track.duration;
                        final maxMs = duration.inMilliseconds < 1 ? 1 : duration.inMilliseconds;
                        final value = position.inMilliseconds.clamp(0, maxMs).toDouble();
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            children: [
                              Slider(value: value, min: 0, max: maxMs.toDouble(), onChanged: (v) => widget.player.seek(Duration(milliseconds: v.toInt()))),
                              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(formatDuration(position), style: const TextStyle(color: Colors.white54)), Text(formatDuration(duration), style: const TextStyle(color: Colors.white54))]),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        IconButton(onPressed: () { setState(() => shuffle = !shuffle); widget.player.setShuffle(shuffle); }, icon: Icon(Icons.shuffle, color: shuffle ? Theme.of(context).colorScheme.primary : Colors.white)),
                        IconButton(onPressed: widget.player.previous, icon: const Icon(Icons.skip_previous_rounded, size: 44)),
                        GestureDetector(onTap: widget.player.toggle, child: Container(width: 78, height: 78, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle), child: Icon(playing ? Icons.pause_rounded : Icons.play_arrow_rounded, color: Colors.black, size: 43))),
                        IconButton(onPressed: widget.player.next, icon: const Icon(Icons.skip_next_rounded, size: 44)),
                        IconButton(onPressed: () { setState(() => repeat = !repeat); widget.player.setRepeat(repeat); }, icon: Icon(Icons.repeat, color: repeat ? Theme.of(context).colorScheme.primary : Colors.white)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        PlayerAction(Icons.lyrics_outlined, 'Текст', () => Navigator.push(context, MaterialPageRoute(builder: (_) => LyricsScreen(track: track)))),
                        PlayerAction(Icons.auto_awesome, 'Похожее', () {}),
                        PlayerAction(Icons.timer_outlined, 'Таймер', () => showTimer(context)),
                        PlayerAction(Icons.queue_music_rounded, 'Очередь', () => Navigator.push(context, MaterialPageRoute(builder: (_) => QueueScreen(player: widget.player)))),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      child: Container(
                        padding: const EdgeInsets.all(17),
                        decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface.withOpacity(.8), borderRadius: BorderRadius.circular(widget.themes.theme.radius)),
                        child: Row(children: [const Expanded(child: Text('Далее в очереди', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700))), Text('${widget.player.queue.length - 1}', style: const TextStyle(color: Colors.white54)), const SizedBox(width: 8), const Icon(Icons.keyboard_arrow_up)]),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key, required this.player, required this.onTap});

  final PlayerService player;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int?>(
      stream: player.player.currentIndexStream,
      builder: (context, _) {
        final track = player.currentTrack;
        return Container(
          margin: const EdgeInsets.fromLTRB(10, 0, 10, 4),
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface.withOpacity(.96), borderRadius: BorderRadius.circular(18)),
          child: StreamBuilder<bool>(
            stream: player.player.playingStream,
            initialData: player.player.playing,
            builder: (context, snapshot) => Row(
              children: [
                GestureDetector(onTap: onTap, child: TrackArt(track: track, size: 48, radius: 12)),
                const SizedBox(width: 10),
                Expanded(child: GestureDetector(onTap: onTap, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(track.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)), Text(track.artist, style: const TextStyle(color: Colors.white54, fontSize: 12))]))),
                IconButton(onPressed: player.previous, icon: const Icon(Icons.skip_previous_rounded)),
                IconButton(onPressed: player.toggle, icon: Icon((snapshot.data ?? false) ? Icons.pause_rounded : Icons.play_arrow_rounded)),
                IconButton(onPressed: player.next, icon: const Icon(Icons.skip_next_rounded)),
              ],
            ),
          ),
        );
      },
    );
  }
}

class QueueScreen extends StatefulWidget {
  const QueueScreen({super.key, required this.player});

  final PlayerService player;

  @override
  State<QueueScreen> createState() => _QueueScreenState();
}

class _QueueScreenState extends State<QueueScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Очередь'), actions: [TextButton(onPressed: () async { await widget.player.clearQueue(); setState(() {}); }, child: const Text('Очистить'))]),
      body: ReorderableListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
        itemCount: widget.player.queue.length,
        onReorder: (oldIndex, newIndex) async { await widget.player.reorderQueue(oldIndex, newIndex); setState(() {}); },
        itemBuilder: (context, index) {
          final track = widget.player.queue[index];
          return ListTile(
            key: ValueKey(track.id),
            contentPadding: const EdgeInsets.symmetric(vertical: 5),
            leading: TrackArt(track: track, size: 52, radius: 10),
            title: Text(track.title, style: const TextStyle(fontWeight: FontWeight.w700)),
            subtitle: Text(track.artist),
            trailing: Row(mainAxisSize: MainAxisSize.min, children: [if (index == (widget.player.player.currentIndex ?? 0)) const Icon(Icons.equalizer_rounded), IconButton(onPressed: () async { await widget.player.removeFromQueue(index); setState(() {}); }, icon: const Icon(Icons.close_rounded))]),
            onTap: () async { await widget.player.playTrack(track); setState(() {}); },
          );
        },
      ),
    );
  }
}

class ThemesScreen extends StatelessWidget {
  const ThemesScreen({super.key, required this.themes});

  final ThemeService themes;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Темы'), actions: [IconButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ThemeEditorScreen(themes: themes))), icon: const Icon(Icons.edit_outlined))]),
      body: AnimatedBuilder(
        animation: themes,
        builder: (context, _) => ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
          children: [
            const Text('Рекомендуемые', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
            const SizedBox(height: 14),
            ...themes.presets.map((theme) => ThemeCard(theme: theme, active: themes.theme.name == theme.name, onApply: () => themes.apply(theme))),
            const SizedBox(height: 20),
            FilledButton.icon(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ThemeEditorScreen(themes: themes))), icon: const Icon(Icons.add), label: const Text('Создать свою тему')),
          ],
        ),
      ),
    );
  }
}

class ThemeEditorScreen extends StatefulWidget {
  const ThemeEditorScreen({super.key, required this.themes});

  final ThemeService themes;

  @override
  State<ThemeEditorScreen> createState() => _ThemeEditorScreenState();
}

class _ThemeEditorScreenState extends State<ThemeEditorScreen> {
  late FlowTheme draft;
  final colors = const [Colors.white, Color(0xFFB9E7FF), Color(0xFFD6F5D1), Color(0xFFFFD6C2), Color(0xFFFFC4E1), Color(0xFFE4D1FF)];

  @override
  void initState() {
    super.initState();
    draft = widget.themes.theme;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Редактор темы'), actions: [TextButton(onPressed: () async { await widget.themes.apply(draft); if (mounted) Navigator.pop(context); }, child: const Text('Сохранить'))]),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: draft.surface.withOpacity(draft.opacity), borderRadius: BorderRadius.circular(draft.radius)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('FlowLy', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)), const SizedBox(height: 10), Row(children: [Expanded(child: Container(height: 76, decoration: BoxDecoration(gradient: LinearGradient(colors: [draft.accent.withOpacity(.9), draft.surface]), borderRadius: BorderRadius.circular(draft.radius)))), const SizedBox(width: 12), const Icon(Icons.play_circle_fill_rounded, size: 52)])]),
          ),
          const SizedBox(height: 24),
          const Text('Основной цвет', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Wrap(spacing: 14, children: colors.map((color) => GestureDetector(onTap: () => setState(() => draft = draft.copyWith(accent: color)), child: CircleAvatar(radius: 17, backgroundColor: color, child: draft.accent.value == color.value ? const Icon(Icons.check, color: Colors.black) : null))).toList()),
          const SizedBox(height: 22),
          const Text('Прозрачность', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          Slider(value: draft.opacity, min: .55, max: 1, onChanged: (value) => setState(() => draft = draft.copyWith(opacity: value))),
          const Text('Радиус карточек', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          Slider(value: draft.radius, min: 8, max: 32, onChanged: (value) => setState(() => draft = draft.copyWith(radius: value))),
          SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('Плавные анимации'), subtitle: const Text('Синхронизация переходов и плеера'), value: draft.animations, onChanged: (value) => setState(() => draft = draft.copyWith(animations: value))),
          SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('Компактный режим'), subtitle: const Text('Больше контента на экране'), value: draft.compact, onChanged: (value) => setState(() => draft = draft.copyWith(compact: value))),
          DropdownButtonFormField<String>(value: draft.coverStyle, decoration: const InputDecoration(labelText: 'Стиль обложек'), items: const [DropdownMenuItem(value: 'rounded', child: Text('Скруглённые')), DropdownMenuItem(value: 'square', child: Text('Квадратные')), DropdownMenuItem(value: 'soft', child: Text('Мягкие'))], onChanged: (value) => setState(() => draft = draft.copyWith(coverStyle: value))),
          const SizedBox(height: 18),
          OutlinedButton(onPressed: () => setState(() => draft = FlowTheme.defaultTheme), child: const Text('Сбросить')),
        ],
      ),
    );
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, required this.player, required this.themes});

  final PlayerService player;
  final ThemeService themes;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Настройки')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
        children: [
          const SettingsGroupTitle('Аккаунт'),
          const SettingsTile(Icons.person_outline, 'Аккаунт', 'Профиль, подписка и данные'),
          const SettingsTile(Icons.security_outlined, 'Безопасность', 'Пароль, двухфакторная аутентификация'),
          const SettingsTile(Icons.credit_card_outlined, 'Платежи', 'Способы оплаты и история'),
          const SettingsGroupTitle('Приложение'),
          const SettingsTile(Icons.music_note_outlined, 'Воспроизведение', 'Качество звука, кроссфейд, эквалайзер'),
          const SettingsTile(Icons.download_outlined, 'Скачивание', 'Настройки скачивания и хранения'),
          const SettingsTile(Icons.notifications_none, 'Уведомления', 'Только важное'),
          SettingsTile(Icons.palette_outlined, 'Внешний вид', 'Темы, цвета и оформление', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ThemesScreen(themes: themes)))),
          SettingsTile(Icons.tune_rounded, 'Фильтры контента', 'Ремиксы, каверы, AI и дубликаты', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FiltersScreen()))),
          SettingsTile(Icons.queue_music_rounded, 'Очередь', 'Управление текущим воспроизведением', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => QueueScreen(player: player)))),
          const SettingsGroupTitle('Другое'),
          const SettingsTile(Icons.language, 'Язык', 'Русский'),
          const SettingsTile(Icons.info_outline, 'О приложении', 'FlowLy 1.1.0'),
          const SettingsTile(Icons.help_outline, 'Поддержка', 'Помощь и обратная связь'),
        ],
      ),
    );
  }
}

class FiltersScreen extends StatefulWidget {
  const FiltersScreen({super.key});

  @override
  State<FiltersScreen> createState() => _FiltersScreenState();
}

class _FiltersScreenState extends State<FiltersScreen> {
  bool remixes = true;
  bool covers = true;
  bool ai = true;
  bool duplicates = true;
  bool originals = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Фильтры контента')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('Чистый каталог', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          const Text('Управляйте тем, какие версии треков FlowLy показывает в рекомендациях.', style: TextStyle(color: Colors.white60)),
          const SizedBox(height: 20),
          SwitchListTile(title: const Text('Приоритет оригиналов'), value: originals, onChanged: (v) => setState(() => originals = v)),
          SwitchListTile(title: const Text('Скрывать ремиксы'), value: remixes, onChanged: (v) => setState(() => remixes = v)),
          SwitchListTile(title: const Text('Скрывать каверы и пародии'), value: covers, onChanged: (v) => setState(() => covers = v)),
          SwitchListTile(title: const Text('Скрывать AI-generated треки'), value: ai, onChanged: (v) => setState(() => ai = v)),
          SwitchListTile(title: const Text('Скрывать дубликаты'), value: duplicates, onChanged: (v) => setState(() => duplicates = v)),
        ],
      ),
    );
  }
}

class ImportScreen extends StatelessWidget {
  const ImportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final services = ['Spotify', 'Apple Music', 'YouTube Music', 'VK Музыка', 'Deezer', 'Yandex Music'];
    return Scaffold(
      appBar: AppBar(title: const Text('Импорт музыки')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
        children: [
          const Text('Перенесите свою библиотеку', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          const Text('FlowLy подготовит плейлисты, избранное, альбомы и историю к переносу.', style: TextStyle(color: Colors.white60)),
          const SizedBox(height: 20),
          ...services.map((name) => ListTile(
                contentPadding: const EdgeInsets.symmetric(vertical: 5),
                leading: CircleAvatar(backgroundColor: Colors.white10, child: Text(name.substring(0, 1))),
                title: Text(name, style: const TextStyle(fontWeight: FontWeight.w700)),
                trailing: FilledButton.tonal(onPressed: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Импорт $name будет подключён через API.'))), child: const Text('Импортировать')),
              )),
        ],
      ),
    );
  }
}

class LyricsScreen extends StatelessWidget {
  const LyricsScreen({super.key, required this.track});

  final Track track;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Текст')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
        children: [
          Text(track.title, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
          Text(track.artist, style: const TextStyle(fontSize: 17, color: Colors.white54)),
          const SizedBox(height: 28),
          const Text('Текст песни подключается через музыкальный API.\n\nЭкран уже отделён от плеера, поэтому позже сюда можно добавить синхронизацию по времени, перевод и режим караоке.', style: TextStyle(fontSize: 18, height: 1.6)),
        ],
      ),
    );
  }
}

class TrackCard extends StatelessWidget {
  const TrackCard({super.key, required this.track, required this.onTap});

  final Track track;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 166,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(children: [TrackArt(track: track, size: 166, radius: 18), Positioned(right: 9, bottom: 9, child: CircleAvatar(backgroundColor: Colors.black54, child: IconButton(onPressed: onTap, icon: const Icon(Icons.play_arrow_rounded, color: Colors.white))))]),
          const SizedBox(height: 8),
          Text(track.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)),
          Text(track.artist, style: const TextStyle(color: Colors.white54)),
        ],
      ),
    );
  }
}

class TrackRow extends StatelessWidget {
  const TrackRow({super.key, required this.track, required this.onTap, this.trailing});

  final Track track;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 3),
      leading: TrackArt(track: track, size: 52, radius: 11),
      title: Text(track.title, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(track.artist, style: const TextStyle(color: Colors.white60)),
      trailing: trailing ?? const Icon(Icons.more_horiz),
      onTap: onTap,
    );
  }
}

class TrackArt extends StatelessWidget {
  const TrackArt({super.key, required this.track, required this.size, this.radius = 16});

  final Track track;
  final double size;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final colors = track.gradient.map(Color.new).toList();
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: colors),
        boxShadow: [BoxShadow(color: colors.first.withOpacity(.22), blurRadius: 18, spreadRadius: 1)],
      ),
      child: Center(child: Text(track.title.substring(0, 1), style: TextStyle(fontSize: size.isFinite ? size * .28 : 36, fontWeight: FontWeight.w900, color: Colors.white.withOpacity(.85)))),
    );
  }
}

class MoodCard extends StatelessWidget {
  const MoodCard({super.key, required this.title, required this.icon, required this.color});

  final String title;
  final IconData icon;
  final int color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 148,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Color(color), borderRadius: BorderRadius.circular(20)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.end, children: [Icon(icon, size: 24), const Spacer(), Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)), const Text('плейлист', style: TextStyle(color: Colors.white60))]),
    );
  }
}

class PlaylistCard extends StatelessWidget {
  const PlaylistCard({super.key, required this.title, required this.count, required this.index});

  final String title;
  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    const secondary = [Color(0xFF132F6B), Color(0xFF7A2B78), Color(0xFF174D77), Color(0xFF245A45)];
    return SizedBox(
      width: 160,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(height: 126, decoration: BoxDecoration(borderRadius: BorderRadius.circular(18), gradient: LinearGradient(colors: [const Color(0xFF5B1A72), secondary[index], const Color(0xFF090B13)])), child: const Center(child: Icon(Icons.play_circle_fill_rounded, size: 42))),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          Text('$count треков', style: const TextStyle(color: Colors.white54)),
        ],
      ),
    );
  }
}

class LibraryTile extends StatelessWidget {
  const LibraryTile(this.icon, this.title, this.subtitle, {super.key});

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(20)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Icon(icon, size: 27), Text(title, style: const TextStyle(fontWeight: FontWeight.w700)), Text(subtitle, style: const TextStyle(color: Colors.white54))]),
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.title, {super.key});

  final String title;

  @override
  Widget build(BuildContext context) => Row(children: [Expanded(child: Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800))), const Text('Ещё', style: TextStyle(color: Colors.white54)), const Icon(Icons.chevron_right, color: Colors.white54)]);
}

class Stat extends StatelessWidget {
  const Stat(this.value, this.label, {super.key});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Column(children: [Text(value, style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w800)), Text(label, style: const TextStyle(color: Colors.white54))]);
}

class ActionTile extends StatelessWidget {
  const ActionTile(this.icon, this.title, this.subtitle, this.onTap, {super.key});

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(onTap: onTap, contentPadding: const EdgeInsets.symmetric(vertical: 4), leading: Icon(icon), title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)), subtitle: Text(subtitle), trailing: const Icon(Icons.chevron_right));
}

class PlayerAction extends StatelessWidget {
  const PlayerAction(this.icon, this.label, this.onTap, {super.key});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(onTap: onTap, borderRadius: BorderRadius.circular(16), child: Padding(padding: const EdgeInsets.all(8), child: Column(children: [Icon(icon), const SizedBox(height: 5), Text(label, style: const TextStyle(fontSize: 12, color: Colors.white70))])));
}

class SettingsGroupTitle extends StatelessWidget {
  const SettingsGroupTitle(this.title, {super.key});

  final String title;

  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.fromLTRB(0, 18, 0, 8), child: Text(title, style: const TextStyle(color: Colors.white54, fontWeight: FontWeight.w700)));
}

class SettingsTile extends StatelessWidget {
  const SettingsTile(this.icon, this.title, this.subtitle, {super.key, this.onTap});

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => ListTile(onTap: onTap, contentPadding: const EdgeInsets.symmetric(vertical: 2), leading: Icon(icon), title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)), subtitle: Text(subtitle), trailing: const Icon(Icons.chevron_right));
}

class ThemeCard extends StatelessWidget {
  const ThemeCard({super.key, required this.theme, required this.active, required this.onApply});

  final FlowTheme theme;
  final bool active;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: theme.surface, borderRadius: BorderRadius.circular(theme.radius)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(height: 110, decoration: BoxDecoration(borderRadius: BorderRadius.circular(theme.radius), gradient: LinearGradient(colors: [theme.accent.withOpacity(.9), theme.surface, theme.background]))),
        const SizedBox(height: 12),
        Row(children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(theme.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)), const Text('Бесплатно', style: TextStyle(color: Colors.white54))])), active ? const Icon(Icons.check_circle_rounded) : FilledButton.tonal(onPressed: onApply, child: const Text('Применить'))]),
      ]),
    );
  }
}

void showTimer(BuildContext context) {
  showModalBottomSheet(
    context: context,
    builder: (_) => SafeArea(
      child: ListView(
        shrinkWrap: true,
        children: [
          const ListTile(title: Text('Таймер сна', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800))),
          for (final value in ['15 минут', '30 минут', '45 минут', '60 минут']) ListTile(title: Text(value), onTap: () => Navigator.pop(context)),
        ],
      ),
    ),
  );
}

String formatDuration(Duration duration) {
  final minutes = duration.inMinutes.remainder(60).toString();
  final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}
