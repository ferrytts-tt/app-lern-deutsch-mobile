import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import '../../../domain/models/media_content.dart';

/// Repository chargé de charger, filtrer et valider les contenus audio
/// de la rubrique « Chansons & Dialogues ».
class MediaRepository {
  static const String manifestAssetPath = 'assets/media/manifest.json';
  static const String mediaAssetsPrefix = 'assets/media/';
  static const String audioAssetsPrefix = 'assets/media/audio/';

  MediaManifest? _cachedManifest;

  /// Charge le manifest et filtre STRICTEMENT les contenus approuvés.
  /// Un contenu avec statut `retire` ou `en_attente` n'est JAMAIS retourné.
  Future<MediaManifest> getApprovedManifest({bool forceReload = false}) async {
    if (_cachedManifest != null && !forceReload) {
      return _filterApproved(_cachedManifest!);
    }

    try {
      final jsonString = await rootBundle.loadString(manifestAssetPath);
      final dynamic decoded = jsonDecode(jsonString);
      final manifest = MediaManifest.fromJson(decoded as Map<String, dynamic>);
      _cachedManifest = manifest;
      return _filterApproved(manifest);
    } catch (e) {
      // Si le manifest est indisponible ou corrompu, retourne une structure vide sécurisée
      return const MediaManifest(version: 1, updatedAt: '', contents: []);
    }
  }

  MediaManifest _filterApproved(MediaManifest raw) {
    return MediaManifest(
      version: raw.version,
      updatedAt: raw.updatedAt,
      contents: raw.approvedContents,
    );
  }

  /// Retourne les contenus approuvés associés à un lot
  Future<List<MediaItem>> getContentsForLot(int lotId) async {
    final manifest = await getApprovedManifest();
    return manifest.contents.where((c) => c.lotId == lotId).toList();
  }

  /// Récupère le dialogue approuvé d'un lot donné
  Future<MediaItem?> getDialogueForLot(int lotId) async {
    final contents = await getContentsForLot(lotId);
    try {
      return contents.firstWhere((c) => c.type == MediaType.dialogue);
    } catch (_) {
      return null;
    }
  }

  /// Récupère la chanson approuvée d'un lot donné
  Future<MediaItem?> getChansonForLot(int lotId) async {
    final contents = await getContentsForLot(lotId);
    try {
      return contents.firstWhere((c) => c.type == MediaType.chanson);
    } catch (_) {
      return null;
    }
  }

  /// Charge et décode la transcription synchronisée (dialogue ou chanson)
  Future<MediaTranscript?> loadTranscript(MediaItem item) async {
    if (!item.isApproved) return null;

    final path = '$mediaAssetsPrefix${item.contentJsonFile}';
    try {
      final jsonString = await rootBundle.loadString(path);
      final dynamic decoded = jsonDecode(jsonString);
      return MediaTranscript.fromJson(decoded as Map<String, dynamic>);
    } catch (e) {
      return null;
    }
  }

  /// Vérifie le checksum SHA-256 d'une liste d'octets audio par rapport à l'item
  static bool verifyChecksum(List<int> bytes, String expectedChecksum) {
    if (expectedChecksum.trim().isEmpty) return false;
    final digest = sha256.convert(bytes);
    return digest.toString().toLowerCase() == expectedChecksum.trim().toLowerCase();
  }

  /// Formate le chemin asset complet vers le fichier audio
  static String getAudioAssetPath(String filename, {bool slow = false, MediaItem? item}) {
    if (slow && item != null && item.audioSlowFile != null) {
      return '$audioAssetsPrefix${item.audioSlowFile}';
    }
    return '$audioAssetsPrefix$filename';
  }
}
