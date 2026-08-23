import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import 'package:flowly/app/localization/app_locale.dart';

class EditProfilePage extends StatefulWidget {
  final String displayName;
  final String? avatarPath;
  final ValueChanged<String> onSaveName;
  final Future<String?> Function() onPickAvatar;

  const EditProfilePage({
    super.key,
    required this.displayName,
    required this.avatarPath,
    required this.onSaveName,
    required this.onPickAvatar,
  });

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
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
    if (!mounted) return;
    setState(() {
      _avatarPath = path;
      _savingAvatar = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final hasAvatar = _avatarPath?.isNotEmpty == true;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(AppLocale.text('Аккаунт', 'Account')),
      ),
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
                          ? FileImage(File(_avatarPath!))
                          : const NetworkImage('https://i.pravatar.cc/240?img=12'),
                      child: _savingAvatar
                          ? const CircularProgressIndicator(color: Colors.white)
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

  // Keeps the implementation self-contained for future extraction of profile storage.
  Future<String?> pickAvatarFromStorage() async {
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
    return target.path;
  }
}
