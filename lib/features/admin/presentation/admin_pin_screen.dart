import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

/// Écran de déverrouillage sécurisé par code PIN pour l'espace administrateur.
class AdminPinScreen extends StatefulWidget {
  const AdminPinScreen({super.key});

  @override
  State<AdminPinScreen> createState() => _AdminPinScreenState();
}

class _AdminPinScreenState extends State<AdminPinScreen>
    with SingleTickerProviderStateMixin {
  String _enteredPin = '';
  bool _hasError = false;
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _shakeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -10.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -10.0, end: 10.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 10.0, end: -10.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -10.0, end: 10.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 10.0, end: 0.0), weight: 1),
    ]).animate(_shakeController);
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  void _onKeyPress(String digit) {
    if (_enteredPin.length < 4) {
      setState(() {
        _hasError = false;
        _enteredPin += digit;
      });

      if (_enteredPin.length == 4) {
        _verifyPin();
      }
    }
  }

  void _onBackspace() {
    if (_enteredPin.isNotEmpty) {
      setState(() {
        _hasError = false;
        _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
      });
    }
  }

  void _verifyPin() {
    if (_enteredPin == AppConstants.adminPin) {
      context.go('/admin/dashboard');
    } else {
      setState(() => _hasError = true);
      _shakeController.forward(from: 0.0);
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) {
          setState(() {
            _enteredPin = '';
            _hasError = false;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: const Text('Espace Formateur / Admin'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),

            // Cadenas et Titre
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: _hasError
                    ? AppColors.gentleError.withValues(alpha: 0.15)
                    : AppColors.primary.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _hasError ? Icons.lock_open_rounded : Icons.admin_panel_settings_rounded,
                size: 48,
                color: _hasError ? AppColors.gentleError : AppColors.primary,
              ),
            ),

            const SizedBox(height: 20),

            Text(
              'Code PIN Administrateur',
              style: AppTextStyles.titleMedium(isDark: isDark).copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              'Entrez le code d\'accès pour gérer les phrases (Défaut : 1234)',
              style: AppTextStyles.caption(isDark: isDark),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 32),

            // Indicateur à 4 cercles animés
            AnimatedBuilder(
              animation: _shakeAnimation,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(_shakeAnimation.value, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(4, (index) {
                      final isFilled = index < _enteredPin.length;
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 10),
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _hasError
                              ? AppColors.gentleError
                              : (isFilled
                                  ? AppColors.primary
                                  : (isDark ? AppColors.borderDark : AppColors.borderLight)),
                          border: Border.all(
                            color: _hasError
                                ? AppColors.gentleError
                                : (isFilled ? AppColors.primary : AppColors.borderDark),
                            width: 2,
                          ),
                        ),
                      );
                    }),
                  ),
                );
              },
            ),

            if (_hasError) ...[
              const SizedBox(height: 16),
              const Text(
                'Code PIN incorrect. Veuillez réessayer.',
                style: TextStyle(
                  color: AppColors.gentleError,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],

            const Spacer(),

            // Pavé numérique (Numpad)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40.0),
              child: Column(
                children: [
                  _buildNumpadRow(['1', '2', '3'], isDark),
                  const SizedBox(height: 16),
                  _buildNumpadRow(['4', '5', '6'], isDark),
                  const SizedBox(height: 16),
                  _buildNumpadRow(['7', '8', '9'], isDark),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Bouton vider tout
                      _buildNumpadAction(
                        icon: Icons.refresh_rounded,
                        onPressed: () => setState(() => _enteredPin = ''),
                        isDark: isDark,
                      ),
                      _buildNumpadButton('0', isDark),
                      // Bouton retour arrière
                      _buildNumpadAction(
                        icon: Icons.backspace_outlined,
                        onPressed: _onBackspace,
                        isDark: isDark,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 36),
          ],
        ),
      ),
    );
  }

  Widget _buildNumpadRow(List<String> digits, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: digits.map((d) => _buildNumpadButton(d, isDark)).toList(),
    );
  }

  Widget _buildNumpadButton(String digit, bool isDark) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _onKeyPress(digit),
        borderRadius: BorderRadius.circular(36),
        child: Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            digit,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNumpadAction({
    required IconData icon,
    required VoidCallback onPressed,
    required bool isDark,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(36),
        child: Container(
          width: 72,
          height: 72,
          alignment: Alignment.center,
          child: Icon(
            icon,
            size: 26,
            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
          ),
        ),
      ),
    );
  }
}
