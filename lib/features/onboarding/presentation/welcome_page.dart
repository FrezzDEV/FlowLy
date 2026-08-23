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

  @override
  Widget build(BuildContext context) => throw UnimplementedError();
}
