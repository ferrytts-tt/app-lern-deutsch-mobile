import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'subscription_service.dart';

/// Identifiants des produits d'abonnement configurés dans Google Play Console.
class BillingProductIds {
  static const String monthly = 'hoppla_premium_monthly';
  static const String annual = 'hoppla_premium_annual';
  static const Set<String> all = {monthly, annual};
}

/// Service gérant Google Play Billing / StoreKit via `in_app_purchase`.
class BillingService {
  BillingService._();
  static final BillingService instance = BillingService._();

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;

  bool _isInitialized = false;
  bool _isAvailable = false;
  final Map<String, ProductDetails> _products = {};

  /// Callback optionnel pour informer l'UI (ex: Paywall) des mises à jour d'achat
  void Function(PurchaseStatus status, String? errorMessage)? onPurchaseUpdate;

  bool get isAvailable => _isAvailable;
  Map<String, ProductDetails> get products => Map.unmodifiable(_products);

  bool get _isSupportedPlatform =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  /// Initialise l'écoute du flux d'achats Google Play / App Store.
  Future<void> initialize() async {
    if (_isInitialized || !_isSupportedPlatform) return;
    _isInitialized = true;

    try {
      _isAvailable = await _iap.isAvailable();
      _purchaseSubscription = _iap.purchaseStream.listen(
        _handlePurchaseUpdates,
        onDone: () => _purchaseSubscription?.cancel(),
        onError: (Object error) {
          debugPrint('[BillingService] Erreur stream achats: $error');
          onPurchaseUpdate?.call(PurchaseStatus.error, error.toString());
        },
      );

      if (_isAvailable) {
        await loadProducts();
      }
    } catch (e) {
      debugPrint('[BillingService] Initialisation impossible: $e');
      _isAvailable = false;
    }
  }

  /// Charge les fiches produits (prix localisés) depuis Google Play.
  Future<Map<String, ProductDetails>> loadProducts() async {
    if (!_isSupportedPlatform) return const {};

    try {
      _isAvailable = await _iap.isAvailable();
      if (!_isAvailable) return const {};

      final response = await _iap.queryProductDetails(BillingProductIds.all);
      _products.clear();
      for (final product in response.productDetails) {
        _products[product.id] = product;
      }
      return products;
    } catch (e) {
      debugPrint('[BillingService] Erreur queryProductDetails: $e');
      return const {};
    }
  }

  /// Lance le flux d'achat natif Google Play Billing pour l'abonnement choisi.
  Future<String?> buySubscription(String productId) async {
    if (!_isSupportedPlatform) {
      return 'Les achats Google Play sont disponibles uniquement sur Android et iOS.';
    }

    if (!_isInitialized) {
      await initialize();
    }

    if (!_isAvailable) {
      return 'Google Play Billing est indisponible sur cet appareil.';
    }

    var product = _products[productId];
    if (product == null) {
      await loadProducts();
      product = _products[productId];
    }

    if (product == null) {
      return 'Offre "$productId" non encore configurée sur Google Play Console.';
    }

    try {
      final purchaseParam = PurchaseParam(productDetails: product);
      final started = await _iap.buyNonConsumable(purchaseParam: purchaseParam);
      if (!started) {
        return 'Impossible de démarrer l\'achat Google Play.';
      }
      return null;
    } catch (e) {
      return 'Erreur lors du lancement du paiement: $e';
    }
  }

  /// Restaure les achats existants liés au compte Google Play.
  Future<String?> restorePurchases() async {
    if (!_isSupportedPlatform) {
      return 'La restauration des achats est disponible uniquement sur Android et iOS.';
    }
    if (!_isInitialized) {
      await initialize();
    }
    if (!_isAvailable) {
      return 'Google Play Billing est indisponible sur cet appareil.';
    }

    try {
      await _iap.restorePurchases();
      return null;
    } catch (e) {
      return 'Erreur lors de la restauration: $e';
    }
  }

  Future<void> _handlePurchaseUpdates(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      switch (purchase.status) {
        case PurchaseStatus.pending:
          onPurchaseUpdate?.call(PurchaseStatus.pending, null);
          break;
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          if (BillingProductIds.all.contains(purchase.productID)) {
            await SubscriptionService.instance.activatePremium();
          }
          if (purchase.pendingCompletePurchase) {
            await _iap.completePurchase(purchase);
          }
          onPurchaseUpdate?.call(purchase.status, null);
          break;
        case PurchaseStatus.error:
          if (purchase.pendingCompletePurchase) {
            await _iap.completePurchase(purchase);
          }
          onPurchaseUpdate?.call(
            PurchaseStatus.error,
            purchase.error?.message ?? 'Paiement refusé ou annulé.',
          );
          break;
        case PurchaseStatus.canceled:
          if (purchase.pendingCompletePurchase) {
            await _iap.completePurchase(purchase);
          }
          onPurchaseUpdate?.call(PurchaseStatus.canceled, null);
          break;
      }
    }
  }

  void dispose() {
    _purchaseSubscription?.cancel();
    _purchaseSubscription = null;
  }
}
