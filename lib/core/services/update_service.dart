import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:package_info_plus/package_info_plus.dart';

/// Statut de mise à jour retourné après comparaison des versions
enum UpdateStatus { none, optional, forced }

/// Configuration de mise à jour lue depuis Firestore
class AppUpdateConfig {
  const AppUpdateConfig({
    required this.minVersion,
    required this.latestVersion,
    required this.storeUrlAndroid,
    required this.storeUrlIos,
    required this.message,
    required this.currentVersion,
    required this.status,
  });

  final String minVersion;
  final String latestVersion;
  final String storeUrlAndroid;
  final String storeUrlIos;

  /// Message localisé depuis Firestore (clé = code langue : fr, en, zh)
  final Map<String, String> message;

  /// Version actuellement installée sur l'appareil
  final String currentVersion;

  final UpdateStatus status;

  bool get isForced => status == UpdateStatus.forced;
  bool get isOptional => status == UpdateStatus.optional;

  String localizedMessage(String langCode) =>
      message[langCode] ?? message['fr'] ?? message.values.firstOrNull ?? '';
}

/// Service de vérification des mises à jour
class UpdateService {
  UpdateService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  /// Vérifie la version et retourne le statut de mise à jour.
  /// Retourne null en cas d'erreur réseau (on laisse l'app fonctionner).
  Future<AppUpdateConfig?> checkForUpdate() async {
    if (kIsWeb) return null;
    try {
      final info = await PackageInfo.fromPlatform();
      final currentVersion = info.version; // ex: "1.0.2"

      final doc = await _firestore
          .collection('app_config')
          .doc('version')
          .get();

      if (!doc.exists || doc.data() == null) return null;
      final data = doc.data()!;

      final minVersion = data['minVersion'] as String? ?? '0.0.0';
      final latestVersion = data['latestVersion'] as String? ?? '0.0.0';
      final storeUrlAndroid = data['storeUrlAndroid'] as String? ?? '';
      final storeUrlIos = data['storeUrlIos'] as String? ?? '';

      final rawMessage = data['message'];
      final message = <String, String>{};
      if (rawMessage is Map) {
        rawMessage.forEach((k, v) {
          if (k is String && v is String) message[k] = v;
        });
      }

      UpdateStatus status;
      if (_compareVersions(currentVersion, minVersion) < 0) {
        status = UpdateStatus.forced;
      } else if (_compareVersions(currentVersion, latestVersion) < 0) {
        status = UpdateStatus.optional;
      } else {
        status = UpdateStatus.none;
      }

      return AppUpdateConfig(
        minVersion: minVersion,
        latestVersion: latestVersion,
        storeUrlAndroid: storeUrlAndroid,
        storeUrlIos: storeUrlIos,
        message: message,
        currentVersion: currentVersion,
        status: status,
      );
    } catch (_) {
      // Erreur réseau ou Firestore → on ne bloque pas l'app
      return null;
    }
  }

  /// Compare deux versions semver. Retourne -1, 0 ou 1.
  int _compareVersions(String v1, String v2) {
    final parts1 = _versionParts(v1);
    final parts2 = _versionParts(v2);
    final len = parts1.length > parts2.length ? parts1.length : parts2.length;
    for (var i = 0; i < len; i++) {
      final p1 = i < parts1.length ? parts1[i] : 0;
      final p2 = i < parts2.length ? parts2[i] : 0;
      if (p1 < p2) return -1;
      if (p1 > p2) return 1;
    }
    return 0;
  }

  List<int> _versionParts(String version) {
    // Ignore le suffixe build (+5) et les labels pre-release (-beta)
    final clean = version.split('+').first.split('-').first;
    return clean.split('.').map((p) => int.tryParse(p) ?? 0).toList();
  }
}
