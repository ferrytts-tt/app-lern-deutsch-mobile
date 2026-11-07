import '../../data/raetsel_definitions.dart';

/// Représente un mot d'indice dans une grille Hoppla Rätsel (style Crostic)
class RaetselClueWord {
  final String phraseId;
  final String word; // Mot en majuscules (ex: "HAST", "MENSCH")
  final String clueType; // 'definition', 'gegenteil', 'synonym', 'audio'
  final String clueQuestionDe; // Définition / question en allemand (ex: "Gegenteil von spät")
  final String clueQuestionFr; // Ex: "Le contraire de tôt"
  final String clueQuestionAr; // Ex: "عكس متأخر"
  final String fullPhraseDe; // Phrase allemande complète
  final String fullPhraseFr; // Traduction française
  final String fullPhraseAr; // Traduction arabe
  final String note; // Fait intéressant / note pédagogique
  final List<int> letterNumbers; // Numéro attribué à chaque lettre du mot (ex: [7, 9, 4, 11])
  final bool isGoldWord; // Mot d'or bonus donnant XP et diamant supplémentaires

  const RaetselClueWord({
    required this.phraseId,
    required this.word,
    required this.clueType,
    this.clueQuestionDe = '',
    required this.clueQuestionFr,
    required this.clueQuestionAr,
    required this.fullPhraseDe,
    required this.fullPhraseFr,
    required this.fullPhraseAr,
    required this.note,
    required this.letterNumbers,
    this.isGoldWord = false,
  });

  Map<String, dynamic> toJson() => {
    'phrase_id': phraseId,
    'word': word,
    'clue_type': clueType,
    'clue_question_de': clueQuestionDe,
    'clue_question_fr': clueQuestionFr,
    'clue_question_ar': clueQuestionAr,
    'full_phrase_de': fullPhraseDe,
    'full_phrase_fr': fullPhraseFr,
    'full_phrase_ar': fullPhraseAr,
    'note': note,
    'letter_numbers': letterNumbers,
    'is_gold_word': isGoldWord,
  };

  factory RaetselClueWord.fromJson(Map<String, dynamic> json) {
    final word = json['word'] as String;
    final fr = json['clue_question_fr'] as String? ?? '';
    final ar = json['clue_question_ar'] as String? ?? '';
    final de = json['clue_question_de'] as String?;
    final fullDe = json['full_phrase_de'] as String? ?? '';
    final note = json['note'] as String? ?? '';
    final isGold = json['is_gold_word'] as bool? ?? false;

    String resolvedDe = de ?? '';
    String resolvedType = json['clue_type'] as String? ?? 'definition';

    // Si la question allemande est absente, vide ou erronément égale au français (niveaux sauvés dans localStorage)
    if (resolvedDe.isEmpty || resolvedDe == fr) {
      final def = RaetselDefinitions.getDefinition(word);
      if (def != null && def['de'] != null) {
        resolvedDe = def['de']!;
        if (def['type'] != null) resolvedType = def['type']!;
      } else {
        final gen = RaetselDefinitions.generateDefinitionForWord(
          word: word,
          phraseFr: fr,
          phraseAr: ar,
          phraseDe: fullDe,
          note: note,
        );
        resolvedDe = gen['de'] ?? '';
        if (gen['type'] != null) resolvedType = gen['type']!;
      }
    }

    return RaetselClueWord(
      phraseId: json['phrase_id'] as String,
      word: word,
      clueType: resolvedType,
      clueQuestionDe: resolvedDe,
      clueQuestionFr: fr,
      clueQuestionAr: ar,
      fullPhraseDe: fullDe,
      fullPhraseFr: json['full_phrase_fr'] as String? ?? '',
      fullPhraseAr: json['full_phrase_ar'] as String? ?? '',
      note: note,
      letterNumbers: (json['letter_numbers'] as List<dynamic>).map((e) => e as int).toList(),
      isGoldWord: isGold,
    );
  }
}

