import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../shared/data/hive_persistence_service.dart';
import '../../features/deck/presentation/providers/deck_notifier.dart';

class ThemeState {
  final ThemeMode themeMode;
  final Color accentColor;

  const ThemeState({
    required this.themeMode,
    required this.accentColor,
  });

  ThemeState copyWith({
    ThemeMode? themeMode,
    Color? accentColor,
  }) {
    return ThemeState(
      themeMode: themeMode ?? this.themeMode,
      accentColor: accentColor ?? this.accentColor,
    );
  }
}

class ThemeNotifier extends StateNotifier<ThemeState> {
  final HivePersistenceService _persistenceService;

  ThemeNotifier(this._persistenceService)
      : super(ThemeState(
          themeMode: _loadThemeMode(_persistenceService),
          accentColor: _loadAccentColor(_persistenceService),
        ));

  static ThemeMode _loadThemeMode(HivePersistenceService service) {
    final modeStr = service.getThemeMode();
    switch (modeStr) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  static Color _loadAccentColor(HivePersistenceService service) {
    final value = service.getAccentColor();
    if (value != null) {
      return Color(value);
    }
    return const Color(0xFFFF6600); // Default Orange
  }

  void setThemeMode(ThemeMode mode) {
    state = state.copyWith(themeMode: mode);
    final modeStr = mode == ThemeMode.light
        ? 'light'
        : mode == ThemeMode.dark
            ? 'dark'
            : 'system';
    _persistenceService.saveThemeMode(modeStr);
  }

  void setAccentColor(Color color) {
    state = state.copyWith(accentColor: color);
    _persistenceService.saveAccentColor(color.value);
  }
}

/// Dynamic StateNotifierProvider exposing theme configuration state
final themeNotifierProvider = StateNotifierProvider<ThemeNotifier, ThemeState>((ref) {
  final persistenceService = ref.watch(persistenceServiceProvider);
  return ThemeNotifier(persistenceService);
});

/// List of premium accent color options available in settings
final List<Color> themeAccentPalette = [
  const Color(0xFFFF6600), // Hacker News Orange (Default)
  const Color(0xFF10B981), // Emerald Green
  const Color(0xFF06B6D4), // Cyan Tech
  const Color(0xFFD946EF), // Fuchsia Glow
  const Color(0xFFF59E0B), // Amber Alert
  const Color(0xFF8B5CF6), // Royal Indigo
];

/// Helper to build light mode theme with dynamic accent color
ThemeData buildLightTheme(Color accentColor) {
  return ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: const Color(0xFFF2F2F7),
    primaryColor: accentColor,
    colorScheme: ColorScheme.light(
      primary: accentColor,
      secondary: accentColor,
      surface: Colors.white,
      background: const Color(0xFFF2F2F7),
    ),
    useMaterial3: true,
    textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      elevation: 0,
    ),
    dividerTheme: DividerThemeData(
      color: Colors.black.withOpacity(0.08),
    ),
  );
}

/// Helper to build dark mode theme with dynamic accent color
ThemeData buildDarkTheme(Color accentColor) {
  return ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF0F0F10),
    primaryColor: accentColor,
    colorScheme: ColorScheme.dark(
      primary: accentColor,
      secondary: accentColor,
      surface: const Color(0xFF1E1E20),
      background: const Color(0xFF0F0F10),
    ),
    useMaterial3: true,
    textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1E1E20),
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    dividerTheme: DividerThemeData(
      color: Colors.white.withOpacity(0.08),
    ),
  );
}
