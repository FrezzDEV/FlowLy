import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../../controllers/main_controller.dart';
import '../../models/song_model.dart';
import '../current_playing/current_playing_song.dart';

class ProfilePage extends StatefulWidget {
  final MainController con;
  const ProfilePage({super.key, required this.con});

  @override
  ProfilePageState createState() => ProfilePageState();
}

class ProfilePageState extends State<ProfilePage> {
  bool _showSettings = false;
  bool _showEditProfile = false;
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
    if (_showSettings || _showEditProfile) {
      setState(() {
        _showSettings = false;
        _showEditProfile = false;
      });
    }
  }

  Future<void> _loadAvatar() async {
    final path = Hive.box('profile').get('avatarPath') as String?;
    if (path != null && await File(path).exists() && mounted) {
      setState(() => _avatarPath = path);
    }
  }

  Future<void> _pickAvatar() async {
    final image = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 90);
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
    if (index >= songs.length) return;
    await widget.con.playSong(songs, index);
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.black,
      builder: (_) => CurrentPlayingSong(con: widget.con),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: _showEditProfile
            ? _EditProfileView(
                avatarPath: _avatarPath,
                onBack: () => setState(() => _showEditProfile = false),
                onPickAvatar: _pickAvatar,
              )
            : _showSettings
                ? _SettingsView(
                    onBack: () => setState(() => _showSettings = false),
                    onAccount: () => setState(() => _showEditProfile = true),
                  )
                : ValueListenableBuilder(
                    valueListenable: Hive.box('liked').listenable(),
                    builder: (context, Box<dynamic> _, child) => ListView(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 82),
                      children: [
                        _ProfileHeader(onSettings: () => setState(() => _showSettings = true)),
                        const SizedBox(height: 10),
                        _Identity(avatarPath: _avatarPath),
                        const SizedBox(height: 14),
                        const _Stats(),
                        const SizedBox(height: 14),
                        const _ImportCard(),
                        const SizedBox(height: 20),
                        const _Title('Топ за месяц'),
                        const SizedBox(height: 8),
                        const _TopCards(_top),
                        const SizedBox(height: 18),
                        const _Title('Любимые треки'),
                        const SizedBox(height: 4),
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
            child: Text(
              'Профиль',
              style: TextStyle(color: Colors.white, fontSize: 29, height: 1, fontWeight: FontWeight.w700, letterSpacing: -.6),
            ),
          ),
          IconButton(
            onPressed: onSettings,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints.tightFor(width: 34, height: 34),
            icon: const Icon(Icons.settings_outlined, color: Color(0xFF8E8E8E), size: 25),
          ),
        ],
      );
}

class _Identity extends StatelessWidget {
  final String? avatarPath;
  const _Identity({required this.avatarPath});

  @override
  Widget build(BuildContext context) {
    final name = Hive.box('profile').get('name', defaultValue: 'Алекс') as String;
    return Column(
      children: [
        CircleAvatar(
          radius: 60,
          backgroundColor: const Color(0xFF242424),
          backgroundImage: avatarPath == null
              ? const NetworkImage('https://i.pravatar.cc/400?img=12')
              : FileImage(File(avatarPath!)) as ImageProvider,
        ),
        const SizedBox(height: 7),
        Text(
          name,
          style: const TextStyle(color: Colors.white, fontSize: 23, height: 1, fontWeight: FontWeight.w700),
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
            padding: EdgeInsets.symmetric(vertical: 12),
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
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 22, height: 1, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: Color(0xFF858585), fontSize: 13, height: 1, fontWeight: FontWeight.w500)),
        ],
      );
}

class _ImportCard extends StatelessWidget {
  const _ImportCard();

  @override
  Widget build(BuildContext context) => Container(
        height: 72,
        decoration: BoxDecoration(
          color: const Color(0xFF111111),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF2A2A2A)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(13)),
              child: const Icon(Icons.download_outlined, color: Colors.black, size: 23),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Импорт музыки', style: TextStyle(color: Colors.white, fontSize: 17, height: 1.05, fontWeight: FontWeight.w700)),
                  SizedBox(height: 3),
                  Text('Перенести из другого сервиса', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Color(0xFF858585), fontSize: 12, height: 1.05, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFF858585), size: 23),
          ],
        ),
      );
}

class _Title extends StatelessWidget {
  final String text;
  const _Title(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(color: Colors.white, fontSize: 22, height: 1.05, fontWeight: FontWeight.w700),
      );
}

