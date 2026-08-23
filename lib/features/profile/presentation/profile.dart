import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import 'package:flowly/app/localization/app_locale.dart';
import 'package:flowly/domain/entities/song_model.dart';
import 'package:flowly/features/player/domain/main_controller.dart';
import 'edit_profile_page.dart';
import '../../settings/presentation/settings_page.dart';

class ProfilePage extends StatefulWidget {
  final MainController con;

  const ProfilePage({super.key, required this.con});

  @override
  ProfilePageState createState() => ProfilePageState();
}

class ProfilePageState extends State<ProfilePage> {
  String? _avatarPath;
  String _displayName = 'Алекс';

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  void showProfile() {
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _loadProfile() async {
    final box = Hive.box('profile');
    final path = box.get('avatarPath') as String?;
    final name = box.get('displayName') as String?;
    if (!mounted) return;
    setState(() {
      _displayName = name?.trim().isNotEmpty == true ? name!.trim() : 'Алекс';
      _avatarPath = path;
    });
  }

  Future<void> _saveName(String name) async {
    final value = name.trim();
    if (value.isEmpty) return;
    await Hive.box('profile').put('displayName', value);
    if (!mounted) return;
    setState(() => _displayName = value);
  }

  Future<String?> _pickAvatar() async {
    final image = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 88,
      maxWidth: 1200,
    );
    if (image == null) return null;

    final directory = await getApplicationDocumentsDirectory();
    final target = File('${directory.path}/flowly_profile_avatar.jpg');
    await File(image.path).copy(target.path);
    await Hive.box('profile').put('avatarPath', target.path);

    if (mounted) setState(() => _avatarPath = target.path);
    return target.path;
  }

