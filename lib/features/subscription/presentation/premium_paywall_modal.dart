import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../../../core/services/billing_service.dart';
import '../../../core/services/subscription_service.dart';
import '../../../core/theme/app_colors.dart';

/// Modal d'Abonnement Premium (Paywall) & Accès Administrateur discret
class PremiumPaywallModal extends StatefulWidget {
  final String? triggeredFeature;

  const PremiumPaywallModal({
    super.key,
    this.triggeredFeature,
  });

  static Future<bool?> show(BuildContext context, {String? triggeredFeature}) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => PremiumPaywallModal(triggeredFeature: triggeredFeature),
    );
  }

  @override
  State<PremiumPaywallModal> createState() => _PremiumPaywallModalState();
}

class _PremiumPaywallModalState extends State<PremiumPaywallModal> {
  int _selectedPlanIndex = 1; // 0 = Mensuel, 1 = Annuel
  bool _isProcessingPurchase = false;
  Map<String, ProductDetails> _storeProducts = {};
  final TextEditingController _codeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initBilling();
  }

  Future<void> _initBilling() async {
    BillingService.instance.onPurchaseUpdate = (status, errorMessage) {
      if (!mounted) return;
      setState(() => _isProcessingPurchase = status == PurchaseStatus.pending);

      if (status == PurchaseStatus.purchased || status == PurchaseStatus.restored) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              status == PurchaseStatus.restored
                  ? '✅ Abonnement restauré avec succès !'
                  : '🎉 Abonnement Hoppla Pro activé !',
            ),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
      } else if (status == PurchaseStatus.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ ${errorMessage ?? "Achat impossible."}'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    };

    await BillingService.instance.initialize();
    final products = await BillingService.instance.loadProducts();
    if (mounted) {
      setState(() => _storeProducts = products);
    }
  }

  @override
  void dispose() {
    BillingService.instance.onPurchaseUpdate = null;
    _codeController.dispose();
    super.dispose();
  }

  void _showAdminLoginDialog() {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    bool isAuthenticating = false;
    String? errorMessage;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.admin_panel_settings_rounded, color: AppColors.primary, size: 26),
              SizedBox(width: 10),
              Text('Espace Administrateur', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Authentification sécurisée réservée à l\'administrateur de l\'application.',
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Adresse e-mail',
                    prefixIcon: const Icon(Icons.email_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Mot de passe',
                    prefixIcon: const Icon(Icons.lock_outline_rounded),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                if (errorMessage != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    errorMessage!,
                    style: const TextStyle(color: Colors.red, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: isAuthenticating
                  ? null
                  : () async {
                      setDialogState(() {
                        isAuthenticating = true;
                        errorMessage = null;
                      });

                      final success = await SubscriptionService.instance.verifyAndLoginAdmin(
                        email: emailController.text,
                        password: passwordController.text,
                      );

                      if (success) {
                        if (dialogCtx.mounted) Navigator.of(dialogCtx).pop();
                        if (mounted) {
                          Navigator.of(context).pop(true);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Row(
                                children: [
                                  Icon(Icons.verified_rounded, color: Colors.white),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      '👑 Bienvenue Administrateur ! Accès total débloqué à vie.',
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                              backgroundColor: Color(0xFF10B981),
                              duration: Duration(seconds: 4),
                            ),
                          );
                        }
                      } else {
                        setDialogState(() {
                          isAuthenticating = false;
                          errorMessage = 'Identifiants incorrects. Accès refusé.';
                        });
                      }
                    },
              child: isAuthenticating
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Se connecter'),
            ),
          ],
        ),
      ),
    );
  }

  void _showActivationCodeDialog() {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.vpn_key_rounded, color: Color(0xFFF59E0B)),
            SizedBox(width: 10),
            Text('Activer un code', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Entrez votre code promotionnel :',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _codeController,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                hintText: 'EX: HOPPLA-PRO',
                prefixIcon: const Icon(Icons.confirmation_number_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              final code = _codeController.text;
              if (code.isEmpty) return;

              final success = await SubscriptionService.instance.activateWithCode(code);
              if (dialogCtx.mounted) Navigator.of(dialogCtx).pop();

              if (success && mounted) {
                Navigator.of(context).pop(true);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('🎉 Code activé avec succès ! Statut Premium débloqué.'),
                    backgroundColor: Color(0xFF10B981),
                  ),
                );
              } else if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('❌ Code invalide ou expiré.'),
                    backgroundColor: Colors.redAccent,
                  ),
                );
              }
            },
            child: const Text('Valider le code'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0F172A) : Colors.white;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.92,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 20, spreadRadius: 4),
        ],
      ),
      child: Column(
        children: [
          // Poignée supérieure
          Container(
            width: 44,
            height: 5,
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(10),
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Column(
                children: [
                  // Badge Couronne Dorée
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFBBF24), Color(0xFFD97706)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFF59E0B).withValues(alpha: 0.35),
                          blurRadius: 16,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.workspace_premium_rounded,
                      size: 44,
                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 16),

                  Text(
                    'Passez à Hoppla Pro',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    widget.triggeredFeature ??
                        'Débloquez les 30 lots, tous les examens et mots croisés illimités !',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.grey[300] : Colors.grey[600],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Liste des fonctionnalités incluses
                  _buildFeatureRow(
                    icon: Icons.auto_stories_rounded,
                    title: '411 Phrases complètes (Lots 4 à 30)',
                    subtitle: 'Vocabulaire essentiel B1/B2 avec audio natif & micro',
                    isDark: isDark,
                  ),
                  _buildFeatureRow(
                    icon: Icons.school_rounded,
                    title: 'Tous les Grands Examens (Paliers 2 à 10)',
                    subtitle: 'Certificats de palier et validation officielle',
                    isDark: isDark,
                  ),
                  _buildFeatureRow(
                    icon: Icons.grid_on_rounded,
                    title: 'Mots Croisés (Rätsel) Niveaux 4+ illimités',
                    subtitle: 'Jouez sans restriction de diamants',
                    isDark: isDark,
                  ),
                  _buildFeatureRow(
                    icon: Icons.headset_rounded,
                    title: 'Écoute passive & Dialogues en continu',
                    subtitle: 'Entraînez votre oreille en arrière-plan',
                    isDark: isDark,
                  ),
                  _buildFeatureRow(
                    icon: Icons.block_rounded,
                    title: 'Expérience 100% Sans Publicité',
                    subtitle: 'Apprentissage fluide sans interruption plein écran',
                    isDark: isDark,
                  ),

                  const SizedBox(height: 22),

                  // Grille de sélection des plans
                  Row(
                    children: [
                      // Plan Mensuel
                      Expanded(
                        child: _buildPlanCard(
                          index: 0,
                          title: 'Mensuel',
                          price: _storeProducts[BillingProductIds.monthly]?.price ?? '4,99 €',
                          period: '/ mois',
                          badge: null,
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Plan Annuel
                      Expanded(
                        child: _buildPlanCard(
                          index: 1,
                          title: 'Annuel',
                          price: _storeProducts[BillingProductIds.annual]?.price ?? '29,99 €',
                          period: '/ an',
                          badge: '-50% ÉCONOMIE',
                          isDark: isDark,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 22),

                  // Bouton Principal d'action (Google Play Billing)
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: _isProcessingPurchase
                          ? null
                          : () async {
                              final productId = _selectedPlanIndex == 1
                                  ? BillingProductIds.annual
                                  : BillingProductIds.monthly;
                              setState(() => _isProcessingPurchase = true);
                              final error = await BillingService.instance.buySubscription(productId);
                              if (!context.mounted) return;
                              if (error != null) {
                                setState(() => _isProcessingPurchase = false);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(error),
                                    backgroundColor: Colors.orange.shade800,
                                  ),
                                );
                              }
                            },
                      child: _isProcessingPurchase
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                            )
                          : Text(
                              _selectedPlanIndex == 1
                                  ? 'S\'abonner (${_storeProducts[BillingProductIds.annual]?.price ?? "29,99 €"}/an)'
                                  : 'S\'abonner (${_storeProducts[BillingProductIds.monthly]?.price ?? "4,99 €"}/mois)',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Restaurer les achats Google Play + Code promo
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton.icon(
                        onPressed: _isProcessingPurchase
                            ? null
                            : () async {
                                final error = await BillingService.instance.restorePurchases();
                                if (!context.mounted) return;
                                if (error != null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(error)),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Vérification des achats Google Play en cours...')),
                                  );
                                }
                              },
                        icon: const Icon(Icons.restore_rounded, size: 17, color: AppColors.primary),
                        label: const Text(
                          'Restaurer',
                          style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.primary, fontSize: 13),
                        ),
                      ),
                      const SizedBox(width: 8),
                      TextButton.icon(
                        onPressed: _showActivationCodeDialog,
                        icon: const Icon(Icons.vpn_key_rounded, size: 17, color: Color(0xFFF59E0B)),
                        label: const Text(
                          'Code promo',
                          style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFFF59E0B), fontSize: 13),
                        ),
                      ),
                    ],
                  ),

                  const Divider(height: 24),

                  // Accès Administrateur discret
                  InkWell(
                    onTap: _showAdminLoginDialog,
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.admin_panel_settings_outlined, size: 16, color: Colors.grey[500]),
                          const SizedBox(width: 6),
                          Text(
                            'Connexion Administrateur',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCard({
    required int index,
    required String title,
    required String price,
    required String period,
    required String? badge,
    required bool isDark,
  }) {
    final isSelected = _selectedPlanIndex == index;
    final borderColor = isSelected ? const Color(0xFF10B981) : Colors.grey.withValues(alpha: 0.25);
    final cardBg = isSelected
        ? (isDark ? const Color(0xFF132F23) : const Color(0xFFECFDF5))
        : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC));

    return InkWell(
      onTap: () => setState(() => _selectedPlanIndex = index),
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor, width: isSelected ? 2 : 1),
            ),
            child: Column(
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  price,
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                    color: isSelected ? const Color(0xFF10B981) : (isDark ? Colors.white : Colors.black87),
                  ),
                ),
                Text(
                  period,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          if (badge != null)
            Positioned(
              top: -10,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    badge,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
