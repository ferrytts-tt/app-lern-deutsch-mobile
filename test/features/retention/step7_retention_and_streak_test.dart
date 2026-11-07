import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app_lern_deutsch_mobile/core/services/notification_service.dart';
import 'package:app_lern_deutsch_mobile/core/widgets/duo_streak_widget.dart';
import 'package:app_lern_deutsch_mobile/core/widgets/mascot_widget.dart';
import 'package:app_lern_deutsch_mobile/domain/models/discreet_badge.dart';
import 'package:app_lern_deutsch_mobile/domain/models/user_profile.dart';
import 'package:app_lern_deutsch_mobile/features/progress/presentation/progress_controller.dart';
import 'package:app_lern_deutsch_mobile/features/progress/presentation/widgets/weekly_summary_sheet.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    MascotWidget.enableAnimations = false;
  });

  tearDown(() {
    MascotWidget.enableAnimations = true;
  });

  group('Étape 7 : Rétention et motivation (Spécification Section 7)', () {
    test('7.1 Série et Gel de série hebdomadaire - Recharge et protection', () {
      final now = DateTime(2026, 10, 25, 12, 0);

      // Profil initial avec gel disponible
      var profile = UserProfile(
        id: 'test_user',
        serieJours: 5,
        derniereSession: now.subtract(const Duration(days: 1)),
        gelSerieDisponible: true,
      );

      // Cas 1 : Jour consécutif normal (diffDays == 1)
      expect(profile.serieJours, 5);
      expect(profile.gelSerieDisponible, isTrue);

      // Cas 2 : Un jour manqué (diffDays == 2) -> le gel protège la flamme
      final skippedDay = now.add(const Duration(days: 2));
      final diffDays = DateTime(skippedDay.year, skippedDay.month, skippedDay.day)
          .difference(DateTime(profile.derniereSession!.year, profile.derniereSession!.month, profile.derniereSession!.day))
          .inDays;
      expect(diffDays, 3); // 3 jours depuis l'avant-veille = 2 jours sautés

      // Simulation de la consommation du gel
      profile = profile.copyWith(
        serieJours: profile.serieJours + 1,
        gelSerieDisponible: false,
        dateGelUtilise: now,
      );
      expect(profile.serieJours, 6);
      expect(profile.gelSerieDisponible, isFalse);
      expect(profile.dateGelUtilise, now);

      // Cas 3 : Moins de 7 jours plus tard -> le gel reste indisponible
      final threeDaysLater = now.add(const Duration(days: 3));
      var checked = profile.checkWeeklyStreakFreeze(threeDaysLater);
      expect(checked.gelSerieDisponible, isFalse);

      // Cas 4 : 7 jours plus tard -> recharge automatique hebdomadaire du gel (Section 7.1)
      final sevenDaysLater = now.add(const Duration(days: 7));
      checked = profile.checkWeeklyStreakFreeze(sevenDaysLater);
      expect(checked.gelSerieDisponible, isTrue);
      expect(checked.dateGelUtilise, isNull);
    });

    test('7.2 Notifications de rappel bienveillantes (Section 7.2)', () {
      final notif = NotificationService.instance;

      // Avec 8 phrases dues :
      // « 8 phrases t'attendent aujourd'hui. 5 minutes suffisent. »
      final msg8 = notif.buildReminderMessage(dueCount: 8);
      expect(msg8, contains('8 phrases'));
      expect(msg8, contains('5 minutes suffisent'));
      expect(msg8, contains('🐿️'));

      // Avec 1 phrase due :
      final msg1 = notif.buildReminderMessage(dueCount: 1);
      expect(msg1, contains('1 phrase'));
      expect(msg1, contains('5 minutes suffisent'));

      // À jour (0 phrase due) :
      // « Tu es à jour ! Découvre 10 nouvelles phrases aujourd'hui. »
      final msg0 = notif.buildReminderMessage(dueCount: 0, newCount: 10);
      expect(msg0, contains('Tu es à jour'));
      expect(msg0, contains('10 nouvelles phrases'));
      expect(msg0, contains('🐿️'));
    });

    test('7.3 Paliers et Récompenses discrètes (Section 7.4)', () {
      // Évaluation sans phrases acquises et série 3 jours
      var badges = DiscreetBadge.evaluateAll(
        acquiredPhrasesCount: 4,
        streakDays: 3,
      );
      expect(badges.length, 5);
      expect(badges.any((b) => b.id == BadgeId.acquired10 && !b.isUnlocked), isTrue);
      expect(badges.any((b) => b.id == BadgeId.streak7 && !b.isUnlocked), isTrue);

      // Évaluation avec 12 phrases acquises (Niveau 7) et série de 7 jours
      badges = DiscreetBadge.evaluateAll(
        acquiredPhrasesCount: 12,
        streakDays: 7,
      );
      final badge10 = badges.firstWhere((b) => b.id == BadgeId.acquired10);
      final badge7Days = badges.firstWhere((b) => b.id == BadgeId.streak7);
      final badge50 = badges.firstWhere((b) => b.id == BadgeId.acquired50);

      expect(badge10.isUnlocked, isTrue);
      expect(badge10.progressRatio, 1.0);
      expect(badge7Days.isUnlocked, isTrue);
      expect(badge7Days.progressRatio, 1.0);
      expect(badge50.isUnlocked, isFalse);
      expect(badge50.progressRatio, closeTo(12 / 50, 0.01));
    });

    testWidgets('7.4 Affichage du widget flamme Duolingo avec indicateur de gel actif', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DuoStreakWidget(
              streakDays: 9,
              isCompact: true,
              hasFreeze: true,
              animate: false,
            ),
          ),
        ),
      );

      expect(find.text('9'), findsOneWidget);
      expect(find.byIcon(Icons.ac_unit_rounded), findsOneWidget); // Flocon de glace pour gel actif
      expect(find.byIcon(Icons.local_fire_department_rounded), findsOneWidget);
    });

    testWidgets('7.5 Modal Bilan Hebdomadaire (Section 7.3)', (tester) async {
      const state = ProgressState(
        weeklyReviewedCount: 38,
        weeklyPromotedCount: 14,
        weeklyPracticeMinutes: 45,
        last7DaysActive: [true, true, false, true, true, true, true],
        freezeAvailable: true,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: WeeklySummarySheet(state: state),
          ),
        ),
      );

      expect(find.text('Bilan Hebdomadaire 📊'), findsOneWidget);
      expect(find.text('38'), findsOneWidget);
      expect(find.text('Phrases révisées'), findsOneWidget);
      expect(find.text('14'), findsOneWidget);
      expect(find.text('Niveau supérieur'), findsOneWidget);
      expect(find.text('45m'), findsOneWidget);
      expect(find.text('Temps passé'), findsOneWidget);
      expect(find.text('6 / 7 jours'), findsOneWidget);
      expect(find.textContaining('1 gel de série disponible'), findsOneWidget);
      expect(find.text('CONTINUER'), findsOneWidget);
    });
  });
}
