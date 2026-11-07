import '../../domain/models/phrase.dart';
import '../../domain/models/user_phrase.dart';
import '../../domain/models/user_profile.dart';
import '../database/app_database.dart';

/// Dépôt de données pour les phrases et la progression de l'utilisateur.
class PhraseRepository {
  final AppDatabase _database;

  PhraseRepository({AppDatabase? database})
      : _database = database ?? AppDatabase.instance;

  Future<int> initializeAndImport() async {
    return await _database.importPhrasesFromJson();
  }

  /// Importe un lot JSON avec déduplication stricte par de_standard (Section 6).
  Future<int> importBatch({String? jsonContent}) async {
    return await _database.importPhrasesFromJson(jsonContent: jsonContent);
  }

  /// Compte le nombre de phrases en base.
  Future<int> countPhrases() async {
    return await _database.countPhrases();
  }

  Future<List<Phrase>> getAllPhrases() async {
    return await _database.getAllPhrases();
  }

  Future<Phrase?> getPhraseById(String id) async {
    return await _database.getPhraseById(id);
  }

  Future<void> savePhrase(Phrase phrase) async {
    await _database.savePhrase(phrase);
  }

  Future<void> deletePhrase(String id) async {
    await _database.deletePhrase(id);
  }

  Future<Map<String, UserPhrase>> getAllUserPhrases() async {
    return await _database.getAllUserPhrases();
  }

  Future<void> saveUserPhrase(UserPhrase userPhrase) async {
    await _database.saveUserPhrase(userPhrase);
  }

  /// Récupère la progression utilisateur (Table progression).
  Future<Map<String, UserPhrase>> getAllProgression({String userId = 'default_user'}) async {
    return await _database.getAllProgression(userId: userId);
  }

  /// Enregistre la progression d'une phrase (Table progression).
  Future<void> saveProgression(UserPhrase phrase, {String userId = 'default_user'}) async {
    await _database.saveProgression(phrase, userId: userId);
  }

  /// Récupère le profil utilisateur (Table utilisateur).
  Future<UserProfile> getUserProfile({String userId = 'default_user'}) async {
    return await _database.getUserProfile(userId: userId);
  }

  /// Enregistre le profil utilisateur (Table utilisateur).
  Future<void> saveUserProfile(UserProfile profile) async {
    await _database.saveUserProfile(profile);
  }
}

