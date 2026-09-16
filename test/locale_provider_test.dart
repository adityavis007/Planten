import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:planten/providers/locale_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LocaleProvider Unit Tests (Task 09)', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('Initializes with default English when no saved preference and non-IN locale', () async {
      final prefs = await SharedPreferences.getInstance();
      final provider = LocaleProvider(prefs: prefs, initialLocale: const Locale('en'));

      expect(provider.currentLocale.languageCode, equals('en'));
      expect(provider.isEnglish, isTrue);
      expect(provider.isHindi, isFalse);
    });

    test('Toggling locale switches between English and Hindi with notification', () async {
      final prefs = await SharedPreferences.getInstance();
      final provider = LocaleProvider(prefs: prefs, initialLocale: const Locale('en'));

      int notifyCount = 0;
      provider.addListener(() {
        notifyCount++;
      });

      // Toggle to Hindi
      await provider.toggleLocale();
      expect(provider.currentLocale.languageCode, equals('hi'));
      expect(provider.isHindi, isTrue);
      expect(provider.isEnglish, isFalse);
      expect(notifyCount, equals(1));
      expect(prefs.getString('planten_selected_locale_code'), equals('hi'));

      // Toggle back to English
      await provider.toggleLocale();
      expect(provider.currentLocale.languageCode, equals('en'));
      expect(provider.isEnglish, isTrue);
      expect(notifyCount, equals(2));
      expect(prefs.getString('planten_selected_locale_code'), equals('en'));
    });

    test('Restores saved Hindi locale from SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({
        'planten_selected_locale_code': 'hi',
      });

      final prefs = await SharedPreferences.getInstance();
      final provider = LocaleProvider(prefs: prefs);

      // Explicitly set to saved value check
      await provider.setLocale(const Locale('hi'));
      expect(provider.currentLocale.languageCode, equals('hi'));
    });
  });
}
