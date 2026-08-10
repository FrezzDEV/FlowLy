import 'package:flutter/material.dart';

void main() => runApp(const FlowLyApp());

class FlowLyApp extends StatelessWidget {
  const FlowLyApp({super.key});

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFF07080D);
    const surface = Color(0xFF11131A);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'FlowLy',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: bg,
        colorScheme: const ColorScheme.dark(
          primary: Colors.white,
          onPrimary: Colors.black,
          surface: surface,
          onSurface: Colors.white,
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: const Shell(),
    );
  }
}

class Track {
  final String title;
  final String artist;
  final String art;
  const Track(this.title, this.artist, this.art);
}

const tracks = <Track>[
  Track('Blinding Lights', 'The Weeknd', 'amber'),
  Track('After Hours', 'The Weeknd', 'red'),
  Track('Starboy', 'The Weeknd', 'blue'),
  Track('Un Verano Sin Ti', 'Bad Bunny', 'pink'),
  Track('Save Your Tears', 'The Weeknd', 'violet'),
  Track('Another Love', 'Tom Odell', 'mono'),
  Track('Believer', 'Imagine Dragons', 'cyan'),
  Track('Hurt', 'Johnny Cash', 'gray'),
  Track('Wasted Times', 'The Weeknd', 'orange'),
];

class Shell extends StatefulWidget {
  const Shell({super.key});
  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int tab = 0;
  Track current = tracks.first;
  bool playing = true;

  void play(Track track) => setState(() {
    current = track;
    playing = true;
  });

