import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../../controllers/main_controller.dart';
import '../../models/song_model.dart';

class ProfilePage extends StatefulWidget {
  final MainController con;

  const ProfilePage({super.key, required this.con});

  @override
  ProfilePageState createState() => ProfilePageState();
}

class ProfilePageState extends State<ProfilePage> {
  bool _showSettings = false;
  String? _avatarPath;

  static const _top = [
    _CardData('Chill Vibes', 'https://images.unsplash.com/photo-1571266028243-d220c9c3b1f3?w=600'),
    _CardData('Night Drive', 'https://images.unsplash.com/photo-1500534623283-312aade485b7?w=600'),
    _CardData('Focus', 'https://images.unsplash.com/photo-1511379938547-c1f69419868d?w=600'),
  ];

  static const _fallbackTracks = [
    _TrackData('Blinding Lights', 'The Weeknd', 'https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?w=300'),
    _TrackData('Save Your Tears', 'The Weeknd', 'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?w=300'),
    _TrackData('Another Love', 'Tom Odell', 'https://images.unsplash.com/photo-1524368535928-5b5e00ddc76b?w=300'),
    _TrackData('Believer', 'Imagine Dragons', 'https://images.unsplash.com/photo-1506157786151-b8491531f063?w=300'),
    _TrackData('Hurt', 'Johnny Cash', 'https://images.unsplash.com/photo-1516280440614-37939bbacd81?w=300'),
  ];

  @override
  void initState() {
    super.initState();
    _loadAvatar();
  }

  void showProfile() {
    if (_showSettings) setState(() => _showSettings = false);
  }

  Future<void> _loadAvatar() async {
    final path = Hive.box('profile').get('avatarPath') as String?;
    if (path != null && await File(path).exists() && mounted) {
      setState(() => _avatarPath = path);
    }
  }

  Future<void> _pickAvatar() async {
    final image = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
    );
    if (image == null) return;

    final dir = await getApplicationDocumentsDirectory();
    final target = File('${dir.path}/flowly_profile_avatar.jpg');
    await File(image.path).copy(target.path);
    await Hive.box('profile').put('avatarPath', target.path);
    if (mounted) setState(() => _avatarPath = target.path);
  }

  List<_TrackData> _tracks() {
    final box = Hive.box('liked');
    final result = <_TrackData>[];
    for (var i = 0; i < box.length && result.length < 5; i++) {
      final value = box.getAt(i);
      if (value is! Map) continue;
      final title = value['songname']?.toString();
      if (title == null || title.isEmpty) continue;
      result.add(_TrackData(
        title,
        value['fullname']?.toString() ?? value['username']?.toString() ?? 'Unknown artist',
        value['cover']?.toString(),
      ));
    }
    return result.isEmpty ? _fallbackTracks : result;
  }

  Future<void> _playTrack(int index) async {
    final box = Hive.box('liked');
    final songs = <SongModel>[];
    for (var i = 0; i < box.length; i++) {
      final value = box.getAt(i);
      if (value is! Map) continue;
      final title = value['songname']?.toString();
      if (title == null || title.isEmpty) continue;
      songs.add(SongModel(
        songid: value['id']?.toString(),
        songname: title,
        userid: value['username']?.toString(),
        trackid: value['track']?.toString(),
        coverImageUrl: value['cover']?.toString(),
        name: value['fullname']?.toString(),
      ));
    }
    if (index < songs.length) await widget.con.playSong(songs, index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: _showSettings
            ? _SettingsView(onBack: () => setState(() => _showSettings = false))
            : ValueListenableBuilder(
                valueListenable: Hive.box('liked').listenable(),
                builder: (context, Box<dynamic> _, child) => ListView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
                  children: [
                    _ProfileHeader(onSettings: () => setState(() => _showSettings = true)),
                    const SizedBox(height: 22),
                    _Identity(avatarPath: _avatarPath, onPickAvatar: _pickAvatar),
                    const SizedBox(height: 30),
                    const _Stats(),
                    const SizedBox(height: 28),
                    const _ImportCard(),
                    const SizedBox(height: 34),
                    const _Title('Топ за месяц'),
                    const SizedBox(height: 14),
                    const _TopCards(_top),
                    const SizedBox(height: 34),
                    const _Title('Любимые треки'),
                    const SizedBox(height: 10),
                    _FavoriteTracks(tracks: _tracks(), onTap: _playTrack),
                  ],
                ),
              ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final VoidCallback onSettings;
  const _ProfileHeader({required this.onSettings});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          const Expanded(
            child: Text('Профиль', style: TextStyle(color: Colors.white, fontSize: 42, height: 1, fontWeight: FontWeight.w800, letterSpacing: -1.4)),
          ),
          IconButton(
            onPressed: onSettings,
            tooltip: 'Настройки',
            icon: const Icon(Icons.settings_outlined, color: Color(0xFF8E8E8E), size: 30),
          ),
        ],
      );
}

