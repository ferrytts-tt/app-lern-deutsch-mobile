import '../models/phrase.dart';

/// Modèle d'un scénario de situation réelle pour l'Exercice 2 du Master XP.
/// Conçu selon les principes de la pragmatique communicative allemande (GER / CEFR).
class GermanMasterScenario {
  final String phraseId;
  final String speakerName;
  final String dialogueGerman;
  final String situationGerman;
  final String situationArabic;
  final String explanationGerman;
  final String explanationArabic;

  const GermanMasterScenario({
    required this.phraseId,
    required this.speakerName,
    required this.dialogueGerman,
    required this.situationGerman,
    required this.situationArabic,
    required this.explanationGerman,
    required this.explanationArabic,
  });
}

/// Catalogue et moteur expert de scénarios pour le mode Master XP.
class GermanMasterScenariosCatalog {
  GermanMasterScenariosCatalog._();

  static final Map<String, GermanMasterScenario> _curatedScenarios = {
    // ----------------- Thème 1 : Smalltalk -----------------
    'phrase_001': const GermanMasterScenario(
      phraseId: 'phrase_001',
      speakerName: 'Markus (Kollege)',
      dialogueGerman: '„Hallo Thomas! Schön dich zu sehen. Wie steht das Leben?“',
      situationGerman: 'Du triffst einen Kollegen morgens im Flur. Wie erwiderst du locker und umgangssprachlich?',
      situationArabic: 'تقابل زميلاً في ممر العمل ويسلم عليك بود. كيف تبادله التحية وتسأله عن أحواله بعفوية؟',
      explanationGerman: '„Na, wie läuft\'s?“ ist im deutschen Alltag die sympathischste und natürlichste Art, sich nach dem Befinden zu erkundigen.',
      explanationArabic: '«Na, wie läuft\'s?» هي الطريقة الألمانية الأكثر عفوية وودية لفتح الحديث والسؤال عن الأحوال بين الزملاء والأصدقاء.',
    ),
    'phrase_002': const GermanMasterScenario(
      phraseId: 'phrase_002',
      speakerName: 'Lukas (Freund)',
      dialogueGerman: '„Moment mal... Bist du das wirklich?! Wie viele Jahre ist das her?“',
      situationGerman: 'Du triffst zufällig einen alten Schulfreund nach langer Zeit in der Innenstadt.',
      situationArabic: 'قابلت صديق دراسة قديماً بالصدفة في وسط المدينة بعد سنوات من الغياب. ماذا تقول بتعجب وسرور؟',
      explanationGerman: '„Mensch, lange nicht gesehen!“ drückt echte, freudige Überraschung und Erstaunen über das Wiedersehen aus.',
      explanationArabic: '«Mensch, lange nicht gesehen!» تعبير ألماني شعبي يعبر عن الدهشة الإيجابية والفرحة الغامرة بلقاء شخص بعد مدة طويلة.',
    ),
    'phrase_003': const GermanMasterScenario(
      phraseId: 'phrase_003',
      speakerName: 'Sarah (Freundin)',
      dialogueGerman: '„Setz dich zu mir! Wir haben uns seit Wochen nicht gesprochen.“',
      situationGerman: 'Deine Freundin ist zurück aus dem Urlaub. Du möchtest direkt wissen, welche Neuigkeiten es gibt.',
      situationArabic: 'عادت صديقتك من الإجازة وتريد أن تسألها فوراً عن آخر الأخبار والمستجدات.',
      explanationGerman: '„Was gibt\'s Neues?“ ist der Standardausdruck im modernen Deutsch, um locker nach den jüngsten Ereignissen zu fragen.',
      explanationArabic: '«Was gibt\'s Neues?» هو التعبير المعياري اليومي للاستفسار عن الأخبار والتطورات الأخيرة.',
    ),
    'phrase_004': const GermanMasterScenario(
      phraseId: 'phrase_004',
      speakerName: 'David (Kollege)',
      dialogueGerman: '„Bleib doch noch zehn Minuten, wir trinken noch schnell einen Kaffee zusammen!“',
      situationGerman: 'Dein Bus fährt in drei Minuten ab. Du kannst leider nicht mehr bleiben und musst sofort aufbrechen.',
      situationArabic: 'دعاك زميلك للبقاء وشرب القهوة، لكن موعد حافلتك اقترب ويجب أن تغادر فوراً.',
      explanationGerman: '„Ich muss los.“ signalisiert einen zügigen, aber völlig natürlichen und höflichen Aufbruch im Alltag.',
      explanationArabic: '«Ich muss los.» كلمة «los» هنا تغني عن الفعل الكامل وتعني فوراً «عليّ الذهاب الآن / حان وقت رحيلي».',
    ),
    'phrase_005': const GermanMasterScenario(
      phraseId: 'phrase_005',
      speakerName: 'Anna (Büro)',
      dialogueGerman: '„Guten Morgen! Ein neuer Montag fängt an... Wie war deine freie Zeit?“',
      situationGerman: 'Es ist Montagmorgen an der Kaffeemaschine. Du möchtest deine Kollegin nach ihren freien Tagen fragen.',
      situationArabic: 'صباح يوم الاثنين بجانب ماكينة القهوة. تريد سؤال زميلتك بلطف عن عطلة نهاية أسبوعها.',
      explanationGerman: '„Na, wie war\'s am Wochenende?“ ist der absolute Klassiker des deutschen Büro-Smalltalks am Wochenanfang.',
      explanationArabic: 'السؤال الذهبي في بيئة العمل الألمانية صباح كل يوم اثنين لكسر الجليد وتوطيد العلاقات مع الزملاء.',
    ),
    'phrase_006': const GermanMasterScenario(
      phraseId: 'phrase_006',
      speakerName: 'Felix (Bekannter)',
      dialogueGerman: '„Überraschung! Ich bin heute spontan in deiner Stadt zu Besuch.“',
      situationGerman: 'Jemand, den du sehr schätzt, besucht dich überraschend. Wie begrüßt du ihn herzlich?',
      situationArabic: 'شخص عزيز عليك يزورك بشكل مفاجئ. كيف تعبر عن سعادتك برؤيته مجدداً وترحب به بحرارة؟',
      explanationGerman: '„Schön, dich mal wieder zu sehen!“ verbindet Herzlichkeit mit sprachlicher Natürlichkeit durch die Partikel „mal“.',
      explanationArabic: 'تعبير دافئ للترحيب برؤية شخص بعد فترة، واستخدام «mal wieder» يضفي لمسة ودية محببة.',
    ),
    'phrase_007': const GermanMasterScenario(
      phraseId: 'phrase_007',
      speakerName: 'Nachbar (Treppenhaus)',
      dialogueGerman: '„Schauen Sie mal aus dem Fenster... Es ist nass, grau und eiskalt.“',
      situationGerman: 'Ein Nachbar beschwert sich über das schlechte Wetter. Wie äußerst du deine Zustimmung locker?',
      situationArabic: 'جارك يتذمر من برودة الجو والغيوم والأمطار. كيف توافقه الرأي وتصف الطقس السيئ بالعامية؟',
      explanationGerman: '„Echt mies“ ist das treffende umgangssprachliche Adjektiv für unangenehmes, ungemütliches Schmuddelwetter.',
      explanationArabic: '«Echt mies» تعني «سيئ جداً / فظيع» وهي مستخدمة بكثرة في ألمانيا لوصف الطقس غير المريح.',
    ),
    'phrase_008': const GermanMasterScenario(
      phraseId: 'phrase_008',
      speakerName: 'Freund (Vor der Tür)',
      dialogueGerman: '„Wollen wir zu Fuß zum Restaurant laufen oder regnet es zu stark?“',
      situationGerman: 'Draußen regnet es mit extremer Wucht. Wie beschreibst du diesen Starkregen bildhaft mit einer Redewendung?',
      situationArabic: 'المطر غزير جداً ويسقط بقوة هائلة كأن أحداً يسكب دلاء من الماء. كيف تصف ذلك بالمثل الشائع؟',
      explanationGerman: '„Es schüttet wie aus Eimern“ ist die bekannteste deutsche Redewendung für sintflutartigen Platzregen.',
      explanationArabic: 'تعبير اصطلاحي شهير يعني «المطر ينهمر كأنه يُسكب من دلاء» للدلالة على غزارة الهطول الشديدة.',
    ),
    'phrase_009': const GermanMasterScenario(
      phraseId: 'phrase_009',
      speakerName: 'Passant am Bahnhof',
      dialogueGerman: '„Entschuldigen Sie bitte, mein Handy-Akku ist leider komplett leer...“',
      situationGerman: 'Du möchtest einen Passanten auf der Straße höflich und flüssig nach der genauen Uhrzeit fragen.',
      situationArabic: 'نفدت بطارية هاتفك في المحطة وتريد أن تسأل شخصاً عابراً عن الوقت بلطف وأسلوب ألماني سلس.',
      explanationGerman: '„Hast du mal die Uhrzeit?“ (oder mit Sie: „Haben Sie mal...“) ist die umgangssprachlich flüssigste Formulierung.',
      explanationArabic: 'الصيغة الألمانية اليومية الأكثر انسيابية للسؤال عن الوقت بدلاً من الصيغ المدرسية الجامدة.',
    ),
    'phrase_010': const GermanMasterScenario(
      phraseId: 'phrase_010',
      speakerName: 'Jonas (Freund)',
      dialogueGerman: '„Mein Zug fährt ein! Ich muss los. Danke für den schönen Nachmittag!“',
      situationGerman: 'Dein Freund steigt in die Bahn ein. Wie verabschiedest du dich herzlich und wünschst ihm alles Gute?',
      situationArabic: 'صديقك يركب القطار مغادراً. كيف تودعه بود متمنياً له الخير حتى اللقاء القادم؟',
      explanationGerman: '„Mach\'s gut, bis bald!“ kombiniert einen herzlichen Segenswunsch („Pass auf dich auf / Mach es gut“) mit Vorfreude auf das Wiedersehen.',
      explanationArabic: '«Mach\'s gut, bis bald!» تجمع بين التمنيات الطيبة بالسلامة والراحة («Mach\'s gut») وتوقع اللقاء قريباً («bis bald»).',
    ),

    // ----------------- Thème 2 : Travail -----------------
    'phrase_011': const GermanMasterScenario(
      phraseId: 'phrase_011',
      speakerName: 'Jan (Projektleiter)',
      dialogueGerman: '„Kommst du heute um 15 Uhr kurz mit in das Spontan-Meeting?“',
      situationGerman: 'Du bist mit dringenden Abgaben völlig überlastet und hast keine Zeit. Wie äußerst du das idiomatisch?',
      situationArabic: 'سألك مدير المشروع إن كان بإمكانك حضور اجتماع، لكنك غارق تماماً بالمهام والضغوط. كيف تعتذر بتعبير ألماني أصيل؟',
      explanationGerman: '„Viel um die Ohren haben“ ist die klassische deutsche Redewendung für enormen Arbeitsdruck und Beschäftigtsein.',
      explanationArabic: '«Viel um die Ohren haben» تعبير مجازي شائع جداً يعني أن لديك مشاغل كثيرة جداً تضغط على وقتك.',
    ),
    'phrase_012': const GermanMasterScenario(
      phraseId: 'phrase_012',
      speakerName: 'Kollegin Sandra',
      dialogueGerman: '„Passt Ihnen unsere Besprechung heute um 14:00 Uhr noch wie geplant?“',
      situationGerman: 'Dir ist ein Notfall dazwischengekommen. Du möchtest das Treffen auf einen späteren Termin verlegen.',
      situationArabic: 'سألتك زميلتك عن موعد الساعة الثانية، ولديك ظرف طارئ وتريد تأجيله بلطف إلى وقت لاحق.',
      explanationGerman: '„Einen Termin schieben“ bedeutet im Arbeitsalltag ganz locker, ein Treffen zeitlich nach hinten zu verschieben.',
      explanationArabic: '«Einen Termin schieben» تعبير مستخدم بكثرة في الشركات الألمانية يعني تأجيل موعد أو نقله لوقت لاحق.',
    ),
    'phrase_013': const GermanMasterScenario(
      phraseId: 'phrase_013',
      speakerName: 'Kollege Tim',
      dialogueGerman: '„Arbeitest du heute noch lange an der Präsentation weiter?“',
      situationGerman: 'Es ist 17 Uhr und deine Arbeit ist für heute getan. Du packst deine Tasche.',
      situationArabic: 'الساعة الخامسة وقد أنجزت عملك لليوم. زميلك يسألك إن كنت ستطيل البقاء، بم تجيبه؟',
      explanationGerman: '„Feierabend machen“ ist das schönste deutsche Wort für das offizielle Ende des täglichen Arbeitstages.',
      explanationArabic: '«Feierabend machen» من أجمل الكلمات الألمانية وتعني إنهاء العمل اليومي وبدء وقت الراحة والحرية.',
    ),
    'phrase_014': const GermanMasterScenario(
      phraseId: 'phrase_014',
      speakerName: 'Vorgesetzter',
      dialogueGerman: '„Können Sie den gesamten Bericht bitte schon morgen früh um 8 Uhr fertig haben?“',
      situationGerman: 'Die Frist ist völlig unrealistisch. Wie sagst du ehrlich und direkt, dass das nicht machbar ist?',
      situationArabic: 'طلب منك المسؤول إنجاز التقرير الضخم كاملاً بحلول الصباح الباكر، والموعد غير ممكن إطلاقاً. كيف توضح ذلك بواقعية؟',
      explanationGerman: '„Das schaff ich nicht“ drückt klar und professionell die Grenzen der zeitlichen Machbarkeit aus.',
      explanationArabic: '«Das schaff ich nicht» تعبير مباشر وواضح يعني «لن أتمكن من إنجاز ذلك / هذا يفوق القدرة الزمنية».',
    ),
    'phrase_015': const GermanMasterScenario(
      phraseId: 'phrase_015',
      speakerName: 'Teamkollege',
      dialogueGerman: '„Entschuldige die Störung, ich habe eine kurze Frage zur Kundendatei.“',
      situationGerman: 'Du gehst an den Schreibtisch eines Kollegen und möchtest wissen, ob er zwei Minuten für dich hat.',
      situationArabic: 'توجهت إلى مكتب زميلك وتريد التأكد إن كان لديه دقيقتان لمساعدتك وسؤاله عن شيء سريع.',
      explanationGerman: '„Hast du mal kurz Zeit?“ ist die höflichste und üblichste Einstiegsfrage im kollegialen Miteinander.',
      explanationArabic: 'السؤال المثالي لاستئذان زميل في العمل قبل سؤاله: «هل لديك وقت قصير؟».',
    ),
    'phrase_016': const GermanMasterScenario(
      phraseId: 'phrase_016',
      speakerName: 'Freundin Laura',
      dialogueGerman: '„Bist du heute gar nicht im Büro? Ich habe dich vermisst.“',
      situationGerman: 'Du bist mit Fieber zu Hause geblieben und hast die Personalabteilung und deinen Chef über deine Krankheit informiert.',
      situationArabic: 'صديقتك تسأل عن غيابك عن العمل، وأنت مريض في المنزل وقد أبلغت الإدارة رسمياً بمرضك.',
      explanationGerman: '„Sich krankmelden“ ist der offizielle und alltägliche Begriff für die Krankheitsanzeige beim Arbeitgeber.',
      explanationArabic: '«Sich krankmelden» هو المصطلح النظامي والشائع للإبلاغ عن الإجازة المرضية لدى جهة العمل.',
    ),
    'phrase_017': const GermanMasterScenario(
      phraseId: 'phrase_017',
      speakerName: 'Kollegin im Flur',
      dialogueGerman: '„Hast du gesehen, wie der Chef eben aus der Konferenz gestürmt ist?“',
      situationGerman: 'Der Chef ist heute extrem gereizt, kritisiert alles und schaut finster. Wie beschreibst du das?',
      situationArabic: 'المدير غاضب جداً اليوم وينتقد كل شيء بوجه عابس. كيف تصف سوء مزاجه لزميلتك؟',
      explanationGerman: '„Schlechte Laune haben“ (verstärkt mit „voll“) beschreibt treffend die miese Stimmung einer Person.',
      explanationArabic: '«Voll schlechte Laune» تعني «في غاية سوء المزاج والعصبية اليوم».',
    ),
    'phrase_018': const GermanMasterScenario(
      phraseId: 'phrase_018',
      speakerName: 'Projektleiter',
      dialogueGerman: '„Hast du die E-Mail an den Lieferanten geschickt, um die wir dich gestern gebeten hatten?“',
      situationGerman: 'Du hast die Aufgabe im Alltagsstress komplett vergessen. Wie entschuldigst du dich sofort ehrlich?',
      situationArabic: 'سألك المسؤول عن مهمة طلبت منك بالأمس ونسيتها تماماً في زحمة المهام. كيف تعتذر بصدق وسرعة؟',
      explanationGerman: '„Hab ich total vergessen, sorry!“ ist die spontane, aufrichtige Entschuldigung bei einem Missgeschick.',
      explanationArabic: 'اعتذار عفوي وصادق: «نسيت الأمر تماماً، أعتذر بشدة!».',
    ),
    'phrase_019': const GermanMasterScenario(
      phraseId: 'phrase_019',
      speakerName: 'Kollege Michael',
      dialogueGerman: '„Was machen wir jetzt wegen der fehlerhaften Lieferung? Sollen wir gleich diskutieren?“',
      situationGerman: 'Ihr müsst jetzt sofort zu einem wichtigen Termin. Du schlägst vor, das Problem im Anschluss zu besprechen.',
      situationArabic: 'زميلك يريد مناقشة مشكلة فوراً، لكنك على وشك الدخول لاجتماع عاجل وتقترح بحث الموضوع لاحقاً.',
      explanationGerman: '„Das klären wir später“ schiebt die inhaltliche Klärung geordnet auf einen passenderen Zeitpunkt auf.',
      explanationArabic: '«Das klären wir später» تعبير عملي منظم يعني «سنحسم هذا الموضوع ونتحدث فيه لاحقاً».',
    ),
    'phrase_020': const GermanMasterScenario(
      phraseId: 'phrase_020',
      speakerName: 'Teamleiter',
      dialogueGerman: '„Hier ist die Datei, die du dringend für die Kundenpräsentation gebraucht hast!“',
      situationGerman: 'Ein Kollege hat dir in höchster Not geholfen und dich vor einem Desaster gerettet. Wie dankst du ihm überschwänglich?',
      situationArabic: 'أنقذك زميلك في اللحظة الأخيرة بملف مصيري قبل بدء العرض التقديمي. كيف تشكره بحرارة وامتنان؟',
      explanationGerman: '„Du hast mir den Tag gerettet!“ ist der höchste Ausdruck spontaner Dankbarkeit im deutschen Arbeitsleben.',
      explanationArabic: '«Du hast mir den Tag gerettet!» تعبير رائع يعني حرفياً ومجازياً «لقد أنقذت يومي وموقفي!».',
    ),
  };

