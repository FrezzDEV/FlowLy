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
  ProfilePageState createState() => ProfilePageState();
}

class ProfilePageState extends State<ProfilePage> {
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

  String _languageName() => AppLocale.isEnglish ? 'English' : 'Русский';

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