  void openPlayer() => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => PlayerSheet(track: current, playing: playing, onPlay: () => setState(() => playing = !playing)),
  );

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeScreen(onPlay: play),
      SearchScreen(onPlay: play),
      LibraryScreen(onPlay: play),
      ProfileScreen(onOpenSettings: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()))),
    ];
    return Scaffold(
      body: SafeArea(child: IndexedStack(index: tab, children: screens)),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          MiniPlayer(track: current, playing: playing, onTap: openPlayer, onPlay: () => setState(() => playing = !playing)),
          NavigationBar(
            selectedIndex: tab,
            onDestinationSelected: (i) => setState(() => tab = i),
            backgroundColor: const Color(0xFF08090E),
            indicatorColor: Colors.white.withOpacity(.08),
            destinations: const [
              NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Главная'),
              NavigationDestination(icon: Icon(Icons.search), label: 'Поиск'),
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
  final ValueChanged<Track> onPlay;
  const HomeScreen({super.key, required this.onPlay});
  @override
  Widget build(BuildContext context) {
    return CustomScrollView(slivers: [
      SliverPadding(padding: const EdgeInsets.fromLTRB(20, 18, 20, 0), sliver: SliverToBoxAdapter(child: Row(children: [
        const Expanded(child: Text('FlowLy', style: TextStyle(fontSize: 31, fontWeight: FontWeight.w700, letterSpacing: -.8))),
        IconButton(onPressed: () {}, icon: const Icon(Icons.notifications_none_rounded)),
      ]))),
      SliverPadding(padding: const EdgeInsets.fromLTRB(20, 28, 0, 0), sliver: SliverToBoxAdapter(child: SectionTitle('Недавно прослушано'))),
      SliverPadding(padding: const EdgeInsets.only(top: 12), sliver: SliverToBoxAdapter(child: SizedBox(height: 205, child: ListView.separated(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 20), itemCount: 4, separatorBuilder: (_, __) => const SizedBox(width: 14), itemBuilder: (_, i) => TrackCard(track: tracks[i], onTap: onPlay)))),
      SliverPadding(padding: const EdgeInsets.fromLTRB(20, 30, 0, 0), sliver: SliverToBoxAdapter(child: SectionTitle('Для тебя'))),
      SliverPadding(padding: const EdgeInsets.only(top: 12), sliver: SliverToBoxAdapter(child: SizedBox(height: 150, child: ListView.separated(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 20), itemCount: 4, separatorBuilder: (_, __) => const SizedBox(width: 14), itemBuilder: (_, i) => MoodCard(['Chill', 'Night Drive', 'Focus', 'Workout'][i], i)))),
      SliverPadding(padding: const EdgeInsets.fromLTRB(20, 30, 0, 0), sliver: SliverToBoxAdapter(child: SectionTitle('Рекомендуем для тебя'))),
      SliverPadding(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8), sliver: SliverList(delegate: SliverChildBuilderDelegate((_, i) => TrackRow(track: tracks[i + 4], onTap: onPlay), childCount: 4))),
      SliverPadding(padding: const EdgeInsets.fromLTRB(20, 22, 0, 0), sliver: SliverToBoxAdapter(child: SectionTitle('Популярные плейлисты'))),
      SliverPadding(padding: const EdgeInsets.only(top: 12, bottom: 20), sliver: SliverToBoxAdapter(child: SizedBox(height: 165, child: ListView.separated(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 20), itemCount: 4, separatorBuilder: (_, __) => const SizedBox(width: 14), itemBuilder: (_, i) => PlaylistCard(['Рассвет', 'Ночь', 'Лето', 'Дорога'][i], 64 + i * 11, i)))),
    ]);
  }
}

class SearchScreen extends StatefulWidget {
  final ValueChanged<Track> onPlay;
  const SearchScreen({super.key, required this.onPlay});
  @override
  State<SearchScreen> createState() => _SearchScreenState();
}
class _SearchScreenState extends State<SearchScreen> {
  final controller = TextEditingController();
  int filter = 0;
  @override
  Widget build(BuildContext context) {
    final q = controller.text.toLowerCase();
    final results = tracks.where((t) => q.isEmpty || '${t.title} ${t.artist}'.toLowerCase().contains(q)).toList();
    return CustomScrollView(slivers: [
      const SliverPadding(padding: EdgeInsets.fromLTRB(20, 22, 20, 18), sliver: SliverToBoxAdapter(child: Text('Поиск', style: TextStyle(fontSize: 36, fontWeight: FontWeight.w700)))),
      SliverPadding(padding: const EdgeInsets.symmetric(horizontal: 20), sliver: SliverToBoxAdapter(child: TextField(controller: controller, onChanged: (_) => setState(() {}), decoration: InputDecoration(prefixIcon: const Icon(Icons.search), hintText: 'Трек, артист, альбом...', suffixIcon: IconButton(onPressed: () {}, icon: const Icon(Icons.tune)), filled: true, fillColor: const Color(0xFF15171E), border: OutlineInputBorder(borderRadius: BorderRadius.circular(22), borderSide: BorderSide.none))))),
      SliverPadding(padding: const EdgeInsets.fromLTRB(20, 20, 0, 14), sliver: SliverToBoxAdapter(child: SizedBox(height: 44, child: ListView.separated(scrollDirection: Axis.horizontal, itemCount: 4, separatorBuilder: (_, __) => const SizedBox(width: 10), itemBuilder: (_, i) { final labels = ['Треки', 'Альбомы', 'Артисты', 'Плейлисты']; return ChoiceChip(label: Text(labels[i]), selected: filter == i, onSelected: (_) => setState(() => filter = i), selectedColor: Colors.white, labelStyle: TextStyle(color: filter == i ? Colors.black : Colors.white, fontWeight: FontWeight.w600)); })))),
      SliverPadding(padding: const EdgeInsets.symmetric(horizontal: 20), sliver: SliverList(delegate: SliverChildBuilderDelegate((_, i) => TrackRow(track: results[i], onTap: widget.onPlay, trailing: const Icon(Icons.add_rounded)), childCount: results.length.clamp(0, 8)))),
    ]);
  }
}

class LibraryScreen extends StatelessWidget {
  final ValueChanged<Track> onPlay;
  const LibraryScreen({super.key, required this.onPlay});
  @override
  Widget build(BuildContext context) => CustomScrollView(slivers: [
    const SliverPadding(padding: EdgeInsets.fromLTRB(20, 22, 20, 20), sliver: SliverToBoxAdapter(child: Text('Библиотека', style: TextStyle(fontSize: 36, fontWeight: FontWeight.w700)))),
    SliverPadding(padding: const EdgeInsets.symmetric(horizontal: 20), sliver: SliverToBoxAdapter(child: GridView.count(crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 1.45, children: const [LibraryTile(Icons.favorite, 'Любимые', '128 треков'), LibraryTile(Icons.queue_music, 'Плейлисты', '24'), LibraryTile(Icons.download, 'Скачанное', '312 треков'), LibraryTile(Icons.history, 'Недавние', '50 треков')]))),
    const SliverPadding(padding: EdgeInsets.fromLTRB(20, 28, 20, 12), sliver: SliverToBoxAdapter(child: Text('Плейлисты', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)))),
    SliverPadding(padding: const EdgeInsets.symmetric(horizontal: 20), sliver: SliverList(delegate: SliverChildListDelegate(['Моя музыка', 'Chill Vibes', 'Топ 2024', 'Тренировка', 'В дороге', 'Грустное'].asMap().entries.map((e) => TrackRow(track: Track(e.value, '${20 + e.key * 13} треков', ['violet','blue','pink','green','orange','cyan'][e.key]), onTap: onPlay)).toList()))),
  ]);
}

