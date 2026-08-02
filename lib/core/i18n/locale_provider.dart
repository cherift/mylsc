import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Clé pour sauvegarder la langue dans SharedPreferences
const String _localePreferenceKey = 'app_locale';

/// Notifier pour gérer le changement de langue
class LocaleNotifier extends StateNotifier<Locale> {
  LocaleNotifier() : super(const Locale('fr', 'FR')) {
    _loadLocale();
  }

  /// Charge la langue sauvegardée depuis SharedPreferences
  Future<void> _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString(_localePreferenceKey);

    if (languageCode != null) {
      state = _getLocaleFromCode(languageCode);
    }
  }

  /// Change la langue de l'application
  Future<void> setLocale(Locale locale) async {
    state = locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localePreferenceKey, locale.languageCode);
  }

  /// Convertit un code de langue en Locale
  Locale _getLocaleFromCode(String code) {
    switch (code) {
      case 'fr':
        return const Locale('fr', 'FR');
      case 'en':
        return const Locale('en', 'US');
      case 'zh':
        return const Locale('zh', 'CN');
      default:
        return const Locale('fr', 'FR');
    }
  }
}

/// Provider pour accéder à la locale courante
final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  return LocaleNotifier();
});
