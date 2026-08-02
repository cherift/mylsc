import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/models/truck_field.dart';

/// Service pour gérer les préférences d'affichage des colonnes de camions
class TruckDisplayPreferencesService {
  static const String _visibleFieldsKey = 'truck_visible_fields';

  /// Sauvegarder les champs visibles
  Future<void> saveVisibleFields(List<String> fieldKeys) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_visibleFieldsKey, fieldKeys);
  }

  /// Charger les champs visibles
  Future<List<String>> loadVisibleFields() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList(_visibleFieldsKey);

    // Si aucune préférence sauvegardée, retourner les champs par défaut
    if (saved == null || saved.isEmpty) {
      return TruckFields.defaultFields.map((f) => f.key).toList();
    }

    return saved;
  }

  /// Réinitialiser aux valeurs par défaut
  Future<void> resetToDefaults() async {
    final defaultKeys = TruckFields.defaultFields.map((f) => f.key).toList();
    await saveVisibleFields(defaultKeys);
  }

  /// Vérifier si un champ est visible
  Future<bool> isFieldVisible(String fieldKey) async {
    final visibleFields = await loadVisibleFields();
    return visibleFields.contains(fieldKey);
  }

  /// Ajouter un champ aux champs visibles
  Future<void> addField(String fieldKey) async {
    final visibleFields = await loadVisibleFields();
    if (!visibleFields.contains(fieldKey)) {
      visibleFields.add(fieldKey);
      await saveVisibleFields(visibleFields);
    }
  }

  /// Retirer un champ des champs visibles
  Future<void> removeField(String fieldKey) async {
    final visibleFields = await loadVisibleFields();
    visibleFields.remove(fieldKey);
    await saveVisibleFields(visibleFields);
  }

  /// Basculer la visibilité d'un champ
  Future<void> toggleField(String fieldKey) async {
    final visibleFields = await loadVisibleFields();
    if (visibleFields.contains(fieldKey)) {
      visibleFields.remove(fieldKey);
    } else {
      visibleFields.add(fieldKey);
    }
    await saveVisibleFields(visibleFields);
  }
}
