import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../../controllers/main_controller.dart';
import '../../models/song_model.dart';
import '../../utils/app_locale.dart';

class ProfilePage extends StatefulWidget {
  final MainController con;

  const ProfilePage({super.key, required this.con});

  @override
  ProfilePageState createState() => ProfilePageState();
}

class ProfilePageState extends State<ProfilePage> {
  bool settings = false;
  bool edit = false;
  String? _avatarPath;
  String _displayName = 'Алекс';

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  void showProfile() {
    if (settings || edit) {
      setState(() {
        settings = false;
        edit = false;
      });
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
    final image = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (image == null) return;

    final dir = await getApplicationDocumentsDirectory();
    final target = File('${dir.path}/flowly_profile_avatar.jpg');
    await File(image.path).copy(target.path);
    await Hive.box('profile').put('avatarPath', target.path);

    if (mounted) setState(() => _avatarPath = target.path);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: edit
            ? _EditProfileView(
                displayName: _displayName,
                onBack: () => setState(() => edit = false),
                onSaved: (name) {
                  setState(() {
                    _displayName = name;
                    edit = false;
                  });
                  Hive.box('profile').put('displayName', name);
                },
              )
            : settings
                ? _Settings(
                    onBack: () => setState(() => settings = false),
                    onAccount: () => setState(() => edit = true),
                    onLanguage: _language,
                  )
                : ValueListenableBuilder<Box<dynamic>>(
                    valueListenable: Hive.box('liked').listenable(),
                    builder: (context, _, __) {
                      final songs = _liked();

                      return ListView(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 88),
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
                                onPressed: () => setState(() => settings = true),
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
                            child: CircleAvatar(
                              radius: 58,
                              backgroundColor: const Color(0xFF202020),
                              backgroundImage: _avatarPath == null
                                  ? const NetworkImage('https://i.pravatar.cc/240?img=12')
                                  : FileImage(File(_avatarPath!)) as ImageProvider<Object>,
                            ),
                          ),
                          const SizedBox(height: 18),
                          Center(
                            child: Text(
                              _displayName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(height: 34),
                          const Divider(color: Color(0xFF292929), height: 1),
                          const SizedBox(height: 26),
                          _StatsRow(
                            playlists: Hive.box('playlists').length,
                            followers: 128,
                            following: 56,
                          ),
                          const SizedBox(height: 26),
                          const Divider(color: Color(0xFF292929), height: 1),
                          const SizedBox(height: 26),
                          _ImportCard(
                            onTap: () => _showImportMessage(context),
                          ),
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
                          const SizedBox(
                            height: 205,
                            child: _TopCards(),
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
                          if (songs.isEmpty)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 24),
                              child: Text(
                                'Пока нет любимых треков',
                                style: TextStyle(
                                  color: Color(0xFF858585),
                                  fontSize: 16,
                                ),
                              ),
                            )
                          else
                            ...songs.take(5).toList().asMap().entries.map(
                                  (entry) => _FavoriteSongRow(
                                    index: entry.key + 1,
                                    song: entry.value,
                                    onTap: () => widget.con.playSong(
                                      songs,
                                      entry.key,
                                    ),
                                  ),
                                ),
                        ],
                      );
                    },
                  ),
      ),
    );
  }

  List<SongModel> _liked() {
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

  void _language() {
    final current = AppLocale.language.value;
    AppLocale.setLanguage(current == 'ru' ? 'en' : 'ru');
    setState(() {});
  }

  void _showImportMessage(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          AppLocale.text(
            'Импорт музыки скоро будет доступен',
            'Music import will be available soon',
          ),
        ),
      ),
    );
  }
}

class _EditProfileView extends StatefulWidget {
  final String displayName;
  final VoidCallback onBack;
  final ValueChanged<String> onSaved;

  const _EditProfileView({
    required this.displayName,
    required this.onBack,
    required this.onSaved,
  });

  @override
  State<_EditProfileView> createState() => _EditProfileViewState();
}

class _EditProfileViewState extends State<_EditProfileView> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.displayName);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
      children: [
        Row(
          children: [
            IconButton(
              onPressed: widget.onBack,
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
            ),
            const SizedBox(width: 8),
            const Text(
              'Аккаунт',
              style: TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 26),
        TextField(
          controller: _controller,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: 'Имя',
            labelStyle: const TextStyle(color: Colors.grey),
            enabledBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: Color(0xFF292929)),
              borderRadius: BorderRadius.circular(14),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: Colors.white),
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
        const SizedBox(height: 18),
        FilledButton(
          onPressed: () {
            final name = _controller.text.trim();
            if (name.isNotEmpty) widget.onSaved(name);
          },
          style: FilledButton.styleFrom(backgroundColor: Colors.white),
          child: const Text(
            'Сохранить',
            style: TextStyle(color: Colors.black),
          ),
        ),
      ],
    );
  }
}

class _Settings extends StatelessWidget {
  final VoidCallback onBack;
  final VoidCallback onAccount;
  final VoidCallback onLanguage;

  const _Settings({
    required this.onBack,
    required this.onAccount,
    required this.onLanguage,
  });

