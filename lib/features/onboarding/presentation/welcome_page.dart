import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:flowly/app/localization/app_locale.dart';
import 'package:flowly/features/settings/presentation/settings_pages.dart';
import 'package:flowly/features/player/domain/main_controller.dart';

class WelcomePage extends StatefulWidget {
  final MainController controller;
  final VoidCallback onFinished;

  const WelcomePage({super.key, required this.controller, required this.onFinished});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  bool _showLanguage = false;

  Future<void> _finish() async {
    await Hive.box('profile').put('has_seen_welcome', true);
    if (mounted) widget.onFinished();
  }

  @override
  Widget build(BuildContext context) {
    final title = AppLocale.translate({'ru': 'Добро пожаловать в FlowLy', 'en': 'Welcome to FlowLy', 'es': 'Bienvenido a FlowLy', 'de': 'Willkommen bei FlowLy', 'fr': 'Bienvenue sur FlowLy', 'tr': "FlowLy'ye hoş geldiniz"});
    final body = AppLocale.translate({'ru': 'Музыка, плеер и библиотека — в одном месте.', 'en': 'Music, player and library — all in one place.', 'es': 'Música, reproductor y biblioteca — todo en un solo lugar.', 'de': 'Musik, Player und Bibliothek — alles an einem Ort.', 'fr': 'Musique, lecteur et bibliothèque — tout au même endroit.', 'tr': 'Müzik, oynatıcı ve kitaplık — hepsi tek yerde.'});
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 26, 28, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),
              Container(width: 72, height: 72, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)), child: const Icon(Icons.graphic_eq, color: Colors.black, size: 40)),
              const SizedBox(height: 28),
              Text(title, style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              Text(body, style: const TextStyle(color: Color(0xFF9B9B9B), fontSize: 17, height: 1.4)),
              const SizedBox(height: 26),
              _WelcomeFeature(icon: Icons.play_circle_outline, text: AppLocale.translate({'ru': 'Полноценный плеер', 'en': 'Full player', 'es': 'Reproductor completo', 'de': 'Vollständiger Player', 'fr': 'Lecteur complet', 'tr': 'Tam oynatıcı'})),
              _WelcomeFeature(icon: Icons.library_music_outlined, text: AppLocale.translate({'ru': 'Библиотека и загрузки', 'en': 'Library and downloads', 'es': 'Biblioteca y descargas', 'de': 'Bibliothek und Downloads', 'fr': 'Bibliothèque et téléchargements', 'tr': 'Kitaplık ve indirmeler'})),
              _WelcomeFeature(icon: Icons.notifications_none_outlined, text: AppLocale.translate({'ru': 'Фоновое воспроизведение', 'en': 'Background playback', 'es': 'Reproducción en segundo plano', 'de': 'Hintergrundwiedergabe', 'fr': 'Lecture en arrière-plan', 'tr': 'Arka planda oynatma'})),
              const Spacer(),
              OutlinedButton.icon(onPressed: () => setState(() => _showLanguage = !_showLanguage), icon: const Icon(Icons.language, color: Colors.white), label: Text(AppLocale.languageName, style: const TextStyle(color: Colors.white)), style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48), side: const BorderSide(color: Color(0xFF333333)))),
              if (_showLanguage) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: const Color(0xFF111111), borderRadius: BorderRadius.circular(14)),
                  child: Wrap(spacing: 8, children: AppLocale.supportedLanguageCodes.map((code) => ChoiceChip(label: Text(AppLocale.languageLabel(code)), selected: AppLocale.language.value == code, onSelected: (_) async { await AppLocale.setLanguage(code); if (mounted) setState(() {}); })).toList()),
                ),
              ],
              const SizedBox(height: 12),
              FilledButton(onPressed: _finish, style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black, minimumSize: const Size.fromHeight(54)), child: Text(AppLocale.translate({'ru': 'Начать', 'en': 'Get started', 'es': 'Comenzar', 'de': 'Starten', 'fr': 'Commencer', 'tr': 'Başla'}))),
              const SizedBox(height: 10),
              TextButton.icon(onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const DownloadSettingsPage())), icon: const Icon(Icons.download_outlined, color: Color(0xFF9B9B9B)), label: Text(AppLocale.translate({'ru': 'Открыть загрузки', 'en': 'Open downloads', 'es': 'Abrir descargas', 'de': 'Downloads öffnen', 'fr': 'Ouvrir les téléchargements', 'tr': 'İndirmeleri aç'}), style: const TextStyle(color: Color(0xFF9B9B9B))))),
            ],
          ),
        ),
      ),
    );
  }
}

class _WelcomeFeature extends StatelessWidget {
  final IconData icon;
  final String text;
  const _WelcomeFeature({required this.icon, required this.text});
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: 12), child: Row(children: [Icon(icon, color: Colors.white, size: 22), const SizedBox(width: 12), Expanded(child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 15)))]));
}
