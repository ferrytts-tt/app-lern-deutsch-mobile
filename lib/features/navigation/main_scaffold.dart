import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../data/database/app_database.dart';
import '../raetsel/domain/raetsel_manager.dart';
import '../raetsel/presentation/widgets/raetsel_locked_dialog.dart';

/// Échafaudage principal avec la barre de navigation à 5 onglets :
/// [Accueil, Écoute, Rätsel 🧩, Progrès, Réglages].
class MainScaffold extends StatefulWidget {
  static bool enableAnimations = true;
  final StatefulNavigationShell navigationShell;

  const MainScaffold({
    super.key,
    required this.navigationShell,
  });

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> with SingleTickerProviderStateMixin {
  final RaetselManager _raetselManager = RaetselManager.instance;
  final AppDatabase _db = AppDatabase.instance;

  bool _isRaetselUnlocked = false;
  int _palier1LearnedCount = 0;
  AnimationController? _pulseController;

  @override
  void initState() {
    super.initState();
    if (MainScaffold.enableAnimations) {
      _pulseController = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1200),
      )..repeat(reverse: true);
    }

    _checkRaetselStatus();
    _raetselManager.unlockNotifier.addListener(_onUnlockNotifierChanged);
  }

  @override
  void dispose() {
    _raetselManager.unlockNotifier.removeListener(_onUnlockNotifierChanged);
    _pulseController?.dispose();
    super.dispose();
  }

  void _onUnlockNotifierChanged() {
    _checkRaetselStatus();
  }

  Future<void> _checkRaetselStatus() async {
    final unlocked = await _raetselManager.isUnlocked();
    final count = await _raetselManager.getPalier1LearnedCount(_db);
    final justUnlocked = await _raetselManager.checkAndClearJustUnlocked();

    if (mounted) {
      setState(() {
        _isRaetselUnlocked = unlocked;
        _palier1LearnedCount = count;
      });

      if (justUnlocked) {
        // Notification / Message célébrant le déblocage
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.primaryDark,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            content: const Row(
              children: [
                Icon(Icons.extension_rounded, color: Colors.white),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '🎉 Hoppla Rätsel débloqué ! Mots croisés disponibles !',
                    style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    }
  }

  void _onTap(int index) {
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }

  void _onRaetselTap() {
    if (_isRaetselUnlocked) {
      _onTap(2);
    } else {
      // Afficher la boîte de dialogue explicative avec jauge (x/30)
      final isDark = Theme.of(context).brightness == Brightness.dark;
      RaetselLockedDialog.show(
        context,
        learnedCount: _palier1LearnedCount,
        isDark: isDark,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final currentIndex = widget.navigationShell.currentIndex;

    return Scaffold(
      body: widget.navigationShell,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: surfaceColor,
          border: Border(
            top: BorderSide(color: borderColor, width: 1),
          ),
          boxShadow: [
            if (!isDark)
              BoxShadow(
                color: AppColors.textPrimaryLight.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, -2),
              ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // 1. Accueil
                _NavBarItem(
                  selectedIcon: Icons.cottage_rounded,
                  unselectedIcon: Icons.cottage_outlined,
                  label: 'Accueil',
                  isSelected: currentIndex == 0,
                  onTap: () => _onTap(0),
                ),

                // 2. Écoute
                _NavBarItem(
                  selectedIcon: Icons.headphones_rounded,
                  unselectedIcon: Icons.headphones_outlined,
                  label: 'Écoute',
                  isSelected: currentIndex == 1,
                  onTap: () => _onTap(1),
                ),

                // 3. Rätsel (Mots croisés - Pièce de puzzle)
                _RaetselNavBarItem(
                  isUnlocked: _isRaetselUnlocked,
                  isSelected: currentIndex == 2,
                  pulseController: _pulseController,
                  onTap: _onRaetselTap,
                ),

                // 4. Progrès
                _NavBarItem(
                  selectedIcon: Icons.insights_rounded,
                  unselectedIcon: Icons.insights_outlined,
                  label: 'Progrès',
                  isSelected: currentIndex == 3,
                  onTap: () => _onTap(3),
                ),

                // 5. Réglages
                _NavBarItem(
                  selectedIcon: Icons.tune_rounded,
                  unselectedIcon: Icons.tune_outlined,
                  label: 'Réglages',
                  isSelected: currentIndex == 4,
                  onTap: () => _onTap(4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavBarItem extends StatelessWidget {
  final IconData selectedIcon;
  final IconData unselectedIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavBarItem({
    required this.selectedIcon,
    required this.unselectedIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selectedColor = AppColors.primary;
    final unselectedColor =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final activeBg = isDark
        ? AppColors.primary.withValues(alpha: 0.18)
        : AppColors.primaryLight;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? activeBg : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: isSelected
              ? Border.all(color: AppColors.primary.withValues(alpha: 0.25), width: 1)
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? selectedIcon : unselectedIcon,
              size: 22,
              color: isSelected ? selectedColor : unselectedColor,
            ),
            if (isSelected) ...[
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.2,
                  color: selectedColor,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Élément spécifique pour l'onglet Rätsel :
/// Gère l'affichage grisé avec cadenas avant déblocage,
/// et l'animation lors du déblocage.
class _RaetselNavBarItem extends StatelessWidget {
  final bool isUnlocked;
  final bool isSelected;
  final AnimationController? pulseController;
  final VoidCallback onTap;

  const _RaetselNavBarItem({
    required this.isUnlocked,
    required this.isSelected,
    required this.pulseController,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selectedColor = AppColors.primary;
    final unselectedColor =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final activeBg = isDark
        ? AppColors.primary.withValues(alpha: 0.18)
        : AppColors.primaryLight;

    // Si non débloqué : icône grisée avec cadenas
    if (!isUnlocked) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(
                Icons.extension_rounded,
                size: 22,
                color: isDark ? const Color(0xFF475569) : const Color(0xFF94A3B8),
              ),
              Positioned(
                right: -4,
                top: -4,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.lock_rounded,
                    size: 11,
                    color: AppColors.accent,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Si débloqué : icône active standard avec support sélection
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? activeBg : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: isSelected
              ? Border.all(color: AppColors.primary.withValues(alpha: 0.25), width: 1)
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? Icons.extension_rounded : Icons.extension_outlined,
              size: 22,
              color: isSelected ? selectedColor : unselectedColor,
            ),
            if (isSelected) ...[
              const SizedBox(width: 5),
              Text(
                'Rätsel',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.2,
                  color: selectedColor,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
