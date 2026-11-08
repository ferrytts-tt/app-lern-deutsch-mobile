import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app_lern_deutsch_mobile/core/services/subscription_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await SubscriptionService.instance.init(prefs: prefs);
    await SubscriptionService.instance.logoutAdmin(prefs: prefs);
  });

  group('SubscriptionService Tests', () {
    test('Par défaut, l\'utilisateur est en version gratuite (Lots 1-3 et Rätsel 1-3)', () {
      final sub = SubscriptionService.instance;
      expect(sub.isPremium, isFalse);
      expect(sub.isAdmin, isFalse);

      // Lots 1, 2, 3 sont accessibles
      expect(sub.isBatchAccessible(0), isTrue); // Lot 1
      expect(sub.isBatchAccessible(1), isTrue); // Lot 2
      expect(sub.isBatchAccessible(2), isTrue); // Lot 3

      // Lot 4 et suivants sont verrouillés
      expect(sub.isBatchAccessible(3), isFalse); // Lot 4
      expect(sub.isBatchAccessible(4), isFalse); // Lot 5

      // Mots croisés Rätsel 1, 2, 3 sont accessibles
      expect(sub.isRaetselLevelAccessible(1), isTrue);
      expect(sub.isRaetselLevelAccessible(2), isTrue);
      expect(sub.isRaetselLevelAccessible(3), isTrue);

      // Rätsel 4 et suivants sont verrouillés
      expect(sub.isRaetselLevelAccessible(4), isFalse);
      expect(sub.isRaetselLevelAccessible(5), isFalse);
    });

    test('Échec de connexion administrateur avec mauvais mot de passe ou email', () async {
      final sub = SubscriptionService.instance;

      final wrongPass = await sub.verifyAndLoginAdmin(
        email: 'tahtoouh@gmail.com',
        password: 'wrong_password',
      );
      expect(wrongPass, isFalse);
      expect(sub.isAdmin, isFalse);
      expect(sub.isPremium, isFalse);

      final wrongEmail = await sub.verifyAndLoginAdmin(
        email: 'hacker@gmail.com',
        password: 'Drogba123@Takhe25431',
      );
      expect(wrongEmail, isFalse);
      expect(sub.isAdmin, isFalse);
    });

    test('Succès de connexion administrateur avec identifiants exacts et déblocage total', () async {
      final sub = SubscriptionService.instance;

      final success = await sub.verifyAndLoginAdmin(
        email: 'tahtoouh@gmail.com',
        password: 'Drogba123@Takhe25431',
      );

      expect(success, isTrue);
      expect(sub.isAdmin, isTrue);
      expect(sub.isPremium, isTrue);

      // Désormais, TOUS les lots (même 4 à 30) et TOUS les Rätsel sont accessibles
      expect(sub.isBatchAccessible(3), isTrue); // Lot 4 débloqué
      expect(sub.isBatchAccessible(10), isTrue); // Lot 11 débloqué
      expect(sub.isRaetselLevelAccessible(4), isTrue); // Rätsel 4 débloqué
      expect(sub.isRaetselLevelAccessible(20), isTrue); // Rätsel 20 débloqué
    });
  });
}
