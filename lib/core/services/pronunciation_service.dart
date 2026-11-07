import 'dart:math';
import 'web_speech.dart';

/// Correspondance mot par mot pour l'évaluation de prononciation
class WordPronunciationMatch {
  final String word;
  final bool isMatched;

  const WordPronunciationMatch({
    required this.word,
    required this.isMatched,
  });
}

/// Résultat détaillé de l'évaluation de prononciation.
class PronunciationEvaluation {
  final bool isSuccess;
  final double score; // 0.0 à 1.0 (ex. 0.85 = 85%)
  final String spokenText;
  final String targetText;
  final String feedbackMessage;
  final List<WordPronunciationMatch> wordMatches;
  final List<String> missedWords;

  const PronunciationEvaluation({
    required this.isSuccess,
    required this.score,
    required this.spokenText,
    required this.targetText,
    required this.feedbackMessage,
    this.wordMatches = const [],
    this.missedWords = const [],
  });

  int get scorePercent => (score * 100).round().clamp(0, 100);
}

/// Service d'écoute micro, reconnaissance vocale et évaluation de la prononciation allemande.
class PronunciationService {
  static PronunciationService? _instance;

  PronunciationService._();

  static PronunciationService get instance {
    _instance ??= PronunciationService._();
    return _instance!;
  }

  bool get isSpeechRecognitionAvailable => WebSpeechPlatform.isSpeechRecognitionAvailable;

  /// Joue le son de validation (carillon montant joyeux).
  void playSuccessSound() {
    WebSpeechPlatform.playSuccessChime();
  }

  /// Joue le son d'échec (ton doux descendant).
  void playFailureSound() {
    WebSpeechPlatform.playFailureChime();
  }

  /// Démarre l'écoute et la reconnaissance vocale allemande (de-DE).
  bool startListening({
    required Function(String text, bool isFinal) onResult,
    required Function(String error) onError,
    required Function(String text) onEnd,
  }) {
    return WebSpeechPlatform.startGermanSpeechRecognition(
      onResult: onResult,
      onError: onError,
      onEnd: onEnd,
    );
  }

  /// Arrête la reconnaissance vocale.
  void stopListening() {
    WebSpeechPlatform.stopGermanSpeechRecognition();
  }

  /// Évalue la prononciation du candidat de manière rigoureuse et exigeante.
  PronunciationEvaluation evaluate({
    required String spoken,
    required String targetParle,
    String? targetStandard,
  }) {
    final cleanSpoken = _normalizeGermanText(spoken);
    final cleanParle = _normalizeGermanText(targetParle);
    final cleanStandard = targetStandard != null ? _normalizeGermanText(targetStandard) : null;

    if (cleanSpoken.isEmpty) {
      return PronunciationEvaluation(
        isSuccess: false,
        score: 0.0,
        spokenText: spoken,
        targetText: targetParle,
        feedbackMessage: "Aucune parole détectée. Clique sur le micro et prononce la phrase distinctement à voix haute.",
        wordMatches: const [],
        missedWords: const [],
      );
    }

    // Découpage en mots pour analyse détaillée
    final spokenWords = cleanSpoken.split(' ').where((w) => w.isNotEmpty).toList();
    final targetWords = cleanParle.split(' ').where((w) => w.isNotEmpty).toList();

    final List<WordPronunciationMatch> wordMatches = [];
    final List<String> missedWords = [];
    int matchedCount = 0;

    for (final tw in targetWords) {
      bool matched = false;
      for (final sw in spokenWords) {
        if (sw == tw || (_levenshteinDistance(sw, tw) <= 1 && tw.length >= 4)) {
          matched = true;
          break;
        }
      }
      wordMatches.add(WordPronunciationMatch(word: tw, isMatched: matched));
      if (matched) {
        matchedCount++;
      } else {
        missedWords.add(tw);
      }
    }

    final double wordRatio = targetWords.isNotEmpty ? matchedCount / targetWords.length : 0.0;

    // Calcul de similarité globale (forme parlée et standard)
    final scoreParle = _calculateSimilarity(cleanSpoken, cleanParle);
    final scoreStandard = cleanStandard != null ? _calculateSimilarity(cleanSpoken, cleanStandard) : 0.0;
    final bestScore = max(scoreParle, scoreStandard);

    // CRITÈRE SÉVÈRE DE VALIDATION :
    // - Score global minimum requis : 78 %
    // - Au moins 75 % des mots de la phrase doivent être correctement reconnus
    // - Pour les phrases courtes (<= 3 mots) : 100 % des mots requis
    final bool isSuccess;
    if (targetWords.length <= 3) {
      isSuccess = wordRatio >= 1.0 && bestScore >= 0.80;
    } else {
      isSuccess = bestScore >= 0.78 && wordRatio >= 0.75;
    }

    final String message;
    if (isSuccess) {
      if (bestScore >= 0.90) {
        message = "Excellente prononciation ! Allemand fluide et très bien articulé. 🎉";
      } else {
        message = "Bonne prononciation validée ! L'allemand est bien compris.";
      }
    } else {
      if (missedWords.isNotEmpty && missedWords.length <= 3) {
        message = "Prononciation insuffisante (${(bestScore * 100).round()}%). Articule bien : « ${missedWords.join(', ')} » et répète la phrase !";
      } else if (bestScore < 0.45) {
        message = "Non reconnu. Écoute le modèle audio (vitesse lente), puis répète chaque mot clairement.";
      } else {
        message = "Prononciation trop hésitante (${(bestScore * 100).round()}%). Il faut bien prononcer toute la phrase. Répète à nouveau !";
      }
    }

    return PronunciationEvaluation(
      isSuccess: isSuccess,
      score: bestScore,
      spokenText: spoken,
      targetText: targetParle,
      feedbackMessage: message,
      wordMatches: wordMatches,
      missedWords: missedWords,
    );
  }

