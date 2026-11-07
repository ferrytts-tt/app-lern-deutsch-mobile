import 'package:flutter/material.dart';

/// Les thèmes pédagogiques de Deutsch Fast.
class TopicInfo {
  final String id;
  final String title;
  final String germanTitle;
  final IconData icon;
  final Color themeColor;
  final int order;

  const TopicInfo({
    required this.id,
    required this.title,
    required this.germanTitle,
    required this.icon,
    required this.themeColor,
    required this.order,
  });

  static const List<TopicInfo> defaultTopics = [
    TopicInfo(
      id: 'salutations',
      title: 'Salutations & Smalltalk',
      germanTitle: 'Begrüßung & Smalltalk',
      icon: Icons.waving_hand_rounded,
      themeColor: Color(0xFF2FA866),
      order: 1,
    ),
    TopicInfo(
      id: 'se_presenter',
      title: 'Se présenter',
      germanTitle: 'Vorstellung',
      icon: Icons.person_rounded,
      themeColor: Color(0xFF2F80ED),
      order: 2,
    ),
    TopicInfo(
      id: 'comprendre',
      title: 'Comprendre & Téléphone',
      germanTitle: 'Verständigung & Telefon',
      icon: Icons.chat_bubble_rounded,
      themeColor: Color(0xFFFFC83D),
      order: 3,
    ),
    TopicInfo(
      id: 'restaurant',
      title: 'Au restaurant & Café',
      germanTitle: 'Restaurant & Café',
      icon: Icons.restaurant_rounded,
      themeColor: Color(0xFF2FA866),
      order: 4,
    ),
    TopicInfo(
      id: 'directions',
      title: 'Directions',
      germanTitle: 'Wegbeschreibung',
      icon: Icons.explore_rounded,
      themeColor: Color(0xFF2F80ED),
      order: 5,
    ),
    TopicInfo(
      id: 'achats',
      title: 'Achats & Argent',
      germanTitle: 'Einkaufen & Geld',
      icon: Icons.shopping_bag_rounded,
      themeColor: Color(0xFFFFC83D),
      order: 6,
    ),
    TopicInfo(
      id: 'transports',
      title: 'Transports & Déplacements',
      germanTitle: 'Reisen & Verkehr',
      icon: Icons.train_rounded,
      themeColor: Color(0xFF2FA866),
      order: 7,
    ),
    TopicInfo(
      id: 'urgences',
      title: 'Urgences & Santé',
      germanTitle: 'Notfall & Gesundheit',
      icon: Icons.local_hospital_rounded,
      themeColor: Color(0xFFF59E4B),
      order: 8,
    ),
    TopicInfo(
      id: 'quotidien',
      title: 'Vie quotidienne & Démarches',
      germanTitle: 'Alltag & Behörden',
      icon: Icons.home_rounded,
      themeColor: Color(0xFF2F80ED),
      order: 9,
    ),
    TopicInfo(
      id: 'travail',
      title: 'Travail & Bureau',
      germanTitle: 'Arbeit & Beruf',
      icon: Icons.work_rounded,
      themeColor: Color(0xFF2FA866),
      order: 10,
    ),
    TopicInfo(
      id: 'loisirs',
      title: 'Avis & Opinions',
      germanTitle: 'Meinungen & Reaktionen',
      icon: Icons.forum_rounded,
      themeColor: Color(0xFFFFC83D),
      order: 11,
    ),
    TopicInfo(
      id: 'famille',
      title: 'Amis & Famille',
      germanTitle: 'Freunde & Familie',
      icon: Icons.groups_rounded,
      themeColor: Color(0xFF2F80ED),
      order: 12,
    ),
    TopicInfo(
      id: 'sentiments',
      title: 'Émotions & Sentiments',
      germanTitle: 'Gefühle & Emotionen',
      icon: Icons.mood_rounded,
      themeColor: Color(0xFF2FA866),
      order: 13,
    ),
    TopicInfo(
      id: 'conversation_serieuse',
      title: 'Conversation sérieuse',
      germanTitle: 'Ernstes Gespräch',
      icon: Icons.record_voice_over_rounded,
      themeColor: Color(0xFF2F80ED),
      order: 14,
    ),
    TopicInfo(
      id: 'famille_maison',
      title: 'Famille & Maison',
      germanTitle: 'Familie & Zuhause',
      icon: Icons.home_work_rounded,
      themeColor: Color(0xFF2FA866),
      order: 15,
    ),
    TopicInfo(
      id: 'courses_argent',
      title: 'Courses & Argent',
      germanTitle: 'Einkaufen & Geld',
      icon: Icons.shopping_cart_rounded,
      themeColor: Color(0xFFFFC83D),
      order: 16,
    ),
    TopicInfo(
      id: 'loisirs_sport',
      title: 'Loisirs & Sport',
      germanTitle: 'Freizeit & Sport',
      icon: Icons.fitness_center_rounded,
      themeColor: Color(0xFFF59E4B),
      order: 17,
    ),
    TopicInfo(
      id: 'reactions',
      title: 'Réactions spontanées',
      germanTitle: 'Spontane Reaktionen',
      icon: Icons.bolt_rounded,
      themeColor: Color(0xFF9C27B0),
      order: 18,
    ),
    TopicInfo(
      id: 'travail_admin',
      title: 'Travail & Démarches',
      germanTitle: 'Arbeit & Formalitäten',
      icon: Icons.business_center_rounded,
      themeColor: Color(0xFF2F80ED),
      order: 19,
    ),
    TopicInfo(
      id: 'vie_quotidienne',
      title: 'Vie quotidienne',
      germanTitle: 'Tägliches Leben',
      icon: Icons.wb_sunny_rounded,
      themeColor: Color(0xFF2FA866),
      order: 20,
    ),
    TopicInfo(
      id: 'jeunes',
      title: 'Langage des jeunes',
      germanTitle: 'Jugendsprache',
      icon: Icons.chat_bubble_rounded,
      themeColor: Color(0xFFF59E4B),
      order: 21,
    ),
    TopicInfo(
      id: 'camarades',
      title: 'Camarades & Sorties',
      germanTitle: 'Freunde & Unterwegs',
      icon: Icons.groups_rounded,
      themeColor: Color(0xFF2F80ED),
      order: 22,
    ),
    TopicInfo(
      id: 'ecole',
      title: 'École & Études',
      germanTitle: 'Schule & Studium',
      icon: Icons.school_rounded,
      themeColor: Color(0xFF9C27B0),
      order: 23,
    ),
    TopicInfo(
      id: 'maison_reseaux',
      title: 'Maison & Réseaux',
      germanTitle: 'Zuhause & Medien',
      icon: Icons.home_rounded,
      themeColor: Color(0xFFFFC83D),
      order: 24,
    ),
    TopicInfo(
      id: 'gare_train',
      title: 'Gare & Train',
      germanTitle: 'Bahnhof & Bahn',
      icon: Icons.train_rounded,
      themeColor: Color(0xFF2F80ED),
      order: 25,
    ),
    TopicInfo(
      id: 'metro_bus',
      title: 'Métro & Bus',
      germanTitle: 'U-Bahn & Bus',
      icon: Icons.directions_bus_rounded,
      themeColor: Color(0xFF2FA866),
      order: 26,
    ),
    TopicInfo(
      id: 'aeroport',
      title: 'Aéroport & Vol',
      germanTitle: 'Flughafen & Flug',
      icon: Icons.flight_takeoff_rounded,
      themeColor: Color(0xFFF59E4B),
      order: 27,
    ),
    TopicInfo(
      id: 'taxi',
      title: 'Taxi & Déplacements',
      germanTitle: 'Taxi & Fahrt',
      icon: Icons.local_taxi_rounded,
      themeColor: Color(0xFFFFC83D),
      order: 28,
    ),
    TopicInfo(
      id: 'telephone',
      title: 'Téléphone & Appels',
      germanTitle: 'Telefon & Anrufe',
      icon: Icons.phone_rounded,
      themeColor: Color(0xFF2F80ED),
      order: 29,
    ),
    TopicInfo(
      id: 'rue_orientation',
      title: 'Rue & Orientation',
      germanTitle: 'Wegbeschreibung',
      icon: Icons.explore_rounded,
      themeColor: Color(0xFF2FA866),
      order: 30,
    ),
  ];

