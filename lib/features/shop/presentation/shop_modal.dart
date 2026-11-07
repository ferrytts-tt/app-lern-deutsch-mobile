import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/services/pronunciation_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/duo_confetti.dart';
import '../../../data/database/app_database.dart';
import '../../../domain/models/user_profile.dart';

/// Modal & Écran de la Boutique Hoppla ! (Échange des Diamants 💎)
class ShopModal extends StatefulWidget {
  final VoidCallback? onPurchased;

  const ShopModal({super.key, this.onPurchased});

  static Future<void> show(BuildContext context, {VoidCallback? onPurchased}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ShopModal(onPurchased: onPurchased),
    );
  }

  @override
  State<ShopModal> createState() => _ShopModalState();
}

class _ShopModalState extends State<ShopModal> {
  int _totalGems = 0;
  int _examJokers = 0;
  bool _hasStreakFreeze = false;
  bool _isDoubleXpActive = false;
  String _doubleXpTimeRemaining = '';
  bool _isWagerActive = false;
  int _wagerDaysRemaining = 7;
  bool _isBerlinPackUnlocked = false;
  bool _isBavarianCostumeEquipped = false;
  UserProfile? _profile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadShopData();
  }

  Future<void> _loadShopData() async {
    final prefs = await SharedPreferences.getInstance();
    final profile = await AppDatabase.instance.getUserProfile();

    final gems = prefs.getInt('total_gems') ?? 0;
    final jokers = prefs.getInt('exam_joker_count') ?? 0;
    final streakFreeze = profile.gelSerieDisponible;
    final berlinPack = prefs.getBool('berlin_pack_unlocked') ?? false;
    final bavarian = prefs.getBool('mascot_costume_bavarian') ?? false;

    // Double XP check
    final doubleXpUntilStr = prefs.getString('double_xp_until');
    bool doubleXpActive = false;
    String remaining = '';
    if (doubleXpUntilStr != null) {
      final until = DateTime.tryParse(doubleXpUntilStr);
      if (until != null && until.isAfter(DateTime.now())) {
        doubleXpActive = true;
        final diff = until.difference(DateTime.now()).inMinutes;
        remaining = '${diff + 1} min';
      }
    }

    // Wager check (Quitte ou double 7 jours)
    final wagerActive = prefs.getBool('wager_active') ?? false;
    int wagerDays = 7;
    if (wagerActive) {
      final startStr = prefs.getString('wager_start_date');
      if (startStr != null) {
        final start = DateTime.tryParse(startStr);
        if (start != null) {
          final daysPassed = DateTime.now().difference(start).inDays;
          wagerDays = (7 - daysPassed).clamp(0, 7);
        }
      }
    }

    if (mounted) {
      setState(() {
        _totalGems = gems;
        _examJokers = jokers;
        _hasStreakFreeze = streakFreeze;
        _isDoubleXpActive = doubleXpActive;
        _doubleXpTimeRemaining = remaining;
        _isWagerActive = wagerActive;
        _wagerDaysRemaining = wagerDays;
        _isBerlinPackUnlocked = berlinPack;
        _isBavarianCostumeEquipped = bavarian;
        _profile = profile;
        _isLoading = false;
      });
    }
  }

  Future<void> _buyItem({
    required String name,
    required int cost,
    required Future<void> Function() onApply,
  }) async {
    if (_totalGems < cost) {
      final missing = cost - _totalGems;
      _showNotEnoughGemsDialog(missing);
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final newGems = _totalGems - cost;
    await prefs.setInt('total_gems', newGems);

    await onApply();

    PronunciationService.instance.playSuccessSound();

    if (mounted) {
      setState(() {
        _totalGems = newGems;
      });
      widget.onPurchased?.call();
      _showSuccessPurchaseDialog(name, cost);
    }
  }

  void _showNotEnoughGemsDialog(int missingGems) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Row(
          children: [
            Icon(Icons.diamond_rounded, size: 24, color: Color(0xFF0284C7)),
            SizedBox(width: 8),
            Text('Diamants insuffisants', style: TextStyle(fontWeight: FontWeight.w900)),
          ],
        ),
        content: Text(
          'Il te manque $missingGems diamants pour acquérir cet article.\n\n'
          '💡 Astuce : Termine tes quêtes quotidiennes, réussis le Grand Examen de Palier (+25 💎) ou ouvre ton coffre du jour pour en récolter !',
          style: const TextStyle(fontSize: 13, height: 1.45),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Compris', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showSuccessPurchaseDialog(String itemName, int cost) {
    showDialog(
      context: context,
      builder: (ctx) => Stack(
        alignment: Alignment.center,
        children: [
          const Positioned.fill(
            child: DuoConfettiOverlay(
              isPlaying: true,
              child: SizedBox.expand(),
            ),
          ),
          AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
            title: const Row(
              children: [
                Icon(Icons.celebration_rounded, size: 24, color: AppColors.secondary),
                SizedBox(width: 8),
                Text('Achat réussi !', style: TextStyle(fontWeight: FontWeight.w900)),
              ],
            ),
            content: Text(
              'Félicitations ! Tu as débloqué : $itemName.\n-$cost diamants ont été déduits de ton solde.',
              style: const TextStyle(fontSize: 13, height: 1.4),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Super !', style: TextStyle(fontWeight: FontWeight.w800)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      height: screenHeight * 0.88,
      decoration: BoxDecoration(
        color: isDark ? AppColors.backgroundDark : const Color(0xFFF8FAFC),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 20, spreadRadius: 4),
        ],
      ),
      child: Column(
        children: [
          // Poignée supérieure
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 44,
            height: 5,
            decoration: BoxDecoration(
              color: isDark ? Colors.white24 : Colors.black12,
              borderRadius: BorderRadius.circular(10),
            ),
          ),

          // En-tête de la Boutique
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE0F2FE),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.storefront_rounded, size: 22, color: Color(0xFF0284C7)),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Boutique Hoppla !',
                          style: AppTextStyles.titleMedium(isDark: isDark).copyWith(
                            fontWeight: FontWeight.w900,
                            fontSize: 19,
                          ),
                        ),
                        Text(
                          'Échange tes diamants contre des bonus',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                // Solde de diamants actuel
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0C243B) : const Color(0xFFE0F2FE),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF0284C7).withValues(alpha: 0.4),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.diamond_rounded, size: 16, color: Color(0xFF0284C7)),
                      const SizedBox(width: 6),
                      Text(
                        '$_totalGems',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0284C7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Contenu déroulant
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Titre section Boosts
                        Row(
                          children: [
                            const Icon(Icons.bolt_rounded, size: 16, color: Color(0xFFF59E0B)),
                            const SizedBox(width: 6),
                            Text(
                              'BONUS & AVANTAGES EXCLUSIFS',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // 1. Gel de Série
                        _buildShopItem(
                          isDark: isDark,
                          iconData: Icons.ac_unit_rounded,
                          iconColor: const Color(0xFF0288D1),
                          iconBg: isDark ? const Color(0xFF0E2A3F) : const Color(0xFFE0F2FE),
                          title: 'Gel de Série (Streak Freeze)',
                          description: 'Protège ta série si tu manques un jour d\'entraînement.',
                          price: 50,
                          isPurchased: _hasStreakFreeze,
                          statusLabel: _hasStreakFreeze ? 'Actif (1/1)' : null,
                          onBuy: () => _buyItem(
                            name: 'Gel de Série',
                            cost: 50,
                            onApply: () async {
                              final p = _profile ?? await AppDatabase.instance.getUserProfile();
                              final updated = p.copyWith(gelSerieDisponible: true);
                              await AppDatabase.instance.saveUserProfile(updated);
                              final prefs = await SharedPreferences.getInstance();
                              await prefs.setBool('has_streak_freeze', true);
                              setState(() {
                                _hasStreakFreeze = true;
                                _profile = updated;
                              });
                            },
                          ),
                        ),

                        const SizedBox(height: 12),

                        // 2. Joker Seconde Chance (Examen de Palier)
                        _buildShopItem(
                          isDark: isDark,
                          iconData: Icons.auto_awesome_rounded,
                          iconColor: const Color(0xFFF59E0B),
                          iconBg: isDark ? const Color(0xFF332608) : const Color(0xFFFEF3C7),
                          title: 'Joker "Seconde Chance" (Examen)',
                          description: 'Annule 2 fautes lors du Grand Examen de Palier (30 Q) pour atteindre les 20/30.',
                          price: 40,
                          statusLabel: _examJokers > 0 ? 'Possédé : $_examJokers' : null,
                          onBuy: () => _buyItem(
                            name: 'Joker Seconde Chance',
                            cost: 40,
                            onApply: () async {
                              final prefs = await SharedPreferences.getInstance();
                              final newCount = _examJokers + 1;
                              await prefs.setInt('exam_joker_count', newCount);
                              setState(() => _examJokers = newCount);
                            },
                          ),
                        ),

                        const SizedBox(height: 12),

                        // 3. Potion Double XP
                        _buildShopItem(
                          isDark: isDark,
                          iconData: Icons.bolt_rounded,
                          iconColor: const Color(0xFF16A34A),
                          iconBg: isDark ? const Color(0xFF0D2818) : const Color(0xFFDCFCE7),
                          title: 'Potion Double XP (15 min)',
                          description: 'Double tous tes gains d\'XP pendant 15 minutes sur les séances et défis.',
                          price: 30,
                          isPurchased: _isDoubleXpActive,
                          statusLabel: _isDoubleXpActive ? 'Actif ($_doubleXpTimeRemaining)' : null,
                          onBuy: () => _buyItem(
                            name: 'Potion Double XP (15 min)',
                            cost: 30,
                            onApply: () async {
                              final prefs = await SharedPreferences.getInstance();
                              final until = DateTime.now().add(const Duration(minutes: 15));
                              await prefs.setString('double_xp_until', until.toIso8601String());
                              setState(() {
                                _isDoubleXpActive = true;
                                _doubleXpTimeRemaining = '15 min';
                              });
                            },
                          ),
                        ),

                        const SizedBox(height: 12),

                        // 4. Quitte ou Double (Pari de Série 7 Jours)
                        _buildShopItem(
                          isDark: isDark,
                          iconData: Icons.track_changes_rounded,
                          iconColor: const Color(0xFF7C3AED),
                          iconBg: isDark ? const Color(0xFF261545) : const Color(0xFFEDE9FE),
                          title: 'Quitte ou Double (Pari 7 Jours)',
                          description: 'Mise 20 diamants. Étudie 7 jours d\'affilée pour remporter 40 diamants (bénéfice x2) !',
                          price: 20,
                          isPurchased: _isWagerActive,
                          statusLabel: _isWagerActive ? 'En cours : $_wagerDaysRemaining j restants' : null,
                          onBuy: () => _buyItem(
                            name: 'Pari Quitte ou Double 7 Jours',
                            cost: 20,
                            onApply: () async {
                              final prefs = await SharedPreferences.getInstance();
                              await prefs.setBool('wager_active', true);
                              await prefs.setString('wager_start_date', DateTime.now().toIso8601String());
                              setState(() {
                                _isWagerActive = true;
                                _wagerDaysRemaining = 7;
                              });
                            },
                          ),
                        ),

                        const SizedBox(height: 12),

                        // 5. Pack Audio Argot & Vraie Vie Berlinoise
                        _buildShopItem(
                          isDark: isDark,
                          iconData: Icons.record_voice_over_rounded,
                          iconColor: const Color(0xFF0284C7),
                          iconBg: isDark ? const Color(0xFF0C243B) : const Color(0xFFE0F2FE),
                          title: 'Pack Audio Secret "Argot Berlinois"',
                          description: 'Débloque 10 formules allemandes ultra-authentiques de la rue berlinoise avec audio natif.',
                          price: 100,
                          isPurchased: _isBerlinPackUnlocked,
                          statusLabel: _isBerlinPackUnlocked ? '✅ Débloqué' : null,
                          onBuy: () => _buyItem(
                            name: 'Pack Audio Secret "Argot Berlinois"',
                            cost: 100,
                            onApply: () async {
                              final prefs = await SharedPreferences.getInstance();
                              await prefs.setBool('berlin_pack_unlocked', true);
                              setState(() => _isBerlinPackUnlocked = true);
                            },
                          ),
                        ),

                        const SizedBox(height: 12),

                        // 6. Chapeau Bavarois Traditionnel Mascotte
                        _buildShopItem(
                          isDark: isDark,
                          iconData: Icons.celebration_rounded,
                          iconColor: const Color(0xFFDB2777),
                          iconBg: isDark ? const Color(0xFF330C23) : const Color(0xFFFCE7F3),
                          title: 'Chapeau Bavarois pour Hoppla',
                          description: 'Habille l\'écureuil d\'un superbe chapeau bavarois traditionnel pour fêter tes réussites !',
                          price: 60,
                          isPurchased: _isBavarianCostumeEquipped,
                          statusLabel: _isBavarianCostumeEquipped ? '✅ Équipé' : null,
                          onBuy: () => _buyItem(
                            name: 'Chapeau Bavarois pour Hoppla',
                            cost: 60,
                            onApply: () async {
                              final prefs = await SharedPreferences.getInstance();
                              await prefs.setBool('mascot_costume_bavarian', true);
                              setState(() => _isBavarianCostumeEquipped = true);
                            },
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Section d'incitation : Comment gagner plus de diamants ?
                        _buildHowToEarnCard(isDark: isDark),

                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildShopItem({
    required bool isDark,
    required IconData iconData,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String description,
    required int price,
    required VoidCallback onBuy,
    bool isPurchased = false,
    String? statusLabel,
  }) {
    final canAfford = _totalGems >= price;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isPurchased
              ? AppColors.primary.withValues(alpha: 0.45)
              : (isDark ? AppColors.borderDark : AppColors.borderLight),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icône produit
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: Icon(iconData, size: 24, color: iconColor),
          ),
          const SizedBox(width: 14),

          // Détails
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                    if (statusLabel != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isPurchased
                              ? (isDark ? const Color(0xFF14301E) : const Color(0xFFDCFCE7))
                              : (isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          statusLabel,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: isPurchased
                                ? AppColors.primary
                                : (isDark ? Colors.white70 : Colors.black87),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 11,
                    height: 1.35,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: 12),

                // Bouton d'achat
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: isPurchased ? null : onBuy,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isPurchased
                          ? Colors.grey.shade400
                          : (canAfford ? const Color(0xFF0284C7) : Colors.grey.shade600),
                      foregroundColor: Colors.white,
                      elevation: isPurchased ? 0 : 2,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!isPurchased) ...[
                          const Icon(Icons.diamond_rounded, size: 13, color: Colors.white),
                          const SizedBox(width: 4),
                          Text(
                            '$price',
                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
                          ),
                          const SizedBox(width: 6),
                        ],
                        Text(
                          isPurchased ? 'Possédé' : 'Acheter',
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHowToEarnCard({required bool isDark}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFF38BDF8).withValues(alpha: 0.35),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.diamond_rounded, size: 16, color: Color(0xFF0284C7)),
              SizedBox(width: 8),
              Text(
                'Comment gagner plus de diamants ?',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                  color: Color(0xFF0284C7),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildEarnRow(Icons.track_changes_rounded, const Color(0xFFD97706), 'Terminer les 3 quêtes du jour', '+25 dans le coffre', isDark),
          const SizedBox(height: 8),
          _buildEarnRow(Icons.school_rounded, AppColors.primary, 'Réussir le Grand Examen de Palier (30 Q)', '+25 & +100 XP', isDark),
          const SizedBox(height: 8),
          _buildEarnRow(Icons.bolt_rounded, const Color(0xFFF59E0B), 'Défi Master XP sans-faute (10/10)', '+5', isDark),
          const SizedBox(height: 8),
          _buildEarnRow(Icons.local_fire_department_rounded, const Color(0xFFFF9600), 'Maintenir une série de 7 jours', '+20', isDark),
        ],
      ),
    );
  }

  Widget _buildEarnRow(IconData iconData, Color iconColor, String title, String reward, bool isDark) {
    return Row(
      children: [
        Icon(iconData, size: 16, color: iconColor),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : const Color(0xFF334155),
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(
            color: const Color(0xFF0284C7).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                reward,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0284C7),
                ),
              ),
              const SizedBox(width: 3),
              const Icon(Icons.diamond_rounded, size: 10, color: Color(0xFF0284C7)),
            ],
          ),
        ),
      ],
    );
  }
}
