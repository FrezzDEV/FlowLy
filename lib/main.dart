import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:path_provider/path_provider.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:flowly/screens/bottom_nav_bar/bottom_nav_bar.dart';
import 'package:flowly/screens/welcome/welcome_page.dart';

import 'controllers/main_controller.dart';
import 'services/crash_reporting_service.dart';
import 'services/settings_service.dart';
import 'utils/app_locale.dart';

Future<void> main() async {
  await CrashReportingService.run(_bootstrap);
}

Future<void> _bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.flowly.audio.playback',
    androidNotificationChannelName: 'FlowLy — Воспроизведение',
    androidNotificationChannelDescription: 'Управление воспроизведением FlowLy',
    androidNotificationOngoing: true,
  );

  final dir = await getApplicationDocumentsDirectory();
  await Hive.initFlutter(dir.path);
  await Hive.openBox('liked');
  await Hive.openBox('Recentsearch');
  await Hive.openBox('RecentlyPlayed');
  await Hive.openBox('playlists');
  await Hive.openBox('profile');
  await Hive.openBox('downloads');
  await Hive.openBox('app_settings');
  await SettingsService.init();
  await AppLocale.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  bool _needsWelcome() {
    return Hive.box('profile').get('has_seen_welcome', defaultValue: false) != true;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: AppLocale.language,
      builder: (context, language, _) {
        return MaterialApp(
          title: 'FlowLy',
          locale: Locale(language),
          supportedLocales: const [
            Locale('ru'),
            Locale('en'),
            Locale('es'),
            Locale('de'),
            Locale('fr'),
            Locale('tr'),
          ],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            fontFamily: 'Proxima',
            canvasColor: Colors.transparent,
            shadowColor: Colors.transparent,
            highlightColor: Colors.transparent,
            scaffoldBackgroundColor: Colors.black,
            splashColor: Colors.transparent,
            hoverColor: Colors.transparent,
            colorScheme: const ColorScheme.dark(
              surface: Colors.black,
              primary: Colors.white,
              onPrimary: Colors.black,
              secondary: Colors.white,
              onSecondary: Colors.black,
            ),
            progressIndicatorTheme: const ProgressIndicatorThemeData(
              circularTrackColor: Color(0xFF2A2A2A),
              color: Colors.white,
              linearMinHeight: 10,
            ),
            textTheme: const TextTheme(
              headlineMedium: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontFamily: 'Proxima Bold',
                fontWeight: FontWeight.w600,
              ),
              bodyLarge: TextStyle(
                fontSize: 16,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          builder: (context, child) {
            final mediaQuery = MediaQuery.of(context);
            return MediaQuery(
              data: mediaQuery.copyWith(
                textScaler: const TextScaler.linear(1.0),
              ),
              child: ScrollConfiguration(
                behavior: const ScrollBehavior().copyWith(overscroll: false),
                child: child ?? const SizedBox.shrink(),
              ),
            );
          },
          home: _needsWelcome() ? _WelcomeHost() : const App(),
        );
      },
    );
  }
}

class _WelcomeHost extends StatefulWidget {
  @override
  State<_WelcomeHost> createState() => _WelcomeHostState();
}

class _WelcomeHostState extends State<_WelcomeHost> {
  late final MainController _controller;

  @override
  void initState() {
    super.initState();
    _controller = MainController()..init();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (Hive.box('profile').get('has_seen_welcome', defaultValue: false) == true) {
      return const App();
    }
    return WelcomePage(
      controller: _controller,
      onFinished: () => setState(() {}),
    );
  }
}
