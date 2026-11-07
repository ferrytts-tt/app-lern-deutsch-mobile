import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_lern_deutsch_mobile/features/settings/presentation/settings_controller.dart';

void main() {
  group('SettingsState Tests', () {
    test('Valeurs par défaut correctes', () {
      const state = SettingsState();
      expect(state.themeMode, ThemeMode.system);
      expect(state.dailyNewPhrases, 8);
      expect(state.dailyGoalMinutes, 15);
      expect(state.ttsSpeed, 1.0);
      expect(state.isLoading, true);
    });

    test('copyWith met à jour les champs individuellement', () {
      const initial = SettingsState();
      final updated = initial.copyWith(
        themeMode: ThemeMode.dark,
        dailyNewPhrases: 10,
        dailyGoalMinutes: 20,
        ttsSpeed: 0.35,
        isLoading: false,
      );

      expect(updated.themeMode, ThemeMode.dark);
      expect(updated.dailyNewPhrases, 10);
      expect(updated.dailyGoalMinutes, 20);
      expect(updated.ttsSpeed, 0.35);
      expect(updated.isLoading, false);
    });
  });
}
