import 'package:flutter/material.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _showSettings = false;

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
                        const Center(
                          child: CircleAvatar(
                            radius: 52,
                            backgroundImage: NetworkImage(
                              'https://i.pravatar.cc/200?img=12',
                            ),
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
                        const SizedBox(height: 28),
                        _ProfileTile(
                          icon: Icons.palette_outlined,
                          title: 'Themes',
                          subtitle: 'Customize your FlowLy look',
                          onTap: () {},
                        ),
                        _ProfileTile(
                          icon: Icons.settings_outlined,
                          title: 'Settings',
                          subtitle: 'Playback, privacy and preferences',
                          onTap: () => setState(() => _showSettings = true),
                        ),
                        _ProfileTile(
                          icon: Icons.notifications_none,
                          title: 'Notifications',
                          subtitle: 'Manage your alerts',
                          onTap: () {},
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

class _ProfileTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ProfileTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 4),
      leading: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: const Color(0xFF181818),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: Colors.white),
      ),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      subtitle: Text(subtitle, style: const TextStyle(color: Colors.grey)),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    );
  }
}

class _SettingsView extends StatelessWidget {
  final VoidCallback onBack;

  const _SettingsView({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
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
                size: 24,
              ),
            ),
            const SizedBox(width: 18),
            const Text(
              'Настройки',
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                height: 1.0,
                fontWeight: FontWeight.w800,
                letterSpacing: -1.0,
              ),
            ),
          ],
        ),
        const SizedBox(height: 38),
        const _SettingsSectionLabel('АККАУНТ'),
        const SizedBox(height: 14),
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
        const SizedBox(height: 40),
        const _SettingsSectionLabel('ПРИЛОЖЕНИЕ'),
        const SizedBox(height: 14),
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
        const SizedBox(height: 40),
        const _SettingsSectionLabel('ДРУГОЕ'),
        const SizedBox(height: 14),
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
          fontSize: 16,
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
        borderRadius: BorderRadius.circular(22),
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
      constraints: const BoxConstraints(minHeight: 112),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFF202020))),
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: iconBackground,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 31),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: titleColor,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFF858585),
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (showChevron)
            const Icon(
              Icons.chevron_right,
              color: Color(0xFF858585),
              size: 31,
            ),
        ],
      ),
    );
  }
}
