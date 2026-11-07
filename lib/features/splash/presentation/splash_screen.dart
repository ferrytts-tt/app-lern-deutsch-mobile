import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_progress_bar.dart';
import '../../../data/database/app_database.dart';

/// Écran Splash de démarrage : initialise la base de données, importe phrases.json
/// et redirige vers Onboarding (1er lancement) ou Accueil.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  double _progress = 0.2;
  String _statusText = 'Initialisation...';

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // 1. Initialiser SQLite et importer le JSON
      setState(() {
        _progress = 0.4;
        _statusText = 'Préparation des phrases...';
      });

      await AppDatabase.instance.importPhrasesFromJson();

      setState(() {
        _progress = 0.8;
        _statusText = 'Prêt !';
      });

      // 2. Vérifier les préférences (premier lancement vs retour)
      final prefs = await SharedPreferences.getInstance();
      final hasCompletedOnboarding =
          prefs.getBool(AppConstants.prefHasCompletedOnboarding) ?? false;

      setState(() {
        _progress = 1.0;
      });

      await Future.delayed(const Duration(milliseconds: 400));

      if (!mounted) return;

      if (hasCompletedOnboarding) {
        context.go('/home');
      } else {
        context.go('/onboarding');
      }
    } catch (e) {
      // En cas de pépin au démarrage, diriger doucement vers l'accueil
      if (mounted) {
        context.go('/home');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.backgroundDark : AppColors.primaryLight;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              const Spacer(flex: 2),

              // Icône stylisée
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFACC15), Color(0xFFEAB308)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFEAB308).withValues(alpha: 0.35),
                      blurRadius: 18,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.bolt_rounded,
                  size: 44,
                  color: Color(0xFF1E293B),
                ),
              ),

              const SizedBox(height: 20),

              Text(
                'Hoppla !',
                style: AppTextStyles.titleLarge(isDark: isDark).copyWith(
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                  color: isDark ? const Color(0xFFFACC15) : const Color(0xFFCA8A04),
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 8),

              Text(
                "Une erreur ? Hoppla ! Tu l'apprends pour de bon.",
                style: AppTextStyles.bodyLarge(isDark: isDark).copyWith(
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),

              const Spacer(flex: 2),

              // Barre de chargement fine et texte d'état
              SizedBox(
                width: 180,
                child: AppProgressBar(
                  value: _progress,
                  height: 8,
                ),
              ),

              const SizedBox(height: 12),

              Text(
                _statusText,
                style: AppTextStyles.caption(isDark: isDark),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
