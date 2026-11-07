import 'dart:math';
import '../../domain/engine/german_master_scenarios.dart';
import '../../domain/models/phrase.dart';
import '../../core/utils/german_verb_detector.dart';

enum PalierQuestionType {
  /// 1. QCM contextuel à 4 choix (Situation réelle en Allemagne)
  contextualQcm,

  /// 2. Système Duolingo : Recomposition de la phrase par blocs de mots 3D
  duolingoWordRebuild,

  /// 3. Phrase à trous multiples : Remplir 2 ou 3 vides dans la phrase
  multiBlankFill,

  /// 4. Compréhension Orale / Écoute Audio (Hörverstehen avec audio)
  audioListening,

  /// 5. Équivalence : Hochdeutsch (B2 standard) -> Allemand parlé réel
  standardToSpoken,

  /// 6. Mot manquant clé (Lückentext avec clavier ou micro)
  singleBlankFill,
}

/// Modèle d'une question de l'Examen de Palier.
class PalierExamQuestion {
  final int questionNumber; // 1 à 30
  final Phrase phrase;
  final PalierQuestionType type;
  final String titlePrompt;
  final String contextSituation;
  final String? blankPhrase; // ex: "Ich (1) [______] heute leider nicht (2) [______]."
  final List<String> expectedBlanks; // Pour multiBlankFill : ['kann', 'kommen']
  final List<String> blankBankOptions; // Banque d'options cliquables pour remplir les trous
  final List<String> wordBank; // Pour Duolingo blocs : mots cibles + distracteurs mélangés
  final String expectedAnswer; // la réponse attendue principale
  final List<String> alternativeAnswers; // variantes acceptées
  final List<String> qcmChoices; // pour le QCM / Audio / Standard->Parlé

  const PalierExamQuestion({
    required this.questionNumber,
    required this.phrase,
    required this.type,
    required this.titlePrompt,
    required this.contextSituation,
    this.blankPhrase,
    this.expectedBlanks = const [],
    this.blankBankOptions = const [],
    this.wordBank = const [],
    required this.expectedAnswer,
    this.alternativeAnswers = const [],
    this.qcmChoices = const [],
  });
}

/// Générateur pédagogique des 30 questions de l'examen de palier.
/// Propose 6 types d'exercices variés (exactement 5 questions de chaque type)
/// pour maintenir l'engagement et plonger le candidat dans les conditions réelles d'un examen B2.
class PalierExamGenerator {
  PalierExamGenerator._();

  /// Génère exactement 30 questions variées à partir de 30 phrases données.
  static List<PalierExamQuestion> generate30Questions({
    required List<Phrase> thirtyPhrases,
    required int palierIndex,
  }) {
    final questions = <PalierExamQuestion>[];
    final random = Random(palierIndex * 777);

    final shuffledPhrases = List<Phrase>.from(thirtyPhrases);
    shuffledPhrases.shuffle(random);

    for (int i = 0; i < shuffledPhrases.length; i++) {
      final phrase = shuffledPhrases[i];
      final qNum = i + 1;

      // Répartition cyclique équilibrée des 6 types d'exercices d'examen
      final typeIndex = i % 6;
      switch (typeIndex) {
        case 0:
          questions.add(_buildQcmQuestion(qNum, phrase, shuffledPhrases, random));
          break;
        case 1:
          questions.add(_buildDuolingoQuestion(qNum, phrase, random));
          break;
        case 2:
          questions.add(_buildMultiBlankQuestion(qNum, phrase, random));
          break;
        case 3:
          questions.add(_buildAudioQuestion(qNum, phrase, shuffledPhrases, random));
          break;
        case 4:
          questions.add(_buildStandardToSpokenQuestion(qNum, phrase, shuffledPhrases, random));
          break;
        case 5:
        default:
          questions.add(_buildSingleBlankQuestion(qNum, phrase));
          break;
      }
    }

    return questions;
  }

