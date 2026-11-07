/// Détecteur précis et pédagogique des verbes allemands pour Deutsch Fast.
///
/// Permet de colorer automatiquement les verbes dans les phrases allemandes
/// pour aider l'apprenant à visualiser la structure syntaxique (position 2, V1, fin de subordonnée).
class GermanVerbDetector {
  GermanVerbDetector._();

  /// Formes verbales courantes allemandes (auxiliaires, modaux, conjugaisons et participes).
  static final Set<String> _knownVerbs = <String>{
    // --- sein ---
    'bin', 'bist', 'ist', 'sind', 'seid', 'war', 'warst', 'waren', 'wart',
    'wäre', 'wärst', 'wären', 'gewesen', 'sei', 'seien',

    // --- haben ---
    'hab', 'habe', 'hast', 'hat', 'haben', 'habt', 'hatte', 'hattest',
    'hatten', 'hattet', 'hätte', 'hättest', 'hätten', 'gehabt',

    // --- werden ---
    'werde', 'wirst', 'wird', 'werden', 'werdet', 'wurde', 'wurdest',
    'wurden', 'wurdet', 'würde', 'würdest', 'würden', 'geworden',

    // --- Modaux ---
    'kann', 'kannst', 'können', 'könnt', 'konnte', 'konntest', 'konnten',
    'könnte', 'könntest', 'könnten', 'gekonnt',
    'muss', 'muß', 'musst', 'mußt', 'müssen', 'müsst', 'musste', 'mussten',
    'müsste', 'müssten', 'gemusst',
    'will', 'willst', 'wollen', 'wollt', 'wollte', 'wollten', 'gewollt',
    'soll', 'sollst', 'sollen', 'sollt', 'sollte', 'sollten', 'gesollt',
    'darf', 'darfst', 'dürfen', 'dürft', 'durfte', 'durften', 'dürfte', 'dürften', 'gedurft',
    'mag', 'magst', 'mögen', 'möchte', 'möchtest', 'möchten', 'möchtet', 'mochte', 'gemocht',

    // --- Verbes fréquents du quotidien & conversationnels ---
    // gehen
    'geh', 'gehe', 'gehst', 'geht', 'gehen', 'ging', 'gegangen',
    // kommen
    'komm', 'komme', 'kommst', 'kommt', 'kommen', 'kam', 'gekommen',
    'mitkommen', 'mitgekommen', 'ankommen', 'angekommen',
    // machen
    'mach', 'mache', 'machst', 'macht', 'machen', 'machte', 'gemacht',
    'aufmachen', 'zumachen', 'weitermachen',
    // geben
    'gib', 'gibst', 'gibt', 'geben', 'gab', 'gegeben', 'ausgeben', 'abgeben',
    // sehen
    'sieh', 'siehst', 'sieht', 'sehen', 'seht', 'sah', 'gesehen', 'aussehen',
    // wissen
    'weiß', 'weißt', 'weisst', 'wissen', 'wisst', 'wusste', 'gewusst',
    // stehen
    'steh', 'stehe', 'stehst', 'steht', 'stehen', 'stand', 'gestanden',
    'aufstehen', 'aufgestanden',
    // bleiben
    'bleib', 'bleibe', 'bleibst', 'bleibt', 'bleiben', 'blieb', 'geblieben',
    // denken
    'denk', 'denke', 'denkst', 'denkt', 'denken', 'dachte', 'gedacht',
    // glauben
    'glaub', 'glaube', 'glaubst', 'glaubt', 'glauben', 'geglaubt',
    // sagen
    'sag', 'sage', 'sagst', 'sagt', 'sagen', 'sagte', 'gesagt', 'bescheid',
    // finden
    'find', 'finde', 'findest', 'findet', 'finden', 'fand', 'gefunden',
    // lassen
    'lass', 'lasse', 'lässt', 'lasst', 'lassen', 'ließ', 'ließen', 'gelassen',
    // tun
    'tu', 'tue', 'tust', 'tut', 'tun', 'getan',
    // schaffen
    'schaff', 'schaffe', 'schaffst', 'schafft', 'schaffen', 'schaffte', 'geschafft',
    // laufen
    'lauf', 'laufe', 'läufst', 'läuft', 'laufen', 'lief', 'gelaufen',
    // nehmen
    'nimm', 'nimmst', 'nimmt', 'nehmen', 'nehmt', 'nahm', 'genommen', 'mitnehmen',
    // bringen
    'bring', 'bringe', 'bringst', 'bringt', 'bringen', 'brachte', 'gebracht', 'mitbringen',
    // holen
    'hol', 'hole', 'holst', 'holt', 'holen', 'holte', 'geholt', 'abholen',
    // sprechen
    'sprich', 'sprichst', 'spricht', 'sprechen', 'sprach', 'gesprochen',
    // hören
    'hör', 'höre', 'hörst', 'hört', 'hören', 'hörte', 'gehört', 'zuhören',
    // verstehen
    'versteh', 'verstehe', 'verstehst', 'versteht', 'verstehen', 'verstand', 'verstanden',
    // helfen
    'hilf', 'hilfst', 'hilft', 'helfen', 'half', 'geholfen',
    // brauchen
    'brauch', 'brauche', 'brauchst', 'braucht', 'brauchen', 'brauchte', 'gebraucht',
    // freuen
    'freu', 'freue', 'freust', 'freut', 'freuen', 'gefreut',
    // passen
    'pass', 'passe', 'passt', 'passen', 'gepasst', 'aufpassen',
    // fahren
    'fahr', 'fahre', 'fährst', 'fährt', 'fahren', 'fuhr', 'gefahren',
    // essen
    'iss', 'isst', 'essen', 'aß', 'gegessen',
    // trinken
    'trink', 'trinke', 'trinkst', 'trinkt', 'trinken', 'trank', 'getrunken',
    // schlafen
    'schlaf', 'schlafe', 'schläfst', 'schläft', 'schlafen', 'schlief', 'geschlafen',
    // schieben
    'schieb', 'schiebe', 'schiebt', 'schieben', 'verschieben', 'geschoben', 'verschoben',
    // vergessen
    'vergiss', 'vergisst', 'vergessen', 'vergaß',
    // klären
    'klär', 'kläre', 'klärst', 'klärt', 'klären', 'geklärt',
    // retten
    'rette', 'rettest', 'rettet', 'retten', 'gerettet',
    // meinen
    'mein', 'meine', 'meinst', 'meint', 'meinen', 'gemeint',
    // telefonieren
    'telefoniere', 'telefonierst', 'telefoniert', 'telefonieren',
    // übernehmen
    'übernehme', 'übernimmst', 'übernimmt', 'übernehmen',
    // melden
    'melde', 'meldest', 'meldet', 'melden', 'gemeldet', 'krankgemeldet',
    // schütten & regnen
    'schütte', 'schüttet', 'schütten', 'geschüttet', 'regnet', 'geregnet',
    // weitere Verben aus dem Korpus
    'besprechen', 'beenden', 'beende', 'bezahlen', 'zahle', 'zahlt',
    'übertreib', 'übertreibe', 'übertreibt', 'absagen', 'abgesagt',
    'angerufen', 'anrufen', 'rufe', 'ruft', 'aufgeräumt', 'aufräumen',
    'ausgeruht', 'ausruhen', 'ausgesperrt', 'ausgeschlafen', 'aussteigen',
    'einsteigen', 'eingestiegen', 'warten', 'wartet', 'warte',
    'stimmen', 'stimmt', 'geklappt', 'klappt', 'klappen',
    'funktioniert', 'funktionieren', 'passiert', 'passieren',
    'gestrichen', 'bedeutet', 'bedeuten', 'erledigt', 'erledigen',
    'drücken', 'drückt', 'treffen', 'trifft', 'getroffen',
    'kennen', 'kennt', 'kannte', 'gekannt', 'kennenlernen', 'kennengelernt',
    'hoffen', 'hofft', 'hoffe', 'probiert', 'probieren',
    'gefallen', 'gefällt', 'stören', 'stört', 'kosten', 'kostet',
    'dauern', 'dauert', 'fehlen', 'fehlt', 'sitzen', 'sitzt', 'gesessen',
    'liegen', 'liegt', 'gelegen', 'hängen', 'hängt', 'gehangen',
    'zeigen', 'zeigt', 'zeig', 'erinnern', 'erinnert',
  };

