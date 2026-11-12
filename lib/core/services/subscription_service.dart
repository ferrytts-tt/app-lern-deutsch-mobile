import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service centralisé de gestion des abonnements, de la monétisation
/// et de l'accès Administrateur sécurisé.
class SubscriptionService {
  SubscriptionService._();
  static final SubscriptionService instance = SubscriptionService._();

  // Empreintes cryptographiques SHA-256 pour la vérification locale
  static const String _adminEmailHash =
      '9d25cfcb1bf204080da56cbe70e005b9dc85ac9086e90fbd22ab433f56ff621b';
  static const String _adminPasswordHash =
      '63c83ef3fe18b821041761fd698ae90699ef83efd346a59796ffe4792e83959b';

  static const String keyIsAdmin = 'is_admin_active';
  static const String keyIsPremium = 'is_premium_active';
  static const String keySubscriptionExpiry = 'subscription_expiry_date';

  bool _isAdminActive = false;
  bool _isPremiumActive = false;
  bool _isInitialized = false;

  /// Notifier réactif pour mettre à jour l'interface instantanément lors d'une connexion
  final ValueNotifier<bool> premiumNotifier = ValueNotifier<bool>(false);

  /// Indique si l'utilisateur bénéficie du statut Premium (ou Admin)
  bool get isPremium => _isAdminActive || _isPremiumActive;

  /// Indique si l'administrateur est actuellement connecté
  bool get isAdmin => _isAdminActive;

  /// Initialise le service en chargeant le statut depuis le stockage local
  Future<void> init({SharedPreferences? prefs}) async {
    if (_isInitialized) return;
    final p = prefs ?? await SharedPreferences.getInstance();
    _isAdminActive = p.getBool(keyIsAdmin) ?? false;
    _isPremiumActive = p.getBool(keyIsPremium) ?? false;

    // Si admin, il est automatiquement et toujours Premium
    if (_isAdminActive) {
      _isPremiumActive = true;
    }

    premiumNotifier.value = isPremium;
    _isInitialized = true;
  }

  /// Vérifie si un lot d'apprentissage (1 à 30) est accessible
  /// Lots 1, 2, 3 (index 0, 1, 2) : 100% GRATUITS pour tous les candidats
  /// Lots 4 à 30 (index 3 à 29) : Réservés aux membres Premium / Admin
  bool isBatchAccessible(int batchIndex) {
    if (batchIndex <= 2) return true; // Lots 1, 2, 3 gratuits
    return isPremium;
  }

  /// Vérifie si un niveau de mots croisés Rätsel est accessible
  /// Niveaux 1, 2, 3 : 100% GRATUITS pour tous les candidats
  /// Niveaux 4+ : Réservés aux membres Premium / Admin
  bool isRaetselLevelAccessible(int levelNumber) {
    if (levelNumber <= 3) return true; // Niveaux 1, 2, 3 gratuits
    return isPremium;
  }

  /// Connexion Administrateur sécurisée par comparaison de hash SHA-256
  Future<bool> verifyAndLoginAdmin({
    required String email,
    required String password,
    SharedPreferences? prefs,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    final cleanPassword = password.trim();

    final inputEmailHash = sha256.convert(utf8.encode(cleanEmail)).toString();
    final inputPasswordHash = sha256.convert(utf8.encode(cleanPassword)).toString();

    if (inputEmailHash == _adminEmailHash && inputPasswordHash == _adminPasswordHash) {
      final p = prefs ?? await SharedPreferences.getInstance();
      _isAdminActive = true;
      _isPremiumActive = true;
      await p.setBool(keyIsAdmin, true);
      await p.setBool(keyIsPremium, true);
      premiumNotifier.value = true;
      return true;
    }
    return false;
  }

  /// Déconnexion de l'espace Administrateur
  Future<void> logoutAdmin({SharedPreferences? prefs}) async {
    final p = prefs ?? await SharedPreferences.getInstance();
    _isAdminActive = false;
    _isPremiumActive = false;
    await p.setBool(keyIsAdmin, false);
    await p.setBool(keyIsPremium, false);
    premiumNotifier.value = false;
  }

  /// Activation de l'abonnement Premium (après paiement ou achat)
  Future<void> activatePremium({SharedPreferences? prefs}) async {
    final p = prefs ?? await SharedPreferences.getInstance();
    _isPremiumActive = true;
    await p.setBool(keyIsPremium, true);
    premiumNotifier.value = true;
  }

  /// Activation via un code d'activation / bon d'achat
  Future<bool> activateWithCode(String code, {SharedPreferences? prefs}) async {
    final cleanCode = code.trim().toUpperCase();
    final validCodes = ['HOPPLA-PRO', 'DEUTSCH-2025', 'VIP-TAHA', 'GERMAN-VIP'];

    if (validCodes.contains(cleanCode) || cleanCode.startsWith('PRO-')) {
      await activatePremium(prefs: prefs);
      return true;
    }
    return false;
  }
}
