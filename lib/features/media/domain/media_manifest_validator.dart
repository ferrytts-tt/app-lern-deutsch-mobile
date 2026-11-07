import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import '../../../domain/models/media_content.dart';

class ValidationError {
  final String context;
  final String message;

  const ValidationError(this.context, this.message);

  @override
  String toString() => '[$context] $message';
}

class ValidationResult {
  final bool isValid;
  final List<ValidationError> errors;
  final List<String> warnings;
  final int validatedLotsCount;
  final int validatedItemsCount;

  const ValidationResult({
    required this.isValid,
    required this.errors,
    required this.warnings,
    required this.validatedLotsCount,
    required this.validatedItemsCount,
  });
}

/// Validateur d'intégrité pour le manifest, les fichiers audio,
/// les transcriptions synchronisées et la présence des phrases du catalogue.
class MediaManifestValidator {
  final String baseDir;
  final String? phrasesJsonPath;

  MediaManifestValidator({
    this.baseDir = '.',
    this.phrasesJsonPath,
  });

  /// Exécute tous les contrôles d'intégrité requis
  Future<ValidationResult> validate() async {
    final errors = <ValidationError>[];
    final warnings = <String>[];

    // 1. Charger et parser le catalogue des phrases pour connaître les 10 phrases de chaque lot
    final phrasesCatalogPath = phrasesJsonPath ?? '$baseDir/assets/data/phrases.json';
    final lotPhrasesMap = <int, Set<String>>{};

    final catalogFile = File(phrasesCatalogPath);
    if (!catalogFile.existsSync()) {
      errors.add(ValidationError('Catalogue', 'Fichier catalogue introuvable : $phrasesCatalogPath'));
    } else {
      try {
        final catalogRaw = jsonDecode(catalogFile.readAsStringSync()) as List;
        for (int i = 0; i < catalogRaw.length; i++) {
          final p = catalogRaw[i] as Map<String, dynamic>;
          final pid = p['id'] as String? ?? 'phrase_${(i + 1).toString().padLeft(3, '0')}';
          final lotNumber = (i ~/ 10) + 1; // 10 phrases par lot
          lotPhrasesMap.putIfAbsent(lotNumber, () => <String>{}).add(pid);
        }
      } catch (e) {
        errors.add(ValidationError('Catalogue', 'Erreur de décodage JSON du catalogue : $e'));
      }
    }

    // 2. Charger le manifest
    final manifestPath = '$baseDir/assets/media/manifest.json';
    final manifestFile = File(manifestPath);
    if (!manifestFile.existsSync()) {
      errors.add(ValidationError('Manifest', 'manifest.json introuvable : $manifestPath'));
      return ValidationResult(
        isValid: false,
        errors: errors,
        warnings: warnings,
        validatedLotsCount: 0,
        validatedItemsCount: 0,
      );
    }

    MediaManifest manifest;
    try {
      final decoded = jsonDecode(manifestFile.readAsStringSync()) as Map<String, dynamic>;
      manifest = MediaManifest.fromJson(decoded);
    } catch (e) {
      errors.add(ValidationError('Manifest', 'Erreur de syntaxe JSON dans manifest.json : $e'));
      return ValidationResult(
        isValid: false,
        errors: errors,
        warnings: warnings,
        validatedLotsCount: 0,
        validatedItemsCount: 0,
      );
    }

    if (manifest.contents.isEmpty) {
      errors.add(const ValidationError('Manifest', 'Le manifest ne contient aucun élément'));
    }

    final lotsEncountered = <int>{};
    int itemsCount = 0;

    // 3. Valider chaque item du manifest
    for (final item in manifest.contents) {
      itemsCount++;
      lotsEncountered.add(item.lotId);
      final itemContext = 'Lot ${item.lotId} - ${item.type.value}';

      // Vérifier le statut de licence
      if (!item.statutLicence.isApproved) {
        warnings.add('$itemContext : Statut de licence non approuvé (${item.statutLicence.value}). Ce contenu sera masqué dans l\'application.');
      }

      // Vérifier existence du fichier audio principal
      final audioFilePath = '$baseDir/assets/media/audio/${item.audioFile}';
      final audioFile = File(audioFilePath);
      if (!audioFile.existsSync()) {
        errors.add(ValidationError(itemContext, 'Fichier audio principal introuvable : $audioFilePath'));
      } else {
        // Vérifier checksum audio
        final bytes = audioFile.readAsBytesSync();
        final actualSha256 = sha256.convert(bytes).toString().toLowerCase();
        if (actualSha256 != item.checksum.toLowerCase().trim()) {
          errors.add(ValidationError(
            itemContext,
            'Checksum SHA-256 invalide pour ${item.audioFile}.\n  Attendu : ${item.checksum}\n  Calculé : $actualSha256',
          ));
        }
      }

      // Vérifier fichier audio lent (si dialogue)
      if (item.audioSlowFile != null && item.audioSlowFile!.isNotEmpty) {
        final slowFilePath = '$baseDir/assets/media/audio/${item.audioSlowFile}';
        final slowFile = File(slowFilePath);
        if (!slowFile.existsSync()) {
          errors.add(ValidationError(itemContext, 'Fichier audio lent introuvable : $slowFilePath'));
        } else if (item.checksumSlow != null && item.checksumSlow!.isNotEmpty) {
          final slowBytes = slowFile.readAsBytesSync();
          final actualSlowSha256 = sha256.convert(slowBytes).toString().toLowerCase();
          if (actualSlowSha256 != item.checksumSlow!.toLowerCase().trim()) {
            errors.add(ValidationError(
              itemContext,
              'Checksum SHA-256 lent invalide pour ${item.audioSlowFile}.\n  Attendu : ${item.checksumSlow}\n  Calculé : $actualSlowSha256',
            ));
          }
        }
      }

      // Vérifier existence et contenu du fichier JSON de transcription
      final transcriptPath = '$baseDir/assets/media/${item.contentJsonFile}';
      final transcriptFile = File(transcriptPath);
      if (!transcriptFile.existsSync()) {
        errors.add(ValidationError(itemContext, 'Fichier de transcription introuvable : $transcriptPath'));
        continue;
      }

      MediaTranscript transcript;
      try {
        final transcriptRaw = jsonDecode(transcriptFile.readAsStringSync()) as Map<String, dynamic>;
        transcript = MediaTranscript.fromJson(transcriptRaw);
      } catch (e) {
        errors.add(ValidationError(itemContext, 'Erreur de syntaxe JSON dans $transcriptPath : $e'));
        continue;
      }

      // Vérifier les 3 titres du contenu
      if (transcript.titleDe.trim().isEmpty) {
        errors.add(ValidationError(itemContext, 'Le titre en allemand (title_de) est vide'));
      }
      if (transcript.titleAr.trim().isEmpty) {
        errors.add(ValidationError(itemContext, 'Le titre en arabe (title_ar) est vide'));
      }
      if (transcript.titleFr.trim().isEmpty) {
        errors.add(ValidationError(itemContext, 'Le titre en français (title_fr) est vide'));
      }

      if (transcript.lignes.isEmpty) {
        errors.add(ValidationError(itemContext, 'La transcription ne contient aucune ligne'));
        continue;
      }

      // Vérifier chaque ligne de transcription
      int previousDebut = -1;
      final foundPhraseIds = <String>{};

      for (int i = 0; i < transcript.lignes.length; i++) {
        final line = transcript.lignes[i];
        final lineRef = '$itemContext - Ligne ${i + 1}';

        // 3 langues obligatoires par ligne
        if (line.de.trim().isEmpty) {
          errors.add(ValidationError(lineRef, 'Texte allemand (de) vide'));
        }
        if (line.ar.trim().isEmpty) {
          errors.add(ValidationError(lineRef, 'Texte arabe (ar) vide'));
        }
        if (line.fr.trim().isEmpty) {
          errors.add(ValidationError(lineRef, 'Texte français (fr) vide'));
        }

        // Locuteur non vide
        if (line.locuteur.trim().isEmpty) {
          errors.add(ValidationError(lineRef, 'Locuteur non spécifié'));
        }

        // Timestamps croissants et valides
        if (line.finMs <= line.debutMs) {
          errors.add(ValidationError(lineRef, 'fin_ms (${line.finMs}) doit être strictement supérieur à debut_ms (${line.debutMs})'));
        }
        if (line.debutMs < previousDebut) {
          errors.add(ValidationError(lineRef, 'debut_ms (${line.debutMs}) est inférieur à la ligne précédente ($previousDebut)'));
        }
        previousDebut = line.debutMs;

        // Enregistrer la phrase du lot si référencée
        if (line.hasPhraseLink) {
          foundPhraseIds.add(line.phraseId!);
        }
      }

      // Si c'est un DIALOGUE : Les 10 phrases du lot doivent OBLIGATOIREMENT être présentes !
      if (item.type == MediaType.dialogue) {
        final expectedLotPhrases = lotPhrasesMap[item.lotId];
        if (expectedLotPhrases != null && expectedLotPhrases.isNotEmpty) {
          final missing = expectedLotPhrases.difference(foundPhraseIds);
          if (missing.isNotEmpty) {
            errors.add(ValidationError(
              itemContext,
              'Les 10 phrases du lot doivent obligatoirement apparaître dans le dialogue.\n'
              '  Phrases manquantes (${missing.length}) : ${missing.join(', ')}',
            ));
          }
        }
      }
    }

    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
      validatedLotsCount: lotsEncountered.length,
      validatedItemsCount: itemsCount,
    );
  }
}