  /// Nettoie et normalise le texte allemand pour la comparaison phonétique.
  String _normalizeGermanText(String text) {
    var s = text.toLowerCase().trim();

    // Supprimer la ponctuation et caractères spéciaux
    s = s.replaceAll(RegExp(r'[.,!?;:()\[\]"«»\-_/\\#*]'), ' ');

    // Normaliser les apostrophes
    s = s.replaceAll("'", '').replaceAll("’", '');

    // Remplacements des contractions usuelles de l'allemand parlé
    s = s.replaceAll(RegExp(r'\bhab\b'), 'habe');
    s = s.replaceAll(RegExp(r'\bmachs\b'), 'mach');
    s = s.replaceAll(RegExp(r'\bgehts\b'), 'geht');
    s = s.replaceAll(RegExp(r'\bgehn\b'), 'gehen');
    s = s.replaceAll(RegExp(r'\bhaste\b'), 'hast du');
    s = s.replaceAll(RegExp(r'\bkannste\b'), 'kannst du');
    s = s.replaceAll(RegExp(r'\bkommste\b'), 'kommst du');
    s = s.replaceAll(RegExp(r'\bnehm\b'), 'nehme');
    s = s.replaceAll(RegExp(r'\bis\b'), 'ist');
    s = s.replaceAll(RegExp(r'\bne\b'), 'eine');
    s = s.replaceAll(RegExp(r'\bnen\b'), 'einen');
    s = s.replaceAll(RegExp(r'\bnem\b'), 'einem');
    s = s.replaceAll(RegExp(r'\bmal\b'), 'einmal');
    s = s.replaceAll(RegExp(r'\bwas\b'), 'etwas');

    // Réduire les espaces multiples
    s = s.replaceAll(RegExp(r'\s+'), ' ').trim();
    return s;
  }

  /// Calcule la similarité globale combinant chevauchement de mots et distance de Levenshtein.
  double _calculateSimilarity(String s1, String s2) {
    if (s1 == s2) return 1.0;
    if (s1.isEmpty || s2.isEmpty) return 0.0;

    final words1 = s1.split(' ').where((w) => w.isNotEmpty).toList();
    final words2 = s2.split(' ').where((w) => w.isNotEmpty).toList();

    // 1. Chevauchement de mots
    int matchingWords = 0;
    final set2 = words2.toSet();
    for (final w in words1) {
      if (set2.contains(w)) {
        matchingWords++;
      } else {
        // Tolérance sur les mots proches (ex: pluriel ou déclinaison)
        for (final targetW in set2) {
          if (_levenshteinDistance(w, targetW) <= 1 && w.length >= 3) {
            matchingWords++;
            break;
          }
        }
      }
    }
    final wordOverlap = matchingWords / max(words1.length, words2.length);

    // 2. Similarité de Levenshtein sur la chaîne entière
    final levDist = _levenshteinDistance(s1, s2);
    final maxLen = max(s1.length, s2.length);
    final levSimilarity = 1.0 - (levDist / maxLen);

    // Combiner les deux métriques
    return (wordOverlap * 0.6 + levSimilarity * 0.4).clamp(0.0, 1.0);
  }

  int _levenshteinDistance(String a, String b) {
    if (a == b) return 0;
    if (a.isEmpty) return b.length;
    if (b.isEmpty) return a.length;

    List<int> v0 = List<int>.generate(b.length + 1, (i) => i);
    List<int> v1 = List<int>.filled(b.length + 1, 0);

    for (int i = 0; i < a.length; i++) {
      v1[0] = i + 1;
      for (int j = 0; j < b.length; j++) {
        final cost = a[i] == b[j] ? 0 : 1;
        v1[j + 1] = min(v1[j] + 1, min(v0[j + 1] + 1, v0[j] + cost));
      }
      for (int j = 0; j <= b.length; j++) {
        v0[j] = v1[j];
      }
    }

    return v1[b.length];
  }
}
