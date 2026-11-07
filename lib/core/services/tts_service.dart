import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';
import 'web_tts.dart';

/// Service audio de synthèse vocale configuré avec de vraies voix réelles natives allemandes.
/// Intègre deux locuteurs natifs authentiques haute fidélité :
/// - Conrad (Locuteur masculin natif allemand 👨)
/// - Katja (Locutrice féminine native allemande 👩)
/// - Mode Alterné Duo (alterne automatiquement Homme / Femme pour un entraînement réaliste complet).
class TtsService {
  static TtsService? _instance;
  final FlutterTts _flutterTts = FlutterTts();
  final AudioPlayer _nativeAudioPlayer = AudioPlayer();

  bool _isInitialized = false;
  int _speakGeneration = 0;
  final ValueNotifier<bool> isPlayingNotifier = ValueNotifier<bool>(false);
  VoidCallback? onCompletion;

  /// Préférence de voix : 'alternate' (recommandé), 'male' (Conrad), 'female' (Katja)
  String _voiceGenderPreference = 'alternate';
  bool _alternateState = false;

  String get voiceGenderPreference => _voiceGenderPreference;

  /// Mode hors-ligne forcé (pour tests ou déconnexion réseau simulée)
  bool forceOffline = false;

  /// Hook de test pour intercepter les appels audio de manière synchrone et déterministe
  @visibleForTesting
  void Function(String text, {bool slow, double? rate})? onSpeakForTesting;

  TtsService._();

  static TtsService get instance {
    _instance ??= TtsService._();
    return _instance!;
  }

  bool get isPlaying => isPlayingNotifier.value;

