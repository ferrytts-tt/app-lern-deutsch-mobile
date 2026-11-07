/// Modèle de données pour la rubrique « Chansons & Dialogues ».
/// Gère le manifest, les items audio, les transcriptions synchronisées
/// et les licences de distribution.
library;

enum MediaLicenseStatus {
  enAttente('en_attente'),
  approuve('approuve'),
  retire('retire');

  final String value;
  const MediaLicenseStatus(this.value);

  static MediaLicenseStatus fromString(String? val) {
    switch (val?.toLowerCase().trim()) {
      case 'approuve':
      case 'approuvé':
        return MediaLicenseStatus.approuve;
      case 'retire':
      case 'retiré':
        return MediaLicenseStatus.retire;
      case 'en_attente':
      default:
        return MediaLicenseStatus.enAttente;
    }
  }

  bool get isApproved => this == MediaLicenseStatus.approuve;
}

enum MediaType {
  dialogue('dialogue'),
  chanson('chanson');

  final String value;
  const MediaType(this.value);

  static MediaType fromString(String? val) {
    switch (val?.toLowerCase().trim()) {
      case 'chanson':
      case 'song':
        return MediaType.chanson;
      case 'dialogue':
      default:
        return MediaType.dialogue;
    }
  }
}

/// Représente un contenu audio déclaré dans manifest.json
class MediaItem {
  final int lotId;
  final MediaType type;
  final String audioFile;
  final String? audioSlowFile;
  final String contentJsonFile;
  final int durationSeconds;
  final int sizeBytes;
  final String checksum;
  final String? checksumSlow;
  final int version;
  final MediaLicenseStatus statutLicence;
  final String source;
  final String createdAt;
  final String? titleDe;
  final String? titleAr;
  final String? titleFr;

  const MediaItem({
    required this.lotId,
    required this.type,
    required this.audioFile,
    this.audioSlowFile,
    required this.contentJsonFile,
    required this.durationSeconds,
    required this.sizeBytes,
    required this.checksum,
    this.checksumSlow,
    required this.version,
    required this.statutLicence,
    required this.source,
    required this.createdAt,
    this.titleDe,
    this.titleAr,
    this.titleFr,
  });

  bool get isApproved => statutLicence.isApproved;

  factory MediaItem.fromJson(Map<String, dynamic> json) {
    return MediaItem(
      lotId: json['lot_id'] is int ? json['lot_id'] as int : int.parse(json['lot_id'].toString().replaceAll(RegExp(r'[^0-9]'), '')),
      type: MediaType.fromString(json['type'] as String?),
      audioFile: json['audio_file'] as String? ?? json['fichier_audio'] as String? ?? '',
      audioSlowFile: json['audio_slow_file'] as String? ?? json['fichier_audio_lent'] as String?,
      contentJsonFile: json['content_json_file'] as String? ?? json['fichier_texte'] as String? ?? '',
      durationSeconds: (json['duration_seconds'] ?? json['duree_secondes'] ?? 0) as int,
      sizeBytes: (json['size_bytes'] ?? json['taille_octets'] ?? 0) as int,
      checksum: json['checksum'] as String? ?? '',
      checksumSlow: json['checksum_slow'] as String?,
      version: (json['version'] ?? 1) as int,
      statutLicence: MediaLicenseStatus.fromString(json['statut_licence'] as String?),
      source: json['source'] as String? ?? 'inconnu',
      createdAt: json['created_at'] as String? ?? json['date_creation'] as String? ?? '',
      titleDe: json['title_de'] as String? ?? json['titre_de'] as String?,
      titleAr: json['title_ar'] as String? ?? json['titre_ar'] as String?,
      titleFr: json['title_fr'] as String? ?? json['titre_fr'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'lot_id': lotId,
      'type': type.value,
      'audio_file': audioFile,
      if (audioSlowFile != null) 'audio_slow_file': audioSlowFile,
      'content_json_file': contentJsonFile,
      'duration_seconds': durationSeconds,
      'size_bytes': sizeBytes,
      'checksum': checksum,
      if (checksumSlow != null) 'checksum_slow': checksumSlow,
      'version': version,
      'statut_licence': statutLicence.value,
      'source': source,
      'created_at': createdAt,
      if (titleDe != null) 'title_de': titleDe,
      if (titleAr != null) 'title_ar': titleAr,
      if (titleFr != null) 'title_fr': titleFr,
    };
  }

  MediaItem copyWith({
    int? lotId,
    MediaType? type,
    String? audioFile,
    String? audioSlowFile,
    String? contentJsonFile,
    int? durationSeconds,
    int? sizeBytes,
    String? checksum,
    String? checksumSlow,
    int? version,
    MediaLicenseStatus? statutLicence,
    String? source,
    String? createdAt,
    String? titleDe,
    String? titleAr,
    String? titleFr,
  }) {
    return MediaItem(
      lotId: lotId ?? this.lotId,
      type: type ?? this.type,
      audioFile: audioFile ?? this.audioFile,
      audioSlowFile: audioSlowFile ?? this.audioSlowFile,
      contentJsonFile: contentJsonFile ?? this.contentJsonFile,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      checksum: checksum ?? this.checksum,
      checksumSlow: checksumSlow ?? this.checksumSlow,
      version: version ?? this.version,
      statutLicence: statutLicence ?? this.statutLicence,
      source: source ?? this.source,
      createdAt: createdAt ?? this.createdAt,
      titleDe: titleDe ?? this.titleDe,
      titleAr: titleAr ?? this.titleAr,
      titleFr: titleFr ?? this.titleFr,
    );
  }
}

/// Représente le manifest global (manifest.json)
class MediaManifest {
  final int version;
  final String updatedAt;
  final List<MediaItem> contents;

