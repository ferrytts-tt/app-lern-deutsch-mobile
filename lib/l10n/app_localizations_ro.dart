// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Romanian Moldavian Moldovan (`ro`).
class AppLocalizationsRo extends AppLocalizations {
  AppLocalizationsRo([String locale = 'ro']) : super(locale);

  @override
  String get appName => 'Deutsch Fast';

  @override
  String get appSubtitle => 'Învață germana rapid';

  @override
  String get navHome => 'Acasă';

  @override
  String get navLibrary => 'Expresii';

  @override
  String get navProgress => 'Progres';

  @override
  String get navSettings => 'Setări';

  @override
  String get onboardingSkip => 'Omite';

  @override
  String get onboardingNext => 'Următorul';

  @override
  String get onboardingStart => 'Începe acum';

  @override
  String get onboardingTitle1 => 'Învață ca un copil, nu ca la școală.';

  @override
  String get onboardingSubtitle1 =>
      'Fără reguli gramaticale plictisitoare. Doar expresii complete și reale, repetate la momentul oportun.';

  @override
  String get onboardingTitle2 =>
      '1000 de expresii utile pentru a înțelege și vorbi.';

  @override
  String get onboardingSubtitle2 =>
      'Câteva minute în fiecare zi. Zero stres, zero pedepse, zero inimi pierdute.';

  @override
  String get onboardingTitle3 =>
      'Ascultă, repetă cu voce tare, progresează fără teamă.';

  @override
  String get onboardingSubtitle3 =>
      'Metoda shadowing îți antrenează accentul și memoria musculară a limbii germane.';

  @override
  String get onboardingDailyPhrases => 'Expresii noi pe zi';

  @override
  String get onboardingDailyMinutes => 'Timp alocat pe zi';

  @override
  String get onboardingStartLevel => 'Nivelul tău de pornire';

  @override
  String get onboardingLevelBeginner => 'Sunt începător absolut';

  @override
  String get onboardingLevelBasics => 'Cunosc deja câteva cuvinte';

  @override
  String get homeGreeting => 'Hallo!';

  @override
  String homeStreakDays(int count) {
    return '$count zile';
  }

  @override
  String get homeStreakBroken => 'Reluăm, este complet normal 🙂';

  @override
  String get homeSessionCardTitle => 'Sesiunea de azi';

  @override
  String homeSessionStats(int reviews, int newCount, int minutes) {
    return '$reviews recapitulări · $newCount noi · ~$minutes min';
  }

  @override
  String get homeStartSession => 'Începe sesiunea';

  @override
  String get homeProgressTitle => 'Progres general';

  @override
  String homeProgressPhrases(int learned, int total) {
    return '$learned / $total expresii';
  }

  @override
  String get homePhraseOfTheDay => 'Expresia zilei';

  @override
  String get homeCurrentPhase => 'Faza actuală: Ascultare / Expresii / Vorbire';

  @override
  String get sessionClose => 'Închide';

  @override
  String get sessionListenNormal => 'Normal';

  @override
  String get sessionListenSlow => 'Lent';

  @override
  String get sessionShadowingTitle => 'E rândul tău! 🎤';

  @override
  String get sessionShadowingHelp =>
      'Repetă cu același ritm. Nu trebuie să fie perfect.';

  @override
  String get sessionNext => 'Următorul';

  @override
  String get sessionSuccess => 'Bravo!';

  @override
  String get sessionGentleCorrection => 'Aproape! Iată expresia corectă:';

  @override
  String get libraryTitle => 'Expresiile mele';

  @override
  String get librarySearchPlaceholder => 'Caută o expresie sau un cuvânt...';

  @override
  String get libraryFilterAll => 'Toate';

  @override
  String get libraryFilterNew => 'Noi';

  @override
  String get libraryFilterInProgress => 'În curs';

  @override
  String get libraryFilterMastered => 'Stăpânite';

  @override
  String get libraryFilterWatchlist => 'De urmărit';

  @override
  String get libraryUnlockAnyway => 'Deblochează oricum';

  @override
  String get progressTitle => 'Progresul meu';

  @override
  String get progressPhrasesLearned => 'Expresii învățate';

  @override
  String get progressSessionsCompleted => 'Sesiuni finalizate';

  @override
  String get progressShadowingsDone => 'Exerciții de shadowing';

  @override
  String get progressListeningTime => 'Timp de ascultare';

  @override
  String get progressActivity30Days => 'Activitate (30 de zile)';

  @override
  String get progressDistribution => 'Distribuție';

  @override
  String get progressMilestones => 'Repere';

  @override
  String get settingsTitle => 'Setări';

  @override
  String get settingsGeneral => 'General';

  @override
  String get settingsAudio => 'Audio & Voce';

  @override
  String get settingsDailyReminder => 'Memento zilnic';

  @override
  String get settingsTheme => 'Temă';

  @override
  String get settingsThemeLight => 'Luminoasă';

  @override
  String get settingsThemeDark => 'Întunecată';

  @override
  String get settingsThemeSystem => 'Sistem';

  @override
  String get settingsBackup => 'Copie de rezervă și restaurare';

  @override
  String get settingsExport => 'Exportă progresul (JSON)';

  @override
  String get settingsImport => 'Restaurează o copie';

  @override
  String get settingsReset => 'Resetează progresul';

  @override
  String get settingsAbout => 'Despre Deutsch Fast';
}