class ProfileScreen extends StatelessWidget {
  final VoidCallback onOpenSettings;
  const ProfileScreen({super.key, required this.onOpenSettings});
  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.fromLTRB(20, 22, 20, 30), children: [
    Row(children: [const CircleAvatar(radius: 32, backgroundColor: Color(0xFF242630), child: Icon(Icons.person, size: 34)), const SizedBox(width: 14), const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Алекс', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)), Text('Персональный музыкальный профиль', style: TextStyle(color: Colors.white54))])), IconButton(onPressed: onOpenSettings, icon: const Icon(Icons.settings_outlined))]),
    const SizedBox(height: 28),
    const Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [Stat('24', 'Плейлисты'), Stat('128', 'Подписки'), Stat('56', 'Подписчики')]),
    const SizedBox(height: 30),
    const Text('Быстрые действия', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
    const SizedBox(height: 12),
    ActionTile(Icons.palette_outlined, 'Темы', 'Настройте стиль FlowLy', () {}),
    ActionTile(Icons.import_export, 'Импорт музыки', 'Перенесите свою медиатеку', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ImportScreen()))),
    ActionTile(Icons.tune, 'Фильтры контента', 'Оригиналы, ремиксы и AI', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FiltersScreen()))),
    ActionTile(Icons.settings_outlined, 'Настройки', 'Воспроизведение, язык, приватность', onOpenSettings),
  ]);
}

class PlayerSheet extends StatefulWidget {
  final Track track; final bool playing; final VoidCallback onPlay;
  const PlayerSheet({super.key, required this.track, required this.playing, required this.onPlay});
  @override State<PlayerSheet> createState() => _PlayerSheetState();
}
class _PlayerSheetState extends State<PlayerSheet> {
  late bool playing;
  @override void initState() { super.initState(); playing = widget.playing; }
  @override Widget build(BuildContext context) => Container(height: MediaQuery.sizeOf(context).height * .94, decoration: const BoxDecoration(color: Color(0xFF08090D), borderRadius: BorderRadius.vertical(top: Radius.circular(28))), child: SafeArea(child: Padding(padding: const EdgeInsets.fromLTRB(20, 10, 20, 20), child: Column(children: [
    Row(children: [IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.keyboard_arrow_down)), const Expanded(child: Column(children: [Text('Сейчас играет', style: TextStyle(color: Colors.white54)), Text('Плейлист «Chill»', style: TextStyle(fontWeight: FontWeight.w600))])), IconButton(onPressed: () {}, icon: const Icon(Icons.more_horiz))]),
    const SizedBox(height: 24),
    Expanded(child: Center(child: ArtCard(track: widget.track, size: MediaQuery.sizeOf(context).width - 40, radius: 24))),
    const SizedBox(height: 22),
    Row(children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(widget.track.title, style: const TextStyle(fontSize: 27, fontWeight: FontWeight.w700)), Text(widget.track.artist, style: const TextStyle(fontSize: 18, color: Colors.white60))])), IconButton(onPressed: () {}, icon: const Icon(Icons.favorite_border, size: 30))]),
    const SizedBox(height: 10), const LinearProgressIndicator(value: .42, minHeight: 3, backgroundColor: Color(0xFF33343A), color: Colors.white), const Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('1:24', style: TextStyle(color: Colors.white54)), Text('3:20', style: TextStyle(color: Colors.white54))]),
    const SizedBox(height: 12),
    Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [IconButton(onPressed: () {}, icon: const Icon(Icons.shuffle, size: 26)), IconButton(onPressed: () {}, icon: const Icon(Icons.skip_previous_rounded, size: 42)), GestureDetector(onTap: () => setState(() => playing = !playing), child: Container(width: 78, height: 78, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle), child: Icon(playing ? Icons.pause_rounded : Icons.play_arrow_rounded, color: Colors.black, size: 42))), IconButton(onPressed: () {}, icon: const Icon(Icons.skip_next_rounded, size: 42)), IconButton(onPressed: () {}, icon: const Icon(Icons.repeat, size: 26))]),
    const SizedBox(height: 10), Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: const [PlayerAction(Icons.lyrics, 'Текст'), PlayerAction(Icons.auto_awesome, 'Похожее'), PlayerAction(Icons.timer_outlined, 'Таймер'), PlayerAction(Icons.queue_music, 'Очередь')]),
    const SizedBox(height: 18), Container(width: double.infinity, padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: const Color(0xFF12141A), borderRadius: BorderRadius.circular(20)), child: const Row(children: [Expanded(child: Text('Далее в очереди', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600))), Icon(Icons.keyboard_arrow_up)])),
  ]))));
}

