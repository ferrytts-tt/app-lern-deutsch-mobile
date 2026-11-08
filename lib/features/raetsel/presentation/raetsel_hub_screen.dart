import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_lern_deutsch_mobile/core/theme/app_colors.dart';
import 'package:app_lern_deutsch_mobile/data/database/app_database.dart';
import '../../../core/services/subscription_service.dart';
import '../../subscription/presentation/premium_paywall_modal.dart';
import '../domain/models/raetsel_level.dart';
import '../domain/raetsel_manager.dart';
import 'raetsel_game_screen.dart';

/// Point d'entrée de l'onglet Hoppla Rätsel.
/// Gère la restauration des niveaux abandonnés, la génération automatique
/// du niveau suivant à partir du pool de phrases, et l'affichage de l'état verrouillé.
class RaetselHubScreen extends ConsumerStatefulWidget {
  const RaetselHubScreen({super.key});

  @override
  ConsumerState<RaetselHubScreen> createState() => _RaetselHubScreenState();
}

class _RaetselHubScreenState extends ConsumerState<RaetselHubScreen> {
  final RaetselManager _manager = RaetselManager.instance;
  final AppDatabase _db = AppDatabase.instance;

  bool _isLoading = true;
  bool _isUnlocked = false;
  int _learnedPalier1Count = 0;
  int _currentLevelNum = 1;
  RaetselLevel? _currentLevel;
  Map<int, String>? _restoredEnteredLetters;

  @override
  void initState() {
    super.initState();
    _initLevel();
  }

  Future<void> _initLevel() async {
    setState(() => _isLoading = true);

    try {
      // S'assurer que les phrases sont prêtes dans la base locale
      var allPhrases = await _db.getAllPhrases();
      if (allPhrases.isEmpty) {
        await _db.importPhrasesFromJson();
      }

      final unlocked = await _manager.isUnlocked();
      final palier1Count = await _manager.getPalier1LearnedCount(_db);
      final currentLevel = await _manager.getCurrentLevelNumber();

      if (!unlocked) {
        if (mounted) {
          setState(() {
            _isUnlocked = false;
            _learnedPalier1Count = palier1Count;
            _isLoading = false;
          });
        }
        return;
      }

      // Si débloqué : vérifier s'il existe une sauvegarde de niveau en cours
      final savedData = await _manager.loadInProgressLevel(expectedLevelNumber: currentLevel);

      RaetselLevel activeLevel;
      Map<int, String>? initialLetters;

      if (savedData != null) {
        activeLevel = savedData.level;
        initialLetters = savedData.enteredLetters;
      } else {
        // Générer un nouveau niveau à partir du pool
        final pool = await _manager.loadPhrasesPool(_db);
        if (pool.isEmpty) {
          if (mounted) {
            setState(() {
              _isUnlocked = false;
              _learnedPalier1Count = palier1Count;
              _isLoading = false;
            });
          }
          return;
        }

        activeLevel = _manager.generateLevel(
          levelNumber: currentLevel,
          pool: pool,
        );
        // Sauvegarder dès la création
        await _manager.saveInProgressLevel(
          level: activeLevel,
          enteredLetters: {},
        );
      }

      if (mounted) {
        setState(() {
          _isUnlocked = true;
          _learnedPalier1Count = palier1Count;
          _currentLevelNum = currentLevel;
          _currentLevel = activeLevel;
          _restoredEnteredLetters = initialLetters;
          _isLoading = false;
        });
      }
    } catch (e, stack) {
      debugPrint('[RaetselHubScreen] Erreur initLevel: $e\n$stack');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isUnlocked = false;
        });
      }
    }
  }

  Future<void> _onLevelFinished() async {
    // Passer au niveau suivant
    await _manager.advanceToNextLevel();
    await _initLevel();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    // Écran d'état verrouillé si Examen 1 non encore passé
    if (!_isUnlocked) {
      return Scaffold(
        backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
          title: const Text('Hoppla Rätsel 🧩'),
          elevation: 0,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        color: (isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1))
                            .withOpacity(0.4),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.extension_rounded,
                        size: 48,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.lock_rounded,
                        size: 22,
                        color: AppColors.accent,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Text(
                  'Mode Verrouillé',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Réussis l\'Examen 1 (20/30) pour débloquer Hoppla Rätsel',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white70 : const Color(0xFF334155),
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Phrases apprises',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            '$_learnedPalier1Count / 30',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              color: AppColors.accent,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: (_learnedPalier1Count / 30.0).clamp(0.0, 1.0),
                          minHeight: 10,
                          backgroundColor:
                              isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accent),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Écran d'état verrouillé pour les niveaux 4+ si non-premium
    if (_currentLevelNum >= 4 && !SubscriptionService.instance.isPremium) {
      return Scaffold(
        backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
          title: const Text('Hoppla Rätsel 🧩'),
          elevation: 0,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.workspace_premium_rounded,
                    size: 50,
                    color: Color(0xFFF59E0B),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Niveau $_currentLevelNum réservé à Hoppla Pro',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Bravo d\'avoir terminé les 3 premiers niveaux gratuits ! Passez à Hoppla Pro pour continuer votre aventure de mots croisés sans aucune limite.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.white70 : const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: () async {
                      final res = await PremiumPaywallModal.show(
                        context,
                        triggeredFeature: 'Débloquez tous les niveaux de mots croisés Rätsel en illimité !',
                      );
                      if (res == true && mounted) {
                        _initLevel();
                      }
                    },
                    icon: const Icon(Icons.workspace_premium_rounded, size: 20),
                    label: const Text(
                      'Débloquer Hoppla Pro',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Écran de jeu actif
    return RaetselGameScreen(
      key: ValueKey('raetsel_level_$_currentLevelNum'),
      level: _currentLevel!,
      initialEnteredLetters: _restoredEnteredLetters,
      onLevelCompleted: _onLevelFinished,
    );
  }
}