  /// Contractions orales fréquentes avec 's (ex: läuft's, gibt's, geht's, war's, mach's)
  static final Set<String> _spokenVerbContractions = <String>{
    "läuft's", "gibt's", "geht's", "war's", "mach's", "macht's",
    "klappt's", "stimmt's", "tut's", "sieht's", "schafft's", "reicht's",
    "ist's", "hat's", "wird's", "geht’s", "läuft’s", "gibt’s", "war’s",
    "mach’s", "macht’s", "tut’s", "hab'", "mach'", "geh'", "komm'",
  };

  /// Mots à ne JAMAIS colorer comme verbes (noms, pronoms, adverbes, etc.)
  static final Set<String> _exclusions = <String>{
    'der', 'die', 'das', 'den', 'dem', 'des', 'ein', 'eine', 'einen', 'einem', 'einer', 'eines',
    'ich', 'du', 'er', 'sie', 'es', 'wir', 'ihr', 'mich', 'dich', 'ihn', 'ihm', 'uns', 'euch',
    'mir', 'dir', 'mein', 'meine', 'dein', 'deine', 'sein', 'seine', // 'sein' est exclu comme possessif sauf si contexte
    'in', 'an', 'auf', 'aus', 'bei', 'mit', 'nach', 'seit', 'von', 'zu', 'über', 'unter', 'vor', 'hinter',
    'und', 'oder', 'aber', 'denn', 'doch', 'weil', 'wenn', 'dass', 'ob',
    'heute', 'morgen', 'gestern', 'jetzt', 'immer', 'nie', 'oft', 'schon', 'noch', 'mal',
    'nicht', 'kein', 'keine', 'keinen', 'keinem', 'keiner',
    'sehr', 'echt', 'total', 'voll', 'ganz', 'gar', 'nur', 'auch', 'so', 'wie', 'wo', 'was', 'wer',
    'später', 'gleich', 'bald', 'gut', 'schlecht', 'mies', 'gern', 'gerne', 'lieber',
    'bock', 'kino', 'tag', 'chef', 'wochenende', 'uhrzeit', 'termin', 'feierabend', 'zeit',
    'laune', 'abend', 'gefallen', 'rechnung', 'angst', 'prüfung', 'sorgen', 'kopf', 'nase',
    'muffensausen', 'stolz', 'happy', 'peinlich', 'leid', 'eimern', 'mensch', 'na', 'sorry',
    'hallo', 'tschüss', 'danke', 'bitte',
  };

