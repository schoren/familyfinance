import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final settingsProvider = NotifierProvider<SettingsNotifier, AppSettings>(() {
  return SettingsNotifier();
});

class AppSettings {
  final Locale? locale;

  AppSettings({this.locale});

  AppSettings copyWith({Locale? locale, bool clearLocale = false}) {
    return AppSettings(
      locale: clearLocale ? null : (locale ?? this.locale),
    );
  }
}

class SettingsNotifier extends Notifier<AppSettings> {
  static const _languageKey = 'selected_language';
  late SharedPreferences _prefs;

  @override
  AppSettings build() {
    _init();
    return AppSettings();
  }

  Future<void> _init() async {
    _prefs = await SharedPreferences.getInstance();
    
    // URL parameter takes precedence
    try {
      final uri = Uri.base;
      final langParam = uri.queryParameters['lang'];
      if (langParam != null && langParam.isNotEmpty) {
        state = state.copyWith(locale: Locale(langParam));
        return;
      }
    } catch (_) {
      // Ignore if Uri.base is not available or fails
    }

    final languageCode = _prefs.getString(_languageKey);
    if (languageCode != null) {
      state = state.copyWith(locale: Locale(languageCode));
    }
  }

  Future<void> setLanguage(String? languageCode) async {
    if (languageCode == null) {
      await _prefs.remove(_languageKey);
      state = state.copyWith(clearLocale: true);
    } else {
      await _prefs.setString(_languageKey, languageCode);
      state = state.copyWith(locale: Locale(languageCode));
    }
  }
}
