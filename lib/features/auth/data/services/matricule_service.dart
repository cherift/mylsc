import 'package:cloud_firestore/cloud_firestore.dart';

/// Service de génération automatique de matricules
/// Génère des matricules uniques selon le rôle :
/// - Chauffeur: CHXXXX (CH0001, CH0002, ...)
/// - Superviseur: SUPXXXX (SUP0001, SUP0002, ...)
/// - Responsable: RSUPXXXX (RSUP0001, RSUP0002, ...)
/// - Autres: XXXXX (00001, 00002, ...)
class MatriculeService {
  MatriculeService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  /// Générer un matricule unique selon le rôle
  Future<String> generateMatricule(String role) async {
    final prefix = _getPrefixForRole(role);
    final counter = await _getNextCounter(prefix);
    return _formatMatricule(prefix, counter);
  }

  /// Obtenir le préfixe selon le rôle
  String _getPrefixForRole(String role) {
    final normalizedRole = role.toLowerCase().trim();

    switch (normalizedRole) {
      case 'chauffeur':
      case 'driver':
        return 'CH';
      case 'superviseur':
      case 'supervisor':
        return 'SUP';
      case 'responsable':
      case 'responsable flotte':
      case 'responsable superviseur':
      case 'manager':
        return 'RSUP';
      case 'rh':
      case 'admin':
      case 'administrateur':
        return 'RH';
      case 'direction':
      case 'management':
        return 'DIR';
      default:
        return '';
    }
  }

  /// Obtenir le prochain compteur pour un préfixe donné
  Future<int> _getNextCounter(String prefix) async {
    final counterDoc = _firestore.collection('counters').doc('matricule_$prefix');

    return _firestore.runTransaction<int>((transaction) async {
      final snapshot = await transaction.get(counterDoc);

      int newCounter;
      if (!snapshot.exists) {
        newCounter = 1;
      } else {
        final currentCounter = snapshot.data()?['value'] as int? ?? 0;
        newCounter = currentCounter + 1;
      }

      transaction.set(
        counterDoc,
        {'value': newCounter, 'updatedAt': FieldValue.serverTimestamp()},
      );

      return newCounter;
    });
  }

  /// Formater le matricule avec le préfixe et le numéro
  String _formatMatricule(String prefix, int counter) {
    if (prefix.isEmpty) {
      return counter.toString().padLeft(5, '0');
    }
    return '$prefix${counter.toString().padLeft(4, '0')}';
  }

  /// Vérifier si un matricule existe déjà
  Future<bool> matriculeExists(String matricule) async {
    final query = await _firestore
        .collection('users')
        .where('matricule', isEqualTo: matricule)
        .limit(1)
        .get();

    return query.docs.isNotEmpty;
  }

  /// Valider le format d'un matricule
  bool isValidMatricule(String matricule) {
    final patterns = [
      RegExp(r'^CH\d{4}$'), // Chauffeur
      RegExp(r'^SUP\d{4}$'), // Superviseur
      RegExp(r'^RSUP\d{4}$'), // Responsable
      RegExp(r'^RH\d{4}$'), // RH
      RegExp(r'^DIR\d{4}$'), // Direction
      RegExp(r'^\d{5}$'), // Autres
    ];

    return patterns.any((pattern) => pattern.hasMatch(matricule));
  }

  /// Extraire le rôle à partir d'un matricule
  String? getRoleFromMatricule(String matricule) {
    if (matricule.startsWith('DIR')) return 'Direction';
    if (matricule.startsWith('CH')) return 'Chauffeur';
    if (matricule.startsWith('RSUP')) return 'Responsable Flotte';
    if (matricule.startsWith('SUP')) return 'Superviseur';
    if (matricule.startsWith('RH')) return 'RH';
    if (RegExp(r'^\d{5}$').hasMatch(matricule)) return 'Autres';
    return null;
  }
}
