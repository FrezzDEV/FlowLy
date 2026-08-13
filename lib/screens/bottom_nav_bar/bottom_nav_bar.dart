import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:line_icons/line_icons.dart';
import 'package:provider/provider.dart';
import 'package:flowly/utils/bottom_nav_bar/persistent-tab-view.dart';

import '../../controllers/main_controller.dart';
import '../../utils/bottom_nav_bar/persistent-tab-view.widget.dart';
import '../../utils/bottom_play_widget.dart';
import '../current_playing/current_playing_song.dart';
import '../home/home_screen.dart';
import '../library/library.dart';
import '../profile/profile.dart';
import '../search_page/search_page.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  final PersistentTabController controller =
      PersistentTabController(initialIndex: 0);
  final GlobalKey<ProfilePageState> _profileKey =
      GlobalKey<ProfilePageState>();

  List<PersistentBottomNavBarItem> _navBarsItems() {
    return [
      PersistentBottomNavBarItem(
        icon: const Icon(Icons.home),
        inactiveIcon: const Icon(LineIcons.home),
        activeColorSecondary: Colors.white,
        activeColorPrimary: Colors.grey,
      ),
      PersistentBottomNavBarItem(
        icon: const Icon(CupertinoIcons.search),
        inactiveIcon: const Icon(CupertinoIcons.search),
        activeColorSecondary: Colors.white,
        activeColorPrimary: Colors.grey,
      ),
      PersistentBottomNavBarItem(
        icon: const _LibraryNavIcon(color: Colors.white),
        inactiveIcon: const _LibraryNavIcon(color: Color(0xFF8E8E8E)),
        activeColorSecondary: Colors.white,
        activeColorPrimary: Colors.grey,
      ),
      PersistentBottomNavBarItem(
        icon: const Icon(CupertinoIcons.person_fill),
        inactiveIcon: const Icon(CupertinoIcons.person),
        activeColorSecondary: Colors.white,
        activeColorPrimary: Colors.grey,
      ),
    ];
  }

  List<Widget> _buildScreens(MainController con) {
    return [
      HomeScreen(con: con),
      SearchPage(con: con),
      Library(con: con),
      ProfilePage(key: _profileKey, con: con),
    ];
  }

  Future<void> _openPlayer(MainController con) {
    return PlayerRoute.open(context, con);
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MainController()..init(),
      child: Consumer<MainController>(
        builder: (context, con, child) {
          return ValueListenableBuilder<bool>(
            valueListenable: PlayerRoute.isOpenNotifier,
            builder: (context, playerOpen, _) {
              return PersistentTabView(
                context,
                controller: controller,
                playWidget: playerOpen
                    ? const SizedBox.shrink()
                    : Material(
                        color: Colors.black,
                        child: PlayWidget(
                          con: con,
                          onTap: () => _openPlayer(con),
                        ),
                      ),
                screens: _buildScreens(con),
                items: _navBarsItems(),
                onItemSelected: (index) {
                  if (index == 3) {
                    _profileKey.currentState?.showProfile();
                  }
                },
                confineInSafeArea: true,
                backgroundColor: Colors.black,
                handleAndroidBackButtonPress: true,
                hideNavigationBarWhenKeyboardShows: true,
                resizeToAvoidBottomInset: true,
                popAllScreensOnTapOfSelectedTab: true,
                popActionScreens: PopActionScreensType.all,
                navBarStyle: NavBarStyle.simple,
                navBarHeight: 64,
                padding: const NavBarPadding.all(0),
              );
            },
          );
        },
      ),
    );
  }
}

class _LibraryNavIcon extends StatelessWidget {
  final Color color;

  const _LibraryNavIcon({required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 24,
      height: 24,
      child: CustomPaint(painter: _LibraryNavPainter(color)),
    );
  }
}

class _LibraryNavPainter extends CustomPainter {
  final Color color;

  const _LibraryNavPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final centerY = size.height / 2;
    canvas.drawLine(Offset(3, centerY - 7), Offset(3, centerY + 7), paint);
    canvas.drawLine(Offset(9, centerY - 9), Offset(9, centerY + 8), paint);
    canvas.drawLine(Offset(15, centerY - 6), Offset(15, centerY + 8), paint);
    canvas.drawLine(Offset(20, centerY - 8), Offset(22, centerY + 7), paint);
  }

  @override
  bool shouldRepaint(covariant _LibraryNavPainter oldDelegate) =>
      oldDelegate.color != color;
}