  /// ── Type 1 : QCM contextuel à 4 choix (Situation réelle) ───────────────────
  static PalierExamQuestion _buildQcmQuestion(
    int qNum,
    Phrase phrase,
    List<Phrase> allPhrases,
    Random random,
  ) {
    final scenario = GermanMasterScenariosCatalog.getScenarioFor(phrase);
    final otherPhrases = allPhrases.where((p) => p.id != phrase.id).toList()..shuffle(random);

    final choices = <String>[phrase.deParle];
    for (final other in otherPhrases) {
      if (!choices.contains(other.deParle) && other.deParle.isNotEmpty) {
        choices.add(other.deParle);
      }
      if (choices.length == 4) break;
    }

    while (choices.length < 4) {
      choices.add('Das weiß ich im Moment nicht.');
    }
    choices.shuffle(random);

    String situationText = scenario.situationGerman;
    if (situationText.isEmpty) {
      situationText = phrase.fr.isNotEmpty
          ? 'Situation : Tu veux exprimer « ${phrase.fr} ».\nQuelle expression allemande correspond exactement ?'
          : 'Quelle est la formulation allemande parlée authentique ?';
    } else {
      situationText = '$situationText\n(Sens : « ${phrase.fr} »)\nQuelle est la réaction naturelle en allemand ?';
    }

    return PalierExamQuestion(
      questionNumber: qNum,
      phrase: phrase,
      type: PalierQuestionType.contextualQcm,
      titlePrompt: '🎯 Situation réelle en Allemagne (QCM)',
      contextSituation: situationText,
      expectedAnswer: phrase.deParle,
      alternativeAnswers: [phrase.deParle],
      qcmChoices: choices,
    );
  }

  /// ── Type 2 : Système Duolingo (Recomposition par blocs de mots) ────────────
  static PalierExamQuestion _buildDuolingoQuestion(
    int qNum,
    Phrase phrase,
    Random random,
  ) {
    final rawTokens = phrase.deParle.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    final cleanWords = rawTokens.map(_cleanWord).where((w) => w.isNotEmpty).toList();

    const distractorPool = [
      'nicht', 'sehr', 'auch', 'und', 'aber', 'wir', 'sie', 'hier', 'jetzt',
      'immer', 'noch', 'gut', 'schon', 'wirklich', 'heute', 'doch', 'mal', 'halt'
    ];
    final lowerClean = cleanWords.map((w) => w.toLowerCase()).toSet();
    final filtered = distractorPool.where((d) => !lowerClean.contains(d)).toList()..shuffle(random);
    final distractors = filtered.take(3).toList();

    final bank = [...cleanWords, ...distractors]..shuffle(random);

    final prompt = phrase.fr.isNotEmpty
        ? 'Recompose la phrase allemande parlée correspondant à :\n« ${phrase.fr} »'
        : 'Recompose la phrase parlée naturelle :';

    return PalierExamQuestion(
      questionNumber: qNum,
      phrase: phrase,
      type: PalierQuestionType.duolingoWordRebuild,
      titlePrompt: '🧩 Recompose la phrase (Blocs de mots)',
      contextSituation: prompt,
      wordBank: bank,
      expectedAnswer: phrase.deParle,
      alternativeAnswers: [cleanWords.join(' '), phrase.deStandard],
    );
  }

