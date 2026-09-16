import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// State provider for managing app-wide language locale (English / हिन्दी).
/// Persists language selection to local storage via SharedPreferences.
class LocaleProvider extends ChangeNotifier {
  static const String _storageKey = 'planten_selected_locale_code';
  static const Locale defaultHindi = Locale('hi');
  static const Locale defaultEnglish = Locale('en');

  Locale _currentLocale;
  SharedPreferences? _prefs;

  LocaleProvider({
    SharedPreferences? prefs,
    Locale? initialLocale,
  }) : _currentLocale = initialLocale ?? const Locale('en') {
    _prefs = prefs;
    if (_prefs == null) {
      _loadFromPrefs();
    }
  }

  Locale get currentLocale => _currentLocale;

  bool get isHindi => _currentLocale.languageCode == 'hi';

  bool get isEnglish => _currentLocale.languageCode == 'en';

  /// Loads saved locale from SharedPreferences or detects device locale
  Future<void> _loadFromPrefs() async {
    _prefs = await SharedPreferences.getInstance();
    final savedCode = _prefs?.getString(_storageKey);

    if (savedCode != null && (savedCode == 'hi' || savedCode == 'en')) {
      _currentLocale = Locale(savedCode);
    } else {
      // Default to Hindi if device locale is Indian, otherwise English
      final deviceLocale = ui.PlatformDispatcher.instance.locale;
      if (deviceLocale.countryCode == 'IN' || deviceLocale.languageCode == 'hi') {
        _currentLocale = defaultHindi;
      } else {
        _currentLocale = defaultEnglish;
      }
    }
    notifyListeners();
  }

  /// Sets and persists a new locale
  Future<void> setLocale(Locale locale) async {
    if (locale.languageCode != 'hi' && locale.languageCode != 'en') {
      return;
    }
    if (_currentLocale.languageCode == locale.languageCode) {
      return;
    }

    _currentLocale = locale;
    notifyListeners();

    _prefs ??= await SharedPreferences.getInstance();
    await _prefs?.setString(_storageKey, locale.languageCode);
  }

  /// Convenience method to toggle between English and Hindi
  Future<void> toggleLocale() async {
    if (isHindi) {
      await setLocale(defaultEnglish);
    } else {
      await setLocale(defaultHindi);
    }
  }
}
