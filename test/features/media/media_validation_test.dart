import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_lern_deutsch_mobile/domain/models/media_content.dart';
import 'package:app_lern_deutsch_mobile/features/media/data/media_repository.dart';
import 'package:app_lern_deutsch_mobile/features/media/domain/media_manifest_validator.dart';

void main() {
  group('Modèle de données MediaContent', () {
    test('MediaLicenseStatus et MediaType désérialisent correctement', () {
      expect(MediaLicenseStatus.fromString('approuve'), MediaLicenseStatus.approuve);
      expect(MediaLicenseStatus.fromString('approuvé'), MediaLicenseStatus.approuve);
      expect(MediaLicenseStatus.fromString('retire'), MediaLicenseStatus.retire);
      expect(MediaLicenseStatus.fromString('en_attente'), MediaLicenseStatus.enAttente);
      expect(MediaLicenseStatus.fromString(null), MediaLicenseStatus.enAttente);

      expect(MediaLicenseStatus.approuve.isApproved, isTrue);
      expect(MediaLicenseStatus.enAttente.isApproved, isFalse);
      expect(MediaLicenseStatus.retire.isApproved, isFalse);

      expect(MediaType.fromString('dialogue'), MediaType.dialogue);
      expect(MediaType.fromString('chanson'), MediaType.chanson);
      expect(MediaType.fromString('song'), MediaType.chanson);
    });

    test('MediaItem toJson et fromJson préservent tous les champs', () {
      final item = MediaItem(
        lotId: 1,
        type: MediaType.dialogue,
        audioFile: 'lot_001_dialogue.mp3',
        audioSlowFile: 'lot_001_dialogue_slow.mp3',
        contentJsonFile: 'lot_001_dialogue.json',
        durationSeconds: 28,
        sizeBytes: 446607,
        checksum: '2899af6c257cd4f6c5926193e90cc9331149842e53b72efc185d1d7c935c0fea',
        checksumSlow: '9045b13689d07beeaa0a3c529f7322d7d781b520b53c7395164f625eb614c6c3',
        version: 1,
        statutLicence: MediaLicenseStatus.approuve,
        source: 'synthese_vocale',
        createdAt: '2026-11-01T12:00:00Z',
        titleDe: 'Zufälliges Treffen',
        titleAr: 'لقاء بالصدفة',
        titleFr: 'Rencontre fortuite',
      );

      final json = item.toJson();
      final reconstructed = MediaItem.fromJson(json);

      expect(reconstructed.lotId, 1);
      expect(reconstructed.type, MediaType.dialogue);
      expect(reconstructed.audioFile, 'lot_001_dialogue.mp3');
      expect(reconstructed.audioSlowFile, 'lot_001_dialogue_slow.mp3');
      expect(reconstructed.isApproved, isTrue);
      expect(reconstructed.checksum, item.checksum);
      expect(reconstructed.titleDe, 'Zufälliges Treffen');
      expect(reconstructed.titleAr, 'لقاء بالصدفة');
      expect(reconstructed.titleFr, 'Rencontre fortuite');
    });

    test('MediaManifest filtre les contenus non approuvés via approvedContents', () {
      final manifest = MediaManifest(
        version: 1,
        updatedAt: '2026-11-01',
        contents: [
          MediaItem(
            lotId: 1,
            type: MediaType.dialogue,
            audioFile: 'lot_001_dialogue.mp3',
            contentJsonFile: 'lot_001_dialogue.json',
            durationSeconds: 28,
            sizeBytes: 100,
            checksum: 'abc',
            version: 1,
            statutLicence: MediaLicenseStatus.approuve,
            source: 'test',
            createdAt: '2026-11-01',
          ),
          MediaItem(
            lotId: 2,
            type: MediaType.chanson,
            audioFile: 'lot_002_chanson.mp3',
            contentJsonFile: 'lot_002_chanson.json',
            durationSeconds: 30,
            sizeBytes: 200,
            checksum: 'def',
            version: 1,
            statutLicence: MediaLicenseStatus.retire,
            source: 'test',
            createdAt: '2026-11-01',
          ),
          MediaItem(
            lotId: 3,
            type: MediaType.dialogue,
            audioFile: 'lot_003_dialogue.mp3',
            contentJsonFile: 'lot_003_dialogue.json',
            durationSeconds: 25,
            sizeBytes: 150,
            checksum: 'ghi',
            version: 1,
            statutLicence: MediaLicenseStatus.enAttente,
            source: 'test',
            createdAt: '2026-11-01',
          ),
        ],
      );

      final approved = manifest.approvedContents;
      expect(approved.length, 1);
      expect(approved.first.lotId, 1);
      expect(approved.first.isApproved, isTrue);
    });

    test('TranscriptLine et MediaTranscript gèrent les phrases référencées', () {
      final lineWithPhrase = TranscriptLine(
        locuteur: 'Conrad',
        de: 'Na, wie läuft\'s?',
        ar: 'طيب، كيف الأحوال؟',
        fr: 'Alors, comment ça roule ?',
        debutMs: 0,
        finMs: 2500,
        phraseId: 'phrase_001',
      );

      final lineWithoutPhrase = TranscriptLine(
        locuteur: 'Katja',
        de: 'Alles klar!',
        ar: 'تمام!',
        fr: 'Tout va bien !',
        debutMs: 2700,
        finMs: 4000,
      );

      expect(lineWithPhrase.hasPhraseLink, isTrue);
      expect(lineWithPhrase.phraseId, 'phrase_001');
      expect(lineWithoutPhrase.hasPhraseLink, isFalse);

      final transcript = MediaTranscript(
        lotId: 1,
        type: MediaType.dialogue,
        titleDe: 'Treffen',
        titleAr: 'لقاء',
        titleFr: 'Rencontre',
        lignes: [lineWithPhrase, lineWithoutPhrase],
      );

      expect(transcript.referencedPhraseIds, contains('phrase_001'));
      expect(transcript.referencedPhraseIds.length, 1);
    });
  });

  group('MediaRepository & Checksums', () {
    test('verifyChecksum valide correctement le SHA-256', () {
      final sampleBytes = utf8.encode('Hoppla test audio sample');
      const expectedChecksum = 'af5d501c735288d18ff9219d1afd2dce5ac05d66be7b046cc2d4346cb9f5e75c';

      expect(MediaRepository.verifyChecksum(sampleBytes, expectedChecksum), isTrue);
      expect(MediaRepository.verifyChecksum(sampleBytes, 'wrong_checksum'), isFalse);
    });
  });

  group('MediaManifestValidator', () {
    test('Le Lot 1 fourni valide tous les critères avec succès', () async {
      final validator = MediaManifestValidator(baseDir: '.');
      final result = await validator.validate();

      expect(result.isValid, isTrue, reason: result.errors.join('\n'));
      expect(result.errors, isEmpty);
      expect(result.validatedLotsCount, greaterThanOrEqualTo(1));
      expect(result.validatedItemsCount, greaterThanOrEqualTo(2));
    });

    test('MediaManifestValidator échoue si le manifest est inexistant', () async {
      final validator = MediaManifestValidator(baseDir: './inexistant_folder_xyz');
      final result = await validator.validate();

      expect(result.isValid, isFalse);
      expect(result.errors.any((e) => e.context == 'Manifest'), isTrue);
    });
  });
}
