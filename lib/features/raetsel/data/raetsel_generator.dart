import 'dart:math';
import '../../../domain/models/phrase.dart';
import '../domain/models/raetsel_level.dart';
import '../domain/raetsel_constants.dart';
import 'raetsel_definitions.dart';

class RaetselGenerator {
  /// Stopwords allemands à ignorer lors de l'extraction des mots-clés
  static const Set<String> _stopWords = {
    'ICH', 'DU', 'ER', 'SIE', 'ES', 'WIR', 'IHR',
    'DER', 'DIE', 'DAS', 'DEN', 'DEM', 'DES',
    'EIN', 'EINE', 'EINEM', 'EINEN', 'EINER', 'EINES',
    'UND', 'ODER', 'ABER', 'DENN', 'DOCH', 'WIE',
    'IN', 'AN', 'AUF', 'AUS', 'BEI', 'MIT', 'NACH', 'VON', 'ZU',
    'IM', 'AM', 'VOM', 'ZUM', 'ZUR', 'BEIM',
    'IST', 'SIND', 'WAR', 'BIN', 'BIST',
  };

  /// Caractères autorisés dans les mots allemands
  static final RegExp _germanLetterRegex = RegExp(r'^[A-ZÄÖÜß]+$');

  /// Nettoie et met en majuscules une chaîne
  static String normalizeGerman(String input) {
    return input
        .toUpperCase()
        .replaceAll('’', "'")
        .replaceAll('`', "'");
  }

  /// Détecte si un caractère est une lettre allemande
  static bool isGermanLetter(String char) {
    if (char.length != 1) return false;
    final upper = char.toUpperCase();
    final code = upper.codeUnitAt(0);
    // A-Z
    if (code >= 65 && code <= 90) return true;
    // Ä, Ö, Ü, ß
    if (upper == 'Ä' || upper == 'Ö' || upper == 'Ü' || upper == 'ß') return true;
    return false;
  }

  /// Extrait des candidats de mots-clés (de 3 à 12 lettres) depuis une phrase
  static List<String> extractKeywordsFromPhrase(Phrase phrase) {
    final candidates = <String>[];
    final text = phrase.deParle.isNotEmpty ? phrase.deParle : phrase.de;
    final words = text.split(RegExp(r'[\s,.;:!?\-"\(\)]+'));

    for (final raw in words) {
      final clean = normalizeGerman(raw.replaceAll(RegExp(r"[^a-zA-ZäöüÄÖÜß]"), ''));
      if (clean.length >= 3 && clean.length <= 12 && !_stopWords.contains(clean)) {
        if (!candidates.contains(clean) && _germanLetterRegex.hasMatch(clean)) {
          candidates.add(clean);
        }
      }
    }

    // Trie d'abord ceux qui ont une définition riche dans RaetselDefinitions, puis par longueur
    candidates.sort((a, b) {
      final hasDefA = RaetselDefinitions.getDefinition(a) != null ? 1 : 0;
      final hasDefB = RaetselDefinitions.getDefinition(b) != null ? 1 : 0;
      if (hasDefA != hasDefB) return hasDefB.compareTo(hasDefA);
      return b.length.compareTo(a.length);
    });

    return candidates;
  }

