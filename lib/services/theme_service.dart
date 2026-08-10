import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FlowTheme {
  const FlowTheme({
    required this.name,
    required this.accent,
    required this.background,
    required this.surface,
    required this.radius,
    required this.opacity,
    required this.compact,
    required this.animations,
    required this.coverStyle,
  });

  final String name;
  final Color accent;
  final Color background;
  final Color surface;
  final double radius;
  final double opacity;
  final bool compact;
  final bool animations;
  final String coverStyle;

  static const defaultTheme = FlowTheme(
    name: 'FlowLy Dark',
    accent: Colors.white,
    background: Color(0xFF07080D),
    surface: Color(0xFF12141A),
    radius: 20,
    opacity: .92,
    compact: false,
    animations: true,
    coverStyle: 'rounded',
  );

  FlowTheme copyWith({
    String? name,
    Color? accent,
    Color? background,
    Color? surface,
    double? radius,
    double? opacity,
    bool? compact,
    bool? animations,
    String? coverStyle,
  }) => FlowTheme(
    name: name ?? this.name,
    accent: accent ?? this.accent,
    background: background ?? this.background,
    surface: surface ?? this.surface,
    radius: radius ?? this.radius,
    opacity: opacity ?? this.opacity,
    compact: compact ?? this.compact,
    animations: animations ?? this.animations,
    coverStyle: coverStyle ?? this.coverStyle,
  );

  Map<String, dynamic> toJson() => {
    'name': name,
    'accent': accent.value,
    'background': background.value,
    'surface': surface.value,
    'radius': radius,
    'opacity': opacity,
    'compact': compact,
    'animations': animations,
    'coverStyle': coverStyle,
  };

  factory FlowTheme.fromJson(Map<String, dynamic> json) => FlowTheme(
    name: json['name'] as String? ?? 'FlowLy Dark',
    accent: Color((json['accent'] as num?)?.toInt() ?? Colors.white.value),
    background: Color((json['background'] as num?)?.toInt() ?? 0xFF07080D),
    surface: Color((json['surface'] as num?)?.toInt() ?? 0xFF12141A),
    radius: (json['radius'] as num?)?.toDouble() ?? 20,
    opacity: (json['opacity'] as num?)?.toDouble() ?? .92,
    compact: json['compact'] as bool? ?? false,
    animations: json['animations'] as bool? ?? true,
    coverStyle: json['coverStyle'] as String? ?? 'rounded',
  );
}

class ThemeService extends ChangeNotifier {
  ThemeService({this.theme = FlowTheme.defaultTheme});

  FlowTheme theme;
  final List<FlowTheme> presets = [
    FlowTheme.defaultTheme,
    FlowTheme.defaultTheme.copyWith(name: 'Ocean', accent: const Color(0xFFB9E7FF), background: const Color(0xFF061018), surface: const Color(0xFF0D1B24)),
    FlowTheme.defaultTheme.copyWith(name: 'Forest', accent: const Color(0xFFD6F5D1), background: const Color(0xFF07100C), surface: const Color(0xFF102019)),
    FlowTheme.defaultTheme.copyWith(name: 'Sunset', accent: const Color(0xFFFFD6C2), background: const Color(0xFF120A0A), surface: const Color(0xFF211313)),
  ];

  Future<void> load() async {
    final prefs = SharedPreferencesAsync();
    final raw = await prefs.getString('flowly_theme');
    if (raw != null) {
      try {
        theme = FlowTheme.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      } catch (_) {
        theme = FlowTheme.defaultTheme;
      }
    }
    notifyListeners();
  }

  Future<void> apply(FlowTheme value) async {
    theme = value;
    notifyListeners();
    await SharedPreferencesAsync().setString('flowly_theme', jsonEncode(value.toJson()));
  }

  Future<void> reset() => apply(FlowTheme.defaultTheme);
}