class _Identity extends StatelessWidget {
  final String? avatarPath;
  final VoidCallback onPickAvatar;
  const _Identity({required this.avatarPath, required this.onPickAvatar});

  @override
  Widget build(BuildContext context) {
    final name = Hive.box('profile').get('name', defaultValue: 'Алекс') as String;
    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            CircleAvatar(
              radius: 84,
              backgroundColor: const Color(0xFF242424),
              backgroundImage: avatarPath == null ? const NetworkImage('https://i.pravatar.cc/400?img=12') : FileImage(File(avatarPath!)) as ImageProvider,
            ),
            Positioned(
              right: -4,
              bottom: -4,
              child: Material(
                color: Colors.white,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: onPickAvatar,
                  child: const SizedBox(width: 40, height: 40, child: Icon(Icons.edit_outlined, color: Colors.black, size: 20)),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(name, style: const TextStyle(color: Colors.white, fontSize: 30, height: 1, fontWeight: FontWeight.w800)),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
              child: const Text('Premium', style: TextStyle(color: Colors.black, fontSize: 15, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ],
    );
  }
}

class _Stats extends StatelessWidget {
  const _Stats();
  @override
  Widget build(BuildContext context) => const Column(
        children: [
          Divider(color: Color(0xFF242424), height: 1),
          Padding(
            padding: EdgeInsets.symmetric(vertical: 25),
            child: Row(
              children: [
                Expanded(child: _Stat('24', 'Плейлисты')),
                Expanded(child: _Stat('128', 'Подписчики')),
                Expanded(child: _Stat('56', 'Подписки')),
              ],
            ),
          ),
          Divider(color: Color(0xFF242424), height: 1),
        ],
      );
}

class _Stat extends StatelessWidget {
  final String value;
  final String label;
  const _Stat(this.value, this.label);
  @override
  Widget build(BuildContext context) => Column(
        children: [
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w800)),
          const SizedBox(height: 3),
          Text(label, style: const TextStyle(color: Color(0xFF8B8B8B), fontSize: 17, fontWeight: FontWeight.w500)),
        ],
      );
}

class _ImportCard extends StatelessWidget {
  const _ImportCard();
  @override
  Widget build(BuildContext context) => Container(
        height: 96,
        decoration: BoxDecoration(color: const Color(0xFF111111), borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFF2A2A2A))),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
              child: const Icon(Icons.download_outlined, color: Colors.black, size: 29),
            ),
            const SizedBox(width: 20),
            const Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Импорт музыки', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                  SizedBox(height: 3),
                  Text('Перенести из другого сервиса', style: TextStyle(color: Color(0xFF858585), fontSize: 15, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFF858585), size: 30),
          ],
        ),
      );
}

class _Title extends StatelessWidget {
  final String text;
  const _Title(this.text);
  @override
  Widget build(BuildContext context) => Text(text, style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800));
}

class _TopCards extends StatelessWidget {
  final List<_CardData> items;
  const _TopCards(this.items);
  @override
  Widget build(BuildContext context) => SizedBox(
        height: 218,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(width: 20),
          itemBuilder: (context, index) => SizedBox(
            width: 226,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: CachedNetworkImage(
                    imageUrl: items[index].image,
                    width: 226,
                    height: 174,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(color: const Color(0xFF202020)),
                    errorWidget: (_, __, ___) => Container(color: const Color(0xFF202020), child: const Icon(Icons.music_note, color: Colors.white54)),
                  ),
                ),
                const SizedBox(height: 10),
                Text(items[index].title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ),
      );
}