class _TopCards extends StatelessWidget {
  final List<_CardData> items;
  const _TopCards(this.items);

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 155,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(width: 12),
          itemBuilder: (context, index) => SizedBox(
            width: 160,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(13),
                  child: CachedNetworkImage(
                    imageUrl: items[index].image,
                    width: 160,
                    height: 126,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(color: const Color(0xFF202020)),
                    errorWidget: (_, __, ___) => Container(color: const Color(0xFF202020), child: const Icon(Icons.music_note, color: Colors.white54)),
                  ),
                ),
                const SizedBox(height: 6),
                Text(items[index].title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.05, fontWeight: FontWeight.w600)),
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
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    SizedBox(width: 24, child: Text('${i + 1}', style: const TextStyle(color: Color(0xFF777777), fontSize: 16, height: 1))),
                    ClipRRect(borderRadius: BorderRadius.circular(11), child: _TrackImage(tracks[i].image)),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(tracks[i].title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 16, height: 1.05, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 2),
                          Text(tracks[i].artist, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFF858585), fontSize: 13, height: 1.05, fontWeight: FontWeight.w500)),
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
    if (url == null || url!.isEmpty) {
      return Container(width: 56, height: 56, color: const Color(0xFF202020), child: const Icon(Icons.music_note, color: Colors.white54, size: 20));
    }
    return CachedNetworkImage(
      imageUrl: url!,
      width: 56,
      height: 56,
      fit: BoxFit.cover,
      placeholder: (_, __) => Container(width: 56, height: 56, color: const Color(0xFF202020)),
      errorWidget: (_, __, ___) => Container(width: 56, height: 56, color: const Color(0xFF202020), child: const Icon(Icons.music_note, color: Colors.white54, size: 20)),
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
  final VoidCallback onAccount;
  const _SettingsView({required this.onBack, required this.onAccount});

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
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 88),
        children: [
          Row(
            children: [
              IconButton(onPressed: onBack, padding: EdgeInsets.zero, constraints: const BoxConstraints.tightFor(width: 34, height: 34), icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 19)),
              const SizedBox(width: 8),
              const Text('Настройки', style: TextStyle(color: Colors.white, fontSize: 22, height: 1, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 16),
          for (var groupIndex = 0; groupIndex < _groups.length; groupIndex++) ...[
            _SettingsLabel(_groups[groupIndex].title),
            const SizedBox(height: 6),
            _SettingsCard(
              rows: _groups[groupIndex].rows,
              onRowTap: (index) {
                if (groupIndex == 0 && index == 0) onAccount();
              },
            ),
            if (groupIndex != _groups.length - 1) const SizedBox(height: 14),
          ],
          const SizedBox(height: 14),
          const _SettingsLabel('АККАУНТ'),
          const SizedBox(height: 6),
          const _SettingsCard(
            rows: [(icon: Icons.logout_outlined, title: 'Выйти из аккаунта', subtitle: '')],
            logout: true,
          ),
        ],
      );
}

class _EditProfileView extends StatefulWidget {
  final String? avatarPath;
  final VoidCallback onBack;
  final Future<void> Function() onPickAvatar;

  const _EditProfileView({required this.avatarPath, required this.onBack, required this.onPickAvatar});

  @override
  State<_EditProfileView> createState() => _EditProfileViewState();
}

class _EditProfileViewState extends State<_EditProfileView> {
  late final TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: Hive.box('profile').get('name', defaultValue: 'Алекс') as String);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isNotEmpty) await Hive.box('profile').put('name', name);
    if (mounted) widget.onBack();
  }

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 88),
        children: [
          Row(
            children: [
              IconButton(onPressed: widget.onBack, padding: EdgeInsets.zero, constraints: const BoxConstraints.tightFor(width: 34, height: 34), icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 19)),
              const SizedBox(width: 8),
              const Text('Редактирование профиля', style: TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 26),
          Center(
            child: CircleAvatar(
              radius: 54,
              backgroundColor: const Color(0xFF242424),
              backgroundImage: widget.avatarPath == null
                  ? const NetworkImage('https://i.pravatar.cc/400?img=12')
                  : FileImage(File(widget.avatarPath!)) as ImageProvider,
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: TextButton.icon(
              onPressed: widget.onPickAvatar,
              icon: const Icon(Icons.photo_outlined, size: 18),
              label: const Text('Изменить фото'),
              style: TextButton.styleFrom(foregroundColor: Colors.white),
            ),
          ),
          const SizedBox(height: 24),
          const Text('Имя', style: TextStyle(color: Color(0xFF858585), fontSize: 12, fontWeight: FontWeight.w500)),
          const SizedBox(height: 7),
          TextField(
            controller: _nameController,
            style: const TextStyle(color: Colors.white, fontSize: 16),
            cursorColor: Colors.white,
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFF111111),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF2A2A2A))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF2A2A2A))),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF555555))),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 48,
            child: FilledButton(
              onPressed: _save,
              style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: const Text('Сохранить', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      );
}

class _SettingsLabel extends StatelessWidget {
  final String text;
  const _SettingsLabel(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(left: 4),
        child: Text(text, style: const TextStyle(color: Color(0xFF8A8A8A), fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: .3)),
      );
}

class _SettingsCard extends StatelessWidget {
  final List<({IconData icon, String title, String subtitle})> rows;
  final bool logout;
  final void Function(int index)? onRowTap;
  const _SettingsCard({required this.rows, this.logout = false, this.onRowTap});

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(color: const Color(0xFF101010), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFF292929))),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            for (var i = 0; i < rows.length; i++)
              InkWell(
                onTap: logout ? null : () => onRowTap?.call(i),
                child: Container(
                  constraints: const BoxConstraints(minHeight: 60),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFF202020)))),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(color: logout ? const Color(0xFF2A1111) : Colors.white, shape: BoxShape.circle),
                        child: Icon(rows[i].icon, color: logout ? const Color(0xFFB52B2B) : Colors.black, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(rows[i].title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: logout ? const Color(0xFFB52B2B) : Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
                            if (rows[i].subtitle.isNotEmpty) Text(rows[i].subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFF858585), fontSize: 10, fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ),
                      if (!logout) const Icon(Icons.chevron_right, color: Color(0xFF858585), size: 20),
                    ],
                  ),
                ),
              ),
          ],
        ),
      );
}