class SettingsScreen extends StatelessWidget { const SettingsScreen({super.key}); @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Настройки')), body: ListView(padding: const EdgeInsets.fromLTRB(20, 12, 20, 30), children: [SettingGroup(title: 'Аккаунт', children: [SettingTile(Icons.person_outline, 'Аккаунт', 'Профиль, подписка и данные'), SettingTile(Icons.security, 'Безопасность', 'Пароль и двухфакторная аутентификация'), SettingTile(Icons.credit_card, 'Платежи', 'Способы оплаты и история')]), SettingGroup(title: 'Приложение', children: [SettingTile(Icons.music_note, 'Воспроизведение', 'Качество звука, кроссфейд, эквалайзер'), SettingTile(Icons.download, 'Скачивание', 'Настройки скачивания и хранения'), SettingTile(Icons.notifications_none, 'Уведомления', 'Только важное'), SettingTile(Icons.palette_outlined, 'Внешний вид', 'Тема, цвета и оформление'), SettingTile(Icons.subtitles_outlined, 'Текст', 'Отображение текста песен')]), SettingGroup(title: 'Другое', children: [SettingTile(Icons.language, 'Язык', 'Русский'), SettingTile(Icons.info_outline, 'О приложении', 'Версия, лицензии и информация'), SettingTile(Icons.help_outline, 'Поддержка', 'Помощь и обратная связь')]) ]); }

class FiltersScreen extends StatefulWidget { const FiltersScreen({super.key}); @override State<FiltersScreen> createState() => _FiltersScreenState(); }
class _FiltersScreenState extends State<FiltersScreen> { bool remixes=true, covers=true, ai=true, duplicates=true; @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Фильтры контента')), body: ListView(padding: const EdgeInsets.all(20), children: [const Text('Чистый каталог', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700)), const SizedBox(height: 8), const Text('Настройте, какие версии треков показывать в рекомендациях.', style: TextStyle(color: Colors.white60)), const SizedBox(height: 20), SwitchListTile(value: remixes, onChanged:(v)=>setState(()=>remixes=v), title: const Text('Скрывать ремиксы'), subtitle: const Text('Показывать оригинальные версии в приоритете')), SwitchListTile(value: covers, onChanged:(v)=>setState(()=>covers=v), title: const Text('Скрывать каверы и пародии')), SwitchListTile(value: ai, onChanged:(v)=>setState(()=>ai=v), title: const Text('Скрывать AI-generated треки')), SwitchListTile(value: duplicates, onChanged:(v)=>setState(()=>duplicates=v), title: const Text('Скрывать дубликаты и низкое качество')) ]); }

class ImportScreen extends StatelessWidget { const ImportScreen({super.key}); @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Импорт музыки')), body: ListView(padding: const EdgeInsets.all(20), children: [const Text('Перенесите свою библиотеку', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700)), const SizedBox(height: 8), const Text('Плейлисты, избранное, альбомы и историю прослушивания.', style: TextStyle(color: Colors.white60)), const SizedBox(height: 24), ...['Spotify','Apple Music','YouTube Music','VK Музыка','Deezer','Yandex Music'].map((name)=>Card(color: const Color(0xFF12141A), child: ListTile(leading: const Icon(Icons.library_music_outlined), title: Text(name), trailing: FilledButton(onPressed: () {}, child: const Text('Импортировать')))))]); }

class TrackCard extends StatelessWidget { final Track track; final ValueChanged<Track> onTap; const TrackCard({super.key, required this.track, required this.onTap}); @override Widget build(BuildContext context) => SizedBox(width: 165, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Stack(children: [ArtCard(track: track, size: 165, radius: 16), Positioned(right: 8,bottom:8,child: CircleAvatar(backgroundColor: Colors.black.withOpacity(.72), child: const Icon(Icons.play_arrow, color: Colors.white)))]), const SizedBox(height: 8), Text(track.title, maxLines:1, overflow:TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)), Text(track.artist, style: const TextStyle(color: Colors.white54))])); }

