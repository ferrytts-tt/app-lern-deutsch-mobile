/// Dictionnaire sémantique des définitions et questions de mots croisés pour Hoppla Rätsel.
/// Toutes les questions / définitions principales sont rédigées EN ALLEMAND,
/// avec les types classiques de mots croisés :
/// - Gegenteil (Antonyme : « Gegenteil von... »)
/// - Synonym / Anderes Wort für
/// - Definition (Définition classique)
/// - Redewendung (Expression idiomatique)
class RaetselDefinitions {
  static const Map<String, Map<String, String>> _definitions = {
    // --- Gegenteil (Antonymes) ---
    'SPÄT': {
      'de': 'Gegenteil von früh',
      'fr': 'Le contraire de tôt',
      'ar': 'عكس مبكر (متأخر)',
      'type': 'gegenteil',
    },
    'FRÜH': {
      'de': 'Gegenteil von spät',
      'fr': 'Le contraire de tard',
      'ar': 'عكس متأخر (مبكراً)',
      'type': 'gegenteil',
    },
    'TAG': {
      'de': 'Gegenteil von Nacht',
      'fr': 'Le contraire de la nuit',
      'ar': 'عكس الليل (النهار)',
      'type': 'gegenteil',
    },
    'NACHT': {
      'de': 'Gegenteil von Tag (dunkle Zeit des Schlafens)',
      'fr': 'Le contraire du jour',
      'ar': 'عكس النهار (الليل)',
      'type': 'gegenteil',
    },
    'GUT': {
      'de': 'Gegenteil von schlecht oder böse',
      'fr': 'Le contraire de mauvais',
      'ar': 'عكس سيء (جيد)',
      'type': 'gegenteil',
    },
    'SCHLECHT': {
      'de': 'Gegenteil von gut',
      'fr': 'Le contraire de bien / bon',
      'ar': 'عكس جيد (سيء)',
      'type': 'gegenteil',
    },
    'SCHLECHTE': {
      'de': 'Gegenteil von gute (z. B. Laune)',
      'fr': 'Le contraire de bonne (ex: mauvaise humeur)',
      'ar': 'عكس جيدة (مثال: مزاج سيء)',
      'type': 'gegenteil',
    },
    'MIES': {
      'de': 'Gegenteil von super oder gut (sehr schlecht)',
      'fr': 'Le contraire de génial (pourri, nul)',
      'ar': 'عكس رائع (سيء للغاية)',
      'type': 'gegenteil',
    },
    'VERGESSEN': {
      'de': 'Gegenteil von sich erinnern',
      'fr': 'Le contraire de se souvenir (oublier)',
      'ar': 'عكس تذكّر (نسي)',
      'type': 'gegenteil',
    },
    'ERINNERN': {
      'de': 'Gegenteil von vergessen',
      'fr': 'Le contraire d’oublier',
      'ar': 'عكس نسي (تذكر)',
      'type': 'gegenteil',
    },
    'SPÄTER': {
      'de': 'Gegenteil von früher oder gleich',
      'fr': 'Le contraire de plus tôt (plus tard)',
      'ar': 'عكس مبكراً أو حالاً (لاحقاً)',
      'type': 'gegenteil',
    },
    'FRÜHER': {
      'de': 'Gegenteil von später',
      'fr': 'Le contraire de plus tard',
      'ar': 'عكس لاحقاً (سابقاً / أبكر)',
      'type': 'gegenteil',
    },
    'GLEICH': {
      'de': 'Gegenteil von später (sofort, im nächsten Moment)',
      'fr': 'Le contraire de plus tard (tout de suite)',
      'ar': 'عكس لاحقاً (حالاً / بعد لحظات)',
      'type': 'gegenteil',
    },
    'JETZT': {
      'de': 'Gegenteil von später (im gegenwärtigen Moment)',
      'fr': 'En ce moment même (maintenant)',
      'ar': 'في هذه اللحظة (الآن)',
      'type': 'gegenteil',
    },
    'KURZ': {
      'de': 'Gegenteil von lang',
      'fr': 'Le contraire de long (court)',
      'ar': 'عكس طويل (قصير)',
      'type': 'gegenteil',
    },
    'LANGE': {
      'de': 'Gegenteil von kurz (über eine große Zeitspanne)',
      'fr': 'Le contraire de court (longtemps)',
      'ar': 'عكس قصير (لفترة طويلة)',
      'type': 'gegenteil',
    },
    'VIEL': {
      'de': 'Gegenteil von wenig (eine große Menge)',
      'fr': 'Le contraire de peu (beaucoup)',
      'ar': 'عكس قليل (كثير)',
      'type': 'gegenteil',
    },
    'WENIG': {
      'de': 'Gegenteil von viel',
      'fr': 'Le contraire de beaucoup (peu)',
      'ar': 'عكس كثير (قليل)',
      'type': 'gegenteil',
    },
    'BISSCHEN': {
      'de': 'Gegenteil von viel (eine kleine Menge / ein wenig)',
      'fr': 'Un tout petit peu',
      'ar': 'قليل / كمية صغيرة',
      'type': 'gegenteil',
    },
    'VOLL': {
      'de': 'Gegenteil von leer',
      'fr': 'Le contraire de vide (plein)',
      'ar': 'عكس فارغ (ممتلئ)',
      'type': 'gegenteil',
    },
    'LEER': {
      'de': 'Gegenteil von voll',
      'fr': 'Le contraire de plein (vide)',
      'ar': 'عكس ممتلئ (فارغ)',
      'type': 'gegenteil',
    },
    'ALT': {
      'de': 'Gegenteil von neu oder jung',
      'fr': 'Le contraire de neuf ou jeune',
      'ar': 'عكس جديد أو شاب (قديم)',
      'type': 'gegenteil',
    },
    'NEU': {
      'de': 'Gegenteil von alt',
      'fr': 'Le contraire d’ancien (nouveau)',
      'ar': 'عكس قديم (جديد)',
      'type': 'gegenteil',
    },
    'NEUES': {
      'de': 'Gegenteil von Altem (aktuelle Nachrichten oder Neuigkeiten)',
      'fr': 'Les nouveautés récentes',
      'ar': 'المستجدات والأخبار الجديدة',
      'type': 'gegenteil',
    },
    'FEIERABEND': {
      'de': 'Gegenteil von Arbeitsbeginn (Ende des Arbeitstages)',
      'fr': 'Fin de la journée de travail',
      'ar': 'عكس بداية الدوام (انتهاء يوم العمل)',
      'type': 'gegenteil',
    },
    'ERNST': {
      'de': 'Gegenteil von Scherz oder Spaß',
      'fr': 'Le contraire de la plaisanterie (sérieux)',
      'ar': 'عكس المزاح (جاد)',
      'type': 'gegenteil',
    },
    'ECHT': {
      'de': 'Gegenteil von gefälscht (wirklich, wahrhaftig)',
      'fr': 'Le contraire de faux (vraiment, authentique)',
      'ar': 'عكس مزيف (حقيقي / فعلاً)',
      'type': 'gegenteil',
    },
    'RICHTIG': {
      'de': 'Gegenteil von falsch',
      'fr': 'Le contraire de faux (juste, correct)',
      'ar': 'عكس خاطئ (صحيح)',
      'type': 'gegenteil',
    },
    'FALSCH': {
      'de': 'Gegenteil von richtig',
      'fr': 'Le contraire de correct (faux)',
      'ar': 'عكس صحيح (خاطئ)',
      'type': 'gegenteil',
    },
    'EINFACH': {
      'de': 'Gegenteil von schwierig oder kompliziert',
      'fr': 'Le contraire de difficile (simple, facile)',
      'ar': 'عكس صعب أو معقد (سهل)',
      'type': 'gegenteil',
    },
    'SCHWER': {
      'de': 'Gegenteil von leicht oder einfach',
      'fr': 'Le contraire de facile ou léger',
      'ar': 'عكس سهل أو خفيف (صعب / ثقيل)',
      'type': 'gegenteil',
    },
    'BLEIB': {
      'de': 'Gegenteil von geh weg (an einem Ort verweilen)',
      'fr': 'Le contraire de partir (reste !)',
      'ar': 'عكس اذهب (ابقَ / امكث)',
      'type': 'gegenteil',
    },
    'KLEIN': {
      'de': 'Gegenteil von groß',
      'fr': 'Le contraire de grand (petit)',
      'ar': 'عكس كبير (صغير)',
      'type': 'gegenteil',
    },
    'GROSS': {
      'de': 'Gegenteil von klein',
      'fr': 'Le contraire de petit (grand)',
      'ar': 'عكس صغير (كبير)',
      'type': 'gegenteil',
    },
    'WARM': {
      'de': 'Gegenteil von kalt',
      'fr': 'Le contraire de froid (chaud)',
      'ar': 'عكس بارد (دافئ)',
      'type': 'gegenteil',
    },
    'KALT': {
      'de': 'Gegenteil von warm oder heiß',
      'fr': 'Le contraire de chaud (froid)',
      'ar': 'عكس دافئ أو ساخن (بارد)',
      'type': 'gegenteil',
    },
    'LAUT': {
      'de': 'Gegenteil von leise',
      'fr': 'Le contraire de silencieux (bruyant)',
      'ar': 'عكس هادئ (صاخب / مرتفع الصوت)',
      'type': 'gegenteil',
    },
    'LEISE': {
      'de': 'Gegenteil von laut',
      'fr': 'Le contraire de bruyant (silencieux)',
      'ar': 'عكس صاخب (هادئ / منخفض)',
      'type': 'gegenteil',
    },
    'SCHNELL': {
      'de': 'Gegenteil von langsam',
      'fr': 'Le contraire de lent (rapide)',
      'ar': 'عكس بطيء (سريع)',
      'type': 'gegenteil',
    },
    'LANGSAM': {
      'de': 'Gegenteil von schnell',
      'fr': 'Le contraire de rapide (lent)',
      'ar': 'عكس سريع (بطيء)',
      'type': 'gegenteil',
    },
    'BILLIG': {
      'de': 'Gegenteil von teuer (preiswert)',
      'fr': 'Le contraire de cher (bon marché)',
      'ar': 'عكس غالٍ (رخيص)',
      'type': 'gegenteil',
    },
    'TEUER': {
      'de': 'Gegenteil von billig oder günstig',
      'fr': 'Le contraire de bon marché (cher)',
      'ar': 'عكس رخيص (غالٍ)',
      'type': 'gegenteil',
    },

    // --- Synonyme & Umchreibungen ---
    'WOCHENENDE': {
      'de': 'Samstag und Sonntag (arbeitsfreie Tage)',
      'fr': 'Période de repos du samedi et dimanche',
      'ar': 'عطلة نهاية الأسبوع (السبت والأحد)',
      'type': 'definition',
    },
    'ABEND': {
      'de': 'Gegenteil von Morgen (Tageszeit nach dem Nachmittag)',
      'fr': 'Le contraire du matin (le soir)',
      'ar': 'عكس الصباح (المساء)',
      'type': 'gegenteil',
    },
    'BOCK': {
      'de': 'Umgangssprachliches Synonym für Lust („Keinen ... haben“)',
      'fr': 'Envie en langage familier',
      'ar': 'رغبة أو مزاج للقيام بشيء (عامية)',
      'type': 'synonym',
    },
    'DAHEIM': {
      'de': 'Synonym für zu Hause (in den eigenen vier Wänden)',
      'fr': 'À la maison, chez soi',
      'ar': 'مرادف لـ في المنزل / في البيت',
      'type': 'synonym',
    },
    'KINO': {
      'de': 'Ort, an dem Filme auf großer Leinwand gezeigt werden',
      'fr': 'Cinéma, salle de projection',
      'ar': 'دار عرض الأفلام السينمائية',
      'type': 'definition',
    },
    'TOTAL': {
      'de': 'Synonym für völlig, ganz und gar',
      'fr': 'Totalement, complètement',
      'ar': 'تماماً أو كلياً',
      'type': 'synonym',
    },
    'MEGA': {
      'de': 'Jugendsprachlich für großartig, riesig oder toll',
      'fr': 'Super, génial, énorme',
      'ar': 'رائع جداً أو ضخم (لغة شبابية)',
      'type': 'synonym',
    },
    'SORRY': {
      'de': 'Alltägliches Wort für Entschuldigung',
      'fr': 'Pardon, désolé',
      'ar': 'كلمة اعتذار شائعة (عذراً)',
      'type': 'synonym',
    },
    'BALD': {
      'de': 'Synonym für in Kürze, demnächst',
      'fr': 'Bientôt, sous peu',
      'ar': 'قريباً / عما قريب',
      'type': 'synonym',
    },
    'TERMIN': {
      'de': 'Vereinbarter Zeitpunkt für ein geschäftliches oder privates Treffen',
      'fr': 'Rendez-vous fixé à une heure précise',
      'ar': 'موعد محدد مسبقاً',
      'type': 'definition',
    },
    'WETTER': {
      'de': 'Zustand der Atmosphäre (Sonne, Wolken, Regen, Wind)',
      'fr': 'Météo du quotidien',
      'ar': 'حالة الطقس والجو',
      'type': 'definition',
    },
    'LAUNE': {
      'de': 'Synonym für Stimmung oder Gemütszustand einer Person',
      'fr': 'Humeur ou disposition d’esprit',
      'ar': 'المزاج أو الحالة النفسية',
      'type': 'synonym',
    },
    'CHEF': {
      'de': 'Synonym für Vorgesetzter oder Leiter am Arbeitsplatz',
      'fr': 'Supérieur hiérarchique au travail',
      'ar': 'المدير أو المسؤول في العمل',
      'type': 'synonym',
    },
    'HEUTE': {
      'de': 'Am gegenwärtigen Kalendertag (Gegenteil von gestern/morgen)',
      'fr': 'Ce jour-ci (aujourd’hui)',
      'ar': 'اليوم الحالي',
      'type': 'definition',
    },
    'MORGEN': {
      'de': 'Gegenteil von Abend (Beginn des Tages oder Folgetag)',
      'fr': 'Le contraire du soir (le matin / demain)',
      'ar': 'عكس المساء (الصباح أو الغد)',
      'type': 'gegenteil',
    },
    'GEFALLEN': {
      'de': 'Ein Gefallen: Eine Hilfeleistung oder ein Freundschaftsdienst',
      'fr': 'Service ou geste d’aide rendu à un ami',
      'ar': 'معروف أو خدمة تقدمها لصديق',
      'type': 'definition',
    },
    'SCHIEBEN': {
      'de': 'Einen Termin auf einen späteren Zeitpunkt verlegen',
      'fr': 'Reporter ou décaler un rendez-vous',
      'ar': 'تأجيل أو ترحيل موعد',
      'type': 'definition',
    },
    'WIEDER': {
      'de': 'Synonym für noch einmal, von Neuem oder zurück',
      'fr': 'À nouveau, de retour',
      'ar': 'مرة أخرى / مجدداً',
      'type': 'synonym',
    },
    'GERETTET': {
      'de': 'Aus einer Gefahr oder Notlage befreit (Partizip II)',
      'fr': 'Sauvé du danger (au passé)',
      'ar': 'أنقذ من مأزق (في صيغة الماضي)',
      'type': 'definition',
    },
    'KOMMST': {
      'de': 'Verb: sich zu einem Ort oder mit jemandem bewegen (Du-Form)',
      'fr': 'Tu viens (du verbe venir)',
      'ar': 'تأتي أو ترافق (فعل أتى)',
      'type': 'definition',
    },
    'SCHAFF': {
      'de': 'Eine schwierige Aufgabe erfolgreich meistern („Das ... ich!“)',
      'fr': 'Y arriver, réussir à faire',
      'ar': 'ينجز أو يقدر على إتمام عمل',
      'type': 'definition',
    },
    'LÄUFT': {
      'de': 'Synonym für funktionieren oder gut vorangehen („Es ...!“)',
      'fr': 'Ça marche, ça roule',
      'ar': 'تسير الأمور على ما يرام',
      'type': 'synonym',
    },
    'KLÄREN': {
      'de': 'Ein Missverständnis oder ein Problem aufklären und lösen',
      'fr': 'Élucider ou régler une situation',
      'ar': 'يوضح أو يحل مسألة',
      'type': 'definition',
    },
    'UHRZEIT': {
      'de': 'Genaue Zeitangabe auf der Uhr (Stunden und Minuten)',
      'fr': 'L’heure exacte de l’horloge',
      'ar': 'التوقيت الدقيق بالساعة والدقائق',
      'type': 'definition',
    },
    'TELEFONIEREN': {
      'de': 'Mit jemandem über das Smartphone oder Telefon sprechen',
      'fr': 'Parler au téléphone',
      'ar': 'يتحدث عبر الهاتف',
      'type': 'definition',
    },
    'SCHÖN': {
      'de': 'Optisch oder gefühlsmäßig angenehm (Gegenteil von hässlich)',
      'fr': 'Beau, agréable',
      'ar': 'جميل أو لطيف',
      'type': 'gegenteil',
    },
    'DANKE': {
      'de': 'Höfliche Formel zur Äußerung von Dankbarkeit',
      'fr': 'Formule pour remercier',
      'ar': 'عبارة الشكر والامتنان',
      'type': 'definition',
    },
    'MEINST': {
      'de': 'Eine Ansicht oder Meinung vertreten („Was ... du dazu?“)',
      'fr': 'Penser, être d’avis',
      'ar': 'يقصد أو يرى رأياً',
      'type': 'definition',
    },
    'SEHEN': {
      'de': 'Optische Reize mit den Augen erfassen',
      'fr': 'Percevoir avec les yeux',
      'ar': 'يرى بالعين',
      'type': 'definition',
    },
    'GESEHEN': {
      'de': 'Mit den Augen wahrgenommen (Partizip II von sehen)',
      'fr': 'Vu (participe passé)',
      'ar': 'رأى (في صيغة الماضي)',
      'type': 'definition',
    },

    // --- Redewendungen ---
    'EIMERN': {
      'de': 'Redewendung für Starkregen: „Es regnet wie aus ...“',
      'fr': 'Expression : « Il pleut des cordes »',
      'ar': 'تعبير مجازي للمطر الغزير كالسيول',
      'type': 'redewendung',
    },
    'OHREN': {
      'de': 'Redewendung für Durchhalten: „Halt die ... steif!“',
      'fr': 'Expression pour encourager : « Tiens bon ! »',
      'ar': 'تعبير مجازي للتشجيع والصمود',
      'type': 'redewendung',
    },
    'DRAN': {
      'de': 'Redewendung bei Verspätung: „spät ... sein“',
      'fr': 'Expression : être à la bourre',
      'ar': 'تعبير: متأخر عن الموعد',
      'type': 'redewendung',
    },
    'SCHÜTTET': {
      'de': 'Sehr stark regnen: „Draußen ... es wie aus Eimern“',
      'fr': 'Pleuvoir à verse',
      'ar': 'يهطل المطر بغزارة',
      'type': 'definition',
    },

    // --- Transport, Stadt & Alltag ---
    'BAHNHOF': {
      'de': 'Gebäude und Anlage, an der Züge halten und Passagiere einsteigen',
      'fr': 'Gare ferroviaire',
      'ar': 'محطة القطار',
      'type': 'definition',
    },
    'ZUG': {
      'de': 'Schienenfahrzeug zur Beförderung von Reisenden oder Gütern',
      'fr': 'Train sur rails',
      'ar': 'القطار السريع',
      'type': 'definition',
    },
    'GLEIS': {
      'de': 'Nummerierter Schienenweg im Bahnhof, an dem die Züge abfahren',
      'fr': 'Voie ferrée numérotée dans la gare',
      'ar': 'رصيف أو مسار السكة الحديدية',
      'type': 'definition',
    },
    'VERSPÄTUNG': {
      'de': 'Gegenteil von Pünktlichkeit (Verzögerung gegenüber dem Fahrplan)',
      'fr': 'Retard par rapport à l’horaire prévu',
      'ar': 'عكس الالتزام بالوقت (التأخير)',
      'type': 'gegenteil',
    },
    'KOFFER': {
      'de': 'Reisegepäckstück mit Griff zum Einpacken von Kleidung',
      'fr': 'Valise de voyage',
      'ar': 'حقيبة السفر للأمتعة',
      'type': 'definition',
    },
    'GELD': {
      'de': 'Offizielles Zahlungsmittel in Form von Banknoten und Münzen',
      'fr': 'Argent liquide',
      'ar': 'النقود والعملات',
      'type': 'definition',
    },
    'KLEINGELD': {
      'de': 'Kleine Münzen zur passenden Bezahlung',
      'fr': 'Petite monnaie (pièces)',
      'ar': 'الفكة والقطع النقدية المعدنية',
      'type': 'definition',
    },
    'HANDGEPÄCK': {
      'de': 'Gepäckstück, das man mit in die Flugzeugkabine nehmen darf',
      'fr': 'Bagage cabine en avion',
      'ar': 'حقيبة اليد المسموح بها في المقصورة',
      'type': 'definition',
    },
    'FLUGHAFEN': {
      'de': 'Start- und Landeplatz für Passagierflugzeuge',
      'fr': 'Aéroport international',
      'ar': 'المطار الجوي',
      'type': 'definition',
    },
    'POLIZEI': {
      'de': 'Behörde für Sicherheit und Ordnung (Notruf 110 in Deutschland)',
      'fr': 'Police (urgence 110)',
      'ar': 'الشرطة والأمن (طوارئ 110)',
      'type': 'definition',
    },
    'KRANKENWAGEN': {
      'de': 'Einsatzfahrzeug zur medizinischen Notfallversorgung',
      'fr': 'Ambulance de secours',
      'ar': 'سيارة الإسعاف لنقل المرضى',
      'type': 'definition',
    },
    'APOTHEKE': {
      'de': 'Fachgeschäft mit dem roten „A“ zum Kauf von Medikamenten',
      'fr': 'Pharmacie pour médicaments',
      'ar': 'الصيدلية لشراء الأدوية',
      'type': 'definition',
    },
    'AUSWEIS': {
      'de': 'Offizielles amtliches Dokument mit Foto zum Nachweis der Identität',
      'fr': 'Carte d’identité officielle',
      'ar': 'بطاقة إثبات الهوية الشخصية',
      'type': 'definition',
    },
    'PORTEMONNAIE': {
      'de': 'Kleine Tasche zur Aufbewahrung von Bargeld und Karten (Geldbörse)',
      'fr': 'Portefeuille ou porte-monnaie',
      'ar': 'محفظة النقود والبطاقات',
      'type': 'definition',
    },
    'TAXI': {
      'de': 'PKW mit Taxameter zur gewerblichen Personenbeförderung',
      'fr': 'Voiture de transport avec chauffeur',
      'ar': 'سيارة الأجرة بالعداد',
      'type': 'definition',
    },
    'TAXAMETER': {
      'de': 'Gerät im Taxi zur Messung des Fahrpreises',
      'fr': 'Compteur kilométrique de taxi',
      'ar': 'عداد حساب أجرة التاكسي',
      'type': 'definition',
    },
    'QUITTUNG': {
      'de': 'Schriftlicher Beleg über den Erhalt einer Zahlung',
      'fr': 'Reçu ou justificatif de paiement',
      'ar': 'إيصال أو فاتورة دفع مكتوبة',
      'type': 'definition',
    },
    'REISEPASS': {
      'de': 'Amtliches Dokument für Reisen in das weltweite Ausland',
      'fr': 'Passeport pour voyager à l’étranger',
      'ar': 'جواز السفر الدولي',
      'type': 'definition',
    },
    'BORDKARTE': {
      'de': 'Dokument zum Einsteigen in das Flugzeug am Flugsteig',
      'fr': 'Carte d’embarquement à l’aéroport',
      'ar': 'بطاقة صعود الطائرة',
      'type': 'definition',
    },
    'HANDY': {
      'de': 'Mobiles Smartphone zum Telefonieren und Surfen im Alltag',
      'fr': 'Téléphone portable / smartphone',
      'ar': 'الهاتف المحمول الذكي',
      'type': 'definition',
    },
    'NUMMER': {
      'de': 'Ziffernfolge, z. B. für den Telefonanschluss oder das Gleis',
      'fr': 'Numéro d’appel ou de voie',
      'ar': 'رقم الهاتف أو التسلسل',
      'type': 'definition',
    },
    'GESCHÄFT': {
      'de': 'Laden oder Boutique, in der Waren verkauft werden',
      'fr': 'Magasin ou commerce',
      'ar': 'المتجر أو المحل التجاري',
      'type': 'definition',
    },
    'MENSCH': {
      'de': 'Umgangssprachlicher Ausruf des Erstaunens („..., das gibt\'s doch nicht!“)',
      'fr': 'Exclamation familière de surprise',
      'ar': 'صيغة تعجب شائعة للتعبير عن المفاجأة',
      'type': 'definition',
    },
    'ZEIT': {
      'de': 'Ablauf der Stunden, Minuten und Sekunden („Keine ... haben“)',
      'fr': 'Temps qui s’écoule',
      'ar': 'الوقت والزمن المنقضي',
      'type': 'definition',
    },
  };

