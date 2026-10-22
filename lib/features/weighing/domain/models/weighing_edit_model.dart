import 'package:cloud_firestore/cloud_firestore.dart';

/// Trace d'une correction de pesée (T.38) — `weighings/{id}/edits/{editId}`
class WeighingEditModel {
  const WeighingEditModel({
    required this.id,
    required this.editedBy,
    required this.editedByName,
    required this.editedAt,
    required this.reason,
    required this.changes,
  });

  factory WeighingEditModel.fromMap(Map<String, dynamic> map, String id) {
    final rawChanges = map['changes'] as Map<String, dynamic>? ?? {};
    return WeighingEditModel(
      id: id,
      editedBy: map['editedBy'] as String? ?? '',
      editedByName: map['editedByName'] as String? ?? '',
      editedAt: (map['editedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      reason: map['reason'] as String? ?? '',
      changes: rawChanges.map((field, value) {
        final change = value as Map<String, dynamic>? ?? {};
        return MapEntry(field, (old: change['old'], value: change['new']));
      }),
    );
  }

  final String id;
  final String editedBy;
  final String editedByName;
  final DateTime editedAt;

  /// Motif de la correction (obligatoire)
  final String reason;

  /// Champ modifié → ancienne / nouvelle valeur
  final Map<String, ({Object? old, Object? value})> changes;

  Map<String, dynamic> toMap() {
    return {
      'editedBy': editedBy,
      'editedByName': editedByName,
      'editedAt': Timestamp.fromDate(editedAt),
      'reason': reason,
      'changes': changes.map(
        (field, change) =>
            MapEntry(field, {'old': change.old, 'new': change.value}),
      ),
    };
  }
}
