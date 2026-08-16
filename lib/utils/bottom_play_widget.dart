import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../controllers/main_controller.dart';
import '../utils/app_locale.dart';
import 'botttom_sheet_widget.dart';
import 'loading.dart';
import 'player/position_seek_widget.dart';

/// Single global player surface.
///
/// Progress 0 = mini-player above the main navigation bar.
/// Progress 1 = full-screen player. The same widget instance is used for both
/// states, so no Navigator route is pushed when opening the player.
class BottomPlayWidget extends StatefulWidget {
  const BottomPlayWidget({
    super.key,
    required this.con,
    this.navBarHeight = 64,
  });

  final MainController con;
  final double navBarHeight;

  @override
  State<BottomPlayWidget> createState() => BottomPlayWidgetState();
}

class BottomPlayWidgetState extends State<BottomPlayWidget>
    with SingleTickerProviderStateMixin {
  static const double _miniHeight = 64;
  static const double _snapThreshold = 0.15;

  late final AnimationController _progress;
  bool _dragging = false;

  MainController get con => widget.con;

  @override
  void initState() {
    super.initState();
    _progress = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      lowerBound: 0,
      upperBound: 1,
      value: 0,
    );
  }

  void expand() {
    if (!mounted || con.currentSong == null) return;
    _progress.animateTo(1, curve: Curves.easeOutCubic);
  }

  void collapse() {
    if (!mounted) return;
    _progress.animateTo(0, curve: Curves.easeOutCubic);
  }

  void _onDragStart(DragStartDetails details) {
    _progress.stop();
    _dragging = true;
  }

  void _onDragUpdate(DragUpdateDetails details, double travel) {
    if (!_dragging || travel <= 0) return;
    final delta = details.primaryDelta ?? 0;
    _progress.value = (_progress.value - (delta / travel)).clamp(0.0, 1.0);
  }

  void _onDragEnd(DragEndDetails details) {
    if (!_dragging) return;
    _dragging = false;

    final velocity = details.primaryVelocity ?? 0;
    final fastUp = velocity < -700;
    final fastDown = velocity > 700;

    final target = fastUp
        ? 1.0
        : fastDown
            ? 0.0
            : _progress.value >= _snapThreshold
                ? 1.0
                : 0.0;

    _progress.animateTo(target, curve: Curves.easeOutCubic);
  }

  @override
  void dispose() {
    _progress.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Existing implementation continues below.
    return const SizedBox.shrink();
  }
}
