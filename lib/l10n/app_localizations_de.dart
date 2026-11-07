// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appName => 'Deutsch Fast';

  @override
  String get appSubtitle => 'Schnell Deutsch lernen';

  @override
  String get navHome => 'Start';

  @override
  String get navLibrary => 'Sätze';

  @override
  String get navProgress => 'Fortschritt';

  @override
  String get navSettings => 'Einstellungen';

  @override
  String get onboardingSkip => 'Überspringen';

  @override
  String get onboardingNext => 'Weiter';

  @override
  String get onboardingStart => 'Loslegen';

  @override
  String get onboardingTitle1 => 'Lerne wie ein Kind, nicht wie in der Schule.';

  @override
  String get onboardingSubtitle1 =>
      'Keine trockene Grammatik. Nur echte, lebendige Sätze zur richtigen Zeit wiederholt.';

  @override
  String get onboardingTitle2 =>
      '1000 nützliche Sätze zum Verstehen und Sprechen.';

  @override
  String get onboardingSubtitle2 =>
      'Jeden Tag ein paar Minuten. Kein Druck, keine Strafen, keine verlorenen Leben.';

  @override
  String get onboardingTitle3 =>
      'Hören, laut nachsprechen, angstfrei Fortschritte machen.';

  @override
  String get onboardingSubtitle3 =>
      'Shadowing trainiert deinen Akzent und dein Muskelgedächtnis für Deutsch.';

  @override
  String get onboardingDailyPhrases => 'Neue Sätze pro Tag';

  @override
  String get onboardingDailyMinutes => 'Zeit pro Tag';

  @override
  String get onboardingStartLevel => 'Dein Startniveau';

  @override
  String get onboardingLevelBeginner => 'Kompletter Anfänger';

  @override
  String get onboardingLevelBasics => 'Ich kenne bereits ein paar Wörter';

  @override
  String get homeGreeting => 'Hallo!';

  @override
  String homeStreakDays(int count) {
    return '$count Tage';
  }

  @override
  String get homeStreakBroken => 'Wir machen einfach weiter, ganz normal 🙂';

  @override
  String get homeSessionCardTitle => 'Heutige Lektion';

  @override
  String homeSessionStats(int reviews, int newCount, int minutes) {
    return '$reviews Wiederholungen · $newCount neu · ~$minutes Min.';
  }

  @override
  String get homeStartSession => 'Lektion starten';

  @override
  String get homeProgressTitle => 'Gesamtfortschritt';

  @override
  String homeProgressPhrases(int learned, int total) {
    return '$learned / $total Sätze';
  }

  @override
  String get homePhraseOfTheDay => 'Satz des Tages';

  @override
  String get homeCurrentPhase => 'Aktuelle Phase: Hören / Sätze / Sprechen';

  @override
  String get sessionClose => 'Schließen';

  @override
  String get sessionListenNormal => 'Normal';

  @override
  String get sessionListenSlow => 'Langsam';

  @override
  String get sessionShadowingTitle => 'Du bist dran! 🎤';

  @override
  String get sessionShadowingHelp =>
      'Sprich im gleichen Rhythmus nach. Es muss nicht perfekt sein.';

  @override
  String get sessionNext => 'Weiter';

  @override
  String get sessionSuccess => 'Super!';

  @override
  String get sessionGentleCorrection => 'Fast! Hier ist der richtige Satz:';

  @override
  String get libraryTitle => 'Meine Sätze';

  @override
  String get librarySearchPlaceholder => 'Nach Satz oder Wort suchen...';

  @override
  String get libraryFilterAll => 'Alle';

  @override
  String get libraryFilterNew => 'Neu';

  @override
  String get libraryFilterInProgress => 'In Bearbeitung';

  @override
  String get libraryFilterMastered => 'Gemeistert';

  @override
  String get libraryFilterWatchlist => 'Merkliste';

  @override
  String get libraryUnlockAnyway => 'Trotzdem freischalten';

  @override
  String get progressTitle => 'Mein Fortschritt';

  @override
  String get progressPhrasesLearned => 'Gelernte Sätze';

  @override
  String get progressSessionsCompleted => 'Abgeschlossene Lektionen';

  @override
  String get progressShadowingsDone => 'Shadowing-Übungen';

  @override
  String get progressListeningTime => 'Hörzeit';

  @override
  String get progressActivity30Days => 'Aktivität (30 Tage)';

  @override
  String get progressDistribution => 'Verteilung';

  @override
  String get progressMilestones => 'Meilensteine';

  @override
  String get settingsTitle => 'Einstellungen';

  @override
  String get settingsGeneral => 'Allgemein';

  @override
  String get settingsAudio => 'Audio & Stimme';

  @override
  String get settingsDailyReminder => 'Tägliche Erinnerung';

  @override
  String get settingsTheme => 'Design';

  @override
  String get settingsThemeLight => 'Hell';

  @override
  String get settingsThemeDark => 'Dunkel';

  @override
  String get settingsThemeSystem => 'System';

  @override
  String get settingsBackup => 'Sichern & Wiederherstellen';

  @override
  String get settingsExport => 'Fortschritt exportieren (JSON)';

  @override
  String get settingsImport => 'Sicherung wiederherstellen';

  @override
  String get settingsReset => 'Fortschritt zurücksetzen';

  @override
  String get settingsAbout => 'Über Deutsch Fast';
}
