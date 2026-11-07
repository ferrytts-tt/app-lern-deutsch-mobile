// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appName => 'Deutsch Fast';

  @override
  String get appSubtitle => 'Apprends l\'allemand rapidement';

  @override
  String get navHome => 'Accueil';

  @override
  String get navLibrary => 'Phrases';

  @override
  String get navProgress => 'Progrès';

  @override
  String get navSettings => 'Réglages';

  @override
  String get onboardingSkip => 'Passer';

  @override
  String get onboardingNext => 'Suivant';

  @override
  String get onboardingStart => 'Commencer';

  @override
  String get onboardingTitle1 =>
      'Apprends comme un enfant, pas comme à l\'école.';

  @override
  String get onboardingSubtitle1 =>
      'Pas de règles rébarbatives. Juste des phrases complètes et vivantes, répétées au bon moment.';

  @override
  String get onboardingTitle2 =>
      '1000 phrases utiles pour comprendre et parler.';

  @override
  String get onboardingSubtitle2 =>
      'Chaque jour quelques minutes. Zéro pression, zéro punition, zéro perte de vie.';

  @override
  String get onboardingTitle3 =>
      'Écoute, répète à voix haute, progresse sans peur.';

  @override
  String get onboardingSubtitle3 =>
      'Le shadowing entraîne votre accent et votre mémoire musculaire de l\'allemand.';

  @override
  String get onboardingDailyPhrases => 'Nouvelles phrases par jour';

  @override
  String get onboardingDailyMinutes => 'Temps par jour';

  @override
  String get onboardingStartLevel => 'Ton niveau de départ';

  @override
  String get onboardingLevelBeginner => 'Je débute totalement';

  @override
  String get onboardingLevelBasics => 'Je connais déjà quelques mots';

  @override
  String get homeGreeting => 'Hallo !';

  @override
  String homeStreakDays(int count) {
    return '$count jours';
  }

  @override
  String get homeStreakBroken => 'On reprend, c\'est normal 🙂';

  @override
  String get homeSessionCardTitle => 'Séance du jour';

  @override
  String homeSessionStats(int reviews, int newCount, int minutes) {
    return '$reviews révisions · $newCount nouvelles · ~$minutes min';
  }

  @override
  String get homeStartSession => 'Commencer la séance';

  @override
  String get homeProgressTitle => 'Progression globale';

  @override
  String homeProgressPhrases(int learned, int total) {
    return '$learned / $total phrases';
  }

  @override
  String get homePhraseOfTheDay => 'Phrase du jour';

  @override
  String get homeCurrentPhase => 'Phase actuelle : Écoute / Phrases / Parole';

  @override
  String get sessionClose => 'Fermer';

  @override
  String get sessionListenNormal => 'Normal';

  @override
  String get sessionListenSlow => 'Lent';

  @override
  String get sessionShadowingTitle => 'À toi de jouer ! 🎤';

  @override
  String get sessionShadowingHelp =>
      'Répète avec le même rythme. Pas besoin d\'être parfait.';

  @override
  String get sessionNext => 'Suivant';

  @override
  String get sessionSuccess => 'Bien !';

  @override
  String get sessionGentleCorrection => 'Presque ! Voilà la bonne phrase :';

  @override
  String get libraryTitle => 'Mes Phrases';

  @override
  String get librarySearchPlaceholder => 'Rechercher une phrase ou un mot...';

  @override
  String get libraryFilterAll => 'Toutes';

  @override
  String get libraryFilterNew => 'Nouvelles';

  @override
  String get libraryFilterInProgress => 'En cours';

  @override
  String get libraryFilterMastered => 'Maîtrisées';

  @override
  String get libraryFilterWatchlist => 'À surveiller';

  @override
  String get libraryUnlockAnyway => 'Débloquer quand même';

  @override
  String get progressTitle => 'Mes Progrès';

  @override
  String get progressPhrasesLearned => 'Phrases apprises';

  @override
  String get progressSessionsCompleted => 'Séances complétées';

  @override
  String get progressShadowingsDone => 'Shadowings réalisés';

  @override
  String get progressListeningTime => 'Temps d\'écoute';

  @override
  String get progressActivity30Days => 'Activité (30 jours)';

  @override
  String get progressDistribution => 'Répartition';

  @override
  String get progressMilestones => 'Jalons';

  @override
  String get settingsTitle => 'Réglages';

  @override
  String get settingsGeneral => 'Général';

  @override
  String get settingsAudio => 'Audio & Voix';

  @override
  String get settingsDailyReminder => 'Rappel quotidien';

  @override
  String get settingsTheme => 'Thème';

  @override
  String get settingsThemeLight => 'Clair';

  @override
  String get settingsThemeDark => 'Sombre';

  @override
  String get settingsThemeSystem => 'Système';

  @override
  String get settingsBackup => 'Sauvegarde & Restauration';

  @override
  String get settingsExport => 'Exporter la progression (JSON)';

  @override
  String get settingsImport => 'Restaurer une sauvegarde';

  @override
  String get settingsReset => 'Réinitialiser la progression';

  @override
  String get settingsAbout => 'À propos de Deutsch Fast';
}
