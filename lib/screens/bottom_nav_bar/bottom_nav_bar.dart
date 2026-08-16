import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:line_icons/line_icons.dart';
import 'package:provider/provider.dart';
import 'package:flowly/utils/bottom_nav_bar/persistent-tab-view.dart';

import '../../controllers/main_controller.dart';
import '../../features/mini_player/player_sheet.dart';
import '../../models/song_model.dart';
import '../../services/global_gesture_service.dart';
import '../../services/settings_service.dart';
import '../../utils/app_locale.dart';
import '../../utils/botttom_sheet_widget.dart';
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
  static const double _navBarHeight = 64;

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

  void _handleMainMenuSwipeEnd(DragEndDetails details) {
    if (!SettingsService.swipeNavigationEnabled) return;
    final velocity = details.primaryVelocity;
    if (velocity == null || velocity.abs() < 260) return;

    final current = controller.index;
    final nextIndex = velocity < 0
        ? (current + 1) % 4
        : (current - 1 + 4) % 4;
    controller.jumpToTab(nextIndex);
    if (nextIndex == 3) {
      _profileKey.currentState?.showProfile();
    }
  }

  void _showUnavailable(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _openMore(BuildContext context, MainController con, SongModel song) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.black,
      builder: (_) => BottomSheetWidget(
        con: con,
        isNext: true,
        song: song,
      ),
    );
  }

  void _toggleFavorite(MainController con, SongModel song) {
    if (song.trackid == null || song.trackid!.isEmpty) return;
    con.addToFavorite(
      name: song.songname ?? '',
      fullname: song.name ?? '',
      username: song.userid ?? '',
      cover: song.coverImageUrl ?? '',
      track: song.trackid ?? '',
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MainController()..init(),
      child: Consumer<MainController>(
        builder: (context, con, child) {
          GlobalGestureService.attach(con);
          final song = con.currentSong;
          final coverUrl = song?.coverImageUrl;

          return GestureDetector(
            behavior: HitTestBehavior.translucent,
            onHorizontalDragEnd: _handleMainMenuSwipeEnd,
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
                  navBarHeight: _navBarHeight,
                  padding: const NavBarPadding.all(0),
                ),
                if (song != null &&
                    coverUrl != null &&
                    coverUrl.isNotEmpty)
                  PlayerSheet(
                    cover: NetworkImage(coverUrl),
                    title: song.songname ?? 'FlowLy',
                    artist: song.name ?? song.userid,
                    isPlaying: con.isPlaying,
                    isLiked: false,
                    bottomOffset: _navBarHeight,
                    progressValue: con.duration.inMilliseconds > 0
                        ? (con.position.inMilliseconds /
                                con.duration.inMilliseconds)
                            .clamp(0.0, 1.0)
                        : 0,
                    position: con.position,
                    duration: con.duration,
                    onPlayPause: con.playOrPause,
                    onPrevious: con.songs.length > 1 ? con.previous : null,
                    onNext: con.songs.length > 1 ? con.next : null,
                    onSeek: con.seek,
                    onLike: () => _toggleFavorite(
                      con,
                      SongModel(
                        songid: song.songid,
                        songname: song.songname,
                        userid: song.userid,
                        trackid: song.trackid,
                        duration: song.duration,
                        coverImageUrl: song.coverImageUrl,
                        name: song.name,
                      ),
                    ),
                    onComment: () => _showUnavailable(
                      context,
                      AppLocale.text(
                        'Комментарии пока недоступны',
                        'Comments are not available yet',
                      ),
                    ),
                    onDownload: () => _showUnavailable(
                      context,
                      AppLocale.text(
                        'Скачивание временно отключено',
                        'Downloads are temporarily disabled',
                      ),
                    ),
                    onMore: () => _openMore(
                      context,
                      con,
                      SongModel(
                        songid: song.songid,
                        songname: song.songname,
                        userid: song.userid,
                        trackid: song.trackid,
                        duration: song.duration,
                        coverImageUrl: song.coverImageUrl,
                        name: song.name,
                      ),
                    ),
                    onUpNext: () => _openMore(
                      context,
                      con,
                      SongModel(
                        songid: song.songid,
                        songname: song.songname,
                        userid: song.userid,
                        trackid: song.trackid,
                        duration: song.duration,
                        coverImageUrl: song.coverImageUrl,
                        name: song.name,
                      ),
                    ),
                    onLyrics: () => _showUnavailable(
                      context,
                      AppLocale.text(
                        'Текст песни пока недоступен',
                        'Lyrics are not available yet',
                      ),
                    ),
                    onRelated: () => _showUnavailable(
                      context,
                      AppLocale.text(
                        'Похожие треки пока недоступны',
                        'Related tracks are not available yet',
                      ),
                    ),
                  ),
              ],
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
