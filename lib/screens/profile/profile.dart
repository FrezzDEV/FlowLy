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

  static const cards = [
    (
      'Chill Vibes',
      'https://images.unsplash.com/photo-1571266028243-d220c9c3b1f3?w=600'
    ),
    (
      'Night Drive',
      'https://images.unsplash.com/photo-1500534623283-312aade485b7?w=600'
    ),
    (
      'Focus',
      'https://images.unsplash.com/photo-1511379938547-c1f69419868d?w=600'
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadAvatar();
  }

  void showProfile() {
    if (settings) {
      setState(() => settings = false);
    }
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

    final dir = await getApplicationDocumentsDirectory();
    final target = File('${dir.path}/flowly_profile_avatar.jpg');
    await File(image.path).copy(target.path);
    await Hive.box('profile').put('avatarPath', target.path);

    if (mounted) {
      setState(() => avatar = target.path);
    }
  }

  List<SongModel> _liked() {
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
    final songs = _liked();
    if (index >= songs.length) return;

    await widget.con.playSong(songs, index);
    if (!mounted) return;

    await PlayerRoute.open(context, widget.con);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: AppLocale.language,
      builder: (_, __, ___) {
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
                        onLanguage: _language,
                      )
                    : ValueListenableBuilder(
                        valueListenable: Hive.box('liked').listenable(),
                        builder: (_, Box<dynamic> _, __) {
                          final songs = _liked();

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
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () => setState(() => settings = true),
                                    icon: const Icon(
                                      Icons.settings_outlined,
                                      color: Color(0xFF8E8E8E),
                                      size: 25,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              CircleAvatar(
                                radius: 60,
                                backgroundColor: const Color(0xFF242424),
                                backgroundImage: avatar == null
                                    ? const NetworkImage(
                                        'https://i.pravatar.cc/400?img=12',
                                      )
                                    : FileImage(File(avatar!)) as ImageProvider,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                Hive.box('profile').get(
                                  'name',
                                  defaultValue: AppLocale.text('Алекс', 'Alex'),
                                ) as String,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 23,
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
                              const _ImportCard(),
                              const SizedBox(height: 20),
                              _Title(
                                AppLocale.text('Топ за месяц', 'Top this month'),
                              ),
                              const SizedBox(height: 8),
                              SizedBox(
                                height: 155,
                                child: ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: cards.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(width: 12),
                                  itemBuilder: (_, i) => SizedBox(
                                    width: 160,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(13),
                                          child: CachedNetworkImage(
                                            imageUrl: cards[i].$2,
                                            width: 160,
                                            height: 126,
                                            fit: BoxFit.cover,
                                            errorWidget: (_, __, ___) => Container(
                                              color: const Color(0xFF202020),
                                              child: const Icon(
                                                Icons.music_note,
                                                color: Colors.white54,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          cards[i].$1,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 18),
                              _Title(
                                AppLocale.text(
                                  'Любимые треки',
                                  'Favorite tracks',
                                ),
                              ),
                              const SizedBox(height: 4),
                              ...List.generate(
                                songs.take(5).length,
                                (i) => InkWell(
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
                                          child: _SongImage(songs[i].coverImageUrl),
                                        ),
                                        const SizedBox(width: 11),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                songs[i].songname ?? '',
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                              Text(
                                                songs[i].name ??
                                                    AppLocale.text(
                                                      'Неизвестный исполнитель',
                                                      'Unknown artist',
                                                    ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  color: Color(0xFF858585),
                                                  fontSize: 13,
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

  Future<void> _language() async {
    final value = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: const Color(0xFF151515),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) => SafeArea(
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
              const _LanguageRow('ru', 'Русский'),
              const _LanguageRow('en', 'English'),
            ],
          ),
        ),
      ),
    );

    if (value != null) {
      await AppLocale.setLanguage(value);
    }
  }
}

class _Stat extends StatelessWidget {
  final String value;
  final String label;

  const _Stat(this.value, this.label);

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF858585),
              fontSize: 13,
            ),
          ),
        ],
      );
}

class _ImportCard extends StatelessWidget {
  const _ImportCard();

  @override
  Widget build(BuildContext context) => Container(
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
                      fontWeight: FontWeight.w700,
                    ),
                  ),
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
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: Color(0xFF858585),
            ),
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
        style: const TextStyle(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.w700,
        ),
      );
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
        child: const Icon(
          Icons.music_note,
          color: Colors.white54,
        ),
      );
    }

    return CachedNetworkImage(
      imageUrl: url!,
      width: 56,
      height: 56,
      fit: BoxFit.cover,
    );
  }
}

class _Settings extends StatelessWidget {
  final VoidCallback onBack;
  final VoidCallback onAccount;
  final Future<void> Function() onLanguage;

  const _Settings({
    required this.onBack,
    required this.onAccount,
    required this.onLanguage,
  });

