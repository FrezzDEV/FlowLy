import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import '../../controllers/main_controller.dart';
import '../../models/song_model.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  ProfilePageState createState() => ProfilePageState();
}

class ProfilePageState extends State<ProfilePage> {
  bool _showSettings = false;
  String? _avatarPath;
  String _displayName = 'Алекс';

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  void showProfile() {
    if (_showSettings) {
      setState(() => _showSettings = false);
    }
  }

  Future<void> _loadProfile() async {
    final box = Hive.box('profile');
    final path = box.get('avatarPath') as String?;
    final name = box.get('displayName') as String?;

    if (!mounted) return;
    setState(() {
      _displayName = name?.trim().isNotEmpty == true ? name!.trim() : 'Алекс';
    });

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

    final directory = await getApplicationDocumentsDirectory();
    final target = File('${directory.path}/flowly_profile_avatar.jpg');
    await File(image.path).copy(target.path);
    await Hive.box('profile').put('avatarPath', target.path);

    if (mounted) {
      setState(() => _avatarPath = target.path);
    }
  }

  void _openSettings() {
    setState(() => _showSettings = true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: _showSettings
            ? _SettingsView(onBack: showProfile)
            : _ProfileContent(
                displayName: _displayName,
                avatarPath: _avatarPath,
                onSettings: _openSettings,
                onPickAvatar: _pickAvatar,
              ),
      ),
    );
  }
}

class _ProfileContent extends StatelessWidget {
  final String displayName;
  final String? avatarPath;
  final VoidCallback onSettings;
  final VoidCallback onPickAvatar;

  const _ProfileContent({
    required this.displayName,
    required this.avatarPath,
    required this.onSettings,
    required this.onPickAvatar,
  });

  static const _fallbackCovers = [
    'https://images.unsplash.com/photo-1516280440614-37939bbacd81?auto=format&fit=crop&w=600&q=80',
    'https://images.unsplash.com/photo-1500534623283-312aade485b7?auto=format&fit=crop&w=600&q=80',
    'https://images.unsplash.com/photo-1516280440614-37939bbacd81?auto=format&fit=crop&w=600&q=80',
  ];

