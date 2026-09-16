import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// State provider for managing app-wide ThemeMode (Light / Dark / System).
/// Persists theme preference to local storage via SharedPreferences.
class ThemeProvider extends ChangeNotifier {
  static const String _storageKey = 'planten_selected_theme_mode';

  ThemeMode _themeMode;
  SharedPreferences? _prefs;

  ThemeProvider({
    SharedPreferences? prefs,
    ThemeMode? initialThemeMode,
  }) : _themeMode = initialThemeMode ?? ThemeMode.light {
    _prefs = prefs;
    if (_prefs == null) {
      _loadFromPrefs();
    } else {
      _loadFromProvidedPrefs();
    }
  }

  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode => _themeMode == ThemeMode.dark;

  bool get isLightMode => _themeMode == ThemeMode.light;

  /// Loads saved theme mode from SharedPreferences
  Future<void> _loadFromPrefs() async {
    _prefs = await SharedPreferences.getInstance();
    _loadFromProvidedPrefs();
  }

  void _loadFromProvidedPrefs() {
    final savedMode = _prefs?.getString(_storageKey);
    if (savedMode != null) {
      switch (savedMode) {
        case 'dark':
          _themeMode = ThemeMode.dark;
          break;
        case 'system':
          _themeMode = ThemeMode.system;
          break;
        case 'light':
        default:
          _themeMode = ThemeMode.light;
          break;
      }
      notifyListeners();
    }
  }

  /// Sets and persists a new [ThemeMode]
  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;

    _themeMode = mode;
    notifyListeners();

    _prefs ??= await SharedPreferences.getInstance();
    final modeString = switch (mode) {
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
      ThemeMode.light => 'light',
    };
    await _prefs?.setString(_storageKey, modeString);
  }

  /// Convenience method to toggle between Light and Dark mode
  Future<void> toggleTheme() async {
    if (isDarkMode) {
      await setThemeMode(ThemeMode.light);
    } else {
      await setThemeMode(ThemeMode.dark);
    }
  }
}