class TrackRow extends StatelessWidget { final Track track; final ValueChanged<Track> onTap; final Widget? trailing; const TrackRow({super.key, required this.track, required this.onTap, this.trailing}); @override Widget build(BuildContext context) => InkWell(onTap:()=>onTap(track), borderRadius: BorderRadius.circular(14), child: Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Row(children: [ArtCard(track:track,size:54,radius:10), const SizedBox(width:12), Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(track.title, style:const TextStyle(fontWeight:FontWeight.w600)), Text(track.artist, style:const TextStyle(color:Colors.white54))])), trailing ?? const Icon(Icons.more_horiz, color:Colors.white54)]))); }

class MiniPlayer extends StatelessWidget { final Track track; final bool playing; final VoidCallback onTap,onPlay; const MiniPlayer({super.key, required this.track, required this.playing, required this.onTap, required this.onPlay}); @override Widget build(BuildContext context)=>InkWell(onTap:onTap, child:Container(margin:const EdgeInsets.fromLTRB(12,4,12,0), padding:const EdgeInsets.all(8), decoration:BoxDecoration(color:const Color(0xFF15171E), borderRadius:BorderRadius.circular(16)), child:Row(children:[ArtCard(track:track,size:48,radius:9), const SizedBox(width:10), Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(track.title, maxLines:1,overflow:TextOverflow.ellipsis,style:const TextStyle(fontWeight:FontWeight.w600)),Text(track.artist,style:const TextStyle(color:Colors.white54))])), IconButton(onPressed:onPlay,icon:Icon(playing?Icons.pause:Icons.play_arrow)), const Icon(Icons.queue_music,color:Colors.white54)]))); }

class ArtCard extends StatelessWidget { final Track track; final double size; final double radius; const ArtCard({super.key,required this.track,required this.size,required this.radius}); Color c(String key){switch(key){case'amber':return const Color(0xFFD56A1D);case'red':return const Color(0xFFB70C30);case'blue':return const Color(0xFF132B72);case'pink':return const Color(0xFFB45A67);case'violet':return const Color(0xFF632A8F);case'mono':return const Color(0xFF777777);case'cyan':return const Color(0xFF0C706F);case'gray':return const Color(0xFF404247);default:return const Color(0xFF9B4B18);}} @override Widget build(BuildContext context)=>Container(width:size,height:size,decoration:BoxDecoration(borderRadius:BorderRadius.circular(radius),gradient:LinearGradient(begin:Alignment.topLeft,end:Alignment.bottomRight,colors:[c(track.art),Colors.black])),child:Stack(children:[Positioned.fill(child:CustomPaint(painter:_ArtPainter(c(track.art)))),Center(child:Text(track.artist.substring(0,1),style:TextStyle(fontSize:size*.24,fontWeight:FontWeight.w900,color:Colors.white.withOpacity(.16))))])); }

class _ArtPainter extends CustomPainter { final Color color; _ArtPainter(this.color); @override void paint(Canvas canvas,Size size){final p=Paint()..color=color.withOpacity(.22); for(var i=0;i<5;i++){canvas.drawCircle(Offset(size.width*(.15+i*.2),size.height*(.25+(i%2)*.3)),size.width*(.08+i*.025),p);}} @override bool shouldRepaint(covariant _ArtPainter old)=>false; }

