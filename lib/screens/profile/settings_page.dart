import 'package:flutter/material.dart';

import '../../utils/app_locale.dart';
import 'settings_pages.dart';

class SettingsPage extends StatelessWidget {
  final String languageName;
  final VoidCallback? onLanguageChanged;

  const SettingsPage({
    super.key,
    required this.languageName,
    this.onLanguageChanged,
  });

  void _push(BuildContext context, Widget page) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(AppLocale.text('Настройки', 'Settings')),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
        children: [
          _SettingsGroup(
            label: AppLocale.text('АККАУНТ', 'ACCOUNT'),
            children: [
              _SettingsRow(
                icon: Icons.person_outline,
                title: AppLocale.text('Аккаунт', 'Account'),
                subtitle: AppLocale.text('Профиль, подписка, данные', 'Profile, subscription, data'),
                onTap: () => _push(context, const PlaybackSettingsPage()),
              ),
              _SettingsRow(
                icon: Icons.shield_outlined,
                title: AppLocale.text('Безопасность', 'Security'),
                subtitle: AppLocale.text('Пароль, 2FA', 'Password, 2FA'),
              ),
              _SettingsRow(
                icon: Icons.credit_card_outlined,
                title: AppLocale.text('Платежи', 'Payments'),
                subtitle: AppLocale.text('Способы оплаты, история', 'Payment methods, history'),
              ),
            ],
          ),
          const SizedBox(height: 22),
          _SettingsGroup(
            label: AppLocale.text('ПРИЛОЖЕНИЕ', 'APP'),
            children: [
              _SettingsRow(
                icon: Icons.play_circle_outline,
                title: AppLocale.text('Воспроизведение', 'Playback'),
                subtitle: AppLocale.text('Качество, повтор, crossfade, EQ', 'Quality, repeat, crossfade, EQ'),
                onTap: () => _push(context, const PlaybackSettingsPage()),
              ),
              _SettingsRow(
                icon: Icons.file_download_outlined,
                title: AppLocale.text('Скачивание', 'Downloads'),
                subtitle: AppLocale.text('Папка и параметры загрузки', 'Folder and download options'),
                onTap: () => _push(context, const _DownloadFolderPage()),
              ),
              _SettingsRow(
                icon: Icons.notifications_none_outlined,
                title: AppLocale.text('Уведомления', 'Notifications'),
                subtitle: AppLocale.text('Музыка, загрузки и обновления', 'Music, downloads and updates'),
                onTap: () => _push(context, const NotificationSettingsPage()),
              ),
              _SettingsRow(
                icon: Icons.palette_outlined,
                title: AppLocale.text('Внешний вид', 'Appearance'),
                subtitle: AppLocale.text('Тема, цвета, стиль', 'Theme, colors, style'),
              ),
              _SettingsRow(
                icon: Icons.bolt_outlined,
                title: AppLocale.text('Быстрые действия', 'Quick actions'),
                subtitle: AppLocale.text('Жесты и горячие клавиши', 'Gestures and shortcuts'),
                onTap: () => _push(context, const QuickActionsSettingsPage()),
              ),
            ],
          ),
          const SizedBox(height: 22),
          _SettingsGroup(
            label: AppLocale.text('ДРУГОЕ', 'OTHER'),
            children: [
              _SettingsRow(
                icon: Icons.language_outlined,
                title: AppLocale.text('Язык', 'Language'),
                subtitle: languageName,
                onTap: () => _push(context, _LanguageSettingsPage(onChanged: onLanguageChanged)),
              ),
              _SettingsRow(
                icon: Icons.system_update_outlined,
                title: AppLocale.text('Обновления', 'Updates'),
                subtitle: AppLocale.text('Проверка и обновления приложения', 'Check for app updates'),
                onTap: () => _push(context, const _UpdatesSettingsPage()),
              ),
              _SettingsRow(
                icon: Icons.info_outline,
                title: AppLocale.text('О приложении', 'About'),
                subtitle: AppLocale.text('Версия, лицензия', 'Version, licenses'),
              ),
              _SettingsRow(
                icon: Icons.support_agent_outlined,
                title: AppLocale.text('Поддержка', 'Support'),
                subtitle: AppLocale.text('Помощь и обратная связь', 'Help and feedback'),
                onTap: () => _push(context, const SupportSettingsPage()),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  final String label;
  final List<Widget> children;

  const _SettingsGroup({required this.label, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 5, bottom: 8),
          child: Text(label, style: const TextStyle(color: Color(0xFF858585), fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: .4)),
        ),
        Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(color: const Color(0xFF101010), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFF292929))),
          child: Column(children: children),
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

  const _SettingsRow({required this.icon, required this.title, required this.subtitle, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 68),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFF202020)))),
        child: Row(
          children: [
            Container(width: 40, height: 40, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle), child: Icon(icon, color: Colors.black, size: 21)),
            const SizedBox(width: 13),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [Text(title, style: const TextStyle(color: Colors.white, fontSize: 15.5, fontWeight: FontWeight.w700)), const SizedBox(height: 2), Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFF858585), fontSize: 11.5, fontWeight: FontWeight.w500))])),
            if (onTap != null) const Icon(Icons.chevron_right_rounded, color: Color(0xFF666666)),
          ],
        ),
      ),
    );
  }
}

class _LanguageSettingsPage extends StatelessWidget {
  final VoidCallback? onChanged;
  const _LanguageSettingsPage({this.onChanged});
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.black,
    appBar: AppBar(backgroundColor: Colors.black, foregroundColor: Colors.white, title: Text(AppLocale.text('Язык', 'Language'))),
    body: _InfoBody(text: AppLocale.text('Выбор языка доступен в текущем модуле локализации.', 'Language selection is available in the current localization module.')),
  );
}

class _UpdatesSettingsPage extends StatelessWidget {
  const _UpdatesSettingsPage();
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.black,
    appBar: AppBar(backgroundColor: Colors.black, foregroundColor: Colors.white, title: Text(AppLocale.text('Обновления', 'Updates'))),
    body: _InfoBody(text: AppLocale.text('Проверка обновлений будет подключена к release pipeline.', 'Update checks will be connected to the release pipeline.')),
  );
}

class _InfoBody extends StatelessWidget {
  final String text;
  const _InfoBody({required this.text});
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.all(20), child: Text(text, style: const TextStyle(color: Color(0xFF858585), height: 1.35)));
}