  @override
  Widget build(BuildContext context) {
    return Consumer<MainController>(
      builder: (context, controller, _) {
        final favorites = _loadFavorites(controller);
        final currentSong = controller.currentSong;
        final playlistCount = Hive.box('playlists').length;

        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 112),
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Профиль',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      height: 1,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1.1,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: onSettings,
                  tooltip: 'Настройки',
                  icon: const Icon(
                    Icons.settings_outlined,
                    color: Color(0xFF858585),
                    size: 27,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
            Center(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  CircleAvatar(
                    radius: 58,
                    backgroundColor: const Color(0xFF202020),
                    backgroundImage: avatarPath == null
                        ? const NetworkImage('https://i.pravatar.cc/240?img=12')
                        : FileImage(File(avatarPath!)),
                  ),
                  Positioned(
                    right: -2,
                    bottom: -2,
                    child: Material(
                      color: Colors.white,
                      shape: const CircleBorder(),
                      child: InkWell(
                        onTap: onPickAvatar,
                        customBorder: const CircleBorder(),
                        child: const SizedBox(
                          width: 36,
                          height: 36,
                          child: Icon(Icons.edit_outlined, color: Colors.black, size: 19),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  displayName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(width: 9),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Premium',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 34),
            const Divider(color: Color(0xFF292929), height: 1),
            const SizedBox(height: 26),
            _StatsRow(
              playlists: playlistCount,
              followers: 128,
              following: 56,
            ),
            const SizedBox(height: 26),
            const Divider(color: Color(0xFF292929), height: 1),
            const SizedBox(height: 26),
            _ImportCard(onTap: () => _showImportMessage(context)),
            const SizedBox(height: 46),
            const Text(
              'Топ за месяц',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 205,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: 3,
                separatorBuilder: (_, index) => const SizedBox(width: 18),
                itemBuilder: (context, index) {
                  final song = index < controller.songs.length ? controller.songs[index] : null;
                  return _TopCard(
                    title: song?.songname ?? ['Chill Vibes', 'Night Drive', 'Focus'][index],
                    imageUrl: song?.coverImageUrl?.isNotEmpty == true
                        ? song!.coverImageUrl!
                        : _fallbackCovers[index],
                  );
                },
              ),
            ),
            const SizedBox(height: 36),
            const Text(
              'Любимые треки',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 14),
            if (favorites.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  'Пока нет любимых треков',
                  style: TextStyle(color: Color(0xFF858585), fontSize: 16),
                ),
              )
            else
              ...favorites.take(5).toList().asMap().entries.map(
                    (entry) => _FavoriteSongRow(
                      index: entry.key + 1,
                      song: entry.value,
                      onTap: () => controller.playSong(favorites, entry.key),
                    ),
                  ),
            if (currentSong != null) const SizedBox(height: 24),
            if (currentSong != null) _CurrentSongBar(song: currentSong, controller: controller),
          ],
        );
      },
    );
  }

  List<SongModel> _loadFavorites(MainController controller) {
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

    return result.isEmpty ? controller.songs.take(5).toList() : result;
  }

  void _showImportMessage(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Импорт музыки скоро будет доступен')),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final int playlists;
  final int followers;
  final int following;

  const _StatsRow({
    required this.playlists,
    required this.followers,
    required this.following,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _Stat(value: playlists.toString(), label: 'Плейлисты'),
        _Stat(value: followers.toString(), label: 'Подписчики'),
        _Stat(value: following.toString(), label: 'Подписки'),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  final String value;
  final String label;

  const _Stat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF858585),
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _ImportCard extends StatelessWidget {
  final VoidCallback onTap;

  const _ImportCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF101010),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          height: 128,
          padding: const EdgeInsets.symmetric(horizontal: 28),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF292929)),
          ),
          child: Row(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                child: const Icon(Icons.download_outlined, color: Colors.black, size: 31),
              ),
              const SizedBox(width: 20),
              const Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Импорт музыки',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Перенести из другого сервиса',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Color(0xFF858585),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Color(0xFF858585), size: 30),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopCard extends StatelessWidget {
  final String title;
  final String imageUrl;

  const _TopCard({required this.title, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 226,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Image.network(
              imageUrl,
              width: 226,
              height: 160,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                width: 226,
                height: 160,
                color: const Color(0xFF1C1C1C),
                child: const Icon(Icons.music_note, color: Color(0xFF777777), size: 36),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _FavoriteSongRow extends StatelessWidget {
  final int index;
  final SongModel song;
  final VoidCallback onTap;

  const _FavoriteSongRow({
    required this.index,
    required this.song,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            SizedBox(
              width: 32,
              child: Text(
                '$index',
                style: const TextStyle(color: Color(0xFF858585), fontSize: 17),
              ),
            ),
            _SongCover(url: song.coverImageUrl),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    song.songname ?? 'Без названия',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    song.name ?? song.userid ?? 'FlowLy',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF858585),
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SongCover extends StatelessWidget {
  final String? url;

  const _SongCover({required this.url});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(15),
      child: SizedBox(
        width: 78,
        height: 78,
        child: url?.isNotEmpty == true
            ? Image.network(
                url!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => _placeholder(),
              )
            : _placeholder(),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: const Color(0xFF1B1B1B),
      child: const Icon(Icons.music_note, color: Color(0xFF777777), size: 28),
    );
  }
}

class _CurrentSongBar extends StatelessWidget {
  final SongModel song;
  final MainController controller;

  const _CurrentSongBar({required this.song, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 86,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: const BoxDecoration(
        color: Colors.black,
        border: Border(top: BorderSide(color: Color(0xFF202020))),
      ),
      child: Row(
        children: [
          _SongCover(url: song.coverImageUrl),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  song.songname ?? 'Без названия',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 3),
                Text(
                  song.name ?? song.userid ?? 'FlowLy',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Color(0xFF858585)),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: controller.previous,
            icon: const Icon(Icons.skip_previous, color: Colors.white, size: 28),
          ),
          IconButton(
            onPressed: controller.playOrPause,
            icon: Icon(
              controller.isPlaying ? Icons.pause : Icons.play_arrow,
              color: Colors.white,
              size: 30,
            ),
          ),
          IconButton(
            onPressed: controller.next,
            icon: const Icon(Icons.skip_next, color: Colors.white, size: 28),
          ),
        ],
      ),
    );
  }
}

class _SettingsView extends StatelessWidget {
  final VoidCallback onBack;

  const _SettingsView({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
      children: [
        Row(
          children: [
            IconButton(
              onPressed: onBack,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 14),
            const Text(
              'Настройки',
              style: TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),
        const _SettingsSectionLabel('АККАУНТ'),
        const SizedBox(height: 9),
        _SettingsCard(
          children: [
            _SettingsRow(
              icon: Icons.person_outline,
              title: 'Аккаунт',
              subtitle: 'Профиль, подписка, данные',
            ),
            _SettingsRow(
              icon: Icons.shield_outlined,
              title: 'Безопасность',
              subtitle: 'Пароль, 2FA',
            ),
            _SettingsRow(
              icon: Icons.credit_card_outlined,
              title: 'Платежи',
              subtitle: 'Способы оплаты, история',
            ),
          ],
        ),
        const SizedBox(height: 24),
        const _SettingsSectionLabel('ПРИЛОЖЕНИЕ'),
        const SizedBox(height: 9),
        _SettingsCard(
          children: [
            _SettingsRow(
              icon: Icons.play_arrow_outlined,
              title: 'Воспроизведение',
              subtitle: 'Качество звука, кроссфейд, EQ',
            ),
            _SettingsRow(
              icon: Icons.download_outlined,
              title: 'Скачивание',
              subtitle: 'Загрузка и хранилище',
            ),
            _SettingsRow(
              icon: Icons.text_fields_outlined,
              title: 'Текст',
              subtitle: 'Отображение текстов песен',
            ),
            _SettingsRow(
              icon: Icons.bolt_outlined,
              title: 'Быстрые действия',
              subtitle: 'Жесты и горячие клавиши',
            ),
          ],
        ),
        const SizedBox(height: 24),
        const _SettingsSectionLabel('ДРУГОЕ'),
        const SizedBox(height: 9),
        _SettingsCard(
          children: [
            _SettingsRow(
              icon: Icons.language_outlined,
              title: 'Язык',
              subtitle: 'Русский',
            ),
            _SettingsRow(
              icon: Icons.info_outline,
              title: 'О приложении',
              subtitle: 'Версия, лицензия',
            ),
            _SettingsRow(
              icon: Icons.support_outlined,
              title: 'Поддержка',
              subtitle: 'Помощь и обратная связь',
            ),
            _SettingsRow(
              icon: Icons.logout_outlined,
              title: 'Выйти из аккаунта',
              subtitle: '',
              titleColor: const Color(0xFFB52B2B),
              iconColor: const Color(0xFFB52B2B),
              iconBackground: const Color(0xFF2A1111),
              showChevron: false,
            ),
          ],
        ),
      ],
    );
  }
}

class _SettingsSectionLabel extends StatelessWidget {
  final String text;

  const _SettingsSectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 6),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF8A8A8A),
          fontSize: 13,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;

  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF101010),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF292929)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color titleColor;
  final Color iconColor;
  final Color iconBackground;
  final bool showChevron;

  const _SettingsRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.titleColor = Colors.white,
    this.iconColor = Colors.black,
    this.iconBackground = Colors.white,
    this.showChevron = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 70),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFF202020))),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: iconBackground,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: titleColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 1),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF858585),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (showChevron)
            const Icon(Icons.chevron_right, color: Color(0xFF858585), size: 22),
        ],
      ),
    );
  }
}
