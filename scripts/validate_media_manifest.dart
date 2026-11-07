import 'dart:io';
import 'package:app_lern_deutsch_mobile/features/media/domain/media_manifest_validator.dart';

/// Script de validation d'intégrité pour les contenus « Chansons & Dialogues ».
/// Exécution : `dart run scripts/validate_media_manifest.dart [base_dir]`
Future<void> main(List<String> args) async {
  final baseDir = args.isNotEmpty ? args[0] : '.';

  stdout.writeln('======================================================');
  stdout.writeln('🎵 Hoppla! - Validation du Manifest Chansons & Dialogues');
  stdout.writeln('======================================================');
  stdout.writeln('Répertoire racine : $baseDir');

  final validator = MediaManifestValidator(baseDir: baseDir);
  final result = await validator.validate();

  if (result.warnings.isNotEmpty) {
    stdout.writeln('\n⚠️ AVERTISSEMENTS (${result.warnings.length}) :');
    for (final w in result.warnings) {
      stdout.writeln('  - $w');
    }
  }

  if (!result.isValid) {
    stderr.writeln('\n❌ ÉCHEC DE VALIDATION (${result.errors.length} erreur(s)) :');
    for (final err in result.errors) {
      stderr.writeln('  • ${err.context} : ${err.message}');
    }
    stderr.writeln('\nLe manifest contient des erreurs bloquantes. Corrigez-les avant livraison.');
    exit(1);
  }

  stdout.writeln('\n✅ VALIDATION RÉUSSIE AVEC SUCCÈS !');
  stdout.writeln('  • Lots contrôlés : ${result.validatedLotsCount}');
  stdout.writeln('  • Contenus audio validés : ${result.validatedItemsCount}');
  stdout.writeln('  • Fichiers audio, checksums SHA-256 et timestamps vérifiés.');
  stdout.writeln('  • Intégration des 10 phrases du lot confirmée.');
  stdout.writeln('======================================================\n');
  exit(0);
}
