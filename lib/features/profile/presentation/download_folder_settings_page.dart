import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flowly/app/localization/app_locale.dart';

class DownloadFolderSettingsPage extends StatefulWidget {
  const DownloadFolderSettingsPage({super.key});
  @override
  State<DownloadFolderSettingsPage> createState() => _DownloadFolderSettingsPageState();
}

class _DownloadFolderSettingsPageState extends State<DownloadFolderSettingsPage> {
  String? path;
  Box<dynamic> get box => Hive.box('profile');
  @override
  void initState() { super.initState(); path = box.get('downloadDirectory') as String?; }
  Future<void> pick() async {
    final selected = await FilePicker.getDirectoryPath(dialogTitle: AppLocale.text('Выберите папку для загрузок', 'Choose download folder'));
    if (selected == null || selected.isEmpty) return;
    await box.put('downloadDirectory', selected);
    if (mounted) setState(() => path = selected);
  }
  Future<void> clear() async { await box.delete('downloadDirectory'); if (mounted) setState(() => path = null); }
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.black,
    appBar: AppBar(backgroundColor: Colors.black, foregroundColor: Colors.white, title: Text(AppLocale.text('Папка загрузок', 'Download folder'))),
    body: ListView(padding: const EdgeInsets.all(20), children: [
      Text(path ?? AppLocale.text('Память приложения по умолчанию', 'App storage by default'), style: const TextStyle(color: Color(0xFF858585))),
      const SizedBox(height: 16),
      FilledButton.icon(onPressed: pick, icon: const Icon(Icons.folder_open), label: Text(AppLocale.text('Выбрать папку', 'Choose folder')), style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black)),
      if (path != null) OutlinedButton.icon(onPressed: clear, icon: const Icon(Icons.restore), label: Text(AppLocale.text('Вернуть по умолчанию', 'Use default folder')), style: OutlinedButton.styleFrom(foregroundColor: Colors.white)),
    ]),
  );
}
