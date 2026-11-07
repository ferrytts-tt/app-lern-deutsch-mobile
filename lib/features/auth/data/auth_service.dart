import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/network/supabase_client.dart';

/// Service gérant l'authentification et les profils candidats via Supabase.
class AuthService {
  final SupabaseClient? _client;

  AuthService({SupabaseClient? client})
      : _client = client ?? (AppSupabase.isInitialized ? AppSupabase.client : null);

  /// Utilisateur actuellement connecté
  User? get currentUser => _client?.auth.currentUser;

  /// Stream des changements d'état d'authentification
  Stream<AuthState> get authStateChanges =>
      _client?.auth.onAuthStateChange ?? const Stream.empty();

  /// Inscription d'un nouveau candidat avec email, mot de passe et nom complet
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    final client = _client;
    if (client == null) throw StateError('Supabase non initialisé');
    try {
      final res = await client.auth.signUp(
        email: email.trim(),
        password: password,
        data: {'full_name': fullName.trim()},
      );

      // Si le profil n'a pas été inséré par le trigger SQL, l'assurer ici
      if (res.user != null) {
        try {
          await client.from('profiles').upsert({
            'id': res.user!.id,
            'email': email.trim(),
            'full_name': fullName.trim(),
            'updated_at': DateTime.now().toIso8601String(),
          });
        } catch (e) {
          debugPrint('[AuthService] Info upsert profil: $e');
        }
      }

      return res;
    } catch (e) {
      debugPrint('[AuthService] Erreur lors de l\'inscription: $e');
      rethrow;
    }
  }

  /// Connexion d'un candidat existant
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    final client = _client;
    if (client == null) throw StateError('Supabase non initialisé');
    try {
      final res = await client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      return res;
    } catch (e) {
      debugPrint('[AuthService] Erreur de connexion: $e');
      rethrow;
    }
  }

  /// Connexion ou Inscription d'un candidat via Google (OAuth)
  Future<bool> signInWithGoogle() async {
    final client = _client;
    if (client == null) throw StateError('Supabase non initialisé');
    try {
      final redirectUrl = kIsWeb
          ? (Uri.base.origin.contains('localhost')
              ? 'http://localhost:5000/'
              : '${Uri.base.origin}/')
          : 'io.supabase.lernapp://login-callback/';
      return await client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: redirectUrl,
      );
    } catch (e) {
      debugPrint('[AuthService] Erreur de connexion Google: $e');
      rethrow;
    }
  }

  /// Déconnexion du candidat
  Future<void> signOut() async {
    final client = _client;
    if (client == null) return;
    try {
      await client.auth.signOut();
    } catch (e) {
      debugPrint('[AuthService] Erreur de déconnexion: $e');
      rethrow;
    }
  }

  /// Réinitialisation du mot de passe par email
  Future<void> resetPassword(String email) async {
    final client = _client;
    if (client == null) throw StateError('Supabase non initialisé');
    try {
      await client.auth.resetPasswordForEmail(email.trim());
    } catch (e) {
      debugPrint('[AuthService] Erreur reset password: $e');
      rethrow;
    }
  }

  /// Récupère le profil du candidat connecté depuis Supabase
  Future<Map<String, dynamic>?> getCandidateProfile() async {
    final user = currentUser;
    final client = _client;
    if (user == null || client == null) return null;

    try {
      final data = await client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();
      return data;
    } catch (e) {
      debugPrint('[AuthService] Erreur récupération profil: $e');
      return null;
    }
  }

  /// Met à jour les statistiques du profil candidat
  Future<void> updateCandidateStats({
    int? streakDays,
    int? totalXp,
    int? totalGems,
    int? highestUnlockedLot,
  }) async {
    final user = currentUser;
    final client = _client;
    if (user == null || client == null) return;

    final updates = <String, dynamic>{
      'updated_at': DateTime.now().toIso8601String(),
    };
    if (streakDays != null) updates['streak_days'] = streakDays;
    if (totalXp != null) updates['total_xp'] = totalXp;
    if (totalGems != null) updates['total_gems'] = totalGems;
    if (highestUnlockedLot != null) updates['highest_unlocked_lot'] = highestUnlockedLot;

    try {
      await client.from('profiles').update(updates).eq('id', user.id);
    } catch (e) {
      debugPrint('[AuthService] Erreur updateCandidateStats: $e');
    }
  }
}
