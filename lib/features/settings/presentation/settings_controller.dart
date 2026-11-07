import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/database/app_database.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/services/tts_service.dart';

class SettingsState {
  final ThemeMode themeMode;
  final Locale locale;
  final String primaryLanguage;
  final String? secondaryLanguage;
  final int dailyNewPhrases;
  final int dailyGoalMinutes;
  final double ttsSpeed;
  final String voiceGender;
  final bool isLoading;
  final bool reminderEnabled;
  final String reminderTime;
  final int streakDays;
  final bool freezeAvailable;

  const SettingsState({
    this.themeMode = ThemeMode.system,
    this.locale = const Locale('fr'),
    this.primaryLanguage = 'fr',
    this.secondaryLanguage,
    this.dailyNewPhrases = AppConstants.defaultDailyNewPhrases,
    this.dailyGoalMinutes = AppConstants.defaultDailyGoalMinutes,
    this.ttsSpeed = AppConstants.defaultTtsSpeedNormal,
    this.voiceGender = 'alternate',
    this.isLoading = true,
    this.reminderEnabled = true,
    this.reminderTime = '19:00',
    this.streakDays = 0,
    this.freezeAvailable = true,
  });

  SettingsState copyWith({
    ThemeMode? themeMode,
    Locale? locale,
    String? primaryLanguage,
    String? secondaryLanguage,
    bool clearSecondaryLanguage = false,
    int? dailyNewPhrases,
    int? dailyGoalMinutes,
    double? ttsSpeed,
    String? voiceGender,
    bool? isLoading,
    bool? reminderEnabled,
    String? reminderTime,
    int? streakDays,
    bool? freezeAvailable,
  }) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      locale: locale ?? this.locale,
      primaryLanguage: primaryLanguage ?? this.primaryLanguage,
      secondaryLanguage: clearSecondaryLanguage ? null : (secondaryLanguage ?? this.secondaryLanguage),
      dailyNewPhrases: dailyNewPhrases ?? this.dailyNewPhrases,
      dailyGoalMinutes: dailyGoalMinutes ?? this.dailyGoalMinutes,
      ttsSpeed: ttsSpeed ?? this.ttsSpeed,
      voiceGender: voiceGender ?? this.voiceGender,
      isLoading: isLoading ?? this.isLoading,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      reminderTime: reminderTime ?? this.reminderTime,
      streakDays: streakDays ?? this.streakDays,
      freezeAvailable: freezeAvailable ?? this.freezeAvailable,
    );
  }
}

class SettingsController extends StateNotifier<SettingsState> {
  final AppDatabase _database = AppDatabase.instance;
  final NotificationService _notifications = NotificationService.instance;

  SettingsController() : super(const SettingsState()) {
    loadSettings();
  }

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await _notifications.init();
    final profile = await _database.getUserProfile();

    final themeStr = prefs.getString(AppConstants.prefThemeMode) ?? 'system';
    ThemeMode mode;
    switch (themeStr) {
      case 'light':
        mode = ThemeMode.light;
        break;
      case 'dark':
        mode = ThemeMode.dark;
        break;
      default:
        mode = ThemeMode.system;
    }

    final savedLang = prefs.getString('app_language_code') ?? profile.primaryLanguage;
    final secondaryLang = prefs.getString('secondary_language_code') ?? profile.secondaryLanguage;

    final dailyNew = prefs.getInt(AppConstants.prefDailyNewPhrases) ??
        profile.objectifQuotidien;
    final dailyMinutes = prefs.getInt(AppConstants.prefDailyGoalMinutes) ??
        AppConstants.defaultDailyGoalMinutes;
    final speed = prefs.getDouble(AppConstants.prefTtsSpeed) ??
        AppConstants.defaultTtsSpeedNormal;
    final voiceGender = prefs.getString('tts_voice_gender') ?? 'alternate';

    state = SettingsState(
      themeMode: mode,
      locale: Locale(savedLang),
      primaryLanguage: savedLang,
      secondaryLanguage: secondaryLang,
      dailyNewPhrases: dailyNew,
      dailyGoalMinutes: dailyMinutes,
      ttsSpeed: speed,
      voiceGender: voiceGender,
      isLoading: false,
      reminderEnabled: _notifications.isEnabled,
      reminderTime: profile.heureRappel,
      streakDays: profile.serieJours,
      freezeAvailable: profile.gelSerieDisponible,
    );
  }

  Future<void> setPrimaryLanguage(String langCode) async {
    state = state.copyWith(
      locale: Locale(langCode),
      primaryLanguage: langCode,
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_language_code', langCode);
    final profile = await _database.getUserProfile();
    await _database.saveUserProfile(profile.copyWith(primaryLanguage: langCode));
  }

  Future<void> setSecondaryLanguage(String? langCode) async {
    state = state.copyWith(
      secondaryLanguage: langCode,
      clearSecondaryLanguage: langCode == null || langCode.isEmpty,
    );
    final prefs = await SharedPreferences.getInstance();
    if (langCode == null || langCode.isEmpty) {
      await prefs.remove('secondary_language_code');
    } else {
      await prefs.setString('secondary_language_code', langCode);
    }
    final profile = await _database.getUserProfile();
    await _database.saveUserProfile(profile.copyWith(
      secondaryLanguage: langCode,
      clearSecondaryLanguage: langCode == null || langCode.isEmpty,
    ));
  }

  Future<void> setVoiceGender(String gender) async {
    state = state.copyWith(voiceGender: gender);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('tts_voice_gender', gender);
    await TtsService.instance.setVoiceGenderPreference(gender);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    final prefs = await SharedPreferences.getInstance();
    String str = 'system';
    if (mode == ThemeMode.light) str = 'light';
    if (mode == ThemeMode.dark) str = 'dark';
    await prefs.setString(AppConstants.prefThemeMode, str);
  }

  Future<void> setDailyNewPhrases(int count) async {
    state = state.copyWith(dailyNewPhrases: count);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(AppConstants.prefDailyNewPhrases, count);
    final profile = await _database.getUserProfile();
    await _database.saveUserProfile(profile.copyWith(objectifQuotidien: count));
  }

  Future<void> setDailyGoalMinutes(int minutes) async {
    state = state.copyWith(dailyGoalMinutes: minutes);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(AppConstants.prefDailyGoalMinutes, minutes);
  }

  Future<void> setTtsSpeed(double speed) async {
    state = state.copyWith(ttsSpeed: speed);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(AppConstants.prefTtsSpeed, speed);
  }

  Future<void> setReminderEnabled(bool enabled) async {
    await _notifications.setEnabled(enabled);
    state = state.copyWith(reminderEnabled: enabled);
  }

  Future<void> setReminderTime(String time) async {
    await _notifications.setPreferredTime(time);
    final profile = await _database.getUserProfile();
    await _database.saveUserProfile(profile.copyWith(heureRappel: time));
    state = state.copyWith(reminderTime: time);
  }

  Future<void> resetProgress() async {
    await _database.resetUserProgress();
    final profile = await _database.getUserProfile();
    await _database.saveUserProfile(profile.copyWith(serieJours: 1));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(AppConstants.prefStreakCount, 1);
    state = state.copyWith(streakDays: 1);
  }
}

final settingsControllerProvider =
    StateNotifierProvider<SettingsController, SettingsState>((ref) {
  return SettingsController();
});