  /// Modifie la préférence de voix et la persiste dans SharedPreferences
  Future<void> setVoiceGenderPreference(String gender) async {
    _voiceGenderPreference = gender;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('tts_voice_gender', gender);
    } catch (_) {}
  }

  /// Détermine le genre de voix effectif ('male' ou 'female')
  String resolveVoiceGender({String? requestedGender, String? phraseId}) {
    if (requestedGender == 'male' || requestedGender == 'female') {
      return requestedGender!;
    }
    if (_voiceGenderPreference == 'male') return 'male';
    if (_voiceGenderPreference == 'female') return 'female';

    // Mode alterné ('alternate') : alternance déterministe par ID ou bascule
    if (phraseId != null) {
      final match = RegExp(r'\d+').firstMatch(phraseId);
      if (match != null) {
        final num = int.tryParse(match.group(0)!) ?? 1;
        return (num % 2 == 1) ? 'male' : 'female';
      }
    }
    _alternateState = !_alternateState;
    return _alternateState ? 'male' : 'female';
  }

  Future<void> init() async {
    if (_isInitialized) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      _voiceGenderPreference = prefs.getString('tts_voice_gender') ?? 'alternate';

      if (!kIsWeb) {
        await _flutterTts.setLanguage('de-DE');
        await _flutterTts.setSpeechRate(AppConstants.defaultTtsSpeedNormal);
        await _flutterTts.setVolume(1.0);
        await _flutterTts.setPitch(1.0);
        await _configureGermanVoice();

        _flutterTts.setStartHandler(() {
          isPlayingNotifier.value = true;
        });

        _flutterTts.setCompletionHandler(() {
          isPlayingNotifier.value = false;
          onCompletion?.call();
        });

        _flutterTts.setCancelHandler(() {
          isPlayingNotifier.value = false;
        });

        _flutterTts.setErrorHandler((_) {
          isPlayingNotifier.value = false;
        });

        _nativeAudioPlayer.playerStateStream.listen((state) {
          if (state.processingState == ProcessingState.completed) {
            isPlayingNotifier.value = false;
            onCompletion?.call();
          }
        });
      }

      _isInitialized = true;
    } catch (e) {
      debugPrint('[TtsService] init warning: $e');
    }
  }

  /// Recherche et active explicitement une voix allemande native dans le moteur TTS local.
  /// Renvoie true si une voix allemande valide est trouvée, false sinon.
  Future<bool> _configureGermanVoice() async {
    try {
      final voices = await _flutterTts.getVoices;
      if (voices is List && voices.isNotEmpty) {
        for (final v in voices) {
          if (v is Map) {
            final locale = (v['locale'] ?? v['lang'] ?? '').toString().toLowerCase();
            final name = (v['name'] ?? '').toString().toLowerCase();
            if (locale.startsWith('de') ||
                name.contains('german') ||
                name.contains('deutsch')) {
              await _flutterTts.setVoice({
                'name': v['name'].toString(),
                'locale': (v['locale'] ?? 'de-DE').toString(),
              });
              await _flutterTts.setLanguage('de-DE');
              debugPrint('[TtsService] Voix allemande native active : ${v['name']}');
              return true;
            }
          }
        }
      }
    } catch (_) {}
    return false;
  }

  /// Récupère le chemin d'accès au fichier audio mis en cache sur disque (sauf sur web).
  Future<File?> _getCachedAudioFile(String cleanText) async {
    if (kIsWeb) return null;
    try {
      final tempDir = await getTemporaryDirectory();
      final cacheDir = Directory('${tempDir.path}/tts_audio_cache');
      if (!cacheDir.existsSync()) {
        await cacheDir.create(recursive: true);
      }
      final hash = cleanText.hashCode.abs();
      return File('${cacheDir.path}/de_$hash.mp3');
    } catch (_) {
      return null;
    }
  }

  /// Lit la phrase avec une prononciation native allemande authentique (Conrad Homme ou Katja Femme).
  /// Prise en charge de vitesses personnalisées :
  /// - Normal : 1.0 (rythme d'un vrai allemand natif)
  /// - Lent : 0.65 (apprentissage clair)
  /// - Très lent : 0.45 (décomposition phonétique)
  Future<void> speak(
    String text, {
    bool slow = false,
    double? customRate,
    VoidCallback? onDone,
    String? phraseId,
    String? voiceGender,
  }) async {
    final targetRate = customRate ??
        (slow
            ? AppConstants.defaultTtsSpeedSlow
            : AppConstants.defaultTtsSpeedNormal);

    final cleanText = text.replaceAll(RegExp(r'[#*_]'), '').trim();

    if (onSpeakForTesting != null) {
      onSpeakForTesting!(cleanText, slow: slow, rate: targetRate);
      isPlayingNotifier.value = false;
      onDone?.call();
      return;
    }

    final currentGen = ++_speakGeneration;
    await init();
    await stop();

    onCompletion = onDone;
    isPlayingNotifier.value = true;

    final resolvedGender = resolveVoiceGender(requestedGender: voiceGender, phraseId: phraseId);

    // 1. Sur le Web : utilisation directe du player audio natif allemand (Studio Conrad Homme ou Katja Femme)
    if (kIsWeb) {
      try {
        await WebTtsAudio.play(
          cleanText,
          targetRate,
          phraseId: phraseId,
          voiceGender: resolvedGender,
        );
      } catch (e) {
        debugPrint('[TtsService] WebTtsAudio error: $e');
      } finally {
        if (currentGen == _speakGeneration) {
          isPlayingNotifier.value = false;
          onDone?.call();
        }
      }
      return;
    }

    // 2. Sur mobile / desktop : Chargement direct du fichier studio local ou cache
    if (!kIsWeb && !forceOffline) {
      try {
        if (phraseId != null && phraseId.startsWith('phrase_')) {
          await _nativeAudioPlayer.stop();
          await _nativeAudioPlayer.setAsset('assets/audio/$resolvedGender/$phraseId.mp3');
          await _nativeAudioPlayer.setSpeed(targetRate.clamp(0.35, 2.0));
          await _nativeAudioPlayer.play();
          return;
        }

        final cachedFile = await _getCachedAudioFile('${resolvedGender}_$cleanText');
        if (cachedFile != null && cachedFile.existsSync() && cachedFile.lengthSync() > 100) {
          await _nativeAudioPlayer.stop();
          await _nativeAudioPlayer.setFilePath(cachedFile.path);
          await _nativeAudioPlayer.setSpeed(targetRate.clamp(0.35, 2.0));
          await _nativeAudioPlayer.play();
          return;
        }
      } catch (e) {
        debugPrint('[TtsService] Local asset error: $e');
      }
    }

    // 3. Repli STRICT sur TTS local allemand (100% hors-ligne, moteur local du téléphone)
    try {
      final hasGermanVoice = await _configureGermanVoice();
      if (!hasGermanVoice) {
        debugPrint('[TtsService] ATTENTION : Aucune voix allemande installée sur ce système. Blocage strict de la voix française par défaut.');
        isPlayingNotifier.value = false;
        onDone?.call();
        return;
      }

      await _flutterTts.stop();
      await _flutterTts.setSpeechRate(targetRate.clamp(0.2, 1.0));
      await _flutterTts.setPitch(resolvedGender == 'female' ? 1.05 : 0.92);
      await _flutterTts.speak(cleanText);
    } catch (e) {
      debugPrint('[TtsService] FlutterTts fallback error: $e');
      isPlayingNotifier.value = false;
      onDone?.call();
    }
  }

  /// Vérifie si une voix allemande locale est installée et utilisable hors-ligne.
  Future<bool> checkGermanVoiceAvailable() async {
    await init();
    return await _configureGermanVoice();
  }

  /// Retourne le nombre de fichiers audio allemands stockés dans le cache hors-ligne.
  Future<int> getCachedAudioCount() async {
    if (kIsWeb) return 0;
    try {
      final tempDir = await getTemporaryDirectory();
      final cacheDir = Directory('${tempDir.path}/tts_audio_cache');
      if (!cacheDir.existsSync()) return 0;
      return cacheDir.listSync().whereType<File>().length;
    } catch (_) {
      return 0;
    }
  }

  /// Vide le cache audio hors-ligne.
  Future<void> clearAudioCache() async {
    if (kIsWeb) return;
    try {
      final tempDir = await getTemporaryDirectory();
      final cacheDir = Directory('${tempDir.path}/tts_audio_cache');
      if (cacheDir.existsSync()) {
        await cacheDir.delete(recursive: true);
      }
    } catch (_) {}
  }

  /// Lit la phrase à un débit spécifique (ex. 0.45, 0.65, 1.0).
  Future<void> speakAtRate(
    String text, {
    required double speechRate,
    VoidCallback? onDone,
  }) async {
    await speak(text, customRate: speechRate, onDone: onDone);
  }

  Future<void> stop() async {
    _speakGeneration++;
    try {
      if (kIsWeb) {
        WebTtsAudio.stop();
      }
      await _nativeAudioPlayer.stop();
      await _flutterTts.stop();
    } catch (_) {
    } finally {
      isPlayingNotifier.value = false;
    }
  }

  void dispose() {
    stop();
    _nativeAudioPlayer.dispose();
    _flutterTts.stop();
    isPlayingNotifier.dispose();
  }
}