  /// ── Type 3 : Phrase à plusieurs trous (2 à 3 vides) ───────────────────────
  static PalierExamQuestion _buildMultiBlankQuestion(
    int qNum,
    Phrase phrase,
    Random random,
  ) {
    final rawTokens = phrase.deParle.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    final numBlanks = rawTokens.length >= 6 ? 3 : (rawTokens.length >= 4 ? 2 : 1);

    final targetIndices = <int>[];
    if (numBlanks == 3) {
      targetIndices.add(1.clamp(0, rawTokens.length - 1));
      targetIndices.add((rawTokens.length ~/ 2).clamp(0, rawTokens.length - 1));
      targetIndices.add((rawTokens.length - 1).clamp(0, rawTokens.length - 1));
    } else if (numBlanks == 2) {
      targetIndices.add(1.clamp(0, rawTokens.length - 1));
      targetIndices.add((rawTokens.length - 1).clamp(0, rawTokens.length - 1));
    } else {
      targetIndices.add((rawTokens.length ~/ 2).clamp(0, rawTokens.length - 1));
    }

    final uniqueIndices = targetIndices.toSet().toList()..sort();
    final expectedBlanks = <String>[];
    final blankWords = List<String>.from(rawTokens);

    for (int k = 0; k < uniqueIndices.length; k++) {
      final idx = uniqueIndices[k];
      final rawWord = rawTokens[idx];
      final clean = _cleanWord(rawWord);
      final punc = _extractPunctuation(rawWord);
      expectedBlanks.add(clean);
      blankWords[idx] = '(${k + 1}) [______]$punc';
    }

    const distractorPool = [
      'nicht', 'doch', 'mal', 'schon', 'wirklich', 'heute', 'halt', 'gar', 'gerne',
      'aber', 'immer', 'eben', 'auch', 'sehr', 'etwas', 'ganz', 'gleich'
    ];
    final lowerExpected = expectedBlanks.map((e) => e.toLowerCase()).toSet();
    final filteredDistractors = distractorPool.where((d) => !lowerExpected.contains(d)).toList()..shuffle(random);
    final distractors = filteredDistractors.take(uniqueIndices.length == 3 ? 3 : 2).toList();

    final bank = [...expectedBlanks, ...distractors]..shuffle(random);

    return PalierExamQuestion(
      questionNumber: qNum,
      phrase: phrase,
      type: PalierQuestionType.multiBlankFill,
      titlePrompt: '✍️ Phrase à trous multiples (${expectedBlanks.length} vides)',
      contextSituation: phrase.fr.isNotEmpty
          ? 'Sens : « ${phrase.fr} »\nComplète les ${expectedBlanks.length} mots manquants dans l\'ordre :'
          : 'Complète les ${expectedBlanks.length} mots manquants dans l\'ordre :',
      blankPhrase: blankWords.join(' '),
      expectedBlanks: expectedBlanks,
      blankBankOptions: bank,
      expectedAnswer: expectedBlanks.join(' '),
      alternativeAnswers: [phrase.deParle, expectedBlanks.map((e) => e.toLowerCase()).join(' ')],
    );
  }

  /// ── Type 4 : Compréhension Orale / Écoute Audio (Hörverstehen) ─────────────
  static PalierExamQuestion _buildAudioQuestion(
    int qNum,
    Phrase phrase,
    List<Phrase> allPhrases,
    Random random,
  ) {
    final otherPhrases = allPhrases.where((p) => p.id != phrase.id).toList()..shuffle(random);
    final choices = <String>[phrase.deParle];

    // Distracteur standard si disponible et différent
    if (phrase.deStandard.isNotEmpty &&
        _cleanWord(phrase.deStandard).toLowerCase() != _cleanWord(phrase.deParle).toLowerCase()) {
      choices.add(phrase.deStandard);
    }

    for (final other in otherPhrases) {
      if (!choices.contains(other.deParle) && other.deParle.isNotEmpty) {
        choices.add(other.deParle);
      }
      if (choices.length == 4) break;
    }

    while (choices.length < 4) {
      choices.add('Ich habe leider keine Zeit.');
    }
    choices.shuffle(random);

    return PalierExamQuestion(
      questionNumber: qNum,
      phrase: phrase,
      type: PalierQuestionType.audioListening,
      titlePrompt: '🎧 Compréhension Orale (Hörverstehen)',
      contextSituation: 'Écoute attentivement la prononciation allemande et choisis la phrase exacte :',
      expectedAnswer: phrase.deParle,
      alternativeAnswers: [phrase.deParle],
      qcmChoices: choices,
    );
  }

