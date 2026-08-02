import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/domain/models/user_model.dart';
import 'user_management_providers.dart';

/// Provider pour écouter les utilisateurs gérés par un responsable
final managedUsersProvider =
    StreamProvider.family<List<UserModel>, String>((ref, managerId) {
  final repository = ref.watch(userManagementRepositoryProvider);
  return repository.watchManagedUsers(managerId);
});

/// Provider pour récupérer le responsable d'un utilisateur par ID
final managerProvider =
    FutureProvider.family<UserModel?, String>((ref, managerId) async {
  final repository = ref.watch(userManagementRepositoryProvider);
  return repository.getUserById(managerId);
});
