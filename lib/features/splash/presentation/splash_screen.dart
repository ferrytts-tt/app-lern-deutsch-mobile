import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/app_progress_bar.dart';
import '../../../data/database/app_database.dart';

/// Écran Splash de démarrage : initialise la base de données, importe phrases.json
/// et redirige vers Onboarding (1er lancement) ou Accueil.
/// L'écureuil Hoppla! effectue une animation de saut pendant 3 secondes.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  double _progress = 0.0;
  String _statusText = 'Initialisation...';

  // Animation de saut (bounce vertical)
  late AnimationController _jumpController;
  late Animation<double> _jumpAnimation;

  // Animation d'apparition (fade in)
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Animation de saut : monte et descend en boucle
    _jumpController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _jumpAnimation = Tween<double>(begin: 0, end: -30).animate(
      CurvedAnimation(parent: _jumpController, curve: Curves.easeInOut),
    );
    _jumpController.repeat(reverse: true);

    // Animation fade-in de l'écureuil
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );
    _fadeController.forward();

    _initializeApp();
  }

  @override
  void dispose() {
    _jumpController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _initializeApp() async {
    try {
      setState(() {
        _progress = 0.3;
        _statusText = 'Préparation des phrases...';
      });

      await AppDatabase.instance.importPhrasesFromJson();

      setState(() {
        _progress = 0.8;
        _statusText = 'Prêt !';
      });

      // Vérifier les préférences (premier lancement vs retour)
      final prefs = await SharedPreferences.getInstance();
      final hasCompletedOnboarding =
          prefs.getBool(AppConstants.prefHasCompletedOnboarding) ?? false;

      setState(() {
        _progress = 1.0;
      });

      // Laisser l'animation de saut tourner au minimum 3 secondes depuis le début
      await Future.delayed(const Duration(milliseconds: 400));

      if (!mounted) return;

      if (hasCompletedOnboarding) {
        context.go('/home');
      } else {
        context.go('/onboarding');
      }
    } catch (e) {
      if (mounted) {
        context.go('/home');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              const Spacer(flex: 2),

              // Écureuil animé avec saut
              FadeTransition(
                opacity: _fadeAnimation,
                child: AnimatedBuilder(
                  animation: _jumpAnimation,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(0, _jumpAnimation.value),
                      child: child,
                    );
                  },
                  child: Image.asset(
                    'assets/images/hoppla_squirrel.jpg',
                    width: 240,
                    height: 240,
                    fit: BoxFit.contain,
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // Ombre portée sous l'écureuil (effet rebond réaliste)
              AnimatedBuilder(
                animation: _jumpAnimation,
                builder: (context, _) {
                  // Plus l'écureuil est haut, plus l'ombre est petite et floue
                  final ratio = 1.0 - (-_jumpAnimation.value / 30) * 0.4;
                  return Container(
                    width: 100 * ratio,
                    height: 10,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.08 * ratio),
                      borderRadius: BorderRadius.circular(50),
                    ),
                  );
                },
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
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
