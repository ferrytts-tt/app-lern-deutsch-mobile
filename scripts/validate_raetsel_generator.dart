import 'dart:convert';
import 'dart:io';
import '../lib/domain/models/phrase.dart';
import '../lib/features/raetsel/data/raetsel_generator.dart';
import '../lib/features/raetsel/domain/models/raetsel_level.dart';

void main() {
  print('===========================================================');
  print('🧪 VALIDATION DU GÉNÉRATEUR HOPPLA RÄTSEL (STYLE CROSTIC)');
  print('===========================================================');

  // 1. Chargement des phrases depuis assets/data/phrases.json
  final phrasesFile = File('assets/data/phrases.json');
  if (!phrasesFile.existsSync()) {
    print('❌ Erreur : assets/data/phrases.json introuvable !');
    exit(1);
  }

  final rawJson = jsonDecode(phrasesFile.readAsStringSync()) as List<dynamic>;
  final allPhrases = rawJson.map((e) => Phrase.fromJson(e as Map<String, dynamic>)).toList();
  print('✅ Total phrases chargées : ${allPhrases.length}');

  // 2. Extraction des 30 phrases du Palier 1 (Lot 1, 2 et 3)
  final palier1Phrases = allPhrases.take(30).toList();
  print('✅ Phrases du Palier 1 pour les tests : ${palier1Phrases.length}');
  assert(palier1Phrases.length == 30);

  // 3. Génération et validation de 20 niveaux consécutifs
  final generatedLevels = <RaetselLevel>[];
  int totalPassed = 0;

  for (int lvl = 1; lvl <= 20; lvl++) {
    final level = RaetselGenerator.generateLevel(
      levelNumber: lvl,
      availablePhrases: palier1Phrases,
    );

    // Assertions de validation
    assert(level.levelNumber == lvl, 'Niveau incorrect');
    assert(level.secretPhraseDe.isNotEmpty, 'Phrase secrète vide');
    assert(level.secretWords.isNotEmpty, 'Aucun mot dans la phrase secrète');
    assert(level.clues.isNotEmpty, 'Aucun indice généré');

    // Vérification du nombre d'indices selon le niveau
    if (lvl <= 5) {
      assert(level.clues.length >= 6 && level.clues.length <= 10, 'Nb indices incorrect L1-5: ${level.clues.length}');
      assert(level.clues.every((c) => c.clueType == 'cloze'), 'Type indice incorrect L1-5');
    } else if (lvl <= 15) {
      assert(level.clues.length >= 8 && level.clues.length <= 12, 'Nb indices incorrect L6-15: ${level.clues.length}');
      final hasCloze = level.clues.any((c) => c.clueType == 'cloze');
      final hasTrans = level.clues.any((c) => c.clueType == 'translation');
      assert(hasCloze && hasTrans, 'Types indices incorrects L6-15');
    } else {
      assert(level.clues.length >= 8 && level.clues.length <= 12, 'Nb indices incorrect L16+: ${level.clues.length}');
      final hasAudio = level.clues.any((c) => c.clueType == 'audio');
      assert(hasAudio, 'Indice audio manquant L16+');
    }

    // Vérification de la cohérence mathématique des numéros de lettres
    // Règle Crostic : numberToLetterMap[num] == char partout
    for (final sw in level.secretWords) {
      for (final sc in sw.chars) {
        if (sc.isLetter) {
          assert(sc.letterNumber != null, 'Numéro manquant pour la lettre ${sc.char}');
          final mapped = level.numberToLetterMap[sc.letterNumber];
          assert(mapped == sc.char, 'Incohérence lettre secrète : ${sc.char} != $mapped');
        }
      }
    }

    for (final clue in level.clues) {
      assert(clue.letterNumbers.length == clue.word.length, 'Incohérence longueur numéros/mot dans ${clue.word}');
      for (int i = 0; i < clue.word.length; i++) {
        final ch = clue.word[i].toUpperCase();
        final num = clue.letterNumbers[i];
        final mapped = level.numberToLetterMap[num];
        assert(mapped == ch, 'Incohérence lettre indice : $ch != $mapped pour mot ${clue.word}');
      }
    }

    // Vérification de l'unicité des mots d'indices dans le même niveau
    final uniqueWords = level.clues.map((c) => c.word).toSet();
    assert(uniqueWords.length == level.clues.length, 'Mots en doublon détectés dans le niveau $lvl');

    // Test du déterminisme : même graine = niveau strictement identique
    final levelReproduction = RaetselGenerator.generateLevel(
      levelNumber: lvl,
      availablePhrases: palier1Phrases,
      customSeed: level.seed,
    );
    assert(
      jsonEncode(level.toJson()) == jsonEncode(levelReproduction.toJson()),
      'Erreur de déterminisme sur le niveau $lvl',
    );

    generatedLevels.add(level);
    totalPassed++;
  }

  print('✅ 20 / 20 niveaux générés et validés avec succès !');

  // Aperçu du Niveau 1
  final l1 = generatedLevels[0];
  print('\n--- EXEMPLE : NIVEAU 1 ---');
  print('Phrase secrète : "${l1.secretPhraseDe}" (${l1.secretPhraseFr})');
  print('Fact/Note : ${l1.secretPhraseNote}');
  print('Mots à trouver (${l1.clues.length}) :');
  for (int i = 0; i < l1.clues.length; i++) {
    final c = l1.clues[i];
    print('  ${i + 1}. [${c.clueType}] ${c.word} (${c.letterNumbers}) -> ${c.clueQuestionDe}');
  }

  // Aperçu du Niveau 6 (avec traduction)
  final l6 = generatedLevels[5];
  print('\n--- EXEMPLE : NIVEAU 6 (Multi-types cloze + traduction) ---');
  print('Phrase secrète : "${l6.secretPhraseDe}"');
  print('Indices (échantillon) :');
  for (final c in l6.clues.take(4)) {
    print('  - [${c.clueType}] ${c.word} -> ${c.clueQuestionDe}');
  }

  // Aperçu du Niveau 16 (avec audio)
  final l16 = generatedLevels[15];
  print('\n--- EXEMPLE : NIVEAU 16 (Avec indices audio) ---');
  print('Phrase secrète : "${l16.secretPhraseDe}"');
  print('Indices (échantillon) :');
  for (final c in l16.clues.take(4)) {
    print('  - [${c.clueType}] ${c.word} -> ${c.clueQuestionDe}');
  }

  // Sauvegarde des 20 grilles de test dans un fichier json de démonstration
  final exportFile = File('assets/data/raetsel_sample_20_levels.json');
  exportFile.writeAsStringSync(
    const JsonEncoder.withIndent('  ').convert(generatedLevels.map((l) => l.toJson()).toList()),
  );
  print('\n💾 20 niveaux de test enregistrés dans : ${exportFile.path}');
  print('\n🎉 ÉTAPE 1 COMPLÈTEMENT VALIDÉE !');
}
