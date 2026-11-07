import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/duo_button.dart';
import '../../../core/widgets/mascot_widget.dart';
import 'auth_controller.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  bool _isSignUp = false;
  bool _obscurePassword = true;

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final controller = ref.read(authControllerProvider.notifier);
    bool success = false;

    if (_isSignUp) {
      success = await controller.signUp(
        email: _emailController.text,
        password: _passwordController.text,
        fullName: _nameController.text,
      );
    } else {
      success = await controller.signIn(
        email: _emailController.text,
        password: _passwordController.text,
      );
    }

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isSignUp ? 'Compte créé avec succès !' : 'Bon retour parmi nous !'),
          backgroundColor: AppColors.primary,
        ),
      );
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/home');
      }
    }
  }

  void _showForgotPasswordDialog() {
    final resetEmailController = TextEditingController(text: _emailController.text);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Mot de passe oublié ?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Entrez votre adresse email pour recevoir un lien de réinitialisation sécurisé :',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: resetEmailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email_outlined),
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final ok = await ref
                  .read(authControllerProvider.notifier)
                  .resetPassword(resetEmailController.text);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      ok
                          ? 'Email de réinitialisation envoyé ! Vérifiez votre boîte.'
                          : 'Erreur lors de l\'envoi de l\'email.',
                    ),
                    backgroundColor: ok ? AppColors.primary : AppColors.gentleError,
                  ),
                );
              }
            },
            child: const Text('Envoyer'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState.status == AuthStatus.loading;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(
          _isSignUp ? 'Créer un compte' : 'Espace Candidat',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/home');
              }
            },
            child: const Text('Passer', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Mascotte / En-tête ludique
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: (isDark ? AppColors.surfaceDark : Colors.white),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.15),
                              blurRadius: 20,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                        child: const MascotWidget(
                          size: 96,
                          mood: MascotMood.happy,
                        ),
                      ),
                    ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),

                    const SizedBox(height: 16),

                    // Titre d'accueil
                    Text(
                      _isSignUp
                          ? 'Rejoignez les candidats Hoppla !'
                          : 'Bon retour parmi nous !',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _isSignUp
                          ? 'Enregistrez votre progression dans le cloud et maîtrisez l\'allemand parlé.'
                          : 'Synchronisez vos examens, vos 1000+ phrases et vos séries.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Sélecteur Connexion / Inscription
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.surfaceDark : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _isSignUp = false),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: !_isSignUp
                                      ? (isDark ? const Color(0xFF2E3A4D) : Colors.white)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: !_isSignUp
                                      ? [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.08),
                                            blurRadius: 4,
                                            offset: const Offset(0, 2),
                                          ),
                                        ]
                                      : null,
                                ),
                                child: Text(
                                  'Se connecter',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontWeight: !_isSignUp ? FontWeight.w800 : FontWeight.w600,
                                    color: !_isSignUp
                                        ? AppColors.primary
                                        : (isDark ? Colors.grey.shade400 : Colors.grey.shade700),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _isSignUp = true),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: _isSignUp
                                      ? (isDark ? const Color(0xFF2E3A4D) : Colors.white)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: _isSignUp
                                      ? [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.08),
                                            blurRadius: 4,
                                            offset: const Offset(0, 2),
                                          ),
                                        ]
                                      : null,
                                ),
                                child: Text(
                                  'Créer un compte',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontWeight: _isSignUp ? FontWeight.w800 : FontWeight.w600,
                                    color: _isSignUp
                                        ? AppColors.primary
                                        : (isDark ? Colors.grey.shade400 : Colors.grey.shade700),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Message d'erreur s'il y en a
                    if (authState.errorMessage != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.gentleErrorBackground,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.gentleError),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline, color: AppColors.gentleError, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                authState.errorMessage!,
                                style: const TextStyle(
                                  color: Color(0xFFC2410C),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ).animate().shake(duration: 350.ms),

                    // Champ Nom (si inscription)
                    if (_isSignUp) ...[
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'Nom ou pseudo',
                          hintText: 'Ex: Samir, Sarah, Ahmed...',
                          prefixIcon: const Icon(Icons.person_outline),
                          filled: true,
                          fillColor: isDark ? AppColors.surfaceDark : Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                              color: isDark ? AppColors.borderDark : AppColors.borderLight,
                            ),
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Veuillez saisir votre nom';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                    ],

                    // Champ Email
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: 'Adresse e-mail',
                        hintText: 'candidat@exemple.com',
                        prefixIcon: const Icon(Icons.email_outlined),
                        filled: true,
                        fillColor: isDark ? AppColors.surfaceDark : Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: isDark ? AppColors.borderDark : AppColors.borderLight,
                          ),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Veuillez saisir votre email';
                        }
                        if (!v.contains('@') || !v.contains('.')) {
                          return 'Format d\'email invalide';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 14),

                    // Champ Mot de passe
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Mot de passe',
                        hintText: 'Au moins 6 caractères',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                          ),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                        filled: true,
                        fillColor: isDark ? AppColors.surfaceDark : Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: isDark ? AppColors.borderDark : AppColors.borderLight,
                          ),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.length < 6) {
                          return 'Au moins 6 caractères requis';
                        }
                        return null;
                      },
                    ),

                    // Mot de passe oublié (si connexion)
                    if (!_isSignUp) ...[
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _showForgotPasswordDialog,
                          child: const Text(
                            'Mot de passe oublié ?',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ] else
                      const SizedBox(height: 20),

                    // Bouton Principal
                    DuoButton(
                      label: isLoading
                          ? 'Chargement...'
                          : (_isSignUp ? 'Créer mon compte' : 'Se connecter'),
                      onPressed: isLoading ? null : _submit,
                      customColor: AppColors.primary,
                      isLoading: isLoading,
                      icon: isLoading ? null : (_isSignUp ? Icons.person_add_rounded : Icons.login_rounded),
                    ),

                    const SizedBox(height: 18),

                    // Séparateur OU
                    Row(
                      children: [
                        Expanded(
                          child: Divider(
                            color: isDark ? AppColors.borderDark : Colors.grey.shade300,
                            thickness: 1,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          child: Text(
                            'OU',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: isDark ? AppColors.textSecondaryDark : Colors.grey.shade600,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Divider(
                            color: isDark ? AppColors.borderDark : Colors.grey.shade300,
                            thickness: 1,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    // Bouton Continuer avec Google
                    _buildGoogleButton(isDark, isLoading),

                    const SizedBox(height: 20),

                    // Avantage Cloud Callout
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight.withValues(alpha: isDark ? 0.1 : 0.6),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.cloud_done_rounded, color: AppColors.primaryDark, size: 22),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Progression sauvegardée : vos révisions, grand examens et séries ne sont jamais perdus.',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: isDark ? Colors.white70 : const Color(0xFF065F46),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGoogleButton(bool isDark, bool isLoading) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isLoading ? null : _submitGoogle,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? const Color(0xFF334155) : Colors.grey.shade300,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: isDark ? Colors.black.withValues(alpha: 0.3) : Colors.grey.shade200,
                offset: const Offset(0, 3),
                blurRadius: 0,
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const _GoogleLogo(size: 22),
              const SizedBox(width: 12),
              Text(
                _isSignUp ? 'S\'inscrire avec Google' : 'Continuer avec Google',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitGoogle() async {
    final controller = ref.read(authControllerProvider.notifier);
    final launched = await controller.signInWithGoogle();
    if (launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Connexion Google en cours...'),
          backgroundColor: AppColors.primary,
        ),
      );
    }
  }
}

/// Logo vectoriel officiel Google en 4 couleurs
class _GoogleLogo extends StatelessWidget {
  final double size;
  const _GoogleLogo({this.size = 22});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _GoogleLogoPainter(),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final strokeWidth = size.width * 0.22;
    final rect = Rect.fromCircle(center: center, radius: radius - strokeWidth / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    // Rouge
    paint.color = const Color(0xFFEA4335);
    canvas.drawArc(rect, -2.35, 1.3, false, paint);

    // Jaune
    paint.color = const Color(0xFFFBBC05);
    canvas.drawArc(rect, -1.05 + 3.14159, 1.25, false, paint);

    // Vert
    paint.color = const Color(0xFF34A853);
    canvas.drawArc(rect, 0.2, 1.3, false, paint);

    // Bleu
    paint.color = const Color(0xFF4285F4);
    canvas.drawArc(rect, -1.05, 1.25, false, paint);

    // Barre centrale bleue
    final barPaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.fill;
    canvas.drawRect(
      Rect.fromLTRB(size.width * 0.45, size.height * 0.40, size.width, size.height * 0.60),
      barPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