  @override
  Widget build(BuildContext context) {
    final groups = <({String title, List<_SettingRowData> rows})>[
      (
        title: AppLocale.text('АККАУНТ', 'ACCOUNT'),
        rows: [
          _SettingRowData(
            Icons.person_outline,
            AppLocale.text('Аккаунт', 'Account'),
            AppLocale.text('Профиль, подписка, данные', 'Profile, subscription, data'),
            onTap: onAccount,
          ),
          _SettingRowData(
            Icons.shield_outlined,
            AppLocale.text('Безопасность', 'Security'),
            AppLocale.text('Пароль, 2FA', 'Password, 2FA'),
          ),
          _SettingRowData(
            Icons.credit_card_outlined,
            AppLocale.text('Платежи', 'Payments'),
            AppLocale.text('Способы оплаты, история', 'Payment methods, history'),
          ),
        ],
      ),
      (
        title: AppLocale.text('ПРИЛОЖЕНИЕ', 'APP'),
        rows: [
          _SettingRowData(
            Icons.play_arrow_outlined,
            AppLocale.text('Воспроизведение', 'Playback'),
            AppLocale.text('Качество звука, кроссфейд, EQ', 'Sound quality, crossfade, EQ'),
          ),
          _SettingRowData(
            Icons.download_outlined,
            AppLocale.text('Скачивание', 'Downloads'),
            AppLocale.text('Загрузка и хранилище', 'Downloads and storage'),
          ),
          _SettingRowData(
            Icons.notifications_none,
            AppLocale.text('Уведомления', 'Notifications'),
            AppLocale.text('Только важные', 'Important only'),
          ),
          _SettingRowData(
            Icons.palette_outlined,
            AppLocale.text('Внешний вид', 'Appearance'),
            AppLocale.text('Тема, цвета, стиль', 'Theme, colors, style'),
          ),
          _SettingRowData(
            Icons.text_fields_outlined,
            AppLocale.text('Текст', 'Text'),
            AppLocale.text('Отображение текстов песен', 'Lyrics display'),
          ),
          _SettingRowData(
            Icons.bolt_outlined,
            AppLocale.text('Быстрые действия', 'Quick actions'),
            AppLocale.text('Жесты и горячие клавиши', 'Gestures and shortcuts'),
          ),
        ],
      ),
      (
        title: AppLocale.text('ДРУГОЕ', 'OTHER'),
        rows: [
          _SettingRowData(
            Icons.language_outlined,
            AppLocale.text('Язык', 'Language'),
            AppLocale.isEnglish ? 'English' : 'Русский',
            onTap: onLanguage,
          ),
          _SettingRowData(
            Icons.info_outline,
            AppLocale.text('О приложении', 'About'),
            AppLocale.text('Версия, лицензия', 'Version, licenses'),
          ),
          _SettingRowData(
            Icons.support_outlined,
            AppLocale.text('Поддержка', 'Support'),
            AppLocale.text('Помощь и обратная связь', 'Help and feedback'),
          ),
        ],
      ),
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 88),
      children: [
        Row(
          children: [
            IconButton(
              onPressed: onBack,
              icon: const Icon(
                Icons.arrow_back_ios_new,
                color: Colors.white,
                size: 19,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              AppLocale.text('Настройки', 'Settings'),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        for (var i = 0; i < groups.length; i++) ...[
          _SettingsLabel(groups[i].title),
          const SizedBox(height: 8),
          _SettingsCard(rows: groups[i].rows),
          if (i != groups.length - 1) const SizedBox(height: 22),
        ],
        const SizedBox(height: 22),
        _SettingsCard(
          rows: [
            _SettingRowData(
              Icons.logout_outlined,
              AppLocale.text('Выйти из аккаунта', 'Log out'),
              '',
            ),
          ],
          logout: true,
        ),
      ],
    );
  }
}

class _SettingRowData {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const _SettingRowData(
    this.icon,
    this.title,
    this.subtitle, {
    this.onTap,
  });
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
  final List<_SettingRowData> rows;
  final bool logout;

  const _SettingsCard({required this.rows, this.logout = false});

  @override
  Widget build(BuildContext context) {
    return Container(
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
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
                        color: logout ? const Color(0xFF2A1111) : Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        row.icon,
                        color: logout ? const Color(0xFFB52B2B) : Colors.black,
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
                              color: logout ? const Color(0xFFB52B2B) : Colors.white,
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
}

class _LanguageRow extends StatelessWidget {
  final String value;
  final String title;

  const _LanguageRow(this.value, this.title);

  @override
  Widget build(BuildContext context) => ListTile(
        onTap: () => Navigator.pop(context, value),
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
  late final TextEditingController name;

  @override
  void initState() {
    super.initState();
    name = TextEditingController(
      text: Hive.box('profile').get(
        'name',
        defaultValue: AppLocale.text('Алекс', 'Alex'),
      ) as String,
    );
  }

  @override
  void dispose() {
    name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 88),
        children: [
          Row(
            children: [
              IconButton(
                onPressed: widget.onBack,
                icon: const Icon(
                  Icons.arrow_back_ios_new,
                  color: Colors.white,
                  size: 19,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                AppLocale.text('Редактирование профиля', 'Edit profile'),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 21,
                  fontWeight: FontWeight.w700,
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
              child: Text(
                AppLocale.text('Изменить фото', 'Change photo'),
                style: const TextStyle(color: Colors.white),
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
            controller: name,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              filled: true,
              fillColor: Color(0xFF111111),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 48,
            child: FilledButton(
              onPressed: () async {
                final trimmed = name.text.trim();
                if (trimmed.isNotEmpty) {
                  await Hive.box('profile').put('name', trimmed);
                }
                if (mounted) {
                  widget.onBack();
                }
              },
              child: Text(
                AppLocale.text('Сохранить', 'Save'),
              ),
            ),
          ),
        ],
      );
}