  const MediaManifest({
    required this.version,
    required this.updatedAt,
    required this.contents,
  });

  /// Ne conserve que les contenus approuvés par licence
  List<MediaItem> get approvedContents =>
      contents.where((c) => c.isApproved).toList();

  factory MediaManifest.fromJson(Map<String, dynamic> json) {
    final list = json['contents'] as List? ?? json['contenus'] as List? ?? [];
    return MediaManifest(
      version: (json['version'] ?? 1) as int,
      updatedAt: json['updated_at'] as String? ?? json['mise_a_jour'] as String? ?? '',
      contents: list.map((e) => MediaItem.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'version': version,
      'updated_at': updatedAt,
      'contents': contents.map((c) => c.toJson()).toList(),
    };
  }
}

/// Ligne de transcription synchronisée
class TranscriptLine {
  final String locuteur; // Conrad, Katja, Chant, etc.
  final String de;
  final String ar;
  final String fr;
  final int debutMs;
  final int finMs;
  final String? phraseId; // ex: phrase_001 si présent dans le lot, null sinon

  const TranscriptLine({
    required this.locuteur,
    required this.de,
    required this.ar,
    required this.fr,
    required this.debutMs,
    required this.finMs,
    this.phraseId,
  });

  bool get hasPhraseLink => phraseId != null && phraseId!.trim().isNotEmpty;

  int get durationMs => finMs - debutMs;

  factory TranscriptLine.fromJson(Map<String, dynamic> json) {
    final pid = json['phrase_id'] as String?;
    return TranscriptLine(
      locuteur: json['locuteur'] as String? ?? json['speaker'] as String? ?? '',
      de: json['de'] as String? ?? '',
      ar: json['ar'] as String? ?? '',
      fr: json['fr'] as String? ?? '',
      debutMs: (json['debut_ms'] ?? json['start_ms'] ?? 0) as int,
      finMs: (json['fin_ms'] ?? json['end_ms'] ?? 0) as int,
      phraseId: (pid != null && pid.trim().isNotEmpty) ? pid.trim() : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'locuteur': locuteur,
      'de': de,
      'ar': ar,
      'fr': fr,
      'debut_ms': debutMs,
      'fin_ms': finMs,
      'phrase_id': phraseId ?? '',
    };
  }
}

/// Contenu textuel d'un lot (lot_XXX_dialogue.json ou lot_XXX_chanson.json)
class MediaTranscript {
  final int lotId;
  final MediaType type;
  final String titleDe;
  final String titleAr;
  final String titleFr;
  final List<TranscriptLine> lignes;

  const MediaTranscript({
    required this.lotId,
    required this.type,
    required this.titleDe,
    required this.titleAr,
    required this.titleFr,
    required this.lignes,
  });

  factory MediaTranscript.fromJson(Map<String, dynamic> json) {
    final rawLines = json['lignes'] as List? ?? json['lines'] as List? ?? [];
    return MediaTranscript(
      lotId: json['lot_id'] is int ? json['lot_id'] as int : int.parse(json['lot_id'].toString().replaceAll(RegExp(r'[^0-9]'), '')),
      type: MediaType.fromString(json['type'] as String?),
      titleDe: json['title_de'] as String? ?? json['titre_de'] as String? ?? '',
      titleAr: json['title_ar'] as String? ?? json['titre_ar'] as String? ?? '',
      titleFr: json['title_fr'] as String? ?? json['titre_fr'] as String? ?? '',
      lignes: rawLines.map((e) => TranscriptLine.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'lot_id': lotId,
      'type': type.value,
      'title_de': titleDe,
      'title_ar': titleAr,
      'title_fr': titleFr,
      'lignes': lignes.map((l) => l.toJson()).toList(),
    };
  }

  /// Retourne tous les IDs de phrases du lot référencés dans la transcription
  Set<String> get referencedPhraseIds =>
      lignes.where((l) => l.hasPhraseLink).map((l) => l.phraseId!).toSet();
}
