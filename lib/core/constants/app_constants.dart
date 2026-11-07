/// Constantes globales de l'application Deutsch Fast.
class AppConstants {
  AppConstants._();

  static const String appName = 'Hoppla!';
  static const String appSlogan = 'Tu l’apprends pour de bon.';
  static const int totalGoalPhrases = 1000;

  // Clés SharedPreferences
  static const String prefHasCompletedOnboarding = 'has_completed_onboarding';
  static const String prefDailyNewPhrases = 'daily_new_phrases';
  static const String prefDailyGoalMinutes = 'daily_goal_minutes';
  static const String prefUserLevel = 'user_level';
  static const String prefTtsSpeed = 'tts_speed';
  static const String prefThemeMode = 'theme_mode'; // 'system', 'light', 'dark'
  static const String prefStreakCount = 'streak_count';
  static const String prefLastActiveDate = 'last_active_date';

  // Valeurs par défaut
  static const int defaultDailyNewPhrases = 8;
  static const int defaultDailyGoalMinutes = 15;
  static const double defaultTtsSpeedNormal = 1.0; // Vitesse normale native allemande
  static const double defaultTtsSpeedSlow = 0.65; // Vitesse lente d'apprentissage
  static const double defaultTtsSpeedVerySlow = 0.45; // Vitesse très lente phonétique

  // Code PIN par défaut pour l'espace administration
  static const String adminPin = '1234';

  // Délais de répétition espacée en jours
  static const int srsCatchupThreshold = 40; // Seuil de retard pour mode rattrapage
}
