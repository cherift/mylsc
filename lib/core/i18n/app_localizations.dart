import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Classe de gestion des traductions de l'application
class AppLocalizations {
  AppLocalizations(this.locale);

  final Locale locale;
  late Map<String, dynamic> _localizedStrings;

  /// Méthode pour obtenir l'instance de AppLocalizations depuis le contexte
  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  /// Delegate pour gérer le chargement des traductions
  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// Langues supportées
  static const List<Locale> supportedLocales = [
    Locale('fr', 'FR'), // Français
    Locale('en', 'US'), // Anglais
    Locale('zh', 'CN'), // Chinois
  ];

  /// Charge le fichier de traduction pour la locale donnée
  Future<bool> load() async {
    final jsonString = await rootBundle
        .loadString('assets/translations/${locale.languageCode}.json');
    final jsonMap = json.decode(jsonString) as Map<String, dynamic>;
    _localizedStrings = jsonMap;
    return true;
  }

  /// Récupère une traduction en utilisant une clé avec notation par points
  /// Par exemple: translate('auth.welcome') retourne "Bienvenue sur My LSC"
  String translate(String key) {
    final keys = key.split('.');
    dynamic value = _localizedStrings;

    for (final k in keys) {
      if (value is Map<String, dynamic> && value.containsKey(k)) {
        value = value[k];
      } else {
        return key; // Retourne la clé si la traduction n'est pas trouvée
      }
    }

    return value.toString();
  }

  /// Raccourci pour translate
  String tr(String key) => translate(key);

  // Accesseurs pour les sections courantes
  String get appTitle => translate('app.title');
  String get appName => translate('app.name');

  // Auth
  String get authWelcome => translate('auth.welcome');
  String get authSubtitle => translate('auth.subtitle');
  String get authEmail => translate('auth.email');
  String get authEmailHint => translate('auth.emailHint');
  String get authPassword => translate('auth.password');
  String get authPasswordHint => translate('auth.passwordHint');
  String get authMatricule => translate('auth.matricule');
  String get authMatriculeHint => translate('auth.matriculeHint');
  String get authLogin => translate('auth.login');
  String get authLoginWithMatricule => translate('auth.loginWithMatricule');
  String get authLoginWithEmail => translate('auth.loginWithEmail');
  String get authForgotPassword => translate('auth.forgotPassword');
  String get authLogout => translate('auth.logout');
  String get authLoggingIn => translate('auth.loggingIn');

  // Common
  String get commonSave => translate('common.save');
  String get commonCancel => translate('common.cancel');
  String get commonDelete => translate('common.delete');
  String get commonEdit => translate('common.edit');
  String get commonClose => translate('common.close');
  String get commonConfirm => translate('common.confirm');
  String get commonSearch => translate('common.search');
  String get commonFilter => translate('common.filter');
  String get commonRefresh => translate('common.refresh');
  String get commonLoading => translate('common.loading');
  String get commonError => translate('common.error');
  String get commonSuccess => translate('common.success');
  String get commonLanguage => translate('common.language');
  String get commonSettings => translate('common.settings');

  // Dashboard
  String get dashboardTitle => translate('dashboard.title');
  String get dashboardHome => translate('dashboard.home');
  String get dashboardVehicles => translate('dashboard.vehicles');
  String get dashboardDrivers => translate('dashboard.drivers');
  String get dashboardFleets => translate('dashboard.fleets');
  String get dashboardMap => translate('dashboard.map');
  String get dashboardPlanning => translate('dashboard.planning');
  String get dashboardReports => translate('dashboard.reports');
  String get dashboardAlerts => translate('dashboard.alerts');
  String get dashboardHelp => translate('dashboard.help');
  String get dashboardQuickActions => translate('dashboard.quickActions');
  String get dashboardNewVehicle => translate('dashboard.newVehicle');
  String get dashboardCreateFleet => translate('dashboard.createFleet');
  String get dashboardPlanRoute => translate('dashboard.planRoute');
  String get dashboardGenerateReport => translate('dashboard.generateReport');
}

/// Delegate pour charger les localisations
class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return AppLocalizations.supportedLocales
        .any((l) => l.languageCode == locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    final localizations = AppLocalizations(locale);
    await localizations.load();
    return localizations;
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
