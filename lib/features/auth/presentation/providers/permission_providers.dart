import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/permission_repository.dart';
import '../../data/services/permission_service.dart';
import '../../domain/models/permission.dart';
import '../../domain/models/permission_history.dart';
import '../../domain/models/user_model.dart';
import '../../../users/presentation/providers/user_management_providers.dart';

/// Provider pour le service de permissions
final permissionServiceProvider = Provider<PermissionService>((ref) {
  return PermissionService();
});

/// Provider pour le repository de permissions
final permissionRepositoryProvider = Provider<PermissionRepository>((ref) {
  return PermissionRepository();
});

/// Provider pour l'historique des permissions d'un utilisateur
final userPermissionHistoryProvider =
    FutureProvider.family<List<PermissionHistoryEntry>, String>(
  (ref, userId) async {
    final repo = ref.watch(permissionRepositoryProvider);
    return repo.getPermissionHistory(userId);
  },
);

/// Provider alternatif pour l'historique (retourne des Maps pour compatibilité)
final userPermissionHistoryMapProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>(
  (ref, userId) async {
    final repo = ref.watch(userManagementRepositoryProvider);
    return repo.getUserPermissionHistory(userId);
  },
);

/// Provider pour vérifier si un utilisateur a une permission spécifique
final userHasPermissionProvider = Provider.family<
    bool,
    ({
      UserModel user,
      Permission permission
    })>((ref, params) {
  final service = ref.watch(permissionServiceProvider);
  return service.can(params.user, params.permission);
});

/// Provider stream pour l'historique des permissions
final userPermissionHistoryStreamProvider =
    StreamProvider.family<List<PermissionHistoryEntry>, String>(
  (ref, userId) {
    final repo = ref.watch(permissionRepositoryProvider);
    return repo.watchPermissionHistory(userId);
  },
);
