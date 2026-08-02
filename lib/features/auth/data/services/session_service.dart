import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/models/user_model.dart';

/// Service de gestion de la session utilisateur
/// Gère la persistance de l'utilisateur connecté
class SessionService {
  SessionService(this._prefs);

  final SharedPreferences _prefs;

  static const String _userKey = 'current_user';
  static const String _rememberMeKey = 'remember_me';
  static const String _sessionExpiryKey = 'session_expiry';

  // Durées de session
  static const Duration _rememberMeDuration = Duration(days: 1);
  static const Duration _defaultSessionDuration = Duration(hours: 8);

  /// Sauvegarder la session utilisateur
  Future<void> saveSession({
    required UserModel user,
    required bool rememberMe,
  }) async {
    await _prefs.setString(_userKey, jsonEncode(user.toMap()));
    await _prefs.setBool(_rememberMeKey, rememberMe);

    final duration = rememberMe ? _rememberMeDuration : _defaultSessionDuration;
    final expiryDate = DateTime.now().add(duration);
    await _prefs.setString(_sessionExpiryKey, expiryDate.toIso8601String());
  }

  /// Récupérer la session utilisateur
  Future<UserModel?> getSession() async {
    final expiryString = _prefs.getString(_sessionExpiryKey);
    if (expiryString == null) return null;

    final expiryDate = DateTime.parse(expiryString);
    if (DateTime.now().isAfter(expiryDate)) {
      await clearSession();
      return null;
    }

    final userJson = _prefs.getString(_userKey);
    if (userJson == null) return null;

    try {
      final userMap = jsonDecode(userJson) as Map<String, dynamic>;
      return UserModel.fromMap(userMap, userMap['id'] as String? ?? '');
    } catch (e) {
      await clearSession();
      return null;
    }
  }

  /// Mettre à jour l'utilisateur de la session
  Future<void> updateUser(UserModel user) async {
    await _prefs.setString(_userKey, jsonEncode(user.toMap()));
  }

  /// Vérifier si une session est active
  Future<bool> hasActiveSession() async {
    final user = await getSession();
    return user != null;
  }

  /// Effacer la session
  Future<void> clearSession() async {
    await _prefs.remove(_userKey);
    await _prefs.remove(_rememberMeKey);
    await _prefs.remove(_sessionExpiryKey);
  }

  /// Vérifier si "Se souvenir de moi" est activé
  bool get isRememberMeEnabled => _prefs.getBool(_rememberMeKey) ?? false;

  /// Obtenir le temps restant de la session en heures
  int? get sessionHoursRemaining {
    final expiryString = _prefs.getString(_sessionExpiryKey);
    if (expiryString == null) return null;

    final expiryDate = DateTime.parse(expiryString);
    final now = DateTime.now();

    if (now.isAfter(expiryDate)) return 0;

    return expiryDate.difference(now).inHours;
  }
}
