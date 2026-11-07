import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/localization/app_languages.dart';
import '../../../core/services/tts_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/custom_card.dart';
import '../../auth/presentation/auth_controller.dart';
import 'settings_controller.dart';

/// Écran Réglages complet : Thème (clair/sombre/système), objectifs, vitesse TTS et gestion des données.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  void _testVoice(double speed, {String? gender}) {
    TtsService.instance.speak(
      gender == 'female'
          ? 'Hallo! Ich bin Katja. Ich freue mich, mit dir Deutsch zu lernen!'
          : (gender == 'male'
              ? 'Guten Tag! Ich bin Conrad. Zusammen meistern wir die deutsche Sprache!'
              : 'Guten Tag! Ich lerne Deutsch mit Hoppla!'),
      slow: speed < 0.8,
      voiceGender: gender,
    );
  }

  void _confirmReset(BuildContext context, SettingsController controller) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.restart_alt_rounded, color: AppColors.gentleError),
            SizedBox(width: 8),
            Text('Réinitialiser ?'),
          ],
        ),
        content: const Text(
          'Cette action remet à zéro tes révisions et ta série de jours, mais conserve toutes les 411 phrases dans l’application. Es-tu certain de vouloir repartir de zéro ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.gentleError,
              foregroundColor: Colors.white,
              shape: const StadiumBorder(),
            ),
            onPressed: () async {
              Navigator.of(ctx).pop();
              await controller.resetProgress();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Progression réinitialisée avec succès.'),
                    backgroundColor: AppColors.primary,
                  ),
                );
              }
            },
            child: const Text('Réinitialiser'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsControllerProvider);
    final controller = ref.read(settingsControllerProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: Text('Réglages', style: AppTextStyles.titleMedium(isDark: isDark)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 0. Espace Candidat & Synchronisation Cloud
            _buildSectionTitle('Compte Candidat & Cloud', isDark),
            _CandidateAccountCard(isDark: isDark),
            const SizedBox(height: 12),

            // 0.5. Langues & Traductions
            _buildSectionTitle('Langues & Traductions', isDark),
            _LanguageSettingsCard(isDark: isDark),
            const SizedBox(height: 12),

            // 1. Thème d'affichage
            _buildSectionTitle('Apparence & Thème', isDark),
            CustomCard(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  _ThemeOptionChip(
                    label: 'Système',
                    icon: Icons.brightness_auto_rounded,
                    isSelected: settings.themeMode == ThemeMode.system,
                    onTap: () => controller.setThemeMode(ThemeMode.system),
                    isDark: isDark,
                  ),
                  const SizedBox(width: 8),
                  _ThemeOptionChip(
                    label: 'Clair',
                    icon: Icons.light_mode_rounded,
                    isSelected: settings.themeMode == ThemeMode.light,
                    onTap: () => controller.setThemeMode(ThemeMode.light),
                    isDark: isDark,
                  ),
                  const SizedBox(width: 8),
                  _ThemeOptionChip(
                    label: 'Sombre',
                    icon: Icons.dark_mode_rounded,
                    isSelected: settings.themeMode == ThemeMode.dark,
                    onTap: () => controller.setThemeMode(ThemeMode.dark),
                    isDark: isDark,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 2. Objectifs d'apprentissage
            _buildSectionTitle('Objectifs Quotidiens', isDark),
            CustomCard(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Nouvelles phrases par jour',
                    style: AppTextStyles.bodyMedium(isDark: isDark).copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [5, 8, 10, 15].map((val) {
                      final isSelected = settings.dailyNewPhrases == val;
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4.0),
                          child: InkWell(
                            onTap: () => controller.setDailyNewPhrases(val),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.primary
                                    : (isDark ? AppColors.surfaceDark : AppColors.backgroundLight),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.primary
                                      : (isDark ? AppColors.borderDark : AppColors.borderLight),
                                ),
                              ),
                              child: Text(
                                '$val',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isSelected
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

                  const Divider(height: 32),

                  Text(
                    'Durée visée par jour',
                    style: AppTextStyles.bodyMedium(isDark: isDark).copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [10, 20, 30].map((val) {
                      final isSelected = settings.dailyGoalMinutes == val;
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4.0),
                          child: InkWell(
                            onTap: () => controller.setDailyGoalMinutes(val),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.primary
                                    : (isDark ? AppColors.surfaceDark : AppColors.backgroundLight),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.primary
                                      : (isDark ? AppColors.borderDark : AppColors.borderLight),
                                ),
                              ),
                              child: Text(
                                '$val min',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isSelected
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
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 3. Rappels Quotidiens (Section 7.2)
            _buildSectionTitle('Rappels Quotidiens (Section 7.2)', isDark),
            CustomCard(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.alarm_rounded, color: AppColors.accentDark, size: 22),
                          const SizedBox(width: 8),
                          Text(
                            'Activer le rappel quotidien',
                            style: AppTextStyles.bodyMedium(isDark: isDark).copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      Switch.adaptive(
                        value: settings.reminderEnabled,
                        activeThumbColor: AppColors.primary,
                        onChanged: (val) => controller.setReminderEnabled(val),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Les révisions marchent seulement si elles reviennent au bon moment.',
                    style: AppTextStyles.caption(isDark: isDark),
                  ),
                  if (settings.reminderEnabled) ...[
                    const Divider(height: 28),
                    Text(
                      'Heure préférée de révision',
                      style: AppTextStyles.bodyMedium(isDark: isDark).copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: ['08:00', '12:30', '19:00', '21:00'].map((timeStr) {
                        final isSelected = settings.reminderTime == timeStr;
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4.0),
                            child: InkWell(
                              onTap: () => controller.setReminderTime(timeStr),
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.primary
                                      : (isDark ? AppColors.surfaceDark : AppColors.backgroundLight),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected
                                        ? AppColors.primary
                                        : (isDark ? AppColors.borderDark : AppColors.borderLight),
                                  ),
                                ),
                                child: Text(
                                  timeStr,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: isSelected
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
                  ],
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 4. Série & Bouclier de Gel (Section 7.1)
            _buildSectionTitle('Série & Gel de Série (Section 7.1)', isDark),
            CustomCard(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.local_fire_department_rounded, color: Color(0xFFFF9600), size: 24),
                      const SizedBox(width: 10),
                      Text(
                        '${settings.streakDays} jours d\'affilée',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF10283A) : const Color(0xFFE1F5FE),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: const Color(0xFF0288D1).withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Text('❄️', style: TextStyle(fontSize: 20)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            settings.freezeAvailable
                                ? '1 gel de série disponible cette semaine. Si tu manques un jour, ta flamme reste intacte !'
                                : 'Gel utilisé cette semaine. Un nouveau gel gratuit sera accordé dimanche.',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF0277BD),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '« Si la série est brisée, chaque jour est un nouveau départ 🐿️ »',
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      fontSize: 12,
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 5. Audio & Voix Réelles Natives
            _buildSectionTitle('Audio & Locuteurs Natifs Réels (de-DE)', isDark),
            CustomCard(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Choix de la voix allemande (Locuteurs réels)',
                    style: AppTextStyles.bodyMedium(isDark: isDark).copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Enregistrements studio de locuteurs natifs authentiques, sans son robotique.',
                    style: AppTextStyles.caption(isDark: isDark),
                  ),
                  const SizedBox(height: 12),
                  // Sélecteur de voix : Alterné (Recommandé), Homme (Conrad), Femme (Katja)
                  _VoiceOptionTile(
                    title: 'Duo Alterné (Homme & Femme)',
                    subtitle: 'Recommandé : habitue ton oreille aux deux voix de locuteurs natifs.',
                    icon: Icons.sync_rounded,
                    iconColor: AppColors.primary,
                    isSelected: settings.voiceGender == 'alternate',
                    onTap: () => controller.setVoiceGender('alternate'),
                    isDark: isDark,
                  ),
                  const SizedBox(height: 8),
                  _VoiceOptionTile(
                    title: 'Conrad (Homme natif 👨)',
                    subtitle: 'Voix masculine posée, chaleureuse et naturelle.',
                    icon: Icons.face_rounded,
                    iconColor: const Color(0xFF0284C7),
                    isSelected: settings.voiceGender == 'male',
                    onTap: () => controller.setVoiceGender('male'),
                    isDark: isDark,
                  ),
                  const SizedBox(height: 8),
                  _VoiceOptionTile(
                    title: 'Katja (Femme native 👩)',
                    subtitle: 'Voix féminine expressive, claire et authentique.',
                    icon: Icons.face_3_rounded,
                    iconColor: const Color(0xFFE11D48),
                    isSelected: settings.voiceGender == 'female',
                    onTap: () => controller.setVoiceGender('female'),
                    isDark: isDark,
                  ),
                  const Divider(height: 28),
                  Text(
                    'Vitesse d\'élocution',
                    style: AppTextStyles.bodyMedium(isDark: isDark).copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _SpeedOption(
                          label: 'Natif Normal',
                          sublabel: '1.0 (Allemand natif)',
                          isSelected: settings.ttsSpeed >= 0.8,
                          onTap: () => controller.setTtsSpeed(1.0),
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _SpeedOption(
                          label: 'Apprentissage',
                          sublabel: '0.65 (Lent)',
                          isSelected: settings.ttsSpeed < 0.8,
                          onTap: () => controller.setTtsSpeed(0.65),
                          isDark: isDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF0284C7),
                          side: const BorderSide(color: Color(0xFF0284C7)),
                          shape: const StadiumBorder(),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        ),
                        onPressed: () => _testVoice(settings.ttsSpeed, gender: 'male'),
                        icon: const Icon(Icons.face_rounded, size: 18),
                        label: const Text('Tester Conrad 👨'),
                      ),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFE11D48),
                          side: const BorderSide(color: Color(0xFFE11D48)),
                          shape: const StadiumBorder(),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        ),
                        onPressed: () => _testVoice(settings.ttsSpeed, gender: 'female'),
                        icon: const Icon(Icons.face_3_rounded, size: 18),
                        label: const Text('Tester Katja 👩'),
                      ),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: isDark ? Colors.white70 : AppColors.textSecondaryLight,
                          side: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                          shape: const StadiumBorder(),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        ),
                        onPressed: () async {
                          await TtsService.instance.clearAudioCache();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Cache audio vidé avec succès 🧹'),
                                backgroundColor: AppColors.primary,
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.cleaning_services_rounded, size: 18),
                        label: const Text('Vider le cache'),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 4. Principes pédagogiques
            _buildSectionTitle('Méthode Hoppla !', isDark),
            CustomCard(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  _MethodPoint(
                    icon: Icons.favorite_rounded,
                    color: AppColors.primary,
                    title: 'Zéro punition',
                    subtitle: 'Pas de vies perdues ni de scores négatifs. Ton toujours encourageant.',
                    isDark: isDark,
                  ),
                  const SizedBox(height: 12),
                  _MethodPoint(
                    icon: Icons.record_voice_over_rounded,
                    color: AppColors.accentDark,
                    title: 'Shadowing actif',
                    subtitle: 'Écouter le modèle, s’enregistrer au micro et reproduire le rythme.',
                    isDark: isDark,
                  ),
                  const SizedBox(height: 12),
                  _MethodPoint(
                    icon: Icons.palette_rounded,
                    color: AppColors.secondary,
                    title: 'Articles colorés',
                    subtitle: 'der en bleu, die en jaune foncé, das en vert pour fixer le genre.',
                    isDark: isDark,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Espace Administrateur / Formateur
            _buildSectionTitle('Espace Administrateur', isDark),
            CustomCard(
              padding: const EdgeInsets.all(16),
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.admin_panel_settings_rounded, color: AppColors.secondary),
                ),
                title: Text(
                  'Gestion des Phrases (Admin)',
                  style: AppTextStyles.bodyLarge(isDark: isDark).copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: const Text('Ajouter, modifier ou supprimer des phrases'),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                onTap: () => context.push('/admin'),
              ),
            ),

            const SizedBox(height: 24),

            // 5. Gestion des données
            _buildSectionTitle('Données & Réinitialisation', isDark),
            CustomCard(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tu souhaites repartir sur de nouvelles bases ?',
                    style: AppTextStyles.bodyMedium(isDark: isDark),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.gentleError,
                      side: const BorderSide(color: AppColors.gentleError),
                      shape: const StadiumBorder(),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    ),
                    onPressed: () => _confirmReset(context, controller),
                    icon: const Icon(Icons.restart_alt_rounded),
                    label: const Text('Réinitialiser ma progression'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Version & Nom
            Center(
              child: Column(
                children: [
                  Text(
                    'Hoppla !',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "Une erreur ? Hoppla ! Tu l'apprends pour de bon.",
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: isDark ? const Color(0xFF86EFAC) : const Color(0xFF16A34A),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Version 1.0.0 · Répétition espacée & Ancrage',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4.0),
      child: Text(
        title,
        style: AppTextStyles.bodyLarge(isDark: isDark).copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _ThemeOptionChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isDark;

  const _ThemeOptionChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary
                : (isDark ? AppColors.surfaceDark : AppColors.backgroundLight),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected
                  ? AppColors.primary
                  : (isDark ? AppColors.borderDark : AppColors.borderLight),
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected
                    ? Colors.white
                    : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isSelected
                      ? Colors.white
                      : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SpeedOption extends StatelessWidget {
  final String label;
  final String sublabel;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isDark;

  const _SpeedOption({
    required this.label,
    required this.sublabel,
    required this.isSelected,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? const Color(0xFF142E1F) : AppColors.primaryLight)
              : (isDark ? AppColors.surfaceDark : AppColors.backgroundLight),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.primary : (isDark ? AppColors.borderDark : AppColors.borderLight),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: isSelected ? AppColors.primary : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              sublabel,
              style: TextStyle(
                fontSize: 11,
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MethodPoint extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final bool isDark;

  const _MethodPoint({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
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
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: AppTextStyles.caption(isDark: isDark),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _VoiceOptionTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isDark;

  const _VoiceOptionTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.isSelected,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? const Color(0xFF142B1E) : const Color(0xFFEFFDF5))
              : (isDark ? AppColors.surfaceDark : AppColors.backgroundLight),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : (isDark ? AppColors.borderDark : AppColors.borderLight),
            width: isSelected ? 1.6 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
              color: isSelected ? AppColors.primary : Colors.grey,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class _CandidateAccountCard extends ConsumerWidget {
  final bool isDark;

  const _CandidateAccountCard({required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final authController = ref.read(authControllerProvider.notifier);
    final isAuth = authState.isAuthenticated;

    return CustomCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isAuth
                      ? AppColors.primary.withValues(alpha: 0.15)
                      : Colors.grey.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isAuth ? Icons.verified_user_rounded : Icons.person_outline_rounded,
                  color: isAuth ? AppColors.primary : Colors.grey,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isAuth ? authState.candidateName : 'Mode Invité / Hors-ligne',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isAuth
                          ? authState.candidateEmail
                          : 'Connectez-vous pour synchroniser votre progression',
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
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                isAuth ? Icons.cloud_done_rounded : Icons.cloud_off_rounded,
                size: 16,
                color: isAuth ? AppColors.primary : Colors.grey,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  isAuth
                      ? (authState.isSyncing
                          ? 'Synchronisation avec Supabase...'
                          : (authState.syncStatusMessage ?? 'Synchronisé avec le Cloud ☁️'))
                      : 'Non synchronisé avec le Cloud',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white70 : Colors.grey.shade700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              if (isAuth) ...[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: authState.isSyncing
                        ? null
                        : () => authController.triggerSync(),
                    icon: const Icon(Icons.sync_rounded, size: 16),
                    label: const Text('Synchroniser', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => authController.signOut(),
                    icon: const Icon(Icons.logout_rounded, size: 16),
                    label: const Text('Déconnexion', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.gentleError,
                      side: const BorderSide(color: AppColors.gentleError),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ] else ...[
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => context.push('/auth'),
                    icon: const Icon(Icons.login_rounded, size: 16),
                    label: const Text('Se connecter / S\'inscrire', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _LanguageSettingsCard extends ConsumerWidget {
  final bool isDark;

  const _LanguageSettingsCard({required this.isDark});

  void _showLanguageSelector(
    BuildContext context, {
    required String title,
    required String currentCode,
    required bool isSecondary,
    required ValueChanged<String?> onSelect,
  }) {
    final languages = AppLanguage.supportedLanguages
        .where((l) => l.code != 'de')
        .toList();

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
              ),
              const SizedBox(height: 12),
              if (isSecondary)
                ListTile(
                  leading: const Text('🚫', style: TextStyle(fontSize: 22)),
                  title: const Text('Aucune deuxième langue'),
                  trailing: currentCode.isEmpty ? const Icon(Icons.check, color: AppColors.primary) : null,
                  onTap: () {
                    Navigator.pop(ctx);
                    onSelect(null);
                  },
                ),
              ...languages.map((lang) {
                final isSelected = currentCode == lang.code;
                return ListTile(
                  leading: Text(lang.flag, style: const TextStyle(fontSize: 22)),
                  title: Text('${lang.nativeName} (${lang.name})'),
                  trailing: isSelected ? const Icon(Icons.check, color: AppColors.primary) : null,
                  onTap: () {
                    Navigator.pop(ctx);
                    onSelect(lang.code);
                  },
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsControllerProvider);
    final controller = ref.read(settingsControllerProvider.notifier);

    final primaryMeta = AppLanguage.fromCode(settings.primaryLanguage);
    final secondaryMeta = settings.secondaryLanguage != null && settings.secondaryLanguage!.isNotEmpty
        ? AppLanguage.fromCode(settings.secondaryLanguage!)
        : null;

    return CustomCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Langue Principale (Interface & Traduction 1)
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              _showLanguageSelector(
                context,
                title: 'Choisir la langue principale',
                currentCode: settings.primaryLanguage,
                isSecondary: false,
                onSelect: (code) {
                  if (code != null) controller.setPrimaryLanguage(code);
                },
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Text(primaryMeta.flag, style: const TextStyle(fontSize: 20)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Langue principale (Interface)',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${primaryMeta.nativeName} (${primaryMeta.name})',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                ],
              ),
            ),
          ),
          const Divider(height: 20),

          // Langue Secondaire (Traduction d'appui 2)
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              _showLanguageSelector(
                context,
                title: 'Deuxième langue d\'appui',
                currentCode: settings.secondaryLanguage ?? '',
                isSecondary: true,
                onSelect: (code) {
                  controller.setSecondaryLanguage(code);
                },
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      secondaryMeta != null ? secondaryMeta.flag : '🚫',
                      style: const TextStyle(fontSize: 20),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Deuxième langue d\'appui',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          secondaryMeta != null
                              ? '${secondaryMeta.nativeName} (${secondaryMeta.name})'
                              : 'Désactivée (Aucune)',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}


