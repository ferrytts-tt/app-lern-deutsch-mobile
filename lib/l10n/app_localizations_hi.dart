// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get appName => 'Deutsch Fast';

  @override
  String get appSubtitle => 'जर्मन जल्दी सीखें';

  @override
  String get navHome => 'होम';

  @override
  String get navLibrary => 'वाक्य';

  @override
  String get navProgress => 'प्रगति';

  @override
  String get navSettings => 'सेटिंग्स';

  @override
  String get onboardingSkip => 'छोड़ें';

  @override
  String get onboardingNext => 'आगे';

  @override
  String get onboardingStart => 'शुरू करें';

  @override
  String get onboardingTitle1 => 'एक बच्चे की तरह सीखें, स्कूल की तरह नहीं।';

  @override
  String get onboardingSubtitle1 =>
      'कोई उबाऊ नियम नहीं। केवल पूरे और वास्तविक वाक्य, सही समय पर दोहराए गए।';

  @override
  String get onboardingTitle2 => 'समझने और बोलने के लिए 1000 व्यावहारिक वाक्य।';

  @override
  String get onboardingSubtitle2 =>
      'हर दिन कुछ मिनट। बिना किसी तनाव या सजा के।';

  @override
  String get onboardingTitle3 =>
      'सुनें, ज़ोर से दोहराएं, बिना डर के आगे बढ़ें।';

  @override
  String get onboardingSubtitle3 =>
      'शैडोइंग तकनीक आपके जर्मन उच्चारण और मांसपेशियों की याददाश्त को प्रशिक्षित करती है।';

  @override
  String get onboardingDailyPhrases => 'प्रति दिन नए वाक्य';

  @override
  String get onboardingDailyMinutes => 'प्रति दिन समय';

  @override
  String get onboardingStartLevel => 'आपका प्रारंभिक स्तर';

  @override
  String get onboardingLevelBeginner => 'बिल्कुल शुरुआत';

  @override
  String get onboardingLevelBasics => 'मुझे कुछ बुनियादी शब्द आते हैं';

  @override
  String get homeGreeting => 'Hallo!';

  @override
  String homeStreakDays(int count) {
    return '$count दिन';
  }

  @override
  String get homeStreakBroken =>
      'फिर से शुरू करते हैं, यह बिल्कुल सामान्य है 🙂';

  @override
  String get homeSessionCardTitle => 'आज का सत्र';

  @override
  String homeSessionStats(int reviews, int newCount, int minutes) {
    return '$reviews समीक्षाएं · $newCount नए · ~$minutes मिनट';
  }

  @override
  String get homeStartSession => 'सत्र शुरू करें';

  @override
  String get homeProgressTitle => 'समग्र प्रगति';

  @override
  String homeProgressPhrases(int learned, int total) {
    return '$learned / $total वाक्य';
  }

  @override
  String get homePhraseOfTheDay => 'आज का वाक्य';

  @override
  String get homeCurrentPhase => 'वर्तमान चरण: सुनना / वाक्य / बोलना';

  @override
  String get sessionClose => 'बंद करें';

  @override
  String get sessionListenNormal => 'सामान्य';

  @override
  String get sessionListenSlow => 'धीमा';

  @override
  String get sessionShadowingTitle => 'अब आपकी बारी! 🎤';

  @override
  String get sessionShadowingHelp =>
      'उसी लय में दोहराएं। एकदम सही होना ज़रूरी नहीं है।';

  @override
  String get sessionNext => 'आगे';

  @override
  String get sessionSuccess => 'बहुत बढ़िया!';

  @override
  String get sessionGentleCorrection => 'लगभग सही! यह सही वाक्य है:';

  @override
  String get libraryTitle => 'मेरे वाक्य';

  @override
  String get librarySearchPlaceholder => 'वाक्य या शब्द खोजें...';

  @override
  String get libraryFilterAll => 'सभी';

  @override
  String get libraryFilterNew => 'नए';

  @override
  String get libraryFilterInProgress => 'जारी है';

  @override
  String get libraryFilterMastered => 'महारत हासिल';

  @override
  String get libraryFilterWatchlist => 'निगरानी में';

  @override
  String get libraryUnlockAnyway => 'फिर भी अनलॉक करें';

  @override
  String get progressTitle => 'मेरी प्रगति';

  @override
  String get progressPhrasesLearned => 'सीखे गए वाक्य';

  @override
  String get progressSessionsCompleted => 'पूरे किए गए सत्र';

  @override
  String get progressShadowingsDone => 'शैडोइंग अभ्यास';

  @override
  String get progressListeningTime => 'सुनने का समय';

  @override
  String get progressActivity30Days => 'गतिविधि (30 दिन)';

  @override
  String get progressDistribution => 'वितरण';

  @override
  String get progressMilestones => 'मील के पत्थर';

  @override
  String get settingsTitle => 'सेटिंग्स';

  @override
  String get settingsGeneral => 'सामान्य';

  @override
  String get settingsAudio => 'ऑडियो और आवाज़';

  @override
  String get settingsDailyReminder => 'दैनिक अनुस्मारक';

  @override
  String get settingsTheme => 'थीम';

  @override
  String get settingsThemeLight => 'लाइट';

  @override
  String get settingsThemeDark => 'डार्क';

  @override
  String get settingsThemeSystem => 'सिस्टम';

  @override
  String get settingsBackup => 'बैकअप और रीस्टोर';

  @override
  String get settingsExport => 'प्रगति निर्यात करें (JSON)';

  @override
  String get settingsImport => 'बैकअप रीस्टोर करें';

  @override
  String get settingsReset => 'प्रगति रीसेट करें';

  @override
  String get settingsAbout => 'Deutsch Fast के बारे में';
}
