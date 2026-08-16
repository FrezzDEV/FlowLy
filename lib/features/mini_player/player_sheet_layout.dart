import 'dart:ui';

class PlayerSheetLayout {
  const PlayerSheetLayout({
    required this.progress,
    required this.screenSize,
    required this.topSafeArea,
    required this.bottomSafeArea,
    this.bottomOffset = 0,
    this.miniHeight = 72,
    this.miniArtworkSize = 48,
    this.expandedArtworkFactor = 0.78,
    this.horizontalPadding = 16,
  });

  final double progress;
  final Size screenSize;
  final double topSafeArea;
  final double bottomSafeArea;
  final double bottomOffset;
  final double miniHeight;
  final double miniArtworkSize;
  final double expandedArtworkFactor;
  final double horizontalPadding;

  double get p => progress.clamp(0.0, 1.0).toDouble();

  double lerp(double from, double to) => lerpDouble(from, to, p)!;

  double interval(double begin, double end) {
    if (end <= begin) return 1;
    return ((p - begin) / (end - begin)).clamp(0.0, 1.0);
  }

  double get miniOpacity => 1 - interval(0.0, 0.2);
  double get expandedOpacity => interval(0.8, 1.0);

  double get expandedArtworkSize => screenSize.width * expandedArtworkFactor;

  double get artworkSize => lerp(miniArtworkSize, expandedArtworkSize);

  double get expandedArtworkLeft =>
      (screenSize.width - expandedArtworkSize) / 2;

  double get artworkLeft => lerp(horizontalPadding, expandedArtworkLeft);

  double get artworkTop => lerp(
        (miniHeight - miniArtworkSize) / 2,
        topSafeArea + 20,
      );

  double get artworkRadius => lerp(10, 18);

  double get availableHeight =>
      (screenSize.height - bottomOffset).clamp(0.0, screenSize.height);

  double get sheetHeight => lerp(miniHeight, availableHeight);

  double get sheetTop => screenSize.height - bottomOffset - sheetHeight;

  double get miniTitleLeft => horizontalPadding + miniArtworkSize + 12;

  double get miniControlsRight => horizontalPadding;

  double get fullContentTop => artworkTop + artworkSize + 18;

  double get actionRowTop => fullContentTop + 92;

  double get progressBottom => bottomSafeArea + 118;

  double get controlsBottom => bottomSafeArea + 28;

  double get scrimOpacity => interval(0.35, 0.85) * 0.28;
}
