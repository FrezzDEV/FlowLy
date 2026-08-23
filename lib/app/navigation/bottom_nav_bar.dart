import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:line_icons/line_icons.dart';
import 'package:provider/provider.dart';

import '../../features/home/presentation/home_screen.dart';
import '../../features/library/presentation/library.dart';
import '../../features/player/domain/main_controller.dart';
import '../../features/player/infrastructure/notification_player_service.dart';
import '../../features/profile/presentation/profile.dart';
import '../../features/search/presentation/search_page.dart';
import '../../shared/widgets/draggable_view.dart';
import '../../core/gestures/global_gesture_service.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  final PersistentTabController controller = PersistentTabController(initialIndex: 0);
  final GlobalKey<ProfilePageState> _profileKey = GlobalKey<ProfilePageState>();
  final GlobalKey<DraggableViewState> _draggableViewKey = GlobalKey<DraggableViewState>();
  final ValueNotifier<bool> _playerOpen = ValueNotifier<bool>(false);
  MainController? _notificationController;
  bool _notificationsReady = false;
  Offset? _pointerDownPosition;
  bool _horizontalSwipeHandled = false;

  @override
  void dispose() {
    _detachNotificationController();
    _playerOpen.dispose();
    super.dispose();
  }

  void _attachNotificationController(MainController con) {
    if (identical(_notificationController, con)) return;
    _detachNotificationController();
    _notificationController = con;
    con.addListener(_onControllerChanged);
    if (!_notificationsReady) {
      _notificationsReady = true;
      NotificationPlayerService.initialize(con).then((_) => NotificationPlayerService.show(con));
    }
  }

  void _detachNotificationController() {
    _notificationController?.removeListener(_onControllerChanged);
    _notificationController = null;
  }

  void _onControllerChanged() {
    final con = _notificationController;
    if (con != null) NotificationPlayerService.show(con);
  }

  List<PersistentBottomNavBarItem> _navBarsItems() => [
        PersistentBottomNavBarItem(icon: const Icon(Icons.home), inactiveIcon: const Icon(LineIcons.home), activeColorSecondary: Colors.white, activeColorPrimary: Colors.grey),
        PersistentBottomNavBarItem(icon: const Icon(CupertinoIcons.search), inactiveIcon: const Icon(CupertinoIcons.search), activeColorSecondary: Colors.white, activeColorPrimary: Colors.grey),
        PersistentBottomNavBarItem(icon: const _LibraryNavIcon(color: Colors.white), inactiveIcon: const _LibraryNavIcon(color: Color(0xFF8E8E8E)), activeColorSecondary: Colors.white, activeColorPrimary: Colors.grey),
        PersistentBottomNavBarItem(icon: const Icon(CupertinoIcons.person_fill), inactiveIcon: const Icon(CupertinoIcons.person), activeColorSecondary: Colors.white, activeColorPrimary: Colors.grey),
      ];

  List<Widget> _buildScreens(MainController con) => [
        HomeScreen(con: con, onTestPlayerTap: () => _openTestPlayer(con)),
        SearchPage(con: con),
        Library(con: con),
        ProfilePage(key: _profileKey, con: con),
      ];

  Future<void> _openTestPlayer(MainController con) async {
    await con.setPlaylist([
      SongModel(songid: 'flowly-test-song-1', songname: 'Midnight Flow', name: 'FlowLy Test Artist', trackid: 'flowly-test-track-1', duration: '03:42'),
      SongModel(songid: 'flowly-test-song-2', songname: 'Neon Dreams', name: 'FlowLy Test Artist', trackid: 'flowly-test-track-2', duration: '04:08'),
      SongModel(songid: 'flowly-test-song-3', songname: 'Afterglow', name: 'FlowLy Test Artist', trackid: 'flowly-test-track-3', duration: '03:31'),
    ]);
    await con.play();
    await _draggableViewKey.currentState?.open();
  }

  Future<bool> _handleBackButton() async {
    if (_playerOpen.value) {
      await _draggableViewKey.currentState?.close();
      return false;
    }
    return true;
  }

  void _tapNavigation(int index) {
    if (index < 0 || index > 3) return;
    if (controller.index == index) return;
    controller.jumpToTab(index);
    if (index == 3) _profileKey.currentState?.showProfile();
  }

  void _startPointer(PointerDownEvent event) {
    _pointerDownPosition = event.position;
    _horizontalSwipeHandled = false;
  }

  void _updatePointer(PointerMoveEvent event) {
    final start = _pointerDownPosition;
    if (start == null || _horizontalSwipeHandled) return;
    final dx = event.position.dx - start.dx;
    final dy = event.position.dy - start.dy;
    if (dx.abs() < 80 || dx.abs() < dy.abs() * 1.35) return;

    final current = controller.index;
    final nextIndex = dx < 0 ? (current + 1) % 4 : (current - 1 + 4) % 4;
    controller.jumpToTab(nextIndex);
    if (nextIndex == 3) _profileKey.currentState?.showProfile();
    _horizontalSwipeHandled = true;
  }

  void _endPointer(PointerEvent event) {
    _pointerDownPosition = null;
    _horizontalSwipeHandled = false;
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => MainController()..init(),
      child: Consumer<MainController>(
        builder: (context, con, child) {
          GlobalGestureService.attach(con);
          _attachNotificationController(con);
          final safeBottom = MediaQuery.paddingOf(context).bottom;
          return WillPopScope(
            onWillPop: _handleBackButton,
            child: Listener(
              behavior: HitTestBehavior.translucent,
              onPointerDown: _startPointer,
              onPointerMove: _updatePointer,
              onPointerUp: _endPointer,
              onPointerCancel: _endPointer,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  PersistentTabView(
                    context,
                    controller: controller,
                    playWidget: const SizedBox.shrink(),
                    screens: _buildScreens(con),
                    items: _navBarsItems(),
                    onItemSelected: (index) {
                      if (index == 3) _profileKey.currentState?.showProfile();
                    },
                    confineInSafeArea: true,
                    backgroundColor: Colors.black,
                    handleAndroidBackButtonPress: false,
                    hideNavigationBarWhenKeyboardShows: true,
                    resizeToAvoidBottomInset: true,
                    popAllScreensOnTapOfSelectedTab: true,
                    popActionScreens: PopActionScreensType.all,
                    navBarStyle: NavBarStyle.simple,
                    navBarHeight: 64,
                    padding: const NavBarPadding.all(0),
                  ),
                  DraggableView(
                    key: _draggableViewKey,
                    con: con,
                    onOpenStateChanged: (open) => _playerOpen.value = open,
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    height: 55 + safeBottom,
                    child: Row(
                      children: List.generate(
                        4,
                        (index) => Expanded(
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => _tapNavigation(index),
                            child: const SizedBox.expand(),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
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
  Widget build(BuildContext context) => SizedBox(width: 24, height: 24, child: CustomPaint(painter: _LibraryNavPainter(color)));
}

class _LibraryNavPainter extends CustomPainter {
  final Color color;
  const _LibraryNavPainter(this.color);
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color..strokeWidth = 2.6..strokeCap = StrokeCap.round..style = PaintingStyle.stroke;
    final centerY = size.height / 2;
    canvas.drawLine(Offset(3, centerY - 7), Offset(3, centerY + 7), paint);
    canvas.drawLine(Offset(9, centerY - 9), Offset(9, centerY + 8), paint);
    canvas.drawLine(Offset(15, centerY - 6), Offset(15, centerY + 8), paint);
    canvas.drawLine(Offset(20, centerY - 8), Offset(22, centerY + 7), paint);
  }
  @override
  bool shouldRepaint(covariant _LibraryNavPainter oldDelegate) => oldDelegate.color != color;
}
