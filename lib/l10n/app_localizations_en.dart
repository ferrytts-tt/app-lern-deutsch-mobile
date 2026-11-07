// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Deutsch Fast';

  @override
  String get appSubtitle => 'Learn German quickly';

  @override
  String get navHome => 'Home';

  @override
  String get navLibrary => 'Phrases';

  @override
  String get navProgress => 'Progress';

  @override
  String get navSettings => 'Settings';

  @override
  String get onboardingSkip => 'Skip';

  @override
  String get onboardingNext => 'Next';

  @override
  String get onboardingStart => 'Get Started';

  @override
  String get onboardingTitle1 => 'Learn like a child, not like in school.';

  @override
  String get onboardingSubtitle1 =>
      'No boring grammar rules. Just full, real phrases repeated at the perfect moment.';

  @override
  String get onboardingTitle2 =>
      '1000 practical phrases to understand and speak.';

  @override
  String get onboardingSubtitle2 =>
      'A few minutes every day. Zero pressure, zero punishment, zero life loss.';

  @override
  String get onboardingTitle3 =>
      'Listen, repeat out loud, improve without fear.';

  @override
  String get onboardingSubtitle3 =>
      'Shadowing trains your accent and German muscle memory.';

  @override
  String get onboardingDailyPhrases => 'New phrases per day';

  @override
  String get onboardingDailyMinutes => 'Time per day';

  @override
  String get onboardingStartLevel => 'Your starting level';

  @override
  String get onboardingLevelBeginner => 'Complete beginner';

  @override
  String get onboardingLevelBasics => 'I know a few basic words';

  @override
  String get homeGreeting => 'Hallo!';

  @override
  String homeStreakDays(int count) {
    return '$count days';
  }

  @override
  String get homeStreakBroken => 'Let\'s pick it back up, totally normal 🙂';

  @override
  String get homeSessionCardTitle => 'Today\'s Session';

  @override
  String homeSessionStats(int reviews, int newCount, int minutes) {
    return '$reviews reviews · $newCount new · ~$minutes min';
  }

  @override
  String get homeStartSession => 'Start Session';

  @override
  String get homeProgressTitle => 'Overall Progress';

  @override
  String homeProgressPhrases(int learned, int total) {
    return '$learned / $total phrases';
  }

  @override
  String get homePhraseOfTheDay => 'Phrase of the day';

  @override
  String get homeCurrentPhase =>
      'Current phase: Listening / Phrases / Speaking';

  @override
  String get sessionClose => 'Close';

  @override
  String get sessionListenNormal => 'Normal';

  @override
  String get sessionListenSlow => 'Slow';

  @override
  String get sessionShadowingTitle => 'Your turn! 🎤';

  @override
  String get sessionShadowingHelp =>
      'Repeat with the same rhythm. No need to be perfect.';

  @override
  String get sessionNext => 'Next';

  @override
  String get sessionSuccess => 'Well done!';

  @override
  String get sessionGentleCorrection => 'Almost! Here is the right phrase:';

  @override
  String get libraryTitle => 'My Phrases';

  @override
  String get librarySearchPlaceholder => 'Search a phrase or word...';

  @override
  String get libraryFilterAll => 'All';

  @override
  String get libraryFilterNew => 'New';

  @override
  String get libraryFilterInProgress => 'In Progress';

  @override
  String get libraryFilterMastered => 'Mastered';

  @override
  String get libraryFilterWatchlist => 'Watchlist';

  @override
  String get libraryUnlockAnyway => 'Unlock anyway';

  @override
  String get progressTitle => 'My Progress';

  @override
  String get progressPhrasesLearned => 'Phrases learned';

  @override
  String get progressSessionsCompleted => 'Sessions completed';

  @override
  String get progressShadowingsDone => 'Shadowings done';

  @override
  String get progressListeningTime => 'Listening time';

  @override
  String get progressActivity30Days => 'Activity (30 days)';

  @override
  String get progressDistribution => 'Distribution';

  @override
  String get progressMilestones => 'Milestones';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsGeneral => 'General';

  @override
  String get settingsAudio => 'Audio & Voice';

  @override
  String get settingsDailyReminder => 'Daily Reminder';

  @override
  String get settingsTheme => 'Theme';

  @override
  String get settingsThemeLight => 'Light';

  @override
  String get settingsThemeDark => 'Dark';

  @override
  String get settingsThemeSystem => 'System';

  @override
  String get settingsBackup => 'Backup & Restore';

  @override
  String get settingsExport => 'Export progress (JSON)';

  @override
  String get settingsImport => 'Restore backup';

  @override
  String get settingsReset => 'Reset progress';

  @override
  String get settingsAbout => 'About Deutsch Fast';
}
