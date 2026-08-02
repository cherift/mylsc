import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/update_service.dart';

final updateServiceProvider = Provider<UpdateService>((ref) => UpdateService());

/// Vérifie la mise à jour au démarrage. Retourne null si hors-ligne ou erreur.
final updateCheckProvider = FutureProvider<AppUpdateConfig?>((ref) async {
  final service = ref.read(updateServiceProvider);
  return service.checkForUpdate();
});
