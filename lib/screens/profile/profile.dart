import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  ProfilePageState createState() => ProfilePageState();
}

class ProfilePageState extends State<ProfilePage> {
  bool _showSettings = false;
  String? _avatarPath;

  @override
  void initState() {
    super.initState();
    _loadAvatar();
  }

  void showProfile() {
    if (_showSettings) {
      setState(() => _showSettings = false);
    }
  }

  Future<void> _loadAvatar() async {
    final path = Hive.box('profile').get('avatarPath') as String?;
    if (path != null && await File(path).exists()) {
      if (mounted) setState(() => _avatarPath = path);
    }
  }

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: _showSettings
            ? _SettingsView(
                onBack: () => setState(() => _showSettings = false),
              )
            : Column(
                children: [
                  _ProfileHeader(
                    onSettings: () => setState(() => _showSettings = true),
                  ),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
                      children: [
                        Center(
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              CircleAvatar(
                                radius: 52,
                                backgroundColor: const Color(0xFF202020),
                                backgroundImage: _avatarPath == null
                                    ? const NetworkImage(
                                        'https://i.pravatar.cc/200?img=12',
                                      )
                                    : FileImage(File(_avatarPath!))
                                        as ImageProvider,
                              ),
                              Positioned(
                                right: -2,
                                bottom: -2,
                                child: Material(
                                  color: Colors.white,
                                  shape: const CircleBorder(),
                                  child: InkWell(
                                    customBorder: const CircleBorder(),
                                    onTap: _pickAvatar,
                                    child: const SizedBox(
                                      width: 36,
                                      height: 36,
                                      child: Icon(
                                        Icons.edit_outlined,
                                        color: Colors.black,
                                        size: 19,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        const Center(
                          child: Text(
                            'FlowLy User',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                            ),
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

class _ProfileHeader extends StatelessWidget {
  final VoidCallback onSettings;

  const _ProfileHeader({required this.onSettings});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 14, 10),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Profile',
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                height: 1.0,
                fontWeight: FontWeight.w800,
                letterSpacing: -1.0,
              ),
            ),
          ),
          IconButton(
            onPressed: onSettings,
            tooltip: 'Settings',
            icon: const Icon(
              Icons.settings_outlined,
              color: Colors.white,
              size: 28,
            ),
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
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      children: [
        Row(
          children: [
            IconButton(
              onPressed: onBack,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              icon: const Icon(
                Icons.arrow_back_ios_new,
                color: Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(width: 16),
            const Text(
              'Настройки',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                height: 1.0,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.7,
              ),
            ),
          ],
        ),
        const SizedBox(height: 30),
        const _SettingsSectionLabel('АККАУНТ'),
        const SizedBox(height: 10),
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
        const SizedBox(height: 28),
        const _SettingsSectionLabel('ПРИЛОЖЕНИЕ'),
        const SizedBox(height: 10),
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
              icon: Icons.notifications_none,
              title: 'Уведомления',
              subtitle: 'Только важные',
            ),
            _SettingsRow(
              icon: Icons.palette_outlined,
              title: 'Внешний вид',
              subtitle: 'Тема, цвета, стиль',
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
        const SizedBox(height: 28),
        const _SettingsSectionLabel('ДРУГОЕ'),
        const SizedBox(height: 10),
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
          fontSize: 14,
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
        borderRadius: BorderRadius.circular(18),
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
      constraints: const BoxConstraints(minHeight: 82),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFF202020))),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: iconBackground,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: titleColor,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 1),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Color(0xFF858585),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (showChevron)
            const Icon(
              Icons.chevron_right,
              color: Color(0xFF858585),
              size: 26,
            ),
        ],
      ),
    );
  }
}