  static List<TopicInfo> _topics = List.from(defaultTopics);

  /// Liste dynamique de toutes les catégories (administrables).
  static List<TopicInfo> get allTopics => _topics;

  static set allTopics(List<TopicInfo> topics) {
    _topics = List.from(topics);
  }

  static TopicInfo getById(String id) {
    final matches = _topics.where((t) => t.id == id);
    if (matches.isNotEmpty) {
      return matches.first;
    }
    // Fallback avec titre propre
    return TopicInfo(
      id: id,
      title: id.replaceAll('_', ' '),
      germanTitle: id,
      icon: Icons.folder_rounded,
      themeColor: const Color(0xFF2FA866),
      order: 99,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'german_title': germanTitle,
      'icon_code': icon.codePoint,
      'color_value': themeColor.toARGB32(),
      'topic_order': order,
    };
  }

  static const List<IconData> selectableIcons = [
    Icons.waving_hand_rounded,
    Icons.person_rounded,
    Icons.chat_bubble_rounded,
    Icons.restaurant_rounded,
    Icons.explore_rounded,
    Icons.shopping_bag_rounded,
    Icons.train_rounded,
    Icons.local_hospital_rounded,
    Icons.home_rounded,
    Icons.work_rounded,
    Icons.sports_esports_rounded,
    Icons.groups_rounded,
    Icons.favorite_rounded,
    Icons.flight_takeoff_rounded,
    Icons.hotel_rounded,
    Icons.school_rounded,
    Icons.menu_book_rounded,
    Icons.music_note_rounded,
    Icons.pets_rounded,
    Icons.nature_rounded,
    Icons.folder_rounded,
  ];

  static IconData iconFromCode(int? code) {
    if (code == null) return Icons.folder_rounded;
    for (final icon in selectableIcons) {
      if (icon.codePoint == code) return icon;
    }
    return Icons.folder_rounded;
  }

  factory TopicInfo.fromMap(Map<String, dynamic> map) {
    return TopicInfo(
      id: map['id'] as String,
      title: map['title'] as String,
      germanTitle: map['german_title'] as String? ?? '',
      icon: iconFromCode(map['icon_code'] as int?),
      themeColor: Color(map['color_value'] as int? ?? 0xFF2FA866),
      order: map['topic_order'] as int? ?? 1,
    );
  }

  TopicInfo copyWith({
    String? id,
    String? title,
    String? germanTitle,
    IconData? icon,
    Color? themeColor,
    int? order,
  }) {
    return TopicInfo(
      id: id ?? this.id,
      title: title ?? this.title,
      germanTitle: germanTitle ?? this.germanTitle,
      icon: icon ?? this.icon,
      themeColor: themeColor ?? this.themeColor,
      order: order ?? this.order,
    );
  }
}
