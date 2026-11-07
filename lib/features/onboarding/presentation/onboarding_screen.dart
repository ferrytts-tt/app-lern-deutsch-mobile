import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/localization/app_languages.dart';
import '../../../core/services/tts_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/custom_card.dart';
import '../../../core/widgets/duo_button.dart';
import '../../../core/widgets/duo_confetti.dart';
import '../../../core/widgets/german_text_annotator.dart';
import '../../../core/widgets/mascot_widget.dart';
import '../../../data/database/app_database.dart';
import '../../../domain/models/phrase.dart';
import '../../../domain/models/user_profile.dart';
import '../../settings/presentation/settings_controller.dart';

/// Parcours d'entrée (Onboarding) fluide en moins de 3 minutes (Section 2 du plan) :
/// 1. Écran d'accueil
/// 2. Choix de la langue de traduction (multi-langues)
/// 3. Question de niveau (débutant, A2, B1, B2)
/// 4. Choix de l'objectif quotidien (5, 10, 20)
/// 5. Choix des thèmes prioritaires (2 à 4 thèmes)
/// 6. Mini-démo de 3 phrases avec première victoire
/// 7. Création de compte (sauvegarde du profil et ajout des 3 phrases à la file)
/// 8. Autorisation des rappels & heure préférée
/// 9. Redirection vers l'écran principal
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0; // 0..7

  // Réglages choisis par l'utilisateur (Section 2 & 6)
  String _selectedLangue = 'fr';
  String? _selectedSecondaryLangue;
  String _selectedNiveau = 'B2';
  int _selectedObjectif = 10;
  final Set<String> _selectedThemes = {'smalltalk', 'travail'};
  String _selectedHeureRappel = '19:00';

  // État de la mini-démo de 3 phrases
  int _demoIndex = 0;
  String? _selectedDemoChoice;
  bool? _isDemoChoiceCorrect;
  bool _isDemoCompleted = false;

  final TextEditingController _emailController = TextEditingController();
  final TtsService _tts = TtsService.instance;
  bool _isTtsPlaying = false;

  // 3 phrases représentatives pour la mini-démo avec traductions multi-langues
  static final List<Phrase> _demoPhrases = [
    Phrase(
      id: 'phrase_001',
      theme: 'smalltalk',
      topic: 'salutations',
      deStandard: 'Wie geht es dir?',
      deParle: 'Na, wie läuft\'s?',
      de: 'Na, wie läuft\'s?',
      translations: {
        'fr': 'Comment ça va ?',
        'ar': 'طيب، كيف الأحوال؟',
        'en': "How's it going?",
        'ro': 'Ce mai faci?',
        'ru': 'Как дела?',
        'tr': 'Nasıl gidiyor?',
        'es': '¿Cómo va todo?',
        'hi': 'सब कैसा चल रहा है?',
      },
      note: 'läuft\'s = läuft es. Na تفتح الحديث.',
      cefr: 'B1',
    ),
    Phrase(
      id: 'phrase_002',
      theme: 'smalltalk',
      topic: 'salutations',
      deStandard: 'Wir haben uns lange nicht gesehen!',
      deParle: 'Mensch, lange nicht gesehen!',
      de: 'Mensch, lange nicht gesehen!',
      translations: {
        'fr': 'Ça fait un bail qu\'on s\'est pas vus !',
        'ar': 'يا رجل، من زمان ما شفتك!',
        'en': 'Man, long time no see!',
        'ro': 'Omule, nu te-am văzut de mult!',
        'ru': 'Дружище, сколько лет, сколько зим!',
        'tr': 'Dostum, ne zamandır görüşemedik!',
        'es': '¡Hombre, cuánto tiempo sin verte!',
        'hi': 'अरे भाई, बहुत दिनों बाद मिले!',
      },
      note: 'Mensch تعجب وليست «إنسان».',
      cefr: 'B1',
    ),
    Phrase(
      id: 'phrase_003',
      theme: 'smalltalk',
      topic: 'salutations',
      deStandard: 'Gibt es etwas Neues?',
      deParle: 'Was gibt\'s Neues?',
      de: 'Was gibt\'s Neues?',
      translations: {
        'fr': 'Quoi de neuf ?',
        'ar': 'شو الجديد؟',
        'en': "What's new?",
        'ro': 'Ce mai e nou?',
        'ru': 'Что нового?',
        'tr': 'Ne haber?',
        'es': '¿Qué hay de nuevo?',
        'hi': 'नया क्या है?',
      },
      note: 'gibt\'s = gibt es.',
      cefr: 'B1',
    ),
  ];

  static final Map<String, List<List<String>>> _demoChoices = {
    'fr': [
      ['Comment ça va ?', 'À demain !', 'Merci beaucoup'],
      ['Ça fait un bail qu\'on s\'est pas vus !', 'Bon appétit !', 'Bonne nuit'],
      ['Quoi de neuf ?', 'Où habites-tu ?', 'Combien ça coûte ?'],
    ],
    'ar': [
      ['طيب، كيف الأحوال؟', 'إلى اللقاء غداً!', 'شكراً جزيلاً'],
      ['يا رجل، من زمان ما شفتك!', 'بالهناء والشفاء!', 'تصبح على خير'],
      ['شو الجديد؟', 'أين تسكن حالياً؟', 'كم سعر التذكرة؟'],
    ],
    'en': [
      ["How's it going?", "See you tomorrow!", "Thank you very much"],
      ["Man, long time no see!", "Enjoy your meal!", "Good night"],
      ["What's new?", "Where do you live?", "How much does it cost?"],
    ],
    'ro': [
      ['Ce mai faci?', 'Pe mâine!', 'Mulțumesc mult'],
      ['Omule, nu te-am văzut de mult!', 'Poftă bună!', 'Noapte bună'],
      ['Ce mai e nou?', 'Unde locuiești?', 'Cât costă?'],
    ],
    'ru': [
      ['Как дела?', 'До завтра!', 'Большое спасибо'],
      ['Дружище, сколько лет, сколько зим!', 'Приятного аппетита!', 'Спокойной ночи'],
      ['Что нового?', 'Где вы живёте?', 'Сколько это стоит?'],
    ],
    'tr': [
      ['Nasıl gidiyor?', 'Yarın görüşürüz!', 'Çok teşekkürler'],
      ['Dostum, ne zamandır görüşemedik!', 'Afiyet olsun!', 'İyi geceler'],
      ['Ne haber?', 'Nerede yaşıyorsun?', 'Fiyatı ne kadar?'],
    ],
    'es': [
      ['¿Cómo va todo?', '¡Hasta mañana!', '¡Muchas gracias!'],
      ['¡Hombre, cuánto tiempo sin verte!', '¡Buen provecho!', 'Buenas noches'],
      ['¿Qué hay de nuevo?', '¿Dónde vives?', '¿Cuánto cuesta?'],
    ],
    'hi': [
      ['सब कैसा चल रहा है?', 'कल मिलते हैं!', 'बहुत बहुत धन्यवाद'],
      ['अरे भाई, बहुत दिनों बाद मिले!', 'भोजन का आनंद लें!', 'शुभ रात्रि'],
      ['नया क्या है?', 'आप कहाँ रहते हैं?', 'इसकी कीमत क्या है?'],
    ],
  };

  @override
  void initState() {
    super.initState();
    _tts.isPlayingNotifier.addListener(() {
      if (mounted) setState(() => _isTtsPlaying = _tts.isPlaying);
    });
  }

  void _nextStep() {
    if (_currentStep < 7) {
      setState(() => _currentStep++);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _finishOnboarding();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _playDemoAudio() async {
    final phrase = _demoPhrases[_demoIndex];
    await _tts.speak(phrase.deParle);
  }

  /// Sauvegarde du profil utilisateur et enregistrement des 3 phrases de démo dans la file SRS (Section 2.7)
  Future<void> _createAccountAndSaveProgress(String email) async {
    final db = AppDatabase.instance;
    final userId = email.trim().isNotEmpty ? email.trim() : 'default_user';

    final profile = UserProfile(
      id: userId,
      primaryLanguage: _selectedLangue,
      secondaryLanguage: _selectedSecondaryLangue,
      objectifQuotidien: _selectedObjectif,
      themesPrioritaires: _selectedThemes.toList(),
      niveauDeclare: _selectedNiveau,
      heureRappel: _selectedHeureRappel,
      serieJours: 0,
      derniereSession: null,
      gelSerieDisponible: true,
    );

    await db.saveUserProfileAndDemoPhrases(
      profile: profile,
      demoPhrases: _demoPhrases,
    );

    _nextStep();
  }

  Future<void> _finishOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.prefHasCompletedOnboarding, true);
    await prefs.setInt(AppConstants.prefDailyNewPhrases, _selectedObjectif);
    await prefs.setString(AppConstants.prefUserLevel, _selectedNiveau);
    await ref.read(settingsControllerProvider.notifier).setPrimaryLanguage(_selectedLangue);
    await ref.read(settingsControllerProvider.notifier).setSecondaryLanguage(_selectedSecondaryLangue);

    if (!mounted) return;
    try {
      context.go('/home');
    } catch (_) {
      // Ignorer si aucun GoRouter n'est présent (ex. tests unitaires/widgets isolés)
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            // Barre supérieure d'en-tête et progression
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
              child: Row(
                children: [
                  if (_currentStep > 0)
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_rounded, size: 20),
                      onPressed: _previousStep,
                    )
                  else
                    const SizedBox(width: 40),

                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: (_currentStep + 1) / 8,
                        backgroundColor: isDark ? AppColors.borderDark : AppColors.borderLight,
                        color: AppColors.primary,
                        minHeight: 6,
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),
                  Text(
                    '${_currentStep + 1}/8',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ),

            // Contenu défilant des 8 étapes
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildStep1Welcome(isDark),
                  _buildStep2Language(isDark),
                  _buildStep3Level(isDark),
                  _buildStep4Goal(isDark),
                  _buildStep5Themes(isDark),
                  _buildStep6Demo(isDark),
                  _buildStep7Account(isDark),
                  _buildStep8Reminders(isDark),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 1. Écran d'accueil (Section 2.1)
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildStep1Welcome(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 16),
          const MascotWidget(mood: MascotMood.happy, size: 120),
          const SizedBox(height: 32),

          Text(
            'Comprends l\'allemand que les Allemands parlent vraiment 🇩🇪',
            style: AppTextStyles.titleMedium(isDark: isDark).copyWith(
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 14),

          Text(
            'Tu as un niveau B2 mais tu bloques face aux natifs ? Découvre les vraies phrases du quotidien par répétition espacée audio.',
            style: AppTextStyles.bodyMedium(isDark: isDark).copyWith(
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              height: 1.45,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 48),

          DuoButton(
            label: 'Commencer',
            icon: Icons.play_arrow_rounded,
            variant: DuoButtonVariant.primary,
            onPressed: _nextStep,
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 2. Choix des langues (Interface & Traductions) (Section 2.2)
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildStep2Language(bool isDark) {
    // Liste des langues d'apprentissage supportées
    final languages = AppLanguage.supportedLanguages
        .where((l) => l.code != 'de') // L'allemand est la langue cible apprise
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 12),
          Text(
            '1. Langue principale (Interface & Traduction)',
            style: AppTextStyles.titleMedium(isDark: isDark).copyWith(fontSize: 20),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            'Choisis ta langue maternelle : l\'interface s\'adapte instantanément !',
            style: AppTextStyles.caption(isDark: isDark),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),

          // Grille des langues principales
          ...languages.map((lang) {
            final isSelected = _selectedLangue == lang.code;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10.0),
              child: _buildSelectionCard(
                title: '${lang.nativeName} (${lang.name})',
                subtitle: isSelected
                    ? '✓ Interface et explications actives'
                    : 'Afficher les traductions et menus en ${lang.name}',
                isSelected: isSelected,
                flag: lang.flag,
                isDark: isDark,
                onTap: () {
                  setState(() {
                    _selectedLangue = lang.code;
                    if (_selectedSecondaryLangue == lang.code) {
                      _selectedSecondaryLangue = null;
                    }
                  });
                  ref.read(settingsControllerProvider.notifier).setPrimaryLanguage(lang.code);
                },
              ),
            );
          }),

          const SizedBox(height: 28),
          const Divider(),
          const SizedBox(height: 16),

          Text(
            '2. Deuxième langue d\'appui (Optionnelle)',
            style: AppTextStyles.titleMedium(isDark: isDark).copyWith(fontSize: 18),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            'Utile pour comparer les tournures (ex: Arabe + Français ou Roumain + Anglais)',
            style: AppTextStyles.caption(isDark: isDark),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),

          // Option "Aucune"
          _buildSelectionCard(
            title: 'Aucune deuxième langue',
            subtitle: 'Uniquement la langue principale',
            isSelected: _selectedSecondaryLangue == null,
            flag: '🚫',
            isDark: isDark,
            onTap: () {
              setState(() => _selectedSecondaryLangue = null);
              ref.read(settingsControllerProvider.notifier).setSecondaryLanguage(null);
            },
          ),
          const SizedBox(height: 10),

          // Options pour les autres langues
          ...languages.where((l) => l.code != _selectedLangue).map((lang) {
            final isSelected = _selectedSecondaryLangue == lang.code;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10.0),
              child: _buildSelectionCard(
                title: '${lang.nativeName} (${lang.name})',
                subtitle: 'Afficher en sous-titre de comparaison',
                isSelected: isSelected,
                flag: lang.flag,
                isDark: isDark,
                onTap: () {
                  setState(() => _selectedSecondaryLangue = lang.code);
                  ref.read(settingsControllerProvider.notifier).setSecondaryLanguage(lang.code);
                },
              ),
            );
          }),

          const SizedBox(height: 36),

          DuoButton(
            label: 'Continuer',
            icon: Icons.arrow_forward_rounded,
            variant: DuoButtonVariant.primary,
            onPressed: _nextStep,
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 3. Question de niveau (Section 2.3)
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildStep3Level(bool isDark) {
    final levels = [
      ('Débutant', 'A1 : Découverte des bases de la langue'),
      ('A2', 'Connaissances élémentaires du quotidien'),
      ('B1', 'Autonomie générale en allemand'),
      ('B2 ou plus', 'Certificat telc / B2 : je comprends les manuels mais pas les natifs'),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 12),
          Text(
            'Quel est ton niveau actuel ?',
            style: AppTextStyles.titleMedium(isDark: isDark),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Une seule question pour calibrer tes phrases sans test long.',
            style: AppTextStyles.caption(isDark: isDark),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),

          ...levels.map((lvl) {
            final isSel = _selectedNiveau == lvl.$1;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: _buildSelectionCard(
                title: lvl.$1,
                subtitle: lvl.$2,
                isSelected: isSel,
                isDark: isDark,
                onTap: () => setState(() => _selectedNiveau = lvl.$1),
              ),
            );
          }),

          const SizedBox(height: 32),

          DuoButton(
            label: 'Continuer',
            icon: Icons.arrow_forward_rounded,
            variant: DuoButtonVariant.primary,
            onPressed: _nextStep,
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 4. Choix de l'objectif quotidien (Section 2.4)
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildStep4Goal(bool isDark) {
    final goals = [
      (5, 'Léger', '5 nouvelles phrases / jour (~5 min)'),
      (10, 'Normal', '10 nouvelles phrases / jour (~10-15 min) • Recommandé'),
      (20, 'Intensif', '20 nouvelles phrases / jour (~20 min)'),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 12),
          Text(
            'Choix de l\'objectif quotidien',
            style: AppTextStyles.titleMedium(isDark: isDark),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1B2F22) : AppColors.primaryLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded, size: 16, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'La régularité compte beaucoup plus que le volume.',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.primaryLight : AppColors.primaryDark,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          ...goals.map((g) {
            final isSel = _selectedObjectif == g.$1;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: _buildSelectionCard(
                title: '${g.$2} (${g.$1} phrases)',
                subtitle: g.$3,
                isSelected: isSel,
                isDark: isDark,
                onTap: () => setState(() => _selectedObjectif = g.$1),
              ),
            );
          }),

          const SizedBox(height: 36),

          DuoButton(
            label: 'Continuer',
            icon: Icons.arrow_forward_rounded,
            variant: DuoButtonVariant.primary,
            onPressed: _nextStep,
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 5. Choix des thèmes prioritaires (Section 2.5)
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildStep5Themes(bool isDark) {
    final themesList = [
      ('travail', '💼 Travail & Bureau', 'Discussions avec collègues, pauses, e-mails'),
      ('smalltalk', '🤝 Amis & Vie quotidienne', 'Sorties, salutations, conversations détendues'),
      ('administration', '🏛️ Administration & Démarches', 'Bürgeramt, formulaires, rendez-vous'),
      ('sante', '🏥 Santé & Médecin', 'Symptômes, pharmacie, explications claires'),
      ('transports', '🚆 Transports & Déplacements', 'Retards, billets, gares et aéroports'),
    ];

    final isValidCount = _selectedThemes.length >= 2 && _selectedThemes.length <= 4;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 12),
          Text(
            'Thèmes prioritaires',
            style: AppTextStyles.titleMedium(isDark: isDark),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            'Coche 2 à 4 thèmes. Tes nouvelles phrases viendront d\'abord de ces sujets.',
            style: AppTextStyles.caption(isDark: isDark),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),

          ...themesList.map((t) {
            final isChecked = _selectedThemes.contains(t.$1);
            return Padding(
              padding: const EdgeInsets.only(bottom: 10.0),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  setState(() {
                    if (isChecked) {
                      if (_selectedThemes.length > 2) _selectedThemes.remove(t.$1);
                    } else {
                      if (_selectedThemes.length < 4) _selectedThemes.add(t.$1);
                    }
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isChecked
                        ? (isDark ? const Color(0xFF142E1F) : AppColors.primaryLight)
                        : (isDark ? AppColors.surfaceDark : Colors.white),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isChecked
                          ? AppColors.primary
                          : (isDark ? AppColors.borderDark : AppColors.borderLight),
                      width: isChecked ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isChecked ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
                        color: isChecked ? AppColors.primary : Colors.grey,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              t.$2,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              t.$3,
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
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
          }),

          const SizedBox(height: 24),

          DuoButton(
            label: isValidCount ? 'Passer à la mini-démo' : 'Coche au moins 2 thèmes',
            icon: Icons.play_arrow_rounded,
            variant: DuoButtonVariant.primary,
            onPressed: isValidCount ? _nextStep : null,
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 6. Mini-démo de 3 phrases (Section 2.6)
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildStep6Demo(bool isDark) {
    if (_isDemoCompleted) {
      return DuoConfettiOverlay(
        isPlaying: true,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              const MascotWidget(mood: MascotMood.celebrating, size: 100),
              const SizedBox(height: 24),
              Text(
                'Bravo ! 🎉',
                style: AppTextStyles.titleMedium(isDark: isDark).copyWith(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: AppColors.primary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Tu viens d\'apprendre 3 phrases que les Allemands disent vraiment.',
                style: AppTextStyles.bodyLarge(isDark: isDark).copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Ces 3 phrases sont prêtes à être sauvegardées dans ta file de révision quotidienne.',
                style: AppTextStyles.caption(isDark: isDark),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              DuoButton(
                label: 'Sauvegarder ma progression',
                icon: Icons.save_rounded,
                variant: DuoButtonVariant.primary,
                onPressed: _nextStep,
              ),
            ],
          ),
        ),
      );
    }

    final phrase = _demoPhrases[_demoIndex];
    final choicesList = _demoChoices[_selectedLangue] ?? _demoChoices['en'] ?? _demoChoices['fr']!;
    final choices = choicesList[_demoIndex];

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.secondaryLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Démo : Phrase ${_demoIndex + 1} sur 3',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: AppColors.secondary,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(_isTtsPlaying ? Icons.volume_up_rounded : Icons.volume_down_rounded, color: AppColors.primary),
                onPressed: _playDemoAudio,
              ),
            ],
          ),

          const SizedBox(height: 16),

          CustomCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Text(
                  'Forme parlée naturelle :',
                  style: AppTextStyles.caption(isDark: isDark),
                ),
                const SizedBox(height: 8),
                GermanTextView(
                  text: phrase.deParle,
                  baseStyle: AppTextStyles.germanPhrase(isDark: isDark).copyWith(fontSize: 24),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceDark : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('🇩🇪 '),
                      Flexible(
                        child: Text(
                          'Standard : ${phrase.deStandard}',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          Text(
            'Quelle est la bonne traduction ?',
            style: AppTextStyles.bodyMedium(isDark: isDark).copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 14),

          ...choices.map((choice) {
            final isSelected = _selectedDemoChoice == choice;
            Color? bgColor;
            Color? borderColor;

            if (isSelected && _isDemoChoiceCorrect != null) {
              bgColor = _isDemoChoiceCorrect!
                  ? AppColors.primaryLight
                  : AppColors.gentleErrorBackground;
              borderColor = _isDemoChoiceCorrect!
                  ? AppColors.primary
                  : AppColors.gentleError;
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 10.0),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () {
                  final correctTarget = phrase.getTranslation(_selectedLangue);
                  final isCorrect = choice.trim().toLowerCase() == correctTarget.trim().toLowerCase();
                  setState(() {
                    _selectedDemoChoice = choice;
                    _isDemoChoiceCorrect = isCorrect;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: bgColor ?? (isDark ? AppColors.surfaceDark : Colors.white),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: borderColor ?? (isDark ? AppColors.borderDark : AppColors.borderLight),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Text(
                    choice,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            );
          }),

          const SizedBox(height: 16),

          if (_isDemoChoiceCorrect != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: _isDemoChoiceCorrect!
                    ? AppColors.primaryLight
                    : AppColors.gentleErrorBackground,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _isDemoChoiceCorrect!
                      ? AppColors.primary
                      : AppColors.gentleError,
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  MascotWidget(
                    mood: _isDemoChoiceCorrect! ? MascotMood.happy : MascotMood.angry,
                    size: 52,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _isDemoChoiceCorrect!
                          ? 'Excellent ! Tu as trouvé la bonne traduction.'
                          : 'Oups ! Retiens bien cette phrase et réessaie.',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: _isDemoChoiceCorrect!
                            ? AppColors.primaryDark
                            : AppColors.gentleError,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          if (_isDemoChoiceCorrect == true)
            DuoButton(
              label: _demoIndex < 2 ? 'Phrase suivante' : 'Terminer la démo',
              icon: Icons.check_rounded,
              variant: DuoButtonVariant.primary,
              onPressed: () {
                if (_demoIndex < 2) {
                  setState(() {
                    _demoIndex++;
                    _selectedDemoChoice = null;
                    _isDemoChoiceCorrect = null;
                  });
                } else {
                  setState(() => _isDemoCompleted = true);
                }
              },
            ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 7. Création de compte (Section 2.7)
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildStep7Account(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 12),
          const MascotWidget(mood: MascotMood.happy, size: 84),
          const SizedBox(height: 20),
          Text(
            'Sauvegarde ta progression',
            style: AppTextStyles.titleMedium(isDark: isDark),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            'Les 3 phrases de ta démo seront directement ajoutées à ta file de révision.',
            style: AppTextStyles.caption(isDark: isDark),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),

          DuoButton(
            label: 'Continuer avec Google',
            icon: Icons.account_circle_rounded,
            variant: DuoButtonVariant.outline,
            onPressed: () => _createAccountAndSaveProgress('google_user@gmail.com'),
          ),

          const SizedBox(height: 14),

          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              hintText: 'Entre ton adresse e-mail',
              prefixIcon: const Icon(Icons.email_outlined),
              filled: true,
              fillColor: isDark ? AppColors.surfaceDark : Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                ),
              ),
            ),
          ),

          const SizedBox(height: 14),

          DuoButton(
            label: 'Continuer avec l\'e-mail',
            icon: Icons.arrow_forward_rounded,
            variant: DuoButtonVariant.primary,
            onPressed: () {
              final email = _emailController.text.trim();
              _createAccountAndSaveProgress(email.isNotEmpty ? email : 'apprenant@deutschfast.de');
            },
          ),

          const SizedBox(height: 14),

          TextButton(
            onPressed: () => _createAccountAndSaveProgress('default_user'),
            child: Text(
              'Continuer en invité (local uniquement)',
              style: TextStyle(
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 8. Autorisation des rappels & heure (Section 2.8)
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildStep8Reminders(bool isDark) {
    final hours = ['08:00', '12:30', '19:00', '21:00'];

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 12),
          const Icon(Icons.alarm_on_rounded, size: 64, color: AppColors.primary),
          const SizedBox(height: 20),
          Text(
            'Reste régulier',
            style: AppTextStyles.titleMedium(isDark: isDark),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            '« Les révisions marchent seulement si elles reviennent au bon moment. »',
            style: AppTextStyles.bodyMedium(isDark: isDark).copyWith(
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Text(
            'À quelle heure préfères-tu faire ta révision de 10 min ?',
            style: AppTextStyles.caption(isDark: isDark),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),

          Row(
            children: hours.map((h) {
              final isSel = _selectedHeureRappel == h;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => setState(() => _selectedHeureRappel = h),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: isSel
                            ? AppColors.primary
                            : (isDark ? AppColors.surfaceDark : Colors.white),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSel
                              ? AppColors.primary
                              : (isDark ? AppColors.borderDark : AppColors.borderLight),
                        ),
                      ),
                      child: Text(
                        h,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isSel
                              ? Colors.white
                              : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 36),

          DuoButton(
            label: 'Activer le rappel quotidien',
            icon: Icons.notifications_active_rounded,
            variant: DuoButtonVariant.primary,
            onPressed: () async {
              final db = AppDatabase.instance;
              final profile = await db.getUserProfile();
              await db.saveUserProfile(profile.copyWith(heureRappel: _selectedHeureRappel));
              await _finishOnboarding();
            },
          ),

          const SizedBox(height: 12),

          TextButton(
            onPressed: _finishOnboarding,
            child: Text(
              'Plus tard',
              style: TextStyle(
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectionCard({
    required String title,
    required String subtitle,
    required bool isSelected,
    String? flag,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? const Color(0xFF142E1F) : AppColors.primaryLight)
              : (isDark ? AppColors.surfaceDark : Colors.white),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : (isDark ? AppColors.borderDark : AppColors.borderLight),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            if (flag != null) ...[
              Text(flag, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 14),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
              color: isSelected ? AppColors.primary : Colors.grey,
            ),
          ],
        ),
      ),
    );
  }
}