  /// Récupère la question/définition d'un mot dans la langue demandée.
  /// Renvoie une Map { 'de': ..., 'fr': ..., 'ar': ..., 'type': ... }
  static Map<String, String>? getDefinition(String wordUpper) {
    return _definitions[wordUpper.toUpperCase()];
  }

  /// Génère une question intelligente de mot croisé pour un mot,
  /// TOUJOURS en allemand pour 'de'.
  static Map<String, String> generateDefinitionForWord({
    required String word,
    required String phraseFr,
    required String? phraseAr,
    required String? phraseDe,
    required String? note,
  }) {
    final upper = word.toUpperCase();
    final predefined = _definitions[upper];
    if (predefined != null) {
      return predefined;
    }

    // Si une note explicative allemande existe (ex: "X = Y")
    if (note != null && note.isNotEmpty) {
      // Si la note contient un égal allemand comme "mies = schlecht" ou "war's = war es"
      final parts = note.split('=');
      if (parts.length >= 2 && parts[0].toUpperCase().contains(upper)) {
        final explanation = parts[1].trim();
        // Ne garder que si ce n'est pas de l'arabe
        if (!explanation.contains(RegExp(r'[\u0600-\u06FF]'))) {
          return {
            'de': 'Synonym oder Erklärung: $explanation',
            'fr': 'Note : $note',
            'ar': 'ملاحظة : $note',
            'type': 'synonym',
          };
        }
      }
    }

    final cleanDe = phraseDe != null && phraseDe.isNotEmpty ? phraseDe : word;

    // Définition par défaut élégante et 100% EN ALLEMAND
    return {
      'de': 'Gesuchtes Wort aus der Redewendung: „$cleanDe“',
      'fr': 'Mot associé à : « $phraseFr »',
      'ar': phraseAr != null && phraseAr.isNotEmpty
          ? 'الكلمة المرتبطة بـ : « $phraseAr »'
          : 'الكلمة المرتبطة بـ : « $phraseFr »',
      'type': 'definition',
    };
  }

