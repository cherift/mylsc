import 'package:cloud_firestore/cloud_firestore.dart';

/// Type de changement de permission
enum PermissionChangeType {
  roleChanged,
  permissionsAdded,
  permissionsRemoved,
  permissionsModified,
}

/// Entrée d'historique des modifications de permissions
class PermissionHistoryEntry {
  const PermissionHistoryEntry({
    required this.id,
    required this.timestamp,
    required this.modifiedBy,
    required this.modifiedByName,
    required this.changeType,
    this.previousRole,
    this.newRole,
    this.addedPermissions,
    this.removedPermissions,
    this.reason,
  });

  /// Créer une instance depuis Firestore
  factory PermissionHistoryEntry.fromMap(Map<String, dynamic> map, String id) {
    return PermissionHistoryEntry(
      id: id,
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      modifiedBy: map['modifiedBy'] as String? ?? '',
      modifiedByName: map['modifiedByName'] as String? ?? '',
      changeType: PermissionChangeType.values.firstWhere(
        (type) => type.name == map['changeType'],
        orElse: () => PermissionChangeType.permissionsModified,
      ),
      previousRole: map['previousRole'] as String?,
      newRole: map['newRole'] as String?,
      addedPermissions: (map['addedPermissions'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
      removedPermissions: (map['removedPermissions'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
      reason: map['reason'] as String?,
    );
  }

  /// ID unique de l'entrée
  final String id;

  /// Date et heure de la modification
  final DateTime timestamp;

  /// ID de l'utilisateur qui a effectué la modification
  final String modifiedBy;

  /// Nom de l'utilisateur qui a effectué la modification
  final String modifiedByName;

  /// Type de changement effectué
  final PermissionChangeType changeType;

  /// Rôle précédent (pour les changements de rôle)
  final String? previousRole;

  /// Nouveau rôle (pour les changements de rôle)
  final String? newRole;

  /// Permissions ajoutées (pour les ajouts de permissions)
  final List<String>? addedPermissions;

  /// Permissions retirées (pour les retraits de permissions)
  final List<String>? removedPermissions;

  /// Raison du changement (optionnel)
  final String? reason;

  /// Convertir en Map pour Firestore
  Map<String, dynamic> toMap() {
    return {
      'timestamp': FieldValue.serverTimestamp(),
      'modifiedBy': modifiedBy,
      'modifiedByName': modifiedByName,
      'changeType': changeType.name,
      if (previousRole != null) 'previousRole': previousRole,
      if (newRole != null) 'newRole': newRole,
      if (addedPermissions != null) 'addedPermissions': addedPermissions,
      if (removedPermissions != null) 'removedPermissions': removedPermissions,
      if (reason != null) 'reason': reason,
    };
  }

  /// Copier avec modifications
  PermissionHistoryEntry copyWith({
    String? id,
    DateTime? timestamp,
    String? modifiedBy,
    String? modifiedByName,
    PermissionChangeType? changeType,
    String? previousRole,
    String? newRole,
    List<String>? addedPermissions,
    List<String>? removedPermissions,
    String? reason,
  }) {
    return PermissionHistoryEntry(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      modifiedBy: modifiedBy ?? this.modifiedBy,
      modifiedByName: modifiedByName ?? this.modifiedByName,
      changeType: changeType ?? this.changeType,
      previousRole: previousRole ?? this.previousRole,
      newRole: newRole ?? this.newRole,
      addedPermissions: addedPermissions ?? this.addedPermissions,
      removedPermissions: removedPermissions ?? this.removedPermissions,
      reason: reason ?? this.reason,
    );
  }

  /// Obtenir une description textuelle du changement
  String getChangeDescription() {
    switch (changeType) {
      case PermissionChangeType.roleChanged:
        return 'Rôle modifié de "$previousRole" à "$newRole"';
      case PermissionChangeType.permissionsAdded:
        final count = addedPermissions?.length ?? 0;
        return '$count permission${count > 1 ? 's' : ''} ajoutée${count > 1 ? 's' : ''}';
      case PermissionChangeType.permissionsRemoved:
        final count = removedPermissions?.length ?? 0;
        return '$count permission${count > 1 ? 's' : ''} retirée${count > 1 ? 's' : ''}';
      case PermissionChangeType.permissionsModified:
        final added = addedPermissions?.length ?? 0;
        final removed = removedPermissions?.length ?? 0;
        return 'Permissions modifiées (+$added, -$removed)';
    }
  }

  /// Obtenir les détails du changement
  String getChangeDetails() {
    final details = <String>[];

    if (previousRole != null && newRole != null) {
      details.add('Rôle: $previousRole → $newRole');
    }

    if (addedPermissions != null && addedPermissions!.isNotEmpty) {
      details.add('Ajouté: ${addedPermissions!.join(', ')}');
    }

    if (removedPermissions != null && removedPermissions!.isNotEmpty) {
      details.add('Retiré: ${removedPermissions!.join(', ')}');
    }

    if (reason != null && reason!.isNotEmpty) {
      details.add('Raison: $reason');
    }

    return details.join('\n');
  }
}

/// Extension pour PermissionChangeType
extension PermissionChangeTypeExtension on PermissionChangeType {
  /// Nom d'affichage du type de changement
  String get displayName {
    switch (this) {
      case PermissionChangeType.roleChanged:
        return 'Changement de rôle';
      case PermissionChangeType.permissionsAdded:
        return 'Permissions ajoutées';
      case PermissionChangeType.permissionsRemoved:
        return 'Permissions retirées';
      case PermissionChangeType.permissionsModified:
        return 'Permissions modifiées';
    }
  }

  /// Couleur associée au type de changement
  String get colorHex {
    switch (this) {
      case PermissionChangeType.roleChanged:
        return '#2196F3'; // Bleu
      case PermissionChangeType.permissionsAdded:
        return '#4CAF50'; // Vert
      case PermissionChangeType.permissionsRemoved:
        return '#F44336'; // Rouge
      case PermissionChangeType.permissionsModified:
        return '#FF9800'; // Orange
    }
  }
}