  /// ── Type 5 : Hochdeutsch B2 -> Allemand parlé réel ────────────────────────
  static PalierExamQuestion _buildStandardToSpokenQuestion(
    int qNum,
    Phrase phrase,
    List<Phrase> allPhrases,
    Random random,
  ) {
    final standard = phrase.deStandard.isNotEmpty ? phrase.deStandard : phrase.de;
    final otherPhrases = allPhrases.where((p) => p.id != phrase.id).toList()..shuffle(random);

    final choices = <String>[phrase.deParle];
    for (final other in otherPhrases) {
      if (!choices.contains(other.deParle) && other.deParle.isNotEmpty) {
        choices.add(other.deParle);
      }
      if (choices.length == 4) break;
    }

    while (choices.length < 4) {
      choices.add('Das ist nicht so wichtig.');
    }
    choices.shuffle(random);

    final prompt = phrase.fr.isNotEmpty
        ? 'Forme standard (B2) : „$standard“\n(Sens : « ${phrase.fr} »)\n\nQuelle est la tournure parlée authentique (Umgangssprache) ?'
        : 'Forme standard (B2) : „$standard“\n\nQuelle est la tournure parlée authentique ?';

    return PalierExamQuestion(
      questionNumber: qNum,
      phrase: phrase,
      type: PalierQuestionType.standardToSpoken,
      titlePrompt: '🇩🇪 Du Standard (B2) au Parlé Authentique',
      contextSituation: prompt,
      expectedAnswer: phrase.deParle,
      alternativeAnswers: [phrase.deParle],
      qcmChoices: choices,
    );
  }

  /// ── Type 6 : Mot manquant clé (Clavier ou Voix) ────────────────────────────
  static PalierExamQuestion _buildSingleBlankQuestion(int qNum, Phrase phrase) {
    final words = phrase.deParle.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();

    String blankPhrase = phrase.deParle;
    String expectedWord = phrase.deParle;
    final alternatives = <String>[];

    if (words.length == 1) {
      blankPhrase = '______';
      expectedWord = _cleanWord(words.first);
    } else {
      int targetIdx = -1;
      for (int i = 0; i < words.length; i++) {
        final clean = _cleanWord(words[i]);
        if (GermanVerbDetector.isVerb(clean)) {
          targetIdx = i;
          break;
        }
      }

      if (targetIdx == -1) {
        int maxLen = 0;
        for (int i = 0; i < words.length; i++) {
          final clean = _cleanWord(words[i]);
          if (clean.length > maxLen) {
            maxLen = clean.length;
            targetIdx = i;
          }
        }
      }

      if (targetIdx == -1) targetIdx = words.length ~/ 2;

      final rawTarget = words[targetIdx];
      expectedWord = _cleanWord(rawTarget);
      final punc = _extractPunctuation(rawTarget);

      final blankWords = List<String>.from(words);
      blankWords[targetIdx] = '[ ______ ]$punc';
      blankPhrase = blankWords.join(' ');

      alternatives.add(phrase.deParle);
      alternatives.add(expectedWord.toLowerCase());
    }

    return PalierExamQuestion(
      questionNumber: qNum,
      phrase: phrase,
      type: PalierQuestionType.singleBlankFill,
      titlePrompt: '🎙️ Mot manquant clé (Clavier ou Voix)',
      contextSituation: phrase.fr.isNotEmpty
          ? 'Sens : « ${phrase.fr} »\nComplète le mot clé manquant :'
          : 'Complète le mot clé manquant :',
      blankPhrase: blankPhrase,
      expectedAnswer: expectedWord,
      alternativeAnswers: alternatives,
    );
  }

  static String _cleanWord(String word) {
    return word.replaceAll(RegExp(r'[^\p{L}\p{N}]', unicode: true), '').trim();
  }

  static String _extractPunctuation(String word) {
    final match = RegExp(r'[!?,;.:]+$').firstMatch(word);
    return match?.group(0) ?? '';
  }
}
