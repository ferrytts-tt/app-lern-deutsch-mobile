import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service de gestion des rappels quotidiens programmés (Section 7.2 du plan de workflow).
/// Gère la programmation des notifications à l'heure choisie par l'utilisateur
/// avec le compte exact de phrases dues pour stimuler la rétention sans culpabiliser.
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  static NotificationService get instance => _instance;
  NotificationService._internal();

  static const String prefReminderEnabledKey = 'pref_daily_reminder_enabled';
  static const String prefReminderTimeKey = 'pref_daily_reminder_time';

  bool _isEnabled = true;
  String _preferredTime = '19:00';

  bool get isEnabled => _isEnabled;
  String get preferredTime => _preferredTime;

  /// Initialise les préférences de rappel.
  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isEnabled = prefs.getBool(prefReminderEnabledKey) ?? true;
      _preferredTime = prefs.getString(prefReminderTimeKey) ?? '19:00';
    } catch (e) {
      debugPrint('NotificationService init error: $e');
    }
  }

  /// Active ou désactive le rappel quotidien.
  Future<void> setEnabled(bool enabled) async {
    _isEnabled = enabled;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(prefReminderEnabledKey, enabled);
    } catch (_) {}
  }

  /// Met à jour l'heure préférée de rappel (ex: "19:00").
  Future<void> setPreferredTime(String time) async {
    _preferredTime = time;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(prefReminderTimeKey, time);
    } catch (_) {}
  }

  /// Génère le message exact de motivation pour la notification (Section 7.2).
  /// Exemples du plan :
  /// « 8 phrases t'attendent aujourd'hui. 5 minutes suffisent. »
  /// « Tu es à jour ! Découvre 10 nouvelles phrases aujourd'hui. »
  String buildReminderMessage({required int dueCount, int newCount = 10}) {
    if (dueCount <= 0) {
      return 'Tu es à jour ! Découvre $newCount nouvelles phrases aujourd\'hui. 🐿️';
    } else if (dueCount == 1) {
      return '1 phrase t\'attend aujourd\'hui. 5 minutes suffisent. 🐿️';
    } else {
      return '$dueCount phrases t\'attendent aujourd\'hui. 5 minutes suffisent. 🐿️';
    }
  }

  /// Simule ou programme la notification locale pour l'heure configurée.
  Future<bool> scheduleDailyReminder({required int dueCount}) async {
    if (!_isEnabled) return false;
    debugPrint('Rappel programmé à $_preferredTime: ${buildReminderMessage(dueCount: dueCount)}');
    return true;
  }
}
