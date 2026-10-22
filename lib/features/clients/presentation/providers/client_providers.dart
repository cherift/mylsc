import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/client_repository.dart';
import '../../domain/models/client_model.dart';

// =============== REPOSITORY PROVIDER ===============

final clientRepositoryProvider = Provider<ClientRepository>((ref) {
  return ClientRepository();
});

// =============== STREAM PROVIDERS ===============

/// Stream des clients actifs (triés par nom).
/// Crée les clients par défaut (CBG, TBA, GEMIC) au premier chargement.
final activeClientsProvider = StreamProvider<List<ClientModel>>((ref) {
  final repository = ref.watch(clientRepositoryProvider);
  repository.ensureDefaultClients().catchError((Object e) {
    debugPrint('ensureDefaultClients: $e');
  });
  return repository.watchActiveClients();
});
