import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:planten/providers/theme_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ThemeProvider Unit Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('Initializes with default light theme when no saved preference', () async {
      final prefs = await SharedPreferences.getInstance();
      final provider = ThemeProvider(prefs: prefs);

      expect(provider.themeMode, equals(ThemeMode.light));
      expect(provider.isLightMode, isTrue);
      expect(provider.isDarkMode, isFalse);
    });

    test('Toggling theme switches between light and dark mode with persistence', () async {
      final prefs = await SharedPreferences.getInstance();
      final provider = ThemeProvider(prefs: prefs);

      int notifyCount = 0;
      provider.addListener(() {
        notifyCount++;
      });

      // Toggle to dark
      await provider.toggleTheme();
      expect(provider.themeMode, equals(ThemeMode.dark));
      expect(provider.isDarkMode, isTrue);
      expect(provider.isLightMode, isFalse);
      expect(notifyCount, equals(1));
      expect(prefs.getString('planten_selected_theme_mode'), equals('dark'));

      // Toggle back to light
      await provider.toggleTheme();
      expect(provider.themeMode, equals(ThemeMode.light));
      expect(provider.isLightMode, isTrue);
      expect(provider.isDarkMode, isFalse);
      expect(notifyCount, equals(2));
      expect(prefs.getString('planten_selected_theme_mode'), equals('light'));
    });

    test('setThemeMode directly sets mode and ignores identical value', () async {
      final prefs = await SharedPreferences.getInstance();
      final provider = ThemeProvider(prefs: prefs);

      int notifyCount = 0;
      provider.addListener(() {
        notifyCount++;
      });

      await provider.setThemeMode(ThemeMode.dark);
      expect(provider.themeMode, equals(ThemeMode.dark));
      expect(notifyCount, equals(1));

      // Setting same mode again should be no-op
      await provider.setThemeMode(ThemeMode.dark);
      expect(notifyCount, equals(1));
    });

    test('Restores saved dark mode from SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({
        'planten_selected_theme_mode': 'dark',
      });

      final prefs = await SharedPreferences.getInstance();
      final provider = ThemeProvider(prefs: prefs);

      expect(provider.themeMode, equals(ThemeMode.dark));
      expect(provider.isDarkMode, isTrue);
    });
  });
}
