import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/domain/models/user_model.dart';
import '../../data/repositories/user_management_repository.dart';

/// Provider pour le repository de gestion des utilisateurs
final userManagementRepositoryProvider = Provider<UserManagementRepository>((ref) {
  return UserManagementRepository();
});

/// Provider pour récupérer tous les utilisateurs
final allUsersProvider = FutureProvider<List<UserModel>>((ref) async {
  final repository = ref.watch(userManagementRepositoryProvider);
  return repository.getAllUsers();
});

/// Provider pour récupérer les utilisateurs actifs
final activeUsersProvider = FutureProvider<List<UserModel>>((ref) async {
  final repository = ref.watch(userManagementRepositoryProvider);
  return repository.getActiveUsers();
});

/// Provider pour les statistiques des utilisateurs par rôle
final userStatsProvider = FutureProvider<Map<String, int>>((ref) async {
  final repository = ref.watch(userManagementRepositoryProvider);
  return repository.getUserStatsByRole();
});

/// Provider pour le nombre total d'utilisateurs
final userCountProvider = FutureProvider<int>((ref) async {
  final repository = ref.watch(userManagementRepositoryProvider);
  return repository.getUserCount();
});

/// Provider pour le nombre d'utilisateurs actifs
final activeUserCountProvider = FutureProvider<int>((ref) async {
  final repository = ref.watch(userManagementRepositoryProvider);
  return repository.getActiveUserCount();
});

/// Provider pour écouter tous les utilisateurs en temps réel
final usersStreamProvider = StreamProvider<List<UserModel>>((ref) {
  final repository = ref.watch(userManagementRepositoryProvider);
  return repository.watchAllUsers();
});

/// Provider pour récupérer un utilisateur spécifique
final userProvider = FutureProvider.family<UserModel?, String>((ref, userId) async {
  final repository = ref.watch(userManagementRepositoryProvider);
  return repository.getUserById(userId);
});

/// Provider pour écouter un utilisateur spécifique en temps réel
final userStreamProvider = StreamProvider.family<UserModel?, String>((ref, userId) {
  final repository = ref.watch(userManagementRepositoryProvider);
  return repository.watchUser(userId);
});