/// Un élément (lettre ou ponctuation) de la phrase secrète en haut
class RaetselSecretChar {
  final String char; // Le caractère réel (ex: 'D', 'U', ',', ' ')
  final bool isLetter; // true si lettre à deviner, false si ponctuation/espace
  final int? letterNumber; // Numéro associé (ex: 7), null si ponctuation ou espace

  const RaetselSecretChar({
    required this.char,
    required this.isLetter,
    this.letterNumber,
  });

  Map<String, dynamic> toJson() => {
    'char': char,
    'is_letter': isLetter,
    'letter_number': letterNumber,
  };

  factory RaetselSecretChar.fromJson(Map<String, dynamic> json) => RaetselSecretChar(
    char: json['char'] as String,
    isLetter: json['is_letter'] as bool,
    letterNumber: json['letter_number'] as int?,
  );
}

/// Mot de la phrase secrète découpé pour l'affichage en blocs de mots en haut
class RaetselSecretWord {
  final String rawWord;
  final List<RaetselSecretChar> chars;

  const RaetselSecretWord({
    required this.rawWord,
    required this.chars,
  });

  Map<String, dynamic> toJson() => {
    'raw_word': rawWord,
    'chars': chars.map((c) => c.toJson()).toList(),
  };

  factory RaetselSecretWord.fromJson(Map<String, dynamic> json) => RaetselSecretWord(
    rawWord: json['raw_word'] as String,
    chars: (json['chars'] as List<dynamic>)
        .map((e) => RaetselSecretChar.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}

/// Représente un niveau complet de Hoppla Rätsel (style Crostic)
class RaetselLevel {
  final int id;
  final int levelNumber;
  final int seed;
  final String secretPhraseId;
  final String secretPhraseDe;
  final String secretPhraseFr;
  final String secretPhraseAr;
  final String secretPhraseNote;
  final List<RaetselSecretWord> secretWords;
  final List<RaetselClueWord> clues;
  final Map<int, String> numberToLetterMap;

  const RaetselLevel({
    required this.id,
    required this.levelNumber,
    required this.seed,
    required this.secretPhraseId,
    required this.secretPhraseDe,
    required this.secretPhraseFr,
    required this.secretPhraseAr,
    required this.secretPhraseNote,
    required this.secretWords,
    required this.clues,
    required this.numberToLetterMap,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'level_number': levelNumber,
    'seed': seed,
    'secret_phrase_id': secretPhraseId,
    'secret_phrase_de': secretPhraseDe,
    'secret_phrase_fr': secretPhraseFr,
    'secret_phrase_ar': secretPhraseAr,
    'secret_phrase_note': secretPhraseNote,
    'secret_words': secretWords.map((w) => w.toJson()).toList(),
    'clues': clues.map((c) => c.toJson()).toList(),
    'number_to_letter_map': numberToLetterMap.map((k, v) => MapEntry(k.toString(), v)),
  };

  factory RaetselLevel.fromJson(Map<String, dynamic> json) => RaetselLevel(
    id: json['id'] as int,
    levelNumber: json['level_number'] as int,
    seed: json['seed'] as int,
    secretPhraseId: json['secret_phrase_id'] as String,
    secretPhraseDe: json['secret_phrase_de'] as String,
    secretPhraseFr: json['secret_phrase_fr'] as String,
    secretPhraseAr: json['secret_phrase_ar'] as String,
    secretPhraseNote: json['secret_phrase_note'] as String? ?? '',
    secretWords: (json['secret_words'] as List<dynamic>)
        .map((e) => RaetselSecretWord.fromJson(e as Map<String, dynamic>))
        .toList(),
    clues: (json['clues'] as List<dynamic>)
        .map((e) => RaetselClueWord.fromJson(e as Map<String, dynamic>))
        .toList(),
    numberToLetterMap: (json['number_to_letter_map'] as Map<String, dynamic>).map(
      (k, v) => MapEntry(int.parse(k), v as String),
    ),
  );
}
