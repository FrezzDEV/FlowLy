import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import 'package:flowly/features/player/domain/main_controller.dart';
import 'package:flowly/domain/entities/song_model.dart';
import 'package:flowly/app/localization/app_locale.dart';
import 'settings_pages.dart';

class ProfilePage extends StatefulWidget {
  final MainController con;

  const ProfilePage({super.key, required this.con});

  @override
  ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _settings = false;
  bool _editing = false;
  String? _avatarPath;
  String _displayName = 'Алекс';

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  void showProfile() {
    if (_settings || _editing) {
      setState(() {
        _settings = false;
        _editing = false;
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
      _avatarPath = path;
    });
  }

  void _openSettings() => setState(() {
        _settings = true;
        _editing = false;
      });

  void _openEditProfile() => setState(() {
        _editing = true;
        _settings = false;
      });

  Future<void> _saveName(String name) async {
    final value = name.trim();
    if (value.isEmpty) return;
    await Hive.box('profile').put('displayName', value);
    if (!mounted) return;
    setState(() {
      _displayName = value;
      _editing = false;
    });
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

    if (mounted) {
      setState(() => _avatarPath = target.path);
    }
    return target.path;
  }

  String _languageName() =>
      AppLocale.isEnglish ? 'English' : 'Русский';

  @override
  Widget build(BuildContext context) {
    if (_editing) {
      return _EditProfilePage(
        displayName: _displayName,
        avatarPath: _avatarPath,
        onBack: () => setState(() => _editing = false),
        onSaveName: _saveName,
        onPickAvatar: _pickAvatar,
      );
    }

    if (_settings) {
      return _SettingsPage(
        languageName: _languageName(),
        onBack: () => setState(() => _settings = false),
        onAccount: _openEditProfile,
        onLanguageChanged: () => setState(() {}),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: ValueListenableBuilder<Box<dynamic>>(
          valueListenable: Hive.box('liked').listenable(),
          builder: (context, _, __) {
            final songs = _likedSongs();
            final avatar = _avatarPath;

            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 96),
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
                        ? const NetworkImage(
                            'https://i.pravatar.cc/240?img=12',
                          )
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
                _ImportSettingsTile(
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
                      AppLocale.text(
                        'Пока нет любимых треков',
                        'No liked songs yet',
                      ),
                      style: const TextStyle(color: Color(0xFF858585)),
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

class _EditProfilePage extends StatefulWidget {
  final String displayName;
  final String? avatarPath;
  final VoidCallback onBack;
  final ValueChanged<String> onSaveName;
  final Future<String?> Function() onPickAvatar;

  const _EditProfilePage({
    required this.displayName,
    required this.avatarPath,
    required this.onBack,
    required this.onSaveName,
    required this.onPickAvatar,
  });

  @override
  State<_EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<_EditProfilePage> {
  late final TextEditingController _nameController;
  String? _avatarPath;
  bool _savingAvatar = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.displayName);
    _avatarPath = widget.avatarPath;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _changeAvatar() async {
    setState(() => _savingAvatar = true);
    final path = await widget.onPickAvatar();
    if (mounted) {
      setState(() {
        _avatarPath = path;
        _savingAvatar = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasAvatar = _avatarPath?.isNotEmpty == true;
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: widget.onBack,
                  icon: const Icon(
                    Icons.arrow_back_ios_new,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  AppLocale.text('Аккаунт', 'Account'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 25,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Center(
              child: GestureDetector(
                onTap: _savingAvatar ? null : _changeAvatar,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircleAvatar(
                      radius: 62,
                      backgroundColor: const Color(0xFF202020),
                      backgroundImage: hasAvatar
                          ? FileImage(File(_avatarPath!))
                              as ImageProvider<Object>
                          : const NetworkImage(
                              'https://i.pravatar.cc/240?img=12',
                            ),
                      child: _savingAvatar
                          ? const CircularProgressIndicator(
                              color: Colors.white,
                            )
                          : null,
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.edit_outlined,
                          color: Colors.black,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),
            TextField(
              controller: _nameController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: AppLocale.text('Имя', 'Name'),
                labelStyle: const TextStyle(color: Color(0xFF858585)),
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
              onPressed: () => widget.onSaveName(_nameController.text),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                minimumSize: const Size.fromHeight(50),
              ),
              child: Text(AppLocale.text('Сохранить', 'Save')),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsPage extends StatelessWidget {
  final String languageName;
  final VoidCallback onBack;
  final VoidCallback onAccount;
  final VoidCallback onLanguageChanged;

  const _SettingsPage({
    required this.languageName,
    required this.onBack,
    required this.onAccount,
    required this.onLanguageChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
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
                Text(
                  AppLocale.text('Настройки', 'Settings'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 25,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 26),
            _SettingsGroup(
              label: AppLocale.text('АККАУНТ', 'ACCOUNT'),
              rows: [
                _SettingsRow(
                  icon: Icons.person_outline,
                  title: AppLocale.text('Аккаунт', 'Account'),
                  subtitle: AppLocale.text(
                    'Профиль, подписка, данные',
                    'Profile, subscription, data',
                  ),
                  onTap: onAccount,
                ),
                _SettingsRow(
                  icon: Icons.shield_outlined,
                  title: AppLocale.text('Безопасность', 'Security'),
                  subtitle: AppLocale.text('Пароль, 2FA', 'Password, 2FA'),
                ),
                _SettingsRow(
                  icon: Icons.credit_card_outlined,
                  title: AppLocale.text('Платежи', 'Payments'),
                  subtitle: AppLocale.text(
                    'Способы оплаты, история',
                    'Payment methods, history',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            _SettingsGroup(
              label: AppLocale.text('ПРИЛОЖЕНИЕ', 'APP'),
              rows: [
                _SettingsRow(
                  icon: Icons.play_circle_outline,
                  title: AppLocale.text('Воспроизведение', 'Playback'),
                  subtitle: AppLocale.text('Качество, повтор, crossfade, EQ', 'Quality, repeat, crossfade, EQ'),
                  onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const PlaybackSettingsPage())),
                ),
                _SettingsRow(
                  icon: Icons.file_download_outlined,
                  title: AppLocale.text('Скачивание', 'Downloads'),
                  subtitle: AppLocale.text(
                    'Папка и параметры загрузки',
                    'Folder and download options',
                  ),
                  onTap: () => _openDownloadSettings(context),
                ),
                _SettingsRow(
                  icon: Icons.notifications_none_outlined,
                  title: AppLocale.text('Уведомления', 'Notifications'),
                  subtitle: AppLocale.text('Музыка, загрузки и обновления', 'Music, downloads and updates'),
                  onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const NotificationSettingsPage())),
                ),
                _SettingsRow(
                  icon: Icons.palette_outlined,
                  title: AppLocale.text('Внешний вид', 'Appearance'),
                  subtitle: AppLocale.text('Тема, цвета, стиль', 'Theme, colors, style'),
                ),
                _SettingsRow(
                  icon: Icons.bolt_outlined,
                  title: AppLocale.text('Быстрые действия', 'Quick actions'),
                  subtitle: AppLocale.text(
                    'Жесты и горячие клавиши',
                    'Gestures and shortcuts',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            _SettingsGroup(
              label: AppLocale.text('ДРУГОЕ', 'OTHER'),
              rows: [
                _SettingsRow(
                  icon: Icons.language_outlined,
                  title: AppLocale.text('Язык', 'Language'),
                  subtitle: languageName,
                  onTap: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => _LanguagePage(
                          onChanged: onLanguageChanged,
                        ),
                      ),
                    );
                  },
                ),
                _SettingsRow(
                  icon: Icons.system_update_outlined,
                  title: AppLocale.text('Обновления', 'Updates'),
                  subtitle: AppLocale.text(
                    'Проверка и обновления приложения',
                    'Check for app updates',
                  ),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const _UpdatesPage(),
                    ),
                  ),
                ),
                _SettingsRow(
                  icon: Icons.info_outline,
                  title: AppLocale.text('О приложении', 'About'),
                  subtitle: AppLocale.text(
                    'Версия, лицензия',
                    'Version, licenses',
                  ),
                ),
                _SettingsRow(
                  icon: Icons.support_agent_outlined,
                  title: AppLocale.text('Поддержка', 'Support'),
                  subtitle: AppLocale.text('Помощь и обратная связь', 'Help and feedback'),
                  onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const SupportSettingsPage())),
                ),
              ],
            ),
            const SizedBox(height: 22),
            _SettingsGroup(
              rows: [
                _SettingsRow(
                  icon: Icons.logout_outlined,
                  title: AppLocale.text('Выйти из аккаунта', 'Sign out'),
                  subtitle: '',
                  danger: true,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _openDownloadSettings(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const _DownloadSettingsPage(),
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  final String? label;
  final List<_SettingsRow> rows;

  const _SettingsGroup({this.label, required this.rows});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Padding(
            padding: const EdgeInsets.only(left: 5, bottom: 8),
            child: Text(
              label!,
              style: const TextStyle(
                color: Color(0xFF858585),
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: .4,
              ),
            ),
          ),
        ],
        Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: const Color(0xFF101010),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF292929)),
          ),
          child: Column(children: rows),
        ),
      ],
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final bool danger;

  const _SettingsRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 68),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFF202020))),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: danger ? const Color(0xFF2A1111) : Colors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: danger ? const Color(0xFFB52B2B) : Colors.black,
                size: 21,
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: danger ? const Color(0xFFB52B2B) : Colors.white,
                      fontSize: 15.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF858585),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (onTap != null)
              const Icon(
                Icons.chevron_right,
                color: Color(0xFF858585),
                size: 21,
              ),
          ],
        ),
      ),
    );
  }
}

class _LanguagePage extends StatefulWidget {
  final VoidCallback onChanged;

  const _LanguagePage({required this.onChanged});

  @override
  State<_LanguagePage> createState() => _LanguagePageState();
}

class _LanguagePageState extends State<_LanguagePage> {
  String _selected = AppLocale.language.value;

  Future<void> _setLanguage(String value) async {
    setState(() => _selected = value);
    await AppLocale.setLanguage(value);
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(AppLocale.text('Язык', 'Language')),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF101010),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF292929)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _LanguageTile(
                title: 'Русский',
                value: 'ru',
                selected: _selected == 'ru',
                onTap: _setLanguage,
              ),
              _LanguageTile(
                title: 'English',
                value: 'en',
                selected: _selected == 'en',
                onTap: _setLanguage,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LanguageTile extends StatelessWidget {
  final String title;
  final String value;
  final bool selected;
  final ValueChanged<String> onTap;

  const _LanguageTile({
    required this.title,
    required this.value,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onTap(value),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
            Radio<String>(
              value: value,
              groupValue: selected ? value : null,
              onChanged: (_) => onTap(value),
              activeColor: Colors.white,
            ),
          ],
        ),
      ),
    );
  }
}

class _DownloadSettingsPage extends StatelessWidget {
  const _DownloadSettingsPage();

  @override
  Widget build(BuildContext context) {
    final path = Hive.box('profile').get('downloadDirectory') as String?;
    final location = path == null
        ? AppLocale.text('Память приложения', 'App storage')
        : path;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(AppLocale.text('Скачивание', 'Downloads')),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _SettingsRow(
            icon: Icons.folder_outlined,
            title: AppLocale.text('Папка', 'Folder'),
            subtitle: location,
          ),
          const SizedBox(height: 10),
          _SettingsRow(
            icon: Icons.wifi_outlined,
            title: AppLocale.text('Только Wi-Fi', 'Wi-Fi only'),
            subtitle: AppLocale.text(
              'Подключение к загрузочному API будет включено позже',
              'Download API will be enabled later',
            ),
          ),
          const SizedBox(height: 14),
          Text(
            AppLocale.text(
              'Скачивание пока заморожено: серверного API ещё нет. Никакие ссылки на сайт не открываются.',
              'Downloads are temporarily frozen: the server API is not ready yet. No website links are opened.',
            ),
            style: const TextStyle(
              color: Color(0xFF858585),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _UpdatesPage extends StatelessWidget {
  const _UpdatesPage();

  static const currentVersion = '1.0.7+8';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(AppLocale.text('Обновления', 'Updates')),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocale.text('Текущая версия', 'Current version'),
              style: const TextStyle(color: Color(0xFF858585)),
            ),
            const SizedBox(height: 6),
            const Text(
              currentVersion,
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 22),
            FilledButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      AppLocale.text(
                        'Проверка обновлений будет подключена через API',
                        'Update checks will be connected through the API',
                      ),
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.refresh),
              label: Text(
                AppLocale.text('Проверить обновления', 'Check for updates'),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              AppLocale.text(
                'Когда сервер обновлений будет готов, здесь появятся changelog, уведомление о новой версии и безопасная установка обновления.',
                'When the update server is ready, this screen will show changelog, new-version notifications and safe update installation.',
              ),
              style: const TextStyle(
                color: Color(0xFF858585),
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
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
        _Stat(playlists.toString(), AppLocale.text('Плейлисты', 'Playlists')),
        _Stat(followers.toString(), AppLocale.text('Подписчики', 'Followers')),
        _Stat(following.toString(), AppLocale.text('Подписки', 'Following')),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  final String value;
  final String label;

  const _Stat(this.value, this.label);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 23,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF858585),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _ImportSettingsTile extends StatelessWidget {
  final VoidCallback onTap;

  const _ImportSettingsTile({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return _SettingsGroup(
      rows: [
        _SettingsRow(
          icon: Icons.library_music_outlined,
          title: AppLocale.text('Импорт музыки', 'Import music'),
          subtitle: AppLocale.text(
            'Перенести музыку из другого сервиса',
            'Move music from another service',
          ),
          onTap: onTap,
        ),
      ],
    );
  }
}

class _TopCards extends StatelessWidget {
  const _TopCards();

  static const items = [
    (
      'Chill Vibes',
      'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?w=600'
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
                    child: const Icon(
                      Icons.music_note,
                      color: Color(0xFF777777),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 7),
              Text(
                items[index].$1,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
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
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(
          children: [
            SizedBox(
              width: 28,
              child: Text(
                '$index',
                style: const TextStyle(
                  color: Color(0xFF858585),
                  fontSize: 15,
                ),
              ),
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 64,
                height: 64,
                child: song.coverImageUrl?.isNotEmpty == true
                    ? Image.network(
                        song.coverImageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const _SongPlaceholder(),
                      )
                    : const _SongPlaceholder(),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    song.songname ?? AppLocale.text('Без названия', 'Untitled'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
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
                      fontSize: 13,
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
        size: 24,
      ),
    );
  }
}
