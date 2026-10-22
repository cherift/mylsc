import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/client_model.dart';

class ClientRepository {
  ClientRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _clientCollection =>
      _firestore.collection('clients');

  /// Clients par défaut (id de document stable → création idempotente)
  static const Map<String, String> defaultClients = {
    'cbg': 'CBG',
    'tba': 'TBA',
    'gemic': 'GEMIC',
  };

  // ============ SEED ============

  /// Crée les clients par défaut s'ils n'existent pas encore.
  /// Un client par défaut désactivé n'est pas recréé.
  Future<void> ensureDefaultClients() async {
    for (final entry in defaultClients.entries) {
      final docRef = _clientCollection.doc(entry.key);
      final doc = await docRef.get();
      if (doc.exists) continue;
      await docRef.set(ClientModel(
        id: entry.key,
        name: entry.value,
        code: entry.value,
        createdAt: DateTime.now(),
        createdBy: 'system',
      ).toMap());
    }
  }

  // ============ CREATE ============

  Future<ClientModel> createClient(ClientModel client) async {
    final docRef = await _clientCollection.add(client.toMap());
    return client.copyWith(id: docRef.id);
  }

  // ============ UPDATE ============

  Future<void> updateClient(ClientModel client) async {
    await _clientCollection.doc(client.id).update({
      'name': client.name,
      'code': client.code,
      'description': client.description,
    });
  }

  // ============ DELETE ============

  /// Suppression logique : le client reste lisible sur les pesées existantes.
  Future<void> deactivateClient(String clientId) async {
    await _clientCollection.doc(clientId).update({'isActive': false});
  }

  // ============ STREAMS ============

  Stream<List<ClientModel>> watchActiveClients() {
    return _clientCollection.snapshots().map((snapshot) {
      final clients = snapshot.docs
          .map((doc) => ClientModel.fromMap(doc.data(), doc.id))
          .where((client) => client.isActive)
          .toList()
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      return clients;
    });
  }
}
