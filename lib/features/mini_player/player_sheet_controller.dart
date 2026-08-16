import 'dart:math' as math;

import 'package:flutter/foundation.dart';

class PlayerSheetController extends ChangeNotifier {
  PlayerSheetController({
    this.expandThreshold = 0.5,
    this.velocityThreshold = 900,
  });

  final double expandThreshold;
  final double velocityThreshold;

  double _progress = 0;
  double _dragStartY = 0;
  double _dragStartProgress = 0;
  bool _dragging = false;
  bool _disposed = false;

  double get progress => _progress;
  bool get isDragging => _dragging;
  bool get isExpanded => _progress >= 0.999;

  void beginDrag(double globalY) {
    _dragging = true;
    _dragStartY = globalY;
    _dragStartProgress = _progress;
  }

  void updateDrag({
    required double globalY,
    required double availableHeight,
  }) {
    if (!_dragging || availableHeight <= 0) return;
    final delta = _dragStartY - globalY;
    setProgress(_dragStartProgress + (delta / availableHeight));
  }

  bool endDrag({required double velocityY}) {
    if (!_dragging) return false;
    _dragging = false;

    final fastUp = velocityY < -velocityThreshold;
    final fastDown = velocityY > velocityThreshold;

    final targetExpanded = fastUp ||
        (!fastDown && _progress >= expandThreshold);

    notifyListeners();
    return targetExpanded;
  }

  void setProgress(double value) {
    final next = value.clamp(0.0, 1.0).toDouble();
    if ((next - _progress).abs() < 0.0005) return;
    _progress = next;
    _notifyIfAlive();
  }

  void reset() {
    _progress = 0;
    _dragging = false;
    _notifyIfAlive();
  }

  double interval(double begin, double end) {
    if (end <= begin) return 1;
    return ((_progress - begin) / (end - begin)).clamp(0.0, 1.0);
  }

  double fadeOut(double begin, double end) => 1 - interval(begin, end);

  double fadeIn(double begin, double end) => interval(begin, end);

  double lerp(double from, double to) {
    return from + ((to - from) * _progress);
  }

  double lerpCurve(
    double from,
    double to, {
    Curve curve = Curves.easeOutCubic,
  }) {
    return from + ((to - from) * curve.transform(_progress));
  }

  double get dragResistance {
    if (_progress <= 0 || _progress >= 1) return 0;
    return math.min(1, (_progress - 0.5).abs() * 2);
  }

  void _notifyIfAlive() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
