import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image_picker/image_picker.dart';

import 'package:flowly/app/localization/app_locale.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  String? _avatarPath;
  String _displayName = 'Алекс';
  bool _savingAvatar = false;

  @override
  void initState() {
    super.initState();
    final box = Hive.box('profile');
    _avatarPath = box.get('avatarPath') as String?;
    _displayName = box.get('displayName', defaultValue: 'Алекс') as String;
  }

  bool get hasAvatar => _avatarPath != null && _avatarPath!.isNotEmpty;

  Future<void> _changeAvatar() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked == null || !mounted) return;
    setState(() => _savingAvatar = true);
    await Hive.box('profile').put('avatarPath', picked.path);
    if (mounted) setState(() { _avatarPath = picked.path; _savingAvatar = false; });
  }

  Future<void> _saveName() async {
    await Hive.box('profile').put('displayName', _displayName.trim().isEmpty ? 'Алекс' : _displayName.trim());
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: Colors.black, foregroundColor: Colors.white, title: Text(AppLocale.text('Аккаунт', 'Account'))),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
          children: [
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
                          ? (FileImage(File(_avatarPath!)) as ImageProvider<Object>)
                          : const NetworkImage('https://i.pravatar.cc/240?img=12') as ImageProvider<Object>,
                      child: _savingAvatar ? const CircularProgressIndicator(color: Colors.white) : null,
                    ),
                    Positioned(right: 0, bottom: 0, child: Container(width: 40, height: 40, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle), child: const Icon(Icons.edit, color: Colors.black))),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),
            TextField(
              controller: TextEditingController(text: _displayName),
              onChanged: (value) => _displayName = value,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(labelText: AppLocale.text('Имя', 'Name'), labelStyle: const TextStyle(color: Colors.grey), enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey)), focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white))),
            ),
            const SizedBox(height: 28),
            FilledButton(onPressed: _saveName, style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black, minimumSize: const Size.fromHeight(50)), child: Text(AppLocale.text('Сохранить', 'Save'))),
          ],
        ),
      ),
    );
  }
}
