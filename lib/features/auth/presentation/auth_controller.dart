import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/network/supabase_client.dart';
import '../../../data/database/app_database.dart';
import '../../sync/data/sync_service.dart';
import '../data/auth_service.dart';

enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  error,
}

class CandidateAuthState {
  final AuthStatus status;
  final User? user;
  final Map<String, dynamic>? profile;
  final String? errorMessage;
  final bool isSyncing;
  final String? syncStatusMessage;

  const CandidateAuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.profile,
    this.errorMessage,
    this.isSyncing = false,
    this.syncStatusMessage,
  });

  bool get isAuthenticated => status == AuthStatus.authenticated && user != null;
  String get candidateName => profile?['full_name'] as String? ?? user?.email?.split('@').first ?? 'Candidat';
  String get candidateEmail => user?.email ?? '';

  CandidateAuthState copyWith({
    AuthStatus? status,
    User? user,
    Map<String, dynamic>? profile,
    String? errorMessage,
    bool? isSyncing,
    String? syncStatusMessage,
    bool clearError = false,
  }) {
    return CandidateAuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      profile: profile ?? this.profile,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      isSyncing: isSyncing ?? this.isSyncing,
      syncStatusMessage: syncStatusMessage ?? this.syncStatusMessage,
    );
  }
}

final authServiceProvider = Provider<AuthService>((ref) => AuthService());
final syncServiceProvider = Provider<SyncService>((ref) => SyncService());

final authControllerProvider =
    StateNotifierProvider<AuthController, CandidateAuthState>((ref) {
  final authService = ref.watch(authServiceProvider);
  final syncService = ref.watch(syncServiceProvider);
  return AuthController(authService, syncService);
});

class AuthController extends StateNotifier<CandidateAuthState> {
  final AuthService _authService;
  final SyncService _syncService;

  AuthController(this._authService, this._syncService)
      : super(const CandidateAuthState()) {
    _init();
  }

  void _init() {
    if (!AppSupabase.isInitialized) {
      state = state.copyWith(status: AuthStatus.unauthenticated);
      return;
    }

    final currentUser = _authService.currentUser;
    if (currentUser != null) {
      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: currentUser,
      );
      _loadProfileAndSync();
    } else {
      state = state.copyWith(status: AuthStatus.unauthenticated);
    }

    _authService.authStateChanges.listen((data) {
      final session = data.session;
      if (session != null) {
        state = state.copyWith(
          status: AuthStatus.authenticated,
          user: session.user,
          clearError: true,
        );
        _loadProfileAndSync();
      } else {
        state = state.copyWith(
          status: AuthStatus.unauthenticated,
          user: null,
          profile: null,
        );
      }
    });
  }

  Future<void> _loadProfileAndSync() async {
    try {
      final profile = await _authService.getCandidateProfile();
      if (profile != null) {
        state = state.copyWith(profile: profile);
      }
      await triggerSync();
    } catch (_) {}
  }

  /// Déclenche une synchronisation Cloud <-> Local
  Future<void> triggerSync() async {
    if (state.isSyncing) return;
    state = state.copyWith(isSyncing: true, syncStatusMessage: 'Synchronisation...');

    final result = await _syncService.syncAll();
    if (result.success) {
      state = state.copyWith(
        isSyncing: false,
        syncStatusMessage: 'Synchronisé avec succès ☁️',
      );
    } else {
      state = state.copyWith(
        isSyncing: false,
        syncStatusMessage: 'Sync hors-ligne',
      );
    }
  }

  /// Inscription candidat : tout est strictement remis à zéro (lots, examens, progression)
  Future<bool> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    state = state.copyWith(status: AuthStatus.loading, clearError: true);
    try {
      // 1. Réinitialisation complète locale : progression, examens de paliers, lots, préférences
      await AppDatabase.instance.resetUserProgress(resetPreferences: true);

      // 2. Création du compte dans Supabase Auth
      final res = await _authService.signUp(
        email: email,
        password: password,
        fullName: fullName,
      );

      if (res.user != null) {
        // 3. Forcer le profil Cloud du nouveau candidat à zéro (Lot 1 débloqué, 0 exams validés, 0 XP, 50 gemmes)
        await _authService.updateCandidateStats(
          highestUnlockedLot: 1,
          streakDays: 0,
          totalXp: 0,
          totalGems: 50,
        );

        state = state.copyWith(
          status: AuthStatus.authenticated,
          user: res.user,
        );

        // 4. Synchroniser le catalogue de phrases (Cloud -> Local) pour garantir toutes les phrases
        await _syncService.syncPhrasesCatalog();
        final profile = await _authService.getCandidateProfile();
        state = state.copyWith(
          profile: profile,
          isSyncing: false,
          syncStatusMessage: 'Nouveau compte initialisé (Lot 1, 0 examens) 🎓',
        );
        return true;
      } else {
        state = state.copyWith(
          status: AuthStatus.unauthenticated,
          errorMessage: 'Vérifiez votre boîte email pour valider votre compte.',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: _humanReadableError(e.toString()),
      );
      return false;
    }
  }

  /// Connexion candidat
  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(status: AuthStatus.loading, clearError: true);
    try {
      final res = await _authService.signIn(
        email: email,
        password: password,
      );
      if (res.user != null) {
        await AppDatabase.instance.resetUserProgress(resetPreferences: true);
        state = state.copyWith(
          status: AuthStatus.authenticated,
          user: res.user,
        );
        await _loadProfileAndSync();
        return true;
      }
      return false;
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: _humanReadableError(e.toString()),
      );
      return false;
    }
  }

  /// Connexion ou Inscription avec un compte Google (OAuth)
  Future<bool> signInWithGoogle() async {
    state = state.copyWith(status: AuthStatus.loading, clearError: true);
    try {
      // Purge des données résiduelles locales avant la connexion
      await AppDatabase.instance.resetUserProgress(resetPreferences: true);
      final launched = await _authService.signInWithGoogle();
      return launched;
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: _humanReadableError(e.toString()),
      );
      return false;
    }
  }

  /// Déconnexion
  Future<void> signOut() async {
    try {
      await _authService.signOut();
      await AppDatabase.instance.resetUserProgress(resetPreferences: true);
      state = const CandidateAuthState(status: AuthStatus.unauthenticated);
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  /// Réinitialiser mot de passe
  Future<bool> resetPassword(String email) async {
    try {
      await _authService.resetPassword(email);
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: _humanReadableError(e.toString()));
      return false;
    }
  }

  String _humanReadableError(String raw) {
    if (raw.toLowerCase().contains('provider is not enabled') ||
        raw.toLowerCase().contains('unsupported provider')) {
      return 'L\'authentification Google n\'est pas encore activée sur le projet Supabase (Authentication > Providers > Google).';
    }
    if (raw.contains('Invalid login credentials')) {
      return 'Email ou mot de passe incorrect.';
    }
    if (raw.contains('User already registered')) {
      return 'Un compte existe déjà avec cette adresse email.';
    }
    if (raw.contains('Password should be at least 6 characters')) {
      return 'Le mot de passe doit comporter au moins 6 caractères.';
    }
    return raw;
  }
}