  /// Génère un niveau Crostic de manière 100% déterministe
  static RaetselLevel generateLevel({
    required int levelNumber,
    required List<Phrase> availablePhrases,
    int? customSeed,
    Map<String, dynamic>? handcraftedIndices,
  }) {
    if (availablePhrases.isEmpty) {
      throw ArgumentError('La liste des phrases disponibles ne peut pas être vide.');
    }

    final seed = customSeed ?? (levelNumber * 10007 + 7331);
    final random = Random(seed);

    // Détermination de la difficulté et du nombre de mots selon le palier (Tier)
    final tier = RaetselConstants.getTierForLevel(levelNumber);
    final int targetWordCount = tier.wordCount;

    // Mélange déterministe des phrases du pool
    final shuffledPhrases = List<Phrase>.from(availablePhrases)..shuffle(random);

    // 1. Choix de la phrase secrète (de préférence entre 10 et 45 caractères alphabétiques)
    Phrase secretPhrase = shuffledPhrases.first;
    for (final p in shuffledPhrases) {
      final text = p.deParle.isNotEmpty ? p.deParle : p.de;
      final letterCount = text.split('').where((c) => isGermanLetter(c)).length;
      if (letterCount >= 10 && letterCount <= 45 && (p.note != null && p.note!.isNotEmpty)) {
        secretPhrase = p;
        break;
      }
    }

    // Pool restant pour les indices (excluant la phrase secrète)
    final cluePool = shuffledPhrases.where((p) => p.id != secretPhrase.id).toList();

    // 2. Sélection des mots d'indices
    final selectedClueWords = <RaetselClueWord>[];
    final usedWords = <String>{};

    for (final p in cluePool) {
      if (selectedClueWords.length >= targetWordCount) break;

      final candidates = extractKeywordsFromPhrase(p);
      if (candidates.isEmpty) continue;

      String? chosenWord;
      for (final w in candidates) {
        if (!usedWords.contains(w)) {
          chosenWord = w;
          break;
        }
      }

      if (chosenWord == null) continue;
      usedWords.add(chosenWord);

      // Détermination du type d'indice selon le niveau
      final String clueType;
      if (levelNumber <= 15) {
        clueType = 'definition'; // Vraie question / définition de mot croisé
      } else {
        // À partir du niveau 16, alternance avec énigmes d'écoute audio
        clueType = (selectedClueWords.length % 3 == 2) ? 'audio' : 'definition';
      }

      // Construction de la vraie définition / question (type mot croisé comme dans Crostic)
      String clueDe;
      String clueFr;
      String clueAr;
      String computedType = clueType;

      // 1. Vérifie si un indice fait-main est fourni dans handcraftedIndices
      if (handcraftedIndices != null && handcraftedIndices.containsKey(chosenWord)) {
        final entry = handcraftedIndices[chosenWord] as Map<String, dynamic>;
        clueDe = entry['de']?.toString() ?? entry['fr']?.toString() ?? '';
        clueFr = entry['fr']?.toString() ?? '';
        clueAr = entry['ar']?.toString() ?? clueFr;
        if (entry.containsKey('type')) computedType = entry['type'].toString();
      } else {
        // 2. Utilisation du dictionnaire de définitions de mots croisés
        final defs = RaetselDefinitions.generateDefinitionForWord(
          word: chosenWord,
          phraseFr: p.fr,
          phraseAr: p.ar,
          phraseDe: p.deParle.isNotEmpty ? p.deParle : p.de,
          note: p.note,
        );
        clueDe = defs['de']!;
        clueFr = defs['fr']!;
        clueAr = defs['ar']!;
        if (defs.containsKey('type') && clueType != 'audio') {
          computedType = defs['type']!;
        }
      }

      if (clueType == 'audio') {
        clueDe = 'Höre den Satz und finde dieses Wort';
        clueFr = 'Écoute la phrase et trouve ce mot : « ${p.fr} »';
        clueAr = 'استمع إلى التسجيل الصوتي واعثر على هذه الكلمة : « ${p.ar ?? p.fr} »';
      }

      final phraseTextDe = p.deParle.isNotEmpty ? p.deParle : p.de;

      selectedClueWords.add(
        RaetselClueWord(
          phraseId: p.id,
          word: chosenWord,
          clueType: computedType,
          clueQuestionDe: clueDe,
          clueQuestionFr: clueFr,
          clueQuestionAr: clueAr,
          fullPhraseDe: phraseTextDe,
          fullPhraseFr: p.fr,
          fullPhraseAr: p.ar ?? '',
          note: p.note ?? '',
          letterNumbers: const [], // Sera peuplé ci-dessous
        ),
      );
    }

    // 3. Attribution cohérente des numéros aux lettres (Alphabet Crostic)
    final numberToLetterMap = <int, String>{};
    final letterToNumberMap = <String, int>{};

    final secretText = secretPhrase.deParle.isNotEmpty ? secretPhrase.deParle : secretPhrase.de;
    int nextNumber = 1;

    for (final char in secretText.split('')) {
      if (isGermanLetter(char)) {
        final upper = char.toUpperCase();
        if (!letterToNumberMap.containsKey(upper)) {
          letterToNumberMap[upper] = nextNumber;
          numberToLetterMap[nextNumber] = upper;
          nextNumber++;
        }
      }
    }

    for (final clue in selectedClueWords) {
      for (final char in clue.word.split('')) {
        if (isGermanLetter(char)) {
          final upper = char.toUpperCase();
          if (!letterToNumberMap.containsKey(upper)) {
            letterToNumberMap[upper] = nextNumber;
            numberToLetterMap[nextNumber] = upper;
            nextNumber++;
          }
        }
      }
    }

    // 4. Construction de la phrase secrète découpée en mots avec numéros
    final secretWords = <RaetselSecretWord>[];
    final rawWordsList = secretText.split(' ');

    for (final rw in rawWordsList) {
      final chars = <RaetselSecretChar>[];
      for (final ch in rw.split('')) {
        final isLetter = isGermanLetter(ch);
        chars.add(
          RaetselSecretChar(
            char: ch.toUpperCase(),
            isLetter: isLetter,
            letterNumber: isLetter ? letterToNumberMap[ch.toUpperCase()] : null,
          ),
        );
      }
      secretWords.add(RaetselSecretWord(rawWord: rw, chars: chars));
    }

    // 5. Finalisation des mots d'indices avec leurs numéros de lettres
    final finalizedClues = <RaetselClueWord>[];
    for (final clue in selectedClueWords) {
      final numbers = clue.word.split('').map((c) => letterToNumberMap[c.toUpperCase()]!).toList();
      finalizedClues.add(
        RaetselClueWord(
          phraseId: clue.phraseId,
          word: clue.word,
          clueType: clue.clueType,
          clueQuestionDe: clue.clueQuestionDe,
          clueQuestionFr: clue.clueQuestionFr,
          clueQuestionAr: clue.clueQuestionAr,
          fullPhraseDe: clue.fullPhraseDe,
          fullPhraseFr: clue.fullPhraseFr,
          fullPhraseAr: clue.fullPhraseAr,
          note: clue.note,
          letterNumbers: numbers,
        ),
      );
    }

    // Sélection déterministe du « Mot d'Or » (Gold-Wort) dans ce niveau
    final int goldWordIndex = finalizedClues.isNotEmpty ? random.nextInt(finalizedClues.length) : -1;
    final finalizedWithGold = <RaetselClueWord>[];
    for (int i = 0; i < finalizedClues.length; i++) {
      final clue = finalizedClues[i];
      finalizedWithGold.add(
        RaetselClueWord(
          phraseId: clue.phraseId,
          word: clue.word,
          clueType: clue.clueType,
          clueQuestionDe: clue.clueQuestionDe,
          clueQuestionFr: clue.clueQuestionFr,
          clueQuestionAr: clue.clueQuestionAr,
          fullPhraseDe: clue.fullPhraseDe,
          fullPhraseFr: clue.fullPhraseFr,
          fullPhraseAr: clue.fullPhraseAr,
          note: clue.note,
          letterNumbers: clue.letterNumbers,
          isGoldWord: (i == goldWordIndex),
        ),
      );
    }

    return RaetselLevel(
      id: levelNumber,
      levelNumber: levelNumber,
      seed: seed,
      secretPhraseId: secretPhrase.id,
      secretPhraseDe: secretText,
      secretPhraseFr: secretPhrase.fr,
      secretPhraseAr: secretPhrase.ar ?? '',
      secretPhraseNote: secretPhrase.note ?? '',
      secretWords: secretWords,
      clues: finalizedWithGold,
      numberToLetterMap: numberToLetterMap,
    );
  }
}