  void _openSettings() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SettingsPage(
          languageName: AppLocale.isEnglish ? 'English' : 'Русский',
          onAccount: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => EditProfilePage(
                displayName: _displayName,
                avatarPath: _avatarPath,
                onSaveName: (name) async {
                  await _saveName(name);
                  if (mounted) Navigator.of(context).pop();
                },
                onPickAvatar: _pickAvatar,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: ValueListenableBuilder<Box<dynamic>>(
          valueListenable: Hive.box('liked').listenable(),
          builder: (context, _, __) {
            final songs = _likedSongs();
            final avatar = _avatarPath;

            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 180),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        AppLocale.text('Профиль', 'Profile'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.6,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: _openSettings,
                      tooltip: AppLocale.text('Настройки', 'Settings'),
                      icon: const Icon(
                        Icons.settings_outlined,
                        color: Color(0xFF8A8A8A),
                        size: 25,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Center(
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: const Color(0xFF202020),
                    backgroundImage: avatar == null
                        ? const NetworkImage('https://i.pravatar.cc/240?img=12')
                        : FileImage(File(avatar)) as ImageProvider<Object>,
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: Text(
                    _displayName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                const Divider(color: Color(0xFF292929), height: 1),
                const SizedBox(height: 20),
                _StatsRow(
                  playlists: Hive.box('playlists').length,
                  followers: 128,
                  following: 56,
                ),
                const SizedBox(height: 22),
                const Divider(color: Color(0xFF292929), height: 1),
                const SizedBox(height: 18),
                _SettingsTile(
                  onTap: () => _showMessage(
                    context,
                    AppLocale.text(
                      'Импорт музыки скоро будет доступен',
                      'Music import will be available soon',
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  AppLocale.text('Топ за месяц', 'Top this month'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 14),
                const SizedBox(height: 184, child: _TopCards()),
                const SizedBox(height: 28),
                Text(
                  AppLocale.text('Любимые треки', 'Liked songs'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                if (songs.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Text(
                      AppLocale.text('Пока нет любимых треков', 'No liked songs yet'),
                      style: const TextStyle(color: Color(0xFF858585)),
                    ),
                  )
                else
                  ...songs.take(5).toList().asMap().entries.map(
                    (entry) => _FavoriteSongRow(
                      index: entry.key + 1,
                      song: entry.value,
                      onTap: () => widget.con.playSong(songs, entry.key),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  List<SongModel> _likedSongs() {
    final box = Hive.box('liked');
    final result = <SongModel>[];
    for (var i = 0; i < box.length; i++) {
      final value = box.getAt(i);
      if (value is Map) {
        result.add(
          SongModel(
            songid: value['id']?.toString(),
            songname: value['songname']?.toString(),
            userid: value['username']?.toString(),
            trackid: value['track']?.toString(),
            duration: '',
            coverImageUrl: value['cover']?.toString(),
            name: value['fullname']?.toString(),
          ),
        );
      }
    }
    return result;
  }

  void _showMessage(BuildContext context, String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text), behavior: SnackBarBehavior.floating),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final int playlists;
  final int followers;
  final int following;

  const _StatsRow({required this.playlists, required this.followers, required this.following});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          _Stat(playlists.toString(), AppLocale.text('Плейлисты', 'Playlists')),
          _Stat(followers.toString(), AppLocale.text('Подписчики', 'Followers')),
          _Stat(following.toString(), AppLocale.text('Подписки', 'Following')),
        ],
      );
}

class _Stat extends StatelessWidget {
  final String value;
  final String label;

  const _Stat(this.value, this.label);

  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(
          children: [
            Text(value, style: const TextStyle(color: Colors.white, fontSize: 23, fontWeight: FontWeight.w800)),
            const SizedBox(height: 3),
            Text(label, style: const TextStyle(color: Color(0xFF858585), fontSize: 12, fontWeight: FontWeight.w500)),
          ],
        ),
      );
}

class _SettingsTile extends StatelessWidget {
  final VoidCallback onTap;
  const _SettingsTile({required this.onTap});

  @override
  Widget build(BuildContext context) => Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: const Color(0xFF101010),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF292929)),
        ),
        child: ListTile(
          onTap: onTap,
          leading: const CircleAvatar(
            backgroundColor: Colors.white,
            child: Icon(Icons.library_music_outlined, color: Colors.black),
          ),
          title: Text(AppLocale.text('Импорт музыки', 'Import music'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          subtitle: Text(AppLocale.text('Перенести музыку из другого сервиса', 'Move music from another service'), style: const TextStyle(color: Color(0xFF858585), fontSize: 12)),
          trailing: const Icon(Icons.chevron_right, color: Color(0xFF858585)),
        ),
      );
}

class _TopCards extends StatelessWidget {
  const _TopCards();
  static const items = [
    ('Chill Vibes', 'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?w=600'),
    ('Night Drive', 'https://images.unsplash.com/photo-1500534623283-312aade485b7?w=600'),
    ('Focus', 'https://images.unsplash.com/photo-1511379938547-c1f69419868d?w=600'),
  ];

  @override
  Widget build(BuildContext context) => ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (context, index) => SizedBox(
          width: 190,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.network(
                  items[index].$2,
                  width: 190,
                  height: 138,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 190,
                    height: 138,
                    color: const Color(0xFF1C1C1C),
                    child: const Icon(Icons.music_note, color: Color(0xFF777777)),
                  ),
                ),
              ),
              const SizedBox(height: 7),
              Text(items[index].$1, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800)),
            ],
          ),
        ),
      );
}

class _FavoriteSongRow extends StatelessWidget {
  final int index;
  final SongModel song;
  final VoidCallback onTap;

  const _FavoriteSongRow({required this.index, required this.song, required this.onTap});

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 7),
          child: Row(
            children: [
              SizedBox(width: 28, child: Text('$index', style: const TextStyle(color: Color(0xFF858585), fontSize: 15))),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 64,
                  height: 64,
                  child: song.coverImageUrl?.isNotEmpty == true
                      ? Image.network(song.coverImageUrl!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const _SongPlaceholder())
                      : const _SongPlaceholder(),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(song.songname ?? AppLocale.text('Без названия', 'Untitled'), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 3),
                    Text(song.name ?? song.userid ?? 'FlowLy', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFF858585), fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}

class _SongPlaceholder extends StatelessWidget {
  const _SongPlaceholder();

  @override
  Widget build(BuildContext context) => Container(
        color: const Color(0xFF1B1B1B),
        child: const Icon(Icons.music_note, color: Color(0xFF777777), size: 24),
      );
}
