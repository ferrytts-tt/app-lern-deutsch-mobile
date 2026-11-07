// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get appName => 'Deutsch Fast';

  @override
  String get appSubtitle => 'Almancayı hızla öğrenin';

  @override
  String get navHome => 'Ana Sayfa';

  @override
  String get navLibrary => 'Cümleler';

  @override
  String get navProgress => 'İlerleme';

  @override
  String get navSettings => 'Ayarlar';

  @override
  String get onboardingSkip => 'Geç';

  @override
  String get onboardingNext => 'İleri';

  @override
  String get onboardingStart => 'Başla';

  @override
  String get onboardingTitle1 => 'Okul gibi değil, bir çocuk gibi öğrenin.';

  @override
  String get onboardingSubtitle1 =>
      'Sıkıcı kurallar yok. Yalnızca tam ve canlı cümleler, tam doğru zamanda tekrarlanır.';

  @override
  String get onboardingTitle2 => 'Anlamak ve konuşmak için 1000 pratik cümle.';

  @override
  String get onboardingSubtitle2 =>
      'Her gün birkaç dakika. Baskı yok, ceza yok, can kaybetmek yok.';

  @override
  String get onboardingTitle3 =>
      'Dinleyin, yüksek sesle tekrarlayın, korkusuzca ilerleyin.';

  @override
  String get onboardingSubtitle3 =>
      'Gölgeleme (shadowing) tekniği Almanca telaffuzunuzu ve kas hafızanızı geliştirir.';

  @override
  String get onboardingDailyPhrases => 'Günlük yeni cümleler';

  @override
  String get onboardingDailyMinutes => 'Günlük süre';

  @override
  String get onboardingStartLevel => 'Başlangıç seviyeniz';

  @override
  String get onboardingLevelBeginner => 'Tamamen yeni başlayanım';

  @override
  String get onboardingLevelBasics => 'Birkaç temel kelime biliyorum';

  @override
  String get homeGreeting => 'Hallo!';

  @override
  String homeStreakDays(int count) {
    return '$count gün';
  }

  @override
  String get homeStreakBroken => 'Kaldığımız yerden devam, bu gayet doğal 🙂';

  @override
  String get homeSessionCardTitle => 'Günün Oturumu';

  @override
  String homeSessionStats(int reviews, int newCount, int minutes) {
    return '$reviews tekrar · $newCount yeni · ~$minutes dk';
  }

  @override
  String get homeStartSession => 'Oturumu Başlat';

  @override
  String get homeProgressTitle => 'Genel İlerleme';

  @override
  String homeProgressPhrases(int learned, int total) {
    return '$learned / $total cümle';
  }

  @override
  String get homePhraseOfTheDay => 'Günün cümlesi';

  @override
  String get homeCurrentPhase => 'Mevcut aşama: Dinleme / Cümleler / Konuşma';

  @override
  String get sessionClose => 'Kapat';

  @override
  String get sessionListenNormal => 'Normal';

  @override
  String get sessionListenSlow => 'Yavaş';

  @override
  String get sessionShadowingTitle => 'Sıra sende! 🎤';

  @override
  String get sessionShadowingHelp =>
      'Aynı ritimle tekrar et. Mükemmel olmak zorunda değilsin.';

  @override
  String get sessionNext => 'İleri';

  @override
  String get sessionSuccess => 'Harika!';

  @override
  String get sessionGentleCorrection => 'Neredeyse! İşte doğru cümle:';

  @override
  String get libraryTitle => 'Cümlelerim';

  @override
  String get librarySearchPlaceholder => 'Bir cümle veya kelime ara...';

  @override
  String get libraryFilterAll => 'Tümü';

  @override
  String get libraryFilterNew => 'Yeni';

  @override
  String get libraryFilterInProgress => 'Devam Edenler';

  @override
  String get libraryFilterMastered => 'Öğrenilenler';

  @override
  String get libraryFilterWatchlist => 'İzleme Listesi';

  @override
  String get libraryUnlockAnyway => 'Yine de kilidi aç';

  @override
  String get progressTitle => 'İlerlemem';

  @override
  String get progressPhrasesLearned => 'Öğrenilen cümleler';

  @override
  String get progressSessionsCompleted => 'Tamamlanan oturumlar';

  @override
  String get progressShadowingsDone => 'Yapılan gölgeleme alıştırmaları';

  @override
  String get progressListeningTime => 'Dinleme süresi';

  @override
  String get progressActivity30Days => 'Aktivite (30 gün)';

  @override
  String get progressDistribution => 'Dağılım';

  @override
  String get progressMilestones => 'Kilometre Taşları';

  @override
  String get settingsTitle => 'Ayarlar';

  @override
  String get settingsGeneral => 'Genel';

  @override
  String get settingsAudio => 'Ses ve Konuşma';

  @override
  String get settingsDailyReminder => 'Günlük Hatırlatıcı';

  @override
  String get settingsTheme => 'Tema';

  @override
  String get settingsThemeLight => 'Açık';

  @override
  String get settingsThemeDark => 'Koyu';

  @override
  String get settingsThemeSystem => 'Sistem';

  @override
  String get settingsBackup => 'Yedekleme ve Geri Yükleme';

  @override
  String get settingsExport => 'İlerlemeyi Dışa Aktar (JSON)';

  @override
  String get settingsImport => 'Yedeği Geri Yükle';

  @override
  String get settingsReset => 'İlerlemeyi Sıfırla';

  @override
  String get settingsAbout => 'Deutsch Fast Hakkında';
}