  /// Récupère le scénario adapté pour une phrase donnée, avec génération contextuelle experte en fallback.
  static GermanMasterScenario getScenarioFor(Phrase phrase) {
    if (_curatedScenarios.containsKey(phrase.id)) {
      return _curatedScenarios[phrase.id]!;
    }

    // Fallback expert et intelligent basé sur le thème et les champs de la phrase
    final arabicText = (phrase.ar != null && phrase.ar!.isNotEmpty)
        ? phrase.ar!
        : (phrase.fr.isNotEmpty ? phrase.fr : phrase.de);
    final deText = phrase.deParle.isNotEmpty ? phrase.deParle : phrase.de;

    return GermanMasterScenario(
      phraseId: phrase.id,
      speakerName: _getSpeakerForTheme(phrase.theme),
      dialogueGerman: _generateDialoguePrompt(phrase),
      situationGerman: 'In welcher typischen Alltagssituation antwortest du mit: „$deText“?',
      situationArabic: 'في محادثة حقيقية تعبر فيها عن: «$arabicText»، ما هي العبارة الألمانية الملائمة؟',
      explanationGerman: '„$deText“ ist der native und passende Ausdruck für diese kommunikative Alltagssituation.',
      explanationArabic: 'هذه العبارة هي الرد الطبيعي والملائم في الثقافة اللغوية الألمانية اليومية لهذا السياق.',
    );
  }

