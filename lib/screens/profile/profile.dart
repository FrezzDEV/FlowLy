import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../../controllers/main_controller.dart';
import '../../models/song_model.dart';
import '../../utils/app_locale.dart';
import '../current_playing/current_playing_song.dart';

class ProfilePage extends StatefulWidget {
  final MainController con;

  const ProfilePage({super.key, required this.con});

  @override
  State<ProfilePage> createState() => ProfilePageState();
}

class ProfilePageState extends State<ProfilePage> {
  bool settings = false;
  bool edit = false;
  String? avatar;

  static const List<_CardData> cards = [
    _CardData(
      'Chill Vibes',
      'https://images.unsplash.com/photo-1571266028243-d220c9c3b1f3?w=600',
    ),
    _CardData(
      'Night Drive',
      'https://images.unsplash.com/photo-1500534623283-312aade485b7?w=600',
    ),
    _CardData(
      'Focus',
      'https://images.unsplash.com/photo-1511379938547-c1f69419868d?w=600',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadAvatar();
  }

  void showProfile() {
    if (!settings && !edit) return;
    setState(() {
      settings = false;
      edit = false;
    });
  }

  Future<void> _loadAvatar() async {
    final path = Hive.box('profile').get('avatarPath') as String?;
    if (path != null && await File(path).exists() && mounted) {
      setState(() => avatar = path);
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
      setState(() => avatar = target.path);
    }
  }

  List<SongModel> _likedSongs() {
    final result = <SongModel>[];
    final box = Hive.box('liked');

    for (var i = 0; i < box.length; i++) {
      final value = box.getAt(i);
      if (value is! Map || value['songname'] == null) continue;

      result.add(
        SongModel(
          songid: value['id']?.toString(),
          songname: value['songname']?.toString(),
          userid: value['username']?.toString(),
          trackid: value['track']?.toString(),
          coverImageUrl: value['cover']?.toString(),
          name: value['fullname']?.toString(),
        ),
      );
    }

    return result;
  }

  Future<void> _openTrack(int index) async {
    final songs = _likedSongs();
    if (index < 0 || index >= songs.length) return;

    await widget.con.playSong(songs, index);
    if (!mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.black,
      builder: (_) => CurrentPlayingSong(con: widget.con),
    );
  }

  Future<void> _chooseLanguage() async {
    final value = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: const Color(0xFF151515),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFF555555),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  AppLocale.text('Язык', 'Language'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                _LanguageRow(
                  value: 'ru',
                  title: 'Русский',
                  onTap: () => Navigator.pop(sheetContext, 'ru'),
                ),
                _LanguageRow(
                  value: 'en',
                  title: 'English',
                  onTap: () => Navigator.pop(sheetContext, 'en'),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (value != null) {
      await AppLocale.setLanguage(value);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: AppLocale.language,
      builder: (context, _, __) {
        return Scaffold(
          backgroundColor: Colors.black,
          body: SafeArea(
            child: edit
                ? _EditProfile(
                    avatar: avatar,
                    onBack: () => setState(() => edit = false),
                    onPick: _pickAvatar,
                  )
                : settings
                    ? _Settings(
                        onBack: () => setState(() => settings = false),
                        onAccount: () => setState(() => edit = true),
                        onLanguage: _chooseLanguage,
                      )
                    : ValueListenableBuilder<Box<dynamic>>(
                        valueListenable: Hive.box('liked').listenable(),
                        builder: (context, box, child) {
                          final songs = _likedSongs();
                          final visibleSongs = songs.take(5).toList();

                          return ListView(
                            padding: const EdgeInsets.fromLTRB(20, 8, 20, 88),
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      AppLocale.text('Профиль', 'Profile'),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 29,
                                        height: 1,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: -0.6,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () => setState(() => settings = true),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints.tightFor(
                                      width: 34,
                                      height: 34,
                                    ),
                                    icon: const Icon(
                                      Icons.settings_outlined,
                                      color: Color(0xFF8E8E8E),
                                      size: 25,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Center(
                                child: CircleAvatar(
                                  radius: 60,
                                  backgroundColor: const Color(0xFF242424),
                                  backgroundImage: avatar == null
                                      ? const NetworkImage(
                                          'https://i.pravatar.cc/400?img=12',
                                        )
                                      : FileImage(File(avatar!)) as ImageProvider,
                                ),
                              ),
                              const SizedBox(height: 7),
                              Text(
                                Hive.box('profile').get(
                                      'name',
                                      defaultValue:
                                          AppLocale.text('Алекс', 'Alex'),
                                    )
                                    as String,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 23,
                                  height: 1,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 14),
                              const Divider(
                                color: Color(0xFF242424),
                                height: 1,
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: _Stat(
                                        '24',
                                        AppLocale.text('Плейлисты', 'Playlists'),
                                      ),
                                    ),
                                    Expanded(
                                      child: _Stat(
                                        '128',
                                        AppLocale.text('Подписчики', 'Followers'),
                                      ),
                                    ),
                                    Expanded(
                                      child: _Stat(
                                        '56',
                                        AppLocale.text('Подписки', 'Following'),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Divider(
                                color: Color(0xFF242424),
                                height: 1,
                              ),
                              const SizedBox(height: 14),
                              _ImportCard(),
                              const SizedBox(height: 20),
                              _SectionTitle(
                                AppLocale.text('Топ за месяц', 'Top this month'),
                              ),
                              const SizedBox(height: 8),
                              const _TopCards(),
                              const SizedBox(height: 18),
                              _SectionTitle(
                                AppLocale.text('Любимые треки', 'Favorite tracks'),
                              ),
                              const SizedBox(height: 4),
                              for (var i = 0; i < visibleSongs.length; i++)
                                InkWell(
                                  onTap: () => _openTrack(i),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 4),
                                    child: Row(
                                      children: [
                                        SizedBox(
                                          width: 24,
                                          child: Text(
                                            '${i + 1}',
                                            style: const TextStyle(
                                              color: Color(0xFF777777),
                                              fontSize: 16,
                                            ),
                                          ),
                                        ),
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(11),
                                          child: _SongImage(
                                            visibleSongs[i].coverImageUrl,
                                          ),
                                        ),
                                        const SizedBox(width: 11),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                visibleSongs[i].songname ?? '',
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 16,
                                                  height: 1.05,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                visibleSongs[i].name ??
                                                    AppLocale.text(
                                                      'Неизвестный исполнитель',
                                                      'Unknown artist',
                                                    ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  color: Color(0xFF858585),
                                                  fontSize: 13,
                                                  height: 1.05,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              if (songs.isEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 18),
                                  child: Text(
                                    AppLocale.text(
                                      'Пока нет любимых треков',
                                      'No favorite tracks yet',
                                    ),
                                    style: const TextStyle(
                                      color: Color(0xFF777777),
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
          ),
        );
      },
    );
  }
}

class _Stat extends StatelessWidget {
  final String value;
  final String label;

  const _Stat(this.value, this.label);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            height: 1,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFF858585),
            fontSize: 13,
            height: 1,
          ),
        ),
      ],
    );
  }
}

class _ImportCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(
              Icons.download_outlined,
              color: Colors.black,
              size: 23,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocale.text('Импорт музыки', 'Import music'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    height: 1.05,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  AppLocale.text(
                    'Перенести из другого сервиса',
                    'Transfer from another service',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF858585),
                    fontSize: 12,
                    height: 1.05,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Color(0xFF858585)),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;

  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 22,
        height: 1.05,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _TopCards extends StatelessWidget {
  const _TopCards();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 155,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: ProfilePageState.cards.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final card = ProfilePageState.cards[index];
          return SizedBox(
            width: 160,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(13),
                  child: CachedNetworkImage(
                    imageUrl: card.image,
                    width: 160,
                    height: 126,
                    fit: BoxFit.cover,
                    placeholder: (_, __) =>
                        Container(color: const Color(0xFF202020)),
                    errorWidget: (_, __, ___) => Container(
                      color: const Color(0xFF202020),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.music_note,
                        color: Colors.white54,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  card.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    height: 1.05,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SongImage extends StatelessWidget {
  final String? url;

  const _SongImage(this.url);

  @override
  Widget build(BuildContext context) {
    if (url == null || url!.isEmpty) {
      return Container(
        width: 56,
        height: 56,
        color: const Color(0xFF202020),
        alignment: Alignment.center,
        child: const Icon(Icons.music_note, color: Colors.white54),
      );
    }

    return CachedNetworkImage(
      imageUrl: url!,
      width: 56,
      height: 56,
      fit: BoxFit.cover,
      placeholder: (_, __) => Container(color: const Color(0xFF202020)),
      errorWidget: (_, __, ___) => Container(
        color: const Color(0xFF202020),
        alignment: Alignment.center,
        child: const Icon(Icons.music_note, color: Colors.white54),
      ),
    );
  }
}

class _SettingsRowData {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const _SettingsRowData({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });
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
    final rows = <_SettingsRowData>[
      _SettingsRowData(
        icon: Icons.person_outline,
        title: AppLocale.text('Аккаунт', 'Account'),
        subtitle: AppLocale.text(
          'Профиль, подписка, данные',
          'Profile, subscription, data',
        ),
        onTap: onAccount,
      ),
      _SettingsRowData(
        icon: Icons.shield_outlined,
        title: AppLocale.text('Безопасность', 'Security'),
        subtitle: AppLocale.text('Пароль, 2FA', 'Password, 2FA'),
      ),
      _SettingsRowData(
        icon: Icons.download_outlined,
        title: AppLocale.text('Скачивание', 'Downloads'),
        subtitle: AppLocale.text(
          'Загрузка и хранилище',
          'Downloads and storage',
        ),
      ),
      _SettingsRowData(
        icon: Icons.language_outlined,
        title: AppLocale.text('Язык', 'Language'),
        subtitle: AppLocale.isEnglish ? 'English' : 'Русский',
        onTap: onLanguage,
      ),
      _SettingsRowData(
        icon: Icons.info_outline,
        title: AppLocale.text('О приложении', 'About'),
        subtitle: AppLocale.text('Версия 1.0.2', 'Version 1.0.2'),
      ),
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 88),
      children: [
        Row(
          children: [
            IconButton(
              onPressed: onBack,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints.tightFor(width: 34, height: 34),
              icon: const Icon(
                Icons.arrow_back_ios_new,
                color: Colors.white,
                size: 19,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              AppLocale.text('Настройки', 'Settings'),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                height: 1,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        for (final row in rows) ...[
          _SettingsRow(row: row),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final _SettingsRowData row;

  const _SettingsRow({required this.row});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: row.onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        constraints: const BoxConstraints(minHeight: 64),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF101010),
          border: Border.all(color: const Color(0xFF292929)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(row.icon, color: Colors.black, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    row.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    row.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF858585),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: Color(0xFF858585),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class _LanguageRow extends StatelessWidget {
  final String value;
  final String title;
  final VoidCallback onTap;

  const _LanguageRow({
    required this.value,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      trailing: Icon(
        AppLocale.language.value == value
            ? Icons.radio_button_checked
            : Icons.radio_button_off,
        color: Colors.white,
      ),
    );
  }
}

class _EditProfile extends StatefulWidget {
  final String? avatar;
  final VoidCallback onBack;
  final Future<void> Function() onPick;

  const _EditProfile({
    required this.avatar,
    required this.onBack,
    required this.onPick,
  });

  @override
  State<_EditProfile> createState() => _EditProfileState();
}

class _EditProfileState extends State<_EditProfile> {
  late final TextEditingController nameController;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(
      text: Hive.box('profile').get(
            'name',
            defaultValue: AppLocale.text('Алекс', 'Alex'),
          )
          as String,
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final value = nameController.text.trim();
    if (value.isNotEmpty) {
      await Hive.box('profile').put('name', value);
    }
    if (mounted) {
      widget.onBack();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 88),
      children: [
        Row(
          children: [
            IconButton(
              onPressed: widget.onBack,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints.tightFor(width: 34, height: 34),
              icon: const Icon(
                Icons.arrow_back_ios_new,
                color: Colors.white,
                size: 19,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                AppLocale.text('Редактирование профиля', 'Edit profile'),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 21,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 26),
        Center(
          child: CircleAvatar(
            radius: 54,
            backgroundColor: const Color(0xFF242424),
            backgroundImage: widget.avatar == null
                ? const NetworkImage('https://i.pravatar.cc/400?img=12')
                : FileImage(File(widget.avatar!)) as ImageProvider,
          ),
        ),
        const SizedBox(height: 10),
        Center(
          child: TextButton(
            onPressed: widget.onPick,
            style: TextButton.styleFrom(foregroundColor: Colors.white),
            child: Text(
              AppLocale.text('Изменить фото', 'Change photo'),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          AppLocale.text('Имя', 'Name'),
          style: const TextStyle(
            color: Color(0xFF858585),
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 7),
        TextField(
          controller: nameController,
          style: const TextStyle(color: Colors.white, fontSize: 16),
          cursorColor: Colors.white,
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFF111111),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF2A2A2A)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF555555)),
            ),
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 48,
          child: FilledButton(
            onPressed: _save,
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              AppLocale.text('Сохранить', 'Save'),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }
}

class _CardData {
  final String title;
  final String image;

  const _CardData(this.title, this.image);
}