  @override
  Widget build(BuildContext context) {
    final language = AppLocale.language.value == 'ru' ? 'Русский' : 'English';

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
      children: [
        Row(
          children: [
            IconButton(
              onPressed: onBack,
              icon: const Icon(
                Icons.arrow_back_ios_new,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 8),
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
        const _SettingsLabel('АККАУНТ'),
        const SizedBox(height: 8),
        _SettingsCard(
          rows: [
            _SettingsRowData(
              Icons.person_outline,
              'Аккаунт',
              'Профиль, подписка, данные',
              onTap: onAccount,
            ),
            const _SettingsRowData(
              Icons.shield_outlined,
              'Безопасность',
              'Пароль, 2FA',
            ),
            const _SettingsRowData(
              Icons.credit_card_outlined,
              'Платежи',
              'Способы оплаты, история',
            ),
          ],
        ),
        const SizedBox(height: 24),
        const _SettingsLabel('ПРИЛОЖЕНИЕ'),
        const SizedBox(height: 8),
        const _SettingsCard(
          rows: [
            _SettingsRowData(
              Icons.play_arrow_outlined,
              'Воспроизведение',
              'Качество звука, кроссфейд, EQ',
            ),
            _SettingsRowData(
              Icons.download_outlined,
              'Скачивание',
              'Загрузка и хранилище',
            ),
            _SettingsRowData(
              Icons.notifications_none,
              'Уведомления',
              'Только важные',
            ),
            _SettingsRowData(
              Icons.palette_outlined,
              'Внешний вид',
              'Тема, цвета, стиль',
            ),
            _SettingsRowData(
              Icons.text_fields_outlined,
              'Текст',
              'Отображение текстов песен',
            ),
            _SettingsRowData(
              Icons.bolt_outlined,
              'Быстрые действия',
              'Жесты и горячие клавиши',
            ),
          ],
        ),
        const SizedBox(height: 24),
        const _SettingsLabel('ДРУГОЕ'),
        const SizedBox(height: 8),
        _SettingsCard(
          rows: [
            _SettingsRowData(
              Icons.language_outlined,
              'Язык',
              language,
              onTap: onLanguage,
            ),
            const _SettingsRowData(
              Icons.info_outline,
              'О приложении',
              'Версия, лицензия',
            ),
            const _SettingsRowData(
              Icons.support_outlined,
              'Поддержка',
              'Помощь и обратная связь',
            ),
          ],
        ),
        const SizedBox(height: 24),
        const _SettingsCard(
          logout: true,
          rows: [
            _SettingsRowData(
              Icons.logout_outlined,
              'Выйти из аккаунта',
              '',
            ),
          ],
        ),
      ],
    );
  }
}

class _SettingsLabel extends StatelessWidget {
  final String text;

  const _SettingsLabel(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(left: 6),
        child: Text(
          text,
          style: const TextStyle(
            color: Color(0xFF8A8A8A),
            fontSize: 13,
            fontWeight: FontWeight.w500,
            letterSpacing: .3,
          ),
        ),
      );
}

class _SettingsCard extends StatelessWidget {
  final List<_SettingsRowData> rows;
  final bool logout;

  const _SettingsCard({
    required this.rows,
    this.logout = false,
  });

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: const Color(0xFF101010),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF292929)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            for (final row in rows)
              InkWell(
                onTap: row.onTap,
                child: Container(
                  constraints: const BoxConstraints(minHeight: 70),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Color(0xFF202020)),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: logout
                              ? const Color(0xFF2A1111)
                              : Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          row.icon,
                          color: logout
                              ? const Color(0xFFB52B2B)
                              : Colors.black,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              row.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: logout
                                    ? const Color(0xFFB52B2B)
                                    : Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (row.subtitle.isNotEmpty)
                              Text(
                                row.subtitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Color(0xFF858585),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (!logout)
                        const Icon(
                          Icons.chevron_right,
                          color: Color(0xFF858585),
                          size: 22,
                        ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      );
}

class _SettingsRowData {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const _SettingsRowData(
    this.icon,
    this.title,
    this.subtitle, {
    this.onTap,
  });
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
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.download_outlined,
                  color: Colors.black,
                  size: 31,
                ),
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
              const Icon(
                Icons.chevron_right,
                color: Color(0xFF858585),
                size: 30,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopCards extends StatelessWidget {
  const _TopCards();

  static const _items = [
    ('Chill Vibes', 'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?w=600'),
    ('Night Drive', 'https://images.unsplash.com/photo-1500534623283-312aade485b7?w=600'),
    ('Focus', 'https://images.unsplash.com/photo-1511379938547-c1f69419868d?w=600'),
  ];

  @override
  Widget build(BuildContext context) => ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 18),
        itemBuilder: (context, index) => SizedBox(
          width: 226,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Image.network(
                  _items[index].$2,
                  width: 226,
                  height: 160,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 226,
                    height: 160,
                    color: const Color(0xFF1C1C1C),
                    child: const Icon(
                      Icons.music_note,
                      color: Color(0xFF777777),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                _items[index].$1,
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
        ),
      );
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
                style: const TextStyle(
                  color: Color(0xFF858585),
                  fontSize: 17,
                ),
              ),
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: SizedBox(
                width: 78,
                height: 78,
                child: song.coverImageUrl?.isNotEmpty == true
                    ? Image.network(
                        song.coverImageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const _SongPlaceholder(),
                      )
                    : const _SongPlaceholder(),
              ),
            ),
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

class _SongPlaceholder extends StatelessWidget {
  const _SongPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1B1B1B),
      child: const Icon(
        Icons.music_note,
        color: Color(0xFF777777),
        size: 28,
      ),
    );
  }
}
