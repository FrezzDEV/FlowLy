import 'dart:ui';

class PlayerSheetLayout {
  const PlayerSheetLayout({
    required this.progress,
    required this.screenSize,
    required this.topSafeArea,
    required this.bottomSafeArea,
    this.bottomOffset = 0,
    this.miniHeight = 64,
    this.miniArtworkSize = 48,
    this.expandedArtworkFactor = 0.78,
    this.expandedArtworkMax = 360,
    this.horizontalPadding = 16,
  });

  final double progress;
  final Size screenSize;
  final double topSafeArea;
  final double bottomSafeArea;
  /// Height reserved by Main Bar above the Android gesture/navigation area.
  final double bottomOffset;
  final double miniHeight;
  final double miniArtworkSize;
  final double expandedArtworkFactor;
  final double expandedArtworkMax;
  final double horizontalPadding;

  double get p => progress.clamp(0.0, 1.0).toDouble();

  double lerp(double from, double to) => lerpDouble(from, to, p)!;

  double interval(double begin, double end) {
    if (end <= begin) return 1;
    return ((p - begin) / (end - begin)).clamp(0.0, 1.0);
  }

  double smoothstep(double begin, double end) {
    final t = interval(begin, end);
    return t * t * (3 - (2 * t));
  }

  double get miniOpacity => 1 - smoothstep(0.0, 0.20);

  double get expandedOpacity => smoothstep(0.62, 0.90);

  double get scrimOpacity =>
      lerpDouble(0, 0.34, smoothstep(0.18, 0.78))!;

  double get expandedArtworkSize =>
      (screenSize.width * expandedArtworkFactor)
          .clamp(miniArtworkSize, expandedArtworkMax)
          .toDouble();

  double get artworkSize =>
      lerp(miniArtworkSize, expandedArtworkSize);

  double get expandedArtworkLeft =>
      (screenSize.width - expandedArtworkSize) / 2;

  double get artworkLeft =>
      lerp(horizontalPadding, expandedArtworkLeft);

  double get artworkTop => lerp(
        (miniHeight - miniArtworkSize) / 2,
        topSafeArea + 24,
      );

  double get artworkRadius => lerp(10, 18);

  double get miniBottom =>
      (screenSize.height - bottomSafeArea - bottomOffset)
          .clamp(miniHeight, screenSize.height);

  double get expandedBottom => screenSize.height;

  double get sheetBottom => lerp(
        miniBottom,
        expandedBottom,
      );

  double get sheetTop => lerp(
        miniBottom - miniHeight,
        topSafeArea,
      );

  double get sheetHeight =>
      (sheetBottom - sheetTop).clamp(0.0, screenSize.height);

  double get dragDistance =>
      (miniBottom - miniHeight - topSafeArea)
          .clamp(1.0, screenSize.height);

  double get miniTitleLeft =>
      horizontalPadding + miniArtworkSize + 12;

  double get miniControlsRight => horizontalPadding;

  double get fullContentTop =>
      artworkTop + artworkSize + 18;

  double get progressBottom =>
      bottomSafeArea + 118;

  double get controlsBottom =>
      bottomSafeArea + 28;

  bool get isMini => p <= 0.001;
  bool get isFull => p >= 0.999;
}
