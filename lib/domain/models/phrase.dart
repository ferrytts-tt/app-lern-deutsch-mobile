/// Modèle d'une phrase allemande du référentiel (Deutsch gesprochen & standard).
class Phrase {
  final String id;
  final String theme; // Thème pédagogique (smalltalk, travail, amis, etc.)
  final String deStandard; // Forme standard (clé anti-doublon)
  final String deParle; // Forme parlée (la vraie cible d'apprentissage)
  final Map<String, String> translations; // Traductions multi-langues ('fr', 'ar', 'en', 'ro', 'ru', 'tr', 'es', 'hi')
  final String _fr;
  final String? _ar;
  final String? note; // Astuce de langue (contractions, sens littéral, etc.)
  final String cefr; // A1, A2, B1, B2
  final String? audioUrl; // URL ou chemin de l'audio pré-enregistré (optionnel)

  // Accesseurs de compatibilité ascendante et descendante
  String get de => deParle;
  String get topic => theme;
  String? get ar => translations['ar'] ?? _ar;
  String get fr => translations['fr'] ?? _fr;

  const Phrase({
    required this.id,
    String? theme,
    String? topic,
    String? deStandard,
    String? deParle,
    String? de,
    String? ar,
    String fr = '',
    this.translations = const {},
    this.note,
    this.cefr = 'B1',
    this.audioUrl,
  })  : theme = theme ?? topic ?? 'general',
        deParle = deParle ?? de ?? '',
        deStandard = deStandard ?? de ?? deParle ?? '',
        _fr = fr,
        _ar = ar;

  /// Récupère la traduction dans la langue demandée, avec repli intelligent
  String getTranslation(String langCode, [String? fallbackLang]) {
    final direct = translations[langCode] ?? (langCode == 'fr' ? _fr : (langCode == 'ar' ? _ar : null));
    if (direct != null && direct.trim().isNotEmpty) return direct;

    if (fallbackLang != null) {
      final fallback = translations[fallbackLang] ?? (fallbackLang == 'fr' ? _fr : (fallbackLang == 'ar' ? _ar : null));
      if (fallback != null && fallback.trim().isNotEmpty) return fallback;
    }

    // Ordre de repli par défaut : en -> fr -> ar -> première dispo
    if (translations.containsKey('en') && translations['en']!.trim().isNotEmpty) {
      return translations['en']!;
    }
    if (_fr.isNotEmpty) return _fr;
    if (translations.containsKey('fr') && translations['fr']!.trim().isNotEmpty) {
      return translations['fr']!;
    }
    final arText = _ar;
    if (arText != null && arText.isNotEmpty) return arText;
    if (translations.containsKey('ar') && translations['ar']!.trim().isNotEmpty) {
      return translations['ar']!;
    }
    return translations.values.firstWhere((t) => t.trim().isNotEmpty, orElse: () => '');
  }

  factory Phrase.fromJson(Map<String, dynamic> json) {
    final deParle = (json['de_parle'] ?? json['de']) as String? ?? '';
    final deStandard = (json['de_standard'] ?? json['de']) as String? ?? deParle;
    final theme = (json['theme'] ?? json['topic']) as String? ?? 'general';

    final rawId = json['id'];
    final id = (rawId == null || rawId.toString().trim().isEmpty || rawId.toString() == 'null')
        ? 'phrase_${DateTime.now().microsecondsSinceEpoch}_${deStandard.hashCode.abs()}'
        : rawId.toString();

    final Map<String, String> transMap = {};
    if (json['translations'] is Map) {
      (json['translations'] as Map).forEach((k, v) {
        if (v != null && v.toString().trim().isNotEmpty) {
          transMap[k.toString()] = v.toString();
        }
      });
    }

    // Support des clés directes au premier niveau
    const langKeys = ['fr', 'ar', 'en', 'ro', 'ru', 'tr', 'es', 'hi', 'de'];
    for (final k in langKeys) {
      if (json[k] is String && (json[k] as String).trim().isNotEmpty) {
        transMap[k] = json[k] as String;
      }
    }

    final frVal = transMap['fr'] ?? (json['fr'] as String? ?? '');
    final arVal = transMap['ar'] ?? (json['ar'] as String?);

    return Phrase(
      id: id,
      theme: theme,
      deStandard: deStandard,
      deParle: deParle,
      fr: frVal,
      ar: arVal,
      translations: transMap,
      note: json['note'] as String?,
      cefr: json['cefr'] as String? ?? 'B1',
      audioUrl: json['audioUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'theme': theme,
      'topic': theme,
      'de_standard': deStandard,
      'de_parle': deParle,
      'de': deParle,
      'translations': translations,
      'fr': fr,
      'ar': ar,
      'note': note,
      'cefr': cefr,
      'audioUrl': audioUrl,
    };
  }

  Phrase copyWith({
    String? id,
    String? theme,
    String? topic,
    String? deStandard,
    String? deParle,
    String? de,
    String? fr,
    Object? ar = _sentinel,
    Map<String, String>? translations,
    String? note,
    String? cefr,
    String? audioUrl,
  }) {
    final Map<String, String> updatedTrans = Map.of(translations ?? this.translations);
    if (fr != null) updatedTrans['fr'] = fr;
    if (ar != _sentinel) {
      if (ar == null) {
        updatedTrans.remove('ar');
      } else {
        updatedTrans['ar'] = ar as String;
      }
    }

    final newFr = fr ?? this.fr;
    final newAr = ar == _sentinel ? this.ar : ar as String?;

    return Phrase(
      id: id ?? this.id,
      theme: theme ?? topic ?? this.theme,
      deStandard: deStandard ?? this.deStandard,
      deParle: deParle ?? de ?? this.deParle,
      fr: newFr,
      ar: newAr,
      translations: updatedTrans,
      note: note ?? this.note,
      cefr: cefr ?? this.cefr,
      audioUrl: audioUrl ?? this.audioUrl,
    );
  }
}

/// Sentinel object used by [Phrase.copyWith] to distinguish between
/// "not provided" and an explicitly passed `null` for nullable fields.
const Object _sentinel = Object();
