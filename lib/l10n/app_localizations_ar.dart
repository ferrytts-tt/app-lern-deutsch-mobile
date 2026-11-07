// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appName => 'Deutsch Fast';

  @override
  String get appSubtitle => 'تعلم الألمانية بسرعة';

  @override
  String get navHome => 'الرئيسية';

  @override
  String get navLibrary => 'الجمل';

  @override
  String get navProgress => 'التقدم';

  @override
  String get navSettings => 'الإعدادات';

  @override
  String get onboardingSkip => 'تخطي';

  @override
  String get onboardingNext => 'التالي';

  @override
  String get onboardingStart => 'ابدأ الآن';

  @override
  String get onboardingTitle1 => 'تعلم مثل الأطفال، وليس مثل المدرسة.';

  @override
  String get onboardingSubtitle1 =>
      'لا قواعد مملة. فقط جمل كاملة وحية، تتكرر في اللحظة المناسبة تماماً.';

  @override
  String get onboardingTitle2 => '1000 جملة عملية للفهم والتحدث.';

  @override
  String get onboardingSubtitle2 =>
      'بضع دقائق كل يوم. بدون ضغط، بدون عقاب، وبدون خسارة قلوب.';

  @override
  String get onboardingTitle3 => 'استمع، كرر بصوت عالٍ، وتقدم دون خوف.';

  @override
  String get onboardingSubtitle3 =>
      'تقنية المحاكاة (Shadowing) تدرب نبرتك وذاكرتك العضلية للألمانية.';

  @override
  String get onboardingDailyPhrases => 'جمل جديدة كل يوم';

  @override
  String get onboardingDailyMinutes => 'الوقت يومياً';

  @override
  String get onboardingStartLevel => 'مستواك الحالي';

  @override
  String get onboardingLevelBeginner => 'مبتدئ تماماً';

  @override
  String get onboardingLevelBasics => 'أعرف بعض الكلمات البسيطة';

  @override
  String get homeGreeting => 'Hallo!';

  @override
  String homeStreakDays(int count) {
    return '$count أيام';
  }

  @override
  String get homeStreakBroken => 'سنواصل من جديد، هذا أمر طبيعي 🙂';

  @override
  String get homeSessionCardTitle => 'جلسة اليوم';

  @override
  String homeSessionStats(int reviews, int newCount, int minutes) {
    return '$reviews مراجعة · $newCount جديدة · ~$minutes دقيقة';
  }

  @override
  String get homeStartSession => 'بدء الجلسة';

  @override
  String get homeProgressTitle => 'التقدم الإجمالي';

  @override
  String homeProgressPhrases(int learned, int total) {
    return '$learned / $total جملة';
  }

  @override
  String get homePhraseOfTheDay => 'جملة اليوم';

  @override
  String get homeCurrentPhase => 'المرحلة الحالية: استماع / جمل / محادثة';

  @override
  String get sessionClose => 'إغلاق';

  @override
  String get sessionListenNormal => 'عادي';

  @override
  String get sessionListenSlow => 'بطيء';

  @override
  String get sessionShadowingTitle => 'دورك الآن! 🎤';

  @override
  String get sessionShadowingHelp =>
      'كرر بنفس الإيقاع. ليس من الضروري أن تكون مثالياً.';

  @override
  String get sessionNext => 'التالي';

  @override
  String get sessionSuccess => 'أحسنت!';

  @override
  String get sessionGentleCorrection => 'تقريباً! ها هي الجملة الصحيحة:';

  @override
  String get libraryTitle => 'جملي';

  @override
  String get librarySearchPlaceholder => 'ابحث عن جملة أو كلمة...';

  @override
  String get libraryFilterAll => 'الكل';

  @override
  String get libraryFilterNew => 'جديدة';

  @override
  String get libraryFilterInProgress => 'قيد التعلم';

  @override
  String get libraryFilterMastered => 'متقنة';

  @override
  String get libraryFilterWatchlist => 'للمتابعة';

  @override
  String get libraryUnlockAnyway => 'فتح على أي حال';

  @override
  String get progressTitle => 'تقدمي';

  @override
  String get progressPhrasesLearned => 'جمل تم تعلمها';

  @override
  String get progressSessionsCompleted => 'جلسات مكتملة';

  @override
  String get progressShadowingsDone => 'محاكاة صوتية منجزة';

  @override
  String get progressListeningTime => 'وقت الاستماع';

  @override
  String get progressActivity30Days => 'النشاط (30 يوماً)';

  @override
  String get progressDistribution => 'التوزيع';

  @override
  String get progressMilestones => 'الإنجازات';

  @override
  String get settingsTitle => 'الإعدادات';

  @override
  String get settingsGeneral => 'عام';

  @override
  String get settingsAudio => 'الصوت والتحدث';

  @override
  String get settingsDailyReminder => 'التذكير اليومي';

  @override
  String get settingsTheme => 'المظهر';

  @override
  String get settingsThemeLight => 'فاتح';

  @override
  String get settingsThemeDark => 'داكن';

  @override
  String get settingsThemeSystem => 'النظام';

  @override
  String get settingsBackup => 'النسخ الاحتياطي والاستعادة';

  @override
  String get settingsExport => 'تصدير التقدم (JSON)';

  @override
  String get settingsImport => 'استعادة النسخة الاحتياطية';

  @override
  String get settingsReset => 'إعادة تعيين التقدم';

  @override
  String get settingsAbout => 'حول Deutsch Fast';
}
