import 'dart:math';

/// Résultat d'évaluation d'une réponse écrite.
class TextEvaluationResult {
  final bool isCorrect;
  final bool hasMinorTypo;
  final int distance;
  final String expected;
  final String actual;

  const TextEvaluationResult({
    required this.isCorrect,
    required this.hasMinorTypo,
    required this.distance,
    required this.expected,
    required this.actual,
  });
}

/// Utilitaire de correction douce pour les exercices de saisie écrite (« Écris-le »).
class TextSimilarity {
  TextSimilarity._();

  /// Nettoie une chaîne : minuscules, suppression ponctuation finale et espaces multiples.
  static String normalize(String input) {
    return input
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[.,!?;:\"«»]'), '')
        .replaceAll(RegExp(r'\s+'), ' ');
  }

  /// Calcule la distance de Levenshtein entre deux chaînes.
  static int levenshteinDistance(String s1, String s2) {
    final a = normalize(s1);
    final b = normalize(s2);

    if (a == b) return 0;
    if (a.isEmpty) return b.length;
    if (b.isEmpty) return a.length;

    final rows = a.length + 1;
    final cols = b.length + 1;
    final matrix = List.generate(rows, (_) => List.filled(cols, 0));

    for (int i = 0; i < rows; i++) {
      matrix[i][0] = i;
    }
    for (int j = 0; j < cols; j++) {
      matrix[0][j] = j;
    }

    for (int i = 1; i < rows; i++) {
      for (int j = 1; j < cols; j++) {
        final cost = (a[i - 1] == b[j - 1]) ? 0 : 1;
        matrix[i][j] = [
          matrix[i - 1][j] + 1, // suppression
          matrix[i][j - 1] + 1, // insertion
          matrix[i - 1][j - 1] + cost, // substitution
        ].reduce(min);
      }
    }

    return matrix[a.length][b.length];
  }

  /// Évalue la saisie utilisateur avec tolérance bienveillante (1 ou 2 fautes de frappe tolérées).
  static TextEvaluationResult evaluate(String userInput, String target) {
    final normUser = normalize(userInput);
    final normTarget = normalize(target);

    if (normUser == normTarget) {
      return TextEvaluationResult(
        isCorrect: true,
        hasMinorTypo: false,
        distance: 0,
        expected: target,
        actual: userInput,
      );
    }

    final distance = levenshteinDistance(normUser, normTarget);
    final allowedMaxErrors = normTarget.length > 20 ? 2 : 1;

    final isTolerated = distance <= allowedMaxErrors;

    return TextEvaluationResult(
      isCorrect: isTolerated,
      hasMinorTypo: isTolerated && distance > 0,
      distance: distance,
      expected: target,
      actual: userInput,
    );
  }
}
