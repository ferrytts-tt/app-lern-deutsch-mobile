import 'dart:convert';

/// Profil et réglages de l'utilisateur (Table utilisateur du plan).
class UserProfile {
  final String id;
  final String primaryLanguage; // ex: 'ar', 'fr', 'en', 'ro', 'ru', 'tr', 'es', 'hi'
  final String? secondaryLanguage; // ex: 'fr', 'en' (optionnel)
  final int objectifQuotidien; // 5 (Léger), 10 (Normal), 20 (Intensif)
  final List<String> themesPrioritaires; // 2 à 4 thèmes prioritaires
  final String niveauDeclare; // débutant, A2, B1, B2 ou plus
  final String heureRappel; // ex: "19:00"
  final int serieJours; // Série de jours consécutifs
  final DateTime? derniereSession;
  final bool gelSerieDisponible; // 1 gel gratuit par semaine pour protéger la série
  final DateTime? dateGelUtilise; // Date à laquelle le gel a été utilisé pour recharge hebdomadaire

  // Alias de compatibilité ascendante pour l'ancien code
  String get langueTraduction => primaryLanguage;

  const UserProfile({
    this.id = 'default_user',
    String? primaryLanguage,
    String? langueTraduction,
    this.secondaryLanguage,
    this.objectifQuotidien = 10,
    this.themesPrioritaires = const ['smalltalk', 'travail'],
    this.niveauDeclare = 'B2',
    this.heureRappel = '19:00',
    this.serieJours = 0,
    this.derniereSession,
    this.gelSerieDisponible = true,
    this.dateGelUtilise,
  }) : primaryLanguage = primaryLanguage ?? langueTraduction ?? 'ar';

  /// Alias pour l'accès aux thèmes prioritaires
  List<String> get priorityThemes => themesPrioritaires;

  /// Vérifie et recharge le gel de série hebdomadaire si 7 jours se sont écoulés (Section 7.1).
  UserProfile checkWeeklyStreakFreeze([DateTime? now]) {
    if (gelSerieDisponible) return this;
    final current = now ?? DateTime.now();
    if (dateGelUtilise != null && current.difference(dateGelUtilise!).inDays >= 7) {
      return copyWith(gelSerieDisponible: true, clearDateGelUtilise: true);
    }
    return this;
  }

  UserProfile copyWith({
    String? id,
    String? primaryLanguage,
    String? langueTraduction,
    String? secondaryLanguage,
    bool clearSecondaryLanguage = false,
    int? objectifQuotidien,
    List<String>? themesPrioritaires,
    String? niveauDeclare,
    String? heureRappel,
    int? serieJours,
    DateTime? derniereSession,
    bool? gelSerieDisponible,
    DateTime? dateGelUtilise,
    bool clearDateGelUtilise = false,
  }) {
    return UserProfile(
      id: id ?? this.id,
      primaryLanguage: primaryLanguage ?? langueTraduction ?? this.primaryLanguage,
      secondaryLanguage: clearSecondaryLanguage ? null : (secondaryLanguage ?? this.secondaryLanguage),
      objectifQuotidien: objectifQuotidien ?? this.objectifQuotidien,
      themesPrioritaires: themesPrioritaires ?? this.themesPrioritaires,
      niveauDeclare: niveauDeclare ?? this.niveauDeclare,
      heureRappel: heureRappel ?? this.heureRappel,
      serieJours: serieJours ?? this.serieJours,
      derniereSession: derniereSession ?? this.derniereSession,
      gelSerieDisponible: gelSerieDisponible ?? this.gelSerieDisponible,
      dateGelUtilise: clearDateGelUtilise ? null : (dateGelUtilise ?? this.dateGelUtilise),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'langue_traduction': primaryLanguage,
      'primary_language': primaryLanguage,
      'secondary_language': secondaryLanguage,
      'objectif_quotidien': objectifQuotidien,
      'themes_prioritaires': jsonEncode(themesPrioritaires),
      'niveau_declare': niveauDeclare,
      'heure_rappel': heureRappel,
      'serie_jours': serieJours,
      'derniere_session': derniereSession?.toIso8601String(),
      'gel_serie_disponible': gelSerieDisponible ? 1 : 0,
      'date_gel_utilise': dateGelUtilise?.toIso8601String(),
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    List<String> themes = const ['smalltalk', 'travail'];
    final themesRaw = map['themes_prioritaires'];
    if (themesRaw is String && themesRaw.isNotEmpty) {
      try {
        final decoded = jsonDecode(themesRaw);
        if (decoded is List) {
          themes = decoded.map((e) => e.toString()).toList();
        }
      } catch (_) {}
    } else if (themesRaw is List) {
      themes = themesRaw.map((e) => e.toString()).toList();
    }

    final sessionStr = map['derniere_session'] as String?;
    final derniereSession = sessionStr != null ? DateTime.tryParse(sessionStr) : null;
    final gelStr = map['date_gel_utilise'] as String?;
    final dateGelUtilise = gelStr != null ? DateTime.tryParse(gelStr) : null;

    final primary = (map['primary_language'] ?? map['langue_traduction']) as String? ?? 'ar';
    final secondary = map['secondary_language'] as String?;

    final profile = UserProfile(
      id: map['id'] as String? ?? 'default_user',
      primaryLanguage: primary,
      secondaryLanguage: secondary,
      objectifQuotidien: map['objectif_quotidien'] as int? ?? 10,
      themesPrioritaires: themes,
      niveauDeclare: map['niveau_declare'] as String? ?? 'B2',
      heureRappel: map['heure_rappel'] as String? ?? '19:00',
      serieJours: map['serie_jours'] as int? ?? 0,
      derniereSession: derniereSession,
      gelSerieDisponible: (map['gel_serie_disponible'] as int? ?? 1) == 1,
      dateGelUtilise: dateGelUtilise,
    );

    return profile.checkWeeklyStreakFreeze();
  }
}