  /// Vérifie si un mot brut dans une phrase est un verbe allemand.
  static bool isVerb(String rawWord) {
    if (rawWord.isEmpty) return false;

    // 1. Nettoyer la ponctuation aux extrémités
    final clean = rawWord
        .replaceAll(RegExp(r'^[«»"“„(\[\{]+|[»"”\)\]\}.,!?:;]+$'), '')
        .trim();

    if (clean.isEmpty) return false;
    final lower = clean.toLowerCase();

    // 2. Vérifier les exclusions explicites
    if (_exclusions.contains(lower)) {
      return false;
    }

    // 3. Vérifier les contractions orales fréquentes (ex: läuft's, gibt's)
    if (_spokenVerbContractions.contains(lower)) {
      return true;
    }

    // 4. Si se termine par 's ou ’s, tester le radical (ex: läuft's -> läuft)
    if (lower.endsWith("'s") || lower.endsWith("’s")) {
      final stem = lower.substring(0, lower.length - 2);
      if (_knownVerbs.contains(stem)) {
        return true;
      }
    }

    // 5. Forme verbale connue directe
    if (_knownVerbs.contains(lower)) {
      return true;
    }

    // 6. Participes passés réguliers (ge...t / ge...en)
    if (lower.startsWith('ge') && lower.length >= 5) {
      if (lower.endsWith('t') || lower.endsWith('en')) {
        return true;
      }
    }

    // 7. Participes avec préfixes séparables (ex: aufgestanden, abgesagt, krankgemeldet)
    if (RegExp(r'^(ab|an|auf|aus|ein|mit|vor|zu|krank)ge\w+(t|en)$').hasMatch(lower)) {
      return true;
    }

    // 8. Verbes avec préfixes inséparables (ver-, be-, ent-, er-, zer-) se terminant en -t ou -en
    if (RegExp(r'^(ver|be|ent|er|zer)\w+(t|en)$').hasMatch(lower)) {
      return true;
    }

    return false;
  }
}
