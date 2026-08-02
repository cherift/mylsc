import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/services/session_service.dart';
import '../../domain/models/user_model.dart';

/// Provider pour SharedPreferences
final sharedPreferencesProvider = FutureProvider<SharedPreferences>((ref) {
  return SharedPreferences.getInstance();
});

/// Provider pour le service de session
final sessionServiceProvider = Provider<SessionService?>((ref) {
  final prefsAsync = ref.watch(sharedPreferencesProvider);
  return prefsAsync.when(
    data: SessionService.new,
    loading: () => null,
    error: (_, __) => null,
  );
});

/// Provider pour le repository d'authentification
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

/// Provider pour le stream de l'état d'authentification Firebase
final authStateChangesProvider = StreamProvider<User?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

/// Provider pour l'utilisateur actuellement connecté
final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authRepositoryProvider).currentUser;
});

/// Contrôleur pour gérer les opérations d'authentification
class AuthController extends StateNotifier<AsyncValue<UserModel?>> {
  AuthController(this._authRepository, this._sessionService)
      : super(const AsyncValue.loading()) {
    _initializeSession();
  }

  final AuthRepository _authRepository;
  final SessionService? _sessionService;

  /// Initialiser la session au démarrage.
  /// Priorité :
  ///  1. Session SharedPreferences (rememberMe = true) → rapide, hors ligne
  ///  2. Firebase Auth currentUser (persiste nativement sur web via IndexedDB)
  ///     → permet de rester connecté après rechargement de page même sans rememberMe
  Future<void> _initializeSession() async {
    if (_sessionService == null) {
      // SharedPreferences pas encore disponible — sera relancé à sa disposition
      state = const AsyncValue.data(null);
      return;
    }

    // 1. Essayer la session sauvegardée (rememberMe)
    final savedUser = await _sessionService.getSession();
    if (savedUser != null) {
      state = AsyncValue.data(savedUser);
      return;
    }

    // 2. Fallback : Firebase Auth a peut-être encore un utilisateur valide
    //    (cas typique : rechargement de page sur le web sans rememberMe)
    final firebaseUser = _authRepository.currentUser;
    if (firebaseUser != null) {
      try {
        final profile = await _authRepository.getUserProfile(firebaseUser.uid);
        if (profile != null) {
          state = AsyncValue.data(profile);
          return;
        }
      } catch (_) {
        // Profil inaccessible (hors ligne, etc.) → déconnecter proprement
      }
    }

    state = const AsyncValue.data(null);
  }

  /// Connexion avec email ou téléphone + mot de passe
  Future<void> signIn({
    required String identifier,
    required String password,
    bool rememberMe = false,
  }) async {
    state = const AsyncValue.loading();
    try {
      // Résoudre l'email : si contient @, c'est un email direct
      // Sinon, c'est un téléphone → chercher l'email associé
      final email = identifier.contains('@')
          ? identifier
          : await _authRepository.findEmailByPhone(identifier);

      final user = await _authRepository.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (_sessionService != null) {
        await _sessionService.saveSession(
          user: user,
          rememberMe: rememberMe,
        );
      }

      state = AsyncValue.data(user);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Inscription avec email et mot de passe
  Future<void> signUp({
    required String email,
    required String password,
    String? firstName,
    String? lastName,
  }) async {
    state = const AsyncValue.loading();
    try {
      final user = await _authRepository.signUpWithEmailAndPassword(
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
      );
      state = AsyncValue.data(user);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Déconnexion
  Future<void> signOut() async {
    state = const AsyncValue.loading();
    try {
      if (_sessionService != null) {
        await _sessionService.clearSession();
      }
      await _authRepository.signOut();
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Réinitialisation du mot de passe
  Future<void> resetPassword(String email) async {
    try {
      await _authRepository.resetPassword(email);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }
}

/// Provider pour le contrôleur d'authentification
final authControllerProvider =
    StateNotifierProvider<AuthController, AsyncValue<UserModel?>>((ref) {
  return AuthController(
    ref.watch(authRepositoryProvider),
    ref.watch(sessionServiceProvider),
  );
});
