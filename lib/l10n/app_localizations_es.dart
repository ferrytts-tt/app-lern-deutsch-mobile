// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appName => 'Deutsch Fast';

  @override
  String get appSubtitle => 'Aprende alemán rápidamente';

  @override
  String get navHome => 'Inicio';

  @override
  String get navLibrary => 'Frases';

  @override
  String get navProgress => 'Progreso';

  @override
  String get navSettings => 'Ajustes';

  @override
  String get onboardingSkip => 'Saltar';

  @override
  String get onboardingNext => 'Siguiente';

  @override
  String get onboardingStart => 'Empezar';

  @override
  String get onboardingTitle1 => 'Aprende como un niño, no como en la escuela.';

  @override
  String get onboardingSubtitle1 =>
      'Sin reglas aburridas. Solo frases completas y reales, repetidas en el momento ideal.';

  @override
  String get onboardingTitle2 =>
      '1000 frases prácticas para entender y hablar.';

  @override
  String get onboardingSubtitle2 =>
      'Unos minutos al día. Cero presión, cero castigos, cero vidas perdidas.';

  @override
  String get onboardingTitle3 =>
      'Escucha, repite en voz alta, progresa sin miedo.';

  @override
  String get onboardingSubtitle3 =>
      'El shadowing entrena tu acento y tu memoria muscular del alemán.';

  @override
  String get onboardingDailyPhrases => 'Frases nuevas al día';

  @override
  String get onboardingDailyMinutes => 'Tiempo al día';

  @override
  String get onboardingStartLevel => 'Tu nivel de inicio';

  @override
  String get onboardingLevelBeginner => 'Principiante absoluto';

  @override
  String get onboardingLevelBasics => 'Conozco algunas palabras básicas';

  @override
  String get homeGreeting => 'Hallo!';

  @override
  String homeStreakDays(int count) {
    return '$count días';
  }

  @override
  String get homeStreakBroken => 'Continuamos, es totalmente normal 🙂';

  @override
  String get homeSessionCardTitle => 'Sesión de hoy';

  @override
  String homeSessionStats(int reviews, int newCount, int minutes) {
    return '$reviews repasos · $newCount nuevas · ~$minutes min';
  }

  @override
  String get homeStartSession => 'Comenzar sesión';

  @override
  String get homeProgressTitle => 'Progreso global';

  @override
  String homeProgressPhrases(int learned, int total) {
    return '$learned / $total frases';
  }

  @override
  String get homePhraseOfTheDay => 'Frase del día';

  @override
  String get homeCurrentPhase => 'Fase actual: Escucha / Frases / Habla';

  @override
  String get sessionClose => 'Cerrar';

  @override
  String get sessionListenNormal => 'Normal';

  @override
  String get sessionListenSlow => 'Lento';

  @override
  String get sessionShadowingTitle => '¡Te toca a ti! 🎤';

  @override
  String get sessionShadowingHelp =>
      'Repite con el mismo ritmo. No hace falta que sea perfecto.';

  @override
  String get sessionNext => 'Siguiente';

  @override
  String get sessionSuccess => '¡Muy bien!';

  @override
  String get sessionGentleCorrection => '¡Casi! Aquí tienes la frase correcta:';

  @override
  String get libraryTitle => 'Mis Frases';

  @override
  String get librarySearchPlaceholder => 'Buscar una frase o palabra...';

  @override
  String get libraryFilterAll => 'Todas';

  @override
  String get libraryFilterNew => 'Nuevas';

  @override
  String get libraryFilterInProgress => 'En curso';

  @override
  String get libraryFilterMastered => 'Dominadas';

  @override
  String get libraryFilterWatchlist => 'Por revisar';

  @override
  String get libraryUnlockAnyway => 'Desbloquear de todos modos';

  @override
  String get progressTitle => 'Mi Progreso';

  @override
  String get progressPhrasesLearned => 'Frases aprendidas';

  @override
  String get progressSessionsCompleted => 'Sesiones completadas';

  @override
  String get progressShadowingsDone => 'Shadowings realizados';

  @override
  String get progressListeningTime => 'Tiempo de escucha';

  @override
  String get progressActivity30Days => 'Actividad (30 días)';

  @override
  String get progressDistribution => 'Distribución';

  @override
  String get progressMilestones => 'Hitos';

  @override
  String get settingsTitle => 'Ajustes';

  @override
  String get settingsGeneral => 'General';

  @override
  String get settingsAudio => 'Audio y Voz';

  @override
  String get settingsDailyReminder => 'Recordatorio diario';

  @override
  String get settingsTheme => 'Tema';

  @override
  String get settingsThemeLight => 'Claro';

  @override
  String get settingsThemeDark => 'Oscuro';

  @override
  String get settingsThemeSystem => 'Sistema';

  @override
  String get settingsBackup => 'Copia de seguridad y restauración';

  @override
  String get settingsExport => 'Exportar progreso (JSON)';

  @override
  String get settingsImport => 'Restaurar copia';

  @override
  String get settingsReset => 'Restablecer progreso';

  @override
  String get settingsAbout => 'Acerca de Deutsch Fast';
}
