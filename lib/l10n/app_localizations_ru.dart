// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appName => 'Deutsch Fast';

  @override
  String get appSubtitle => 'Учите немецкий быстро';

  @override
  String get navHome => 'Главная';

  @override
  String get navLibrary => 'Фразы';

  @override
  String get navProgress => 'Прогресс';

  @override
  String get navSettings => 'Настройки';

  @override
  String get onboardingSkip => 'Пропустить';

  @override
  String get onboardingNext => 'Далее';

  @override
  String get onboardingStart => 'Начать';

  @override
  String get onboardingTitle1 => 'Учитесь как ребенок, а не как в школе.';

  @override
  String get onboardingSubtitle1 =>
      'Никаких скучных правил. Только живые и полные фразы, повторяемые в нужный момент.';

  @override
  String get onboardingTitle2 => '1000 полезных фраз для понимания и речи.';

  @override
  String get onboardingSubtitle2 =>
      'Несколько минут каждый день. Без давления, без наказаний и без потери жизней.';

  @override
  String get onboardingTitle3 =>
      'Слушайте, повторяйте вслух, развивайтесь без страха.';

  @override
  String get onboardingSubtitle3 =>
      'Техника shadowing тренирует ваш акцент и мышечную память немецкого языка.';

  @override
  String get onboardingDailyPhrases => 'Новых фраз в день';

  @override
  String get onboardingDailyMinutes => 'Время в день';

  @override
  String get onboardingStartLevel => 'Ваш начальный уровень';

  @override
  String get onboardingLevelBeginner => 'Абсолютный новичок';

  @override
  String get onboardingLevelBasics => 'Знаю несколько базовых слов';

  @override
  String get homeGreeting => 'Hallo!';

  @override
  String homeStreakDays(int count) {
    return '$count дн.';
  }

  @override
  String get homeStreakBroken => 'Продолжаем, это абсолютно нормально 🙂';

  @override
  String get homeSessionCardTitle => 'Сегодняшняя сессия';

  @override
  String homeSessionStats(int reviews, int newCount, int minutes) {
    return '$reviews повторений · $newCount новых · ~$minutes мин';
  }

  @override
  String get homeStartSession => 'Начать занятие';

  @override
  String get homeProgressTitle => 'Общий прогресс';

  @override
  String homeProgressPhrases(int learned, int total) {
    return '$learned / $total фраз';
  }

  @override
  String get homePhraseOfTheDay => 'Фраза дня';

  @override
  String get homeCurrentPhase => 'Текущий этап: Аудирование / Фразы / Разговор';

  @override
  String get sessionClose => 'Закрыть';

  @override
  String get sessionListenNormal => 'Обычно';

  @override
  String get sessionListenSlow => 'Медленно';

  @override
  String get sessionShadowingTitle => 'Ваша очередь! 🎤';

  @override
  String get sessionShadowingHelp =>
      'Повторяйте с тем же ритмом. Идеальность не требуется.';

  @override
  String get sessionNext => 'Далее';

  @override
  String get sessionSuccess => 'Отлично!';

  @override
  String get sessionGentleCorrection => 'Почти! Вот правильная фраза:';

  @override
  String get libraryTitle => 'Мои фразы';

  @override
  String get librarySearchPlaceholder => 'Искать фразу или слово...';

  @override
  String get libraryFilterAll => 'Все';

  @override
  String get libraryFilterNew => 'Новые';

  @override
  String get libraryFilterInProgress => 'В процессе';

  @override
  String get libraryFilterMastered => 'Освоено';

  @override
  String get libraryFilterWatchlist => 'Внимание';

  @override
  String get libraryUnlockAnyway => 'Все равно разблокировать';

  @override
  String get progressTitle => 'Мой прогресс';

  @override
  String get progressPhrasesLearned => 'Изучено фраз';

  @override
  String get progressSessionsCompleted => 'Завершено занятий';

  @override
  String get progressShadowingsDone => 'Упражнений на повторение';

  @override
  String get progressListeningTime => 'Время прослушивания';

  @override
  String get progressActivity30Days => 'Активность (30 дней)';

  @override
  String get progressDistribution => 'Распределение';

  @override
  String get progressMilestones => 'Достижения';

  @override
  String get settingsTitle => 'Настройки';

  @override
  String get settingsGeneral => 'Общие';

  @override
  String get settingsAudio => 'Аудио и голос';

  @override
  String get settingsDailyReminder => 'Ежедневное напоминание';

  @override
  String get settingsTheme => 'Тема';

  @override
  String get settingsThemeLight => 'Светлая';

  @override
  String get settingsThemeDark => 'Темная';

  @override
  String get settingsThemeSystem => 'Системная';

  @override
  String get settingsBackup => 'Резервное копирование и восстановление';

  @override
  String get settingsExport => 'Экспорт прогресса (JSON)';

  @override
  String get settingsImport => 'Восстановить из копии';

  @override
  String get settingsReset => 'Сбросить прогресс';

  @override
  String get settingsAbout => 'О приложении Deutsch Fast';
}