  /// Pépites culturelles et anecdotes allemandes passionnantes pour récompenser le joueur à chaque fin de niveau
  static const List<Map<String, String>> _kulturPerlen = [
    {
      'title': 'Der heilige Feierabend 🍺',
      'text': 'En Allemagne, le « Feierabend » n\'est pas juste l\'heure de sortie du travail : c\'est un rituel sacré où l\'on coupe tout contact professionnel pour consacrer sa soirée au repos et aux proches.',
      'tag': 'CULTURE ALLEMANDE',
    },
    {
      'title': 'Le mot magique : Kummerspeck 🍫',
      'text': 'Les Allemands ont un mot poétique pour désigner les petits kilos pris en grignotant après un coup de blues ou un chagrin : le « Kummerspeck » (littéralement « le lard du chagrin ») !',
      'tag': 'TRÉSOR DE LA LANGUE',
    },
    {
      'title': '« Ich verstehe nur Bahnhof » 🚂',
      'text': 'Cette célèbre expression remonte aux soldats fatigués de la 1ère guerre mondiale qui ne voulaient plus entendre parler que du « train / Bahnhof » pour rentrer chez eux. Aujourd\'hui, elle signifie : « Je ne comprends absolument rien ! »',
      'tag': 'ORIGINE D’EXPRESSION',
    },
    {
      'title': 'Daumen drücken ! ✊',
      'text': 'Pour souhaiter bonne chance à quelqu\'un en Allemagne, on ne croise pas les doigts : on rentre ses pouces dans ses poings fermés en disant « Ich drücke dir die Daumen ! »',
      'tag': 'GESTUELLE & COUTUME',
    },
    {
      'title': 'Der Ohrwurm 🎵',
      'text': 'Vous avez un refrain entêtant qui tourne en boucle dans votre tête depuis ce matin ? Les germanophones l\'appellent avec humour un « Ohrwurm » (un ver d\'oreille) !',
      'tag': 'MOTS COMPOSÉS',
    },
    {
      'title': 'Die Schadenfreude 😈',
      'text': 'La « Schadenfreude » désigne le petit plaisir malicieux ressenti face à la mésaventure sans gravité d\'un proche. Le concept est tellement précis que l\'anglais et le français l\'ont emprunté tel quel !',
      'tag': 'PHILOSOPHIE LINGUISTIQUE',
    },
    {
      'title': 'Den Teufel an die Wand malen 👹',
      'text': 'Littéralement « peindre le diable sur le mur ». On dit ça à quelqu\'un qui dramatise ou imagine tout de suite le pire scénario possible avant même d\'avoir essayé.',
      'tag': 'EXPRESSION COURANTE',
    },
    {
      'title': 'Fernweh : la nostalgie du voyage ✈️',
      'text': 'Tout le monde connaît le mal du pays (« Heimweh »). Mais l\'allemand a aussi inventé le « Fernweh » : cette envie irrésistible et nostalgique de partir loin explorer le monde !',
      'tag': 'POÉSIE DES MOTS',
    },
    {
      'title': 'Das ist mir Wurst ! 🌭',
      'text': '« Ça m\'est complètement égal ! » Les charcuteries ont une telle place dans le quotidien allemand que la saucisse est devenue l\'étalon suprême de l\'indifférence totale.',
      'tag': 'HUMOUR DU QUOTIDIEN',
    },
    {
      'title': 'Ein Stein vom Herzen fallen ❤️',
      'text': 'Quand une épreuve stressante se termine enfin avec succès, on dit « Ein Stein fällt mir vom Herzen » : un énorme rocher s\'effondre de notre cœur, laissant place à un vrai soulagement.',
      'tag': 'ÉMOTION & GRATITUDE',
    },
  ];

  /// Retourne la pépite culturelle attribuée à un numéro de niveau
  static Map<String, String> getKulturPerle(int levelNumber) {
    final idx = (levelNumber - 1) % _kulturPerlen.length;
    return _kulturPerlen[idx];
  }
}