class SectionTitle extends StatelessWidget { final String title; const SectionTitle(this.title,{super.key}); @override Widget build(BuildContext context)=>Row(children:[Text(title,style:const TextStyle(fontSize:20,fontWeight:FontWeight.w700)),const Spacer(),const Padding(padding:EdgeInsets.only(right:20),child:Text('Ещё  ›',style:TextStyle(color:Colors.white54)))]); }
class MoodCard extends StatelessWidget { final String title; final int index; const MoodCard(this.title,this.index,{super.key}); @override Widget build(BuildContext context)=>Container(width:145,decoration:BoxDecoration(borderRadius:BorderRadius.circular(18),gradient:LinearGradient(begin:Alignment.topLeft,end:Alignment.bottomRight,colors:[[Color(0xFF6D247D),Color(0xFF1C1641)],[Color(0xFF123C7D),Color(0xFF111827)],[Color(0xFF0C665B),Color(0xFF102B2B)],[Color(0xFF6C247A),Color(0xFF27143D)]][index])),padding:const EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.start,mainAxisAlignment:MainAxisAlignment.end,children:[Icon([Icons.cloud_outlined,Icons.nightlight_outlined,Icons.track_changes,Icons.bolt_outlined][index],color:Colors.white),const SizedBox(height:18),Text(title,style:const TextStyle(fontSize:19,fontWeight:FontWeight.w700)),const Text('плейлист',style:TextStyle(color:Colors.white54))])); }
class PlaylistCard extends StatelessWidget { final String title; final int count,index; const PlaylistCard(this.title,this.count,this.index,{super.key}); @override Widget build(BuildContext context)=>Container(width:160,decoration:BoxDecoration(borderRadius:BorderRadius.circular(18),gradient:LinearGradient(colors:[[Color(0xFF9B3D9E),Color(0xFF2B205E)],[Color(0xFF172C80),Color(0xFF07101F)],[Color(0xFF9B416E),Color(0xFF26304A)],[Color(0xFF28749B),Color(0xFF12294C)]][index])),padding:const EdgeInsets.all(14),child:Column(crossAxisAlignment:CrossAxisAlignment.start,mainAxisAlignment:MainAxisAlignment.end,children:[const Spacer(),const Icon(Icons.play_circle_fill,size:30),const SizedBox(height:8),Text(title,style:const TextStyle(fontSize:18,fontWeight:FontWeight.w700)),Text('$count треков',style:const TextStyle(color:Colors.white60))])); }
class LibraryTile extends StatelessWidget { final IconData icon; final String title,subtitle; const LibraryTile(this.icon,this.title,this.subtitle,{super.key}); @override Widget build(BuildContext context)=>Container(decoration:BoxDecoration(color:const Color(0xFF12141A),borderRadius:BorderRadius.circular(20)),padding:const EdgeInsets.all(16),child:Column(mainAxisAlignment:MainAxisAlignment.center,children:[Icon(icon,size:34),const SizedBox(height:10),Text(title,style:const TextStyle(fontSize:17,fontWeight:FontWeight.w600)),Text(subtitle,style:const TextStyle(color:Colors.white54))])); }
class Stat extends StatelessWidget { final String value,label; const Stat(this.value,this.label,{super.key}); @override Widget build(BuildContext context)=>Column(children:[Text(value,style:const TextStyle(fontSize:22,fontWeight:FontWeight.w700)),Text(label,style:const TextStyle(color:Colors.white54))]); }
class ActionTile extends StatelessWidget { final IconData icon; final String title,subtitle; final VoidCallback onTap; const ActionTile(this.icon,this.title,this.subtitle,this.onTap,{super.key}); @override Widget build(BuildContext context)=>ListTile(onTap:onTap,contentPadding:const EdgeInsets.symmetric(vertical:6),leading:Icon(icon),title:Text(title),subtitle:Text(subtitle),trailing:const Icon(Icons.chevron_right,color:Colors.white54)); }
class SettingGroup extends StatelessWidget { final String title; final List<Widget> children; const SettingGroup({super.key,required this.title,required this.children}); @override Widget build(BuildContext context)=>Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Padding(padding:const EdgeInsets.fromLTRB(4,18,4,8),child:Text(title,style:const TextStyle(color:Colors.white60))),Container(decoration:BoxDecoration(color:const Color(0xFF11131A),borderRadius:BorderRadius.circular(18)),child:Column(children:children))]); }
class SettingTile extends StatelessWidget { final IconData icon; final String title,subtitle; const SettingTile(this.icon,this.title,this.subtitle,{super.key}); @override Widget build(BuildContext context)=>ListTile(leading:Icon(icon),title:Text(title),subtitle:Text(subtitle),trailing:const Icon(Icons.chevron_right,color:Colors.white54)); }
class PlayerAction extends StatelessWidget { final IconData icon; final String label; const PlayerAction(this.icon,this.label,{super.key}); @override Widget build(BuildContext context)=>Column(children:[Icon(icon),const SizedBox(height:6),Text(label,style:const TextStyle(color:Colors.white60))]); }