class _FavoriteTracks extends StatelessWidget {
  final List<_TrackData> tracks;
  final Future<void> Function(int) onTap;
  const _FavoriteTracks({required this.tracks, required this.onTap});
  @override
  Widget build(BuildContext context) => Column(
        children: [
          for (var i = 0; i < tracks.length; i++)
            InkWell(
              onTap: () => onTap(i),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    SizedBox(width: 42, child: Text('${i + 1}', style: const TextStyle(color: Color(0xFF777777), fontSize: 20))),
                    ClipRRect(borderRadius: BorderRadius.circular(16), child: _TrackImage(tracks[i].image)),
                    const SizedBox(width: 18),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(tracks[i].title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 2),
                          Text(tracks[i].artist, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFF858585), fontSize: 16, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      );
}

class _TrackImage extends StatelessWidget {
  final String? url;
  const _TrackImage(this.url);
  @override
  Widget build(BuildContext context) {
    if (url == null || url!.isEmpty) return Container(width: 78, height: 78, color: const Color(0xFF202020), child: const Icon(Icons.music_note, color: Colors.white54));
    return CachedNetworkImage(
      imageUrl: url!,
      width: 78,
      height: 78,
      fit: BoxFit.cover,
      placeholder: (_, __) => Container(width: 78, height: 78, color: const Color(0xFF202020)),
      errorWidget: (_, __, ___) => Container(width: 78, height: 78, color: const Color(0xFF202020), child: const Icon(Icons.music_note, color: Colors.white54)),
    );
  }
}

class _CardData {
  final String title;
  final String image;
  const _CardData(this.title, this.image);
}

class _TrackData {
  final String title;
  final String artist;
  final String? image;
  const _TrackData(this.title, this.artist, this.image);
}

class _SettingsView extends StatelessWidget {
  final VoidCallback onBack;
  const _SettingsView({required this.onBack});

  static const _groups = <({String title, List<({IconData icon, String title, String subtitle})> rows})>[
    (
      title: 'АККАУНТ',
      rows: [
        (icon: Icons.person_outline, title: 'Аккаунт', subtitle: 'Профиль, подписка, данные'),
        (icon: Icons.shield_outlined, title: 'Безопасность', subtitle: 'Пароль, 2FA'),
        (icon: Icons.credit_card_outlined, title: 'Платежи', subtitle: 'Способы оплаты, история'),
      ],
    ),
    (
      title: 'ПРИЛОЖЕНИЕ',
      rows: [
        (icon: Icons.play_arrow_outlined, title: 'Воспроизведение', subtitle: 'Качество звука, кроссфейд, EQ'),
        (icon: Icons.download_outlined, title: 'Скачивание', subtitle: 'Загрузка и хранилище'),
        (icon: Icons.notifications_none, title: 'Уведомления', subtitle: 'Только важные'),
        (icon: Icons.palette_outlined, title: 'Внешний вид', subtitle: 'Тема, цвета, стиль'),
        (icon: Icons.text_fields_outlined, title: 'Текст', subtitle: 'Отображение текстов песен'),
      ],
    ),
    (
      title: 'ДРУГОЕ',
      rows: [
        (icon: Icons.language_outlined, title: 'Язык', subtitle: 'Русский'),
        (icon: Icons.info_outline, title: 'О приложении', subtitle: 'Версия, лицензия'),
        (icon: Icons.support_outlined, title: 'Поддержка', subtitle: 'Помощь и обратная связь'),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
        children: [
          Row(
            children: [
              IconButton(onPressed: onBack, padding: EdgeInsets.zero, constraints: const BoxConstraints(minWidth: 40, minHeight: 40), icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 22)),
              const SizedBox(width: 16),
              const Text('Настройки', style: TextStyle(color: Colors.white, fontSize: 26, height: 1, fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 26),
          for (var groupIndex = 0; groupIndex < _groups.length; groupIndex++) ...[
            _SettingsLabel(_groups[groupIndex].title),
            const SizedBox(height: 8),
            _SettingsCard(rows: _groups[groupIndex].rows),
            if (groupIndex != _groups.length - 1) const SizedBox(height: 24),
          ],
          const SizedBox(height: 24),
          const _SettingsLabel('АККАУНТ'),
          const SizedBox(height: 8),
          const _SettingsCard(
            rows: [
              (icon: Icons.logout_outlined, title: 'Выйти из аккаунта', subtitle: ''),
            ],
            logout: true,
          ),
        ],
      );
}

class _SettingsLabel extends StatelessWidget {
  final String text;
  const _SettingsLabel(this.text);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(left: 6),
        child: Text(text, style: const TextStyle(color: Color(0xFF8A8A8A), fontSize: 13, fontWeight: FontWeight.w500, letterSpacing: .3)),
      );
}

class _SettingsCard extends StatelessWidget {
  final List<({IconData icon, String title, String subtitle})> rows;
  final bool logout;
  const _SettingsCard({required this.rows, this.logout = false});
  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(color: const Color(0xFF101010), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFF292929))),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            for (final row in rows)
              Container(
                constraints: const BoxConstraints(minHeight: 70),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFF202020)))),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(color: logout ? const Color(0xFF2A1111) : Colors.white, shape: BoxShape.circle),
                      child: Icon(row.icon, color: logout ? const Color(0xFFB52B2B) : Colors.black, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(row.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: logout ? const Color(0xFFB52B2B) : Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                          if (row.subtitle.isNotEmpty) Text(row.subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFF858585), fontSize: 12, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                    if (!logout) const Icon(Icons.chevron_right, color: Color(0xFF858585), size: 22),
                  ],
                ),
              ),
          ],
        ),
      );
}