  static String _getSpeakerForTheme(String theme) {
    switch (theme.toLowerCase()) {
      case 'travail':
        return 'Kollege / Chef';
      case 'amis':
        return 'Freund / Bekannter';
      case 'restaurant':
        return 'Kellner / Bedienung';
      case 'sante':
        return 'Arzt / Apotheker';
      case 'transport':
        return 'Fahrgast / Schaffner';
      case 'administration':
        return 'Beamter / Sachbearbeiter';
      case 'telephone':
        return 'Anrufer am Telefon';
      case 'opinions':
        return 'Gesprächspartner';
      case 'emotions':
        return 'Freundin / Kumpel';
      default:
        return 'Gesprächspartner';
    }
  }

  static String _generateDialoguePrompt(Phrase phrase) {
    switch (phrase.theme.toLowerCase()) {
      case 'restaurant':
        return '„Guten Tag! Haben Sie schon gewählt oder möchten Sie etwas bestellen?“';
      case 'sante':
        return '„Wie geht es Ihnen denn heute? Was fehlt Ihnen?“';
      case 'transport':
        return '„Entschuldigen Sie, wissen Sie, wann der nächste Anschluss kommt?“';
      case 'administration':
        return '„Haben Sie alle erforderlichen Unterlagen dabei?“';
      case 'telephone':
        return '„Hallo? Kannst du mich gut verstehen?“';
      case 'opinions':
        return '„Wie findest du eigentlich diesen Vorschlag?“';
      default:
        return '„Hallo! Wie sieht es bei dir aus?“';
    }
  }
}
