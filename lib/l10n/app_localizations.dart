import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_ro.dart';
import 'app_localizations_ru.dart';
import 'app_localizations_tr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('hi'),
    Locale('ro'),
    Locale('ru'),
    Locale('tr')
  ];

  /// No description provided for @appName.
  ///
  /// In fr, this message translates to:
  /// **'Deutsch Fast'**
  String get appName;

  /// No description provided for @appSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Apprends l\'allemand rapidement'**
  String get appSubtitle;

  /// No description provided for @navHome.
  ///
  /// In fr, this message translates to:
  /// **'Accueil'**
  String get navHome;

  /// No description provided for @navLibrary.
  ///
  /// In fr, this message translates to:
  /// **'Phrases'**
  String get navLibrary;

  /// No description provided for @navProgress.
  ///
  /// In fr, this message translates to:
  /// **'Progrès'**
  String get navProgress;

  /// No description provided for @navSettings.
  ///
  /// In fr, this message translates to:
  /// **'Réglages'**
  String get navSettings;

  /// No description provided for @onboardingSkip.
  ///
  /// In fr, this message translates to:
  /// **'Passer'**
  String get onboardingSkip;

  /// No description provided for @onboardingNext.
  ///
  /// In fr, this message translates to:
  /// **'Suivant'**
  String get onboardingNext;

  /// No description provided for @onboardingStart.
  ///
  /// In fr, this message translates to:
  /// **'Commencer'**
  String get onboardingStart;

  /// No description provided for @onboardingTitle1.
  ///
  /// In fr, this message translates to:
  /// **'Apprends comme un enfant, pas comme à l\'école.'**
  String get onboardingTitle1;

  /// No description provided for @onboardingSubtitle1.
  ///
  /// In fr, this message translates to:
  /// **'Pas de règles rébarbatives. Juste des phrases complètes et vivantes, répétées au bon moment.'**
  String get onboardingSubtitle1;

  /// No description provided for @onboardingTitle2.
  ///
  /// In fr, this message translates to:
  /// **'1000 phrases utiles pour comprendre et parler.'**
  String get onboardingTitle2;

  /// No description provided for @onboardingSubtitle2.
  ///
  /// In fr, this message translates to:
  /// **'Chaque jour quelques minutes. Zéro pression, zéro punition, zéro perte de vie.'**
  String get onboardingSubtitle2;

  /// No description provided for @onboardingTitle3.
  ///
  /// In fr, this message translates to:
  /// **'Écoute, répète à voix haute, progresse sans peur.'**
  String get onboardingTitle3;

  /// No description provided for @onboardingSubtitle3.
  ///
  /// In fr, this message translates to:
  /// **'Le shadowing entraîne votre accent et votre mémoire musculaire de l\'allemand.'**
  String get onboardingSubtitle3;

  /// No description provided for @onboardingDailyPhrases.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelles phrases par jour'**
  String get onboardingDailyPhrases;

  /// No description provided for @onboardingDailyMinutes.
  ///
  /// In fr, this message translates to:
  /// **'Temps par jour'**
  String get onboardingDailyMinutes;

  /// No description provided for @onboardingStartLevel.
  ///
  /// In fr, this message translates to:
  /// **'Ton niveau de départ'**
  String get onboardingStartLevel;

  /// No description provided for @onboardingLevelBeginner.
  ///
  /// In fr, this message translates to:
  /// **'Je débute totalement'**
  String get onboardingLevelBeginner;

  /// No description provided for @onboardingLevelBasics.
  ///
  /// In fr, this message translates to:
  /// **'Je connais déjà quelques mots'**
  String get onboardingLevelBasics;

  /// No description provided for @homeGreeting.
  ///
  /// In fr, this message translates to:
  /// **'Hallo !'**
  String get homeGreeting;

  /// No description provided for @homeStreakDays.
  ///
  /// In fr, this message translates to:
  /// **'{count} jours'**
  String homeStreakDays(int count);

  /// No description provided for @homeStreakBroken.
  ///
  /// In fr, this message translates to:
  /// **'On reprend, c\'est normal 🙂'**
  String get homeStreakBroken;

  /// No description provided for @homeSessionCardTitle.
  ///
  /// In fr, this message translates to:
  /// **'Séance du jour'**
  String get homeSessionCardTitle;

  /// No description provided for @homeSessionStats.
  ///
  /// In fr, this message translates to:
  /// **'{reviews} révisions · {newCount} nouvelles · ~{minutes} min'**
  String homeSessionStats(int reviews, int newCount, int minutes);

  /// No description provided for @homeStartSession.
  ///
  /// In fr, this message translates to:
  /// **'Commencer la séance'**
  String get homeStartSession;

  /// No description provided for @homeProgressTitle.
  ///
  /// In fr, this message translates to:
  /// **'Progression globale'**
  String get homeProgressTitle;

  /// No description provided for @homeProgressPhrases.
  ///
  /// In fr, this message translates to:
  /// **'{learned} / {total} phrases'**
  String homeProgressPhrases(int learned, int total);

  /// No description provided for @homePhraseOfTheDay.
  ///
  /// In fr, this message translates to:
  /// **'Phrase du jour'**
  String get homePhraseOfTheDay;

  /// No description provided for @homeCurrentPhase.
  ///
  /// In fr, this message translates to:
  /// **'Phase actuelle : Écoute / Phrases / Parole'**
  String get homeCurrentPhase;

  /// No description provided for @sessionClose.
  ///
  /// In fr, this message translates to:
  /// **'Fermer'**
  String get sessionClose;

  /// No description provided for @sessionListenNormal.
  ///
  /// In fr, this message translates to:
  /// **'Normal'**
  String get sessionListenNormal;

  /// No description provided for @sessionListenSlow.
  ///
  /// In fr, this message translates to:
  /// **'Lent'**
  String get sessionListenSlow;

  /// No description provided for @sessionShadowingTitle.
  ///
  /// In fr, this message translates to:
  /// **'À toi de jouer ! 🎤'**
  String get sessionShadowingTitle;

  /// No description provided for @sessionShadowingHelp.
  ///
  /// In fr, this message translates to:
  /// **'Répète avec le même rythme. Pas besoin d\'être parfait.'**
  String get sessionShadowingHelp;

  /// No description provided for @sessionNext.
  ///
  /// In fr, this message translates to:
  /// **'Suivant'**
  String get sessionNext;

  /// No description provided for @sessionSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Bien !'**
  String get sessionSuccess;

  /// No description provided for @sessionGentleCorrection.
  ///
  /// In fr, this message translates to:
  /// **'Presque ! Voilà la bonne phrase :'**
  String get sessionGentleCorrection;

  /// No description provided for @libraryTitle.
  ///
  /// In fr, this message translates to:
  /// **'Mes Phrases'**
  String get libraryTitle;

  /// No description provided for @librarySearchPlaceholder.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher une phrase ou un mot...'**
  String get librarySearchPlaceholder;

  /// No description provided for @libraryFilterAll.
  ///
  /// In fr, this message translates to:
  /// **'Toutes'**
  String get libraryFilterAll;

  /// No description provided for @libraryFilterNew.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelles'**
  String get libraryFilterNew;

  /// No description provided for @libraryFilterInProgress.
  ///
  /// In fr, this message translates to:
  /// **'En cours'**
  String get libraryFilterInProgress;

  /// No description provided for @libraryFilterMastered.
  ///
  /// In fr, this message translates to:
  /// **'Maîtrisées'**
  String get libraryFilterMastered;

  /// No description provided for @libraryFilterWatchlist.
  ///
  /// In fr, this message translates to:
  /// **'À surveiller'**
  String get libraryFilterWatchlist;

  /// No description provided for @libraryUnlockAnyway.
  ///
  /// In fr, this message translates to:
  /// **'Débloquer quand même'**
  String get libraryUnlockAnyway;

  /// No description provided for @progressTitle.
  ///
  /// In fr, this message translates to:
  /// **'Mes Progrès'**
  String get progressTitle;

  /// No description provided for @progressPhrasesLearned.
  ///
  /// In fr, this message translates to:
  /// **'Phrases apprises'**
  String get progressPhrasesLearned;

  /// No description provided for @progressSessionsCompleted.
  ///
  /// In fr, this message translates to:
  /// **'Séances complétées'**
  String get progressSessionsCompleted;

  /// No description provided for @progressShadowingsDone.
  ///
  /// In fr, this message translates to:
  /// **'Shadowings réalisés'**
  String get progressShadowingsDone;

  /// No description provided for @progressListeningTime.
  ///
  /// In fr, this message translates to:
  /// **'Temps d\'écoute'**
  String get progressListeningTime;

  /// No description provided for @progressActivity30Days.
  ///
  /// In fr, this message translates to:
  /// **'Activité (30 jours)'**
  String get progressActivity30Days;

  /// No description provided for @progressDistribution.
  ///
  /// In fr, this message translates to:
  /// **'Répartition'**
  String get progressDistribution;

  /// No description provided for @progressMilestones.
  ///
  /// In fr, this message translates to:
  /// **'Jalons'**
  String get progressMilestones;

  /// No description provided for @settingsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Réglages'**
  String get settingsTitle;

  /// No description provided for @settingsGeneral.
  ///
  /// In fr, this message translates to:
  /// **'Général'**
  String get settingsGeneral;

  /// No description provided for @settingsAudio.
  ///
  /// In fr, this message translates to:
  /// **'Audio & Voix'**
  String get settingsAudio;

  /// No description provided for @settingsDailyReminder.
  ///
  /// In fr, this message translates to:
  /// **'Rappel quotidien'**
  String get settingsDailyReminder;

  /// No description provided for @settingsTheme.
  ///
  /// In fr, this message translates to:
  /// **'Thème'**
  String get settingsTheme;

  /// No description provided for @settingsThemeLight.
  ///
  /// In fr, this message translates to:
  /// **'Clair'**
  String get settingsThemeLight;

  /// No description provided for @settingsThemeDark.
  ///
  /// In fr, this message translates to:
  /// **'Sombre'**
  String get settingsThemeDark;

  /// No description provided for @settingsThemeSystem.
  ///
  /// In fr, this message translates to:
  /// **'Système'**
  String get settingsThemeSystem;

  /// No description provided for @settingsBackup.
  ///
  /// In fr, this message translates to:
  /// **'Sauvegarde & Restauration'**
  String get settingsBackup;

  /// No description provided for @settingsExport.
  ///
  /// In fr, this message translates to:
  /// **'Exporter la progression (JSON)'**
  String get settingsExport;

  /// No description provided for @settingsImport.
  ///
  /// In fr, this message translates to:
  /// **'Restaurer une sauvegarde'**
  String get settingsImport;

  /// No description provided for @settingsReset.
  ///
  /// In fr, this message translates to:
  /// **'Réinitialiser la progression'**
  String get settingsReset;

  /// No description provided for @settingsAbout.
  ///
  /// In fr, this message translates to:
  /// **'À propos de Deutsch Fast'**
  String get settingsAbout;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
        'ar',
        'de',
        'en',
        'es',
        'fr',
        'hi',
        'ro',
        'ru',
        'tr'
      ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'hi':
      return AppLocalizationsHi();
    case 'ro':
      return AppLocalizationsRo();
    case 'ru':
      return AppLocalizationsRu();
    case 'tr':
      return AppLocalizationsTr();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
