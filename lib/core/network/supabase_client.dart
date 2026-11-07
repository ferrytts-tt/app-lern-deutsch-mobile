import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Configuration et singleton Supabase pour Hoppla / Deutsch Fast.
class AppSupabase {
  static const String supabaseUrl = 'https://ikrbaazspnrlbwfngnoc.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImlrcmJhYXpzcG5ybGJ3Zm5nbm9jIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTM2MzA3MjksImV4cCI6MjEwOTIwNjcyOX0.rIO3d8S4RaZIsDmpVg_i3csQubkoVMeZIE1VW45nkVM';

  static bool _isInitialized = false;
  static bool get isInitialized => _isInitialized;

  /// Initialise le client Supabase au démarrage
  static Future<void> initialize() async {
    try {
      await Supabase.initialize(
        url: supabaseUrl,
        // ignore: deprecated_member_use
        anonKey: supabaseAnonKey,
        debug: kDebugMode,
      );
      _isInitialized = true;
      debugPrint('[Supabase] Initialisé avec succès vers $supabaseUrl');
    } catch (e) {
      _isInitialized = false;
      debugPrint('[Supabase] Erreur d\'initialisation: $e');
    }
  }

  /// Instance principale du client
  static SupabaseClient get client => Supabase.instance.client;

  /// Utilisateur actuellement connecté (null si invité / hors-ligne)
  static User? get currentUser => _isInitialized ? client.auth.currentUser : null;

  /// ID de l'utilisateur connecté
  static String? get currentUserId => currentUser?.id;

  /// Vérifie si l'utilisateur est authentifié
  static bool get isAuthenticated => currentUser != null;
}
