import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../domain/models/media_content.dart';
import '../data/media_repository.dart';

enum TranslationDisplayMode {
  arabe('arabe', '🇸🇦 Arabe'),
  francais('francais', '🇫🇷 Français'),
  aucune('aucune', '🚫 Sans traduction');

  final String id;
  final String label;
  const TranslationDisplayMode(this.id, this.label);
}

class MediaPlayerState {
  final MediaItem? currentItem;
  final MediaTranscript? transcript;
  final bool isLoading;
  final bool isPlaying;
  final Duration position;
  final Duration duration;
  final double speed;
  final bool isLooping;
  final TranslationDisplayMode translationMode;
  final bool isListenFirstMode;
  final bool isGermanRevealed;
  final int activeLineIndex;
  final String? errorMessage;
  final double playbackProgress; // 0.0 to 1.0

  const MediaPlayerState({
    this.currentItem,
    this.transcript,
    this.isLoading = false,
    this.isPlaying = false,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.speed = 1.0,
    this.isLooping = false,
    this.translationMode = TranslationDisplayMode.arabe,
    this.isListenFirstMode = false,
    this.isGermanRevealed = false,
    this.activeLineIndex = -1,
    this.errorMessage,
    this.playbackProgress = 0.0,
  });

  MediaPlayerState copyWith({
    MediaItem? currentItem,
    MediaTranscript? transcript,
    bool? isLoading,
    bool? isPlaying,
    Duration? position,
    Duration? duration,
    double? speed,
    bool? isLooping,
    TranslationDisplayMode? translationMode,
    bool? isListenFirstMode,
    bool? isGermanRevealed,
    int? activeLineIndex,
    String? errorMessage,
    double? playbackProgress,
  }) {
    return MediaPlayerState(
      currentItem: currentItem ?? this.currentItem,
      transcript: transcript ?? this.transcript,
      isLoading: isLoading ?? this.isLoading,
      isPlaying: isPlaying ?? this.isPlaying,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      speed: speed ?? this.speed,
      isLooping: isLooping ?? this.isLooping,
      translationMode: translationMode ?? this.translationMode,
      isListenFirstMode: isListenFirstMode ?? this.isListenFirstMode,
      isGermanRevealed: isGermanRevealed ?? this.isGermanRevealed,
      activeLineIndex: activeLineIndex ?? this.activeLineIndex,
      errorMessage: errorMessage,
      playbackProgress: playbackProgress ?? this.playbackProgress,
    );
  }
}

final mediaPlayerControllerProvider =
    StateNotifierProvider.autoDispose<MediaPlayerController, MediaPlayerState>((ref) {
  return MediaPlayerController(MediaRepository());
});

class MediaPlayerController extends StateNotifier<MediaPlayerState> {
  final MediaRepository _repository;
  final AudioPlayer _audioPlayer;

  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<PlayerState>? _playerStateSub;
  StreamSubscription<Duration?>? _durationSub;

  MediaPlayerController(this._repository)
      : _audioPlayer = AudioPlayer(),
        super(const MediaPlayerState()) {
    _initAudioStreams();
  }

  void _initAudioStreams() {
    _positionSub = _audioPlayer.positionStream.listen((pos) {
      if (!mounted) return;
      final dur = state.duration;
      final progress = dur.inMilliseconds > 0
          ? (pos.inMilliseconds / dur.inMilliseconds).clamp(0.0, 1.0)
          : 0.0;

      final lineIdx = _computeActiveLineIndex(pos.inMilliseconds);

      state = state.copyWith(
        position: pos,
        playbackProgress: progress,
        activeLineIndex: lineIdx,
      );

      // Si le mode écoute d'abord est actif et qu'on atteint la fin, révéler automatiquement
      if (state.isListenFirstMode && progress >= 0.95 && !state.isGermanRevealed) {
        state = state.copyWith(isGermanRevealed: true);
      }
    });

    _durationSub = _audioPlayer.durationStream.listen((dur) {
      if (!mounted || dur == null) return;
      state = state.copyWith(duration: dur);
    });

    _playerStateSub = _audioPlayer.playerStateStream.listen((playerState) {
      if (!mounted) return;
      final isPlaying = playerState.playing &&
          playerState.processingState != ProcessingState.completed;
      state = state.copyWith(isPlaying: isPlaying);

      // Gestion de fin de lecture
      if (playerState.processingState == ProcessingState.completed) {
        if (state.isLooping) {
          seek(Duration.zero);
          play();
        } else {
          _saveLastPosition(Duration.zero);
        }
      }
    });
  }

  int _computeActiveLineIndex(int currentMs) {
    final lines = state.transcript?.lignes;
    if (lines == null || lines.isEmpty) return -1;

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (currentMs >= line.debutMs && currentMs < line.finMs) {
        return i;
      }
    }
    // Si entre deux répliques, pointer vers la dernière passée
    for (int i = lines.length - 1; i >= 0; i--) {
      if (currentMs >= lines[i].finMs) {
        return i;
      }
    }
    return 0;
  }

  /// Charge un contenu média (Dialogue ou Chanson)
  Future<void> loadContent(MediaItem item, {bool autoPlay = false}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      // 1. Charger la transcription
      final transcript = await _repository.loadTranscript(item);

      // 2. Préparer l'audio
      final assetPath = MediaRepository.getAudioAssetPath(item.audioFile, item: item);
      await _audioPlayer.setAsset(assetPath);
      await _audioPlayer.setSpeed(state.speed);

      // 3. Récupérer la dernière position mémorisée
      final lastPos = await _getLastSavedPosition(item);

      state = state.copyWith(
        currentItem: item,
        transcript: transcript,
        isLoading: false,
        duration: _audioPlayer.duration ?? Duration(seconds: item.durationSeconds),
        position: lastPos,
        isGermanRevealed: !state.isListenFirstMode,
      );

      if (lastPos > Duration.zero) {
        await _audioPlayer.seek(lastPos);
      }

      if (autoPlay) {
        await play();
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Impossible de charger le fichier audio : $e',
      );
    }
  }

  Future<void> play() async {
    try {
      await _audioPlayer.play();
    } catch (e) {
      debugPrint('MediaPlayerController.play error: $e');
    }
  }

  Future<void> pause() async {
    try {
      await _audioPlayer.pause();
      if (state.currentItem != null) {
        _saveLastPosition(state.position);
      }
    } catch (e) {
      debugPrint('MediaPlayerController.pause error: $e');
    }
  }

  Future<void> togglePlayPause() async {
    if (state.isPlaying) {
      await pause();
    } else {
      await play();
    }
  }

  Future<void> seek(Duration position) async {
    try {
      await _audioPlayer.seek(position);
      if (state.currentItem != null) {
        _saveLastPosition(position);
      }
    } catch (e) {
      debugPrint('MediaPlayerController.seek error: $e');
    }
  }

  /// Rejoue une ligne précise en un appui
  Future<void> seekToLine(int lineIndex) async {
    final lines = state.transcript?.lignes;
    if (lines == null || lineIndex < 0 || lineIndex >= lines.length) return;

    final line = lines[lineIndex];
    final targetPos = Duration(milliseconds: line.debutMs);
    await seek(targetPos);
    if (!state.isPlaying) {
      await play();
    }
  }

  /// Avancer ou reculer de 5 secondes
  Future<void> seekRelative(int seconds) async {
    final newPos = state.position + Duration(seconds: seconds);
    final clamped = newPos < Duration.zero
        ? Duration.zero
        : (newPos > state.duration ? state.duration : newPos);
    await seek(clamped);
  }

  /// Basculer la vitesse entre 0.75x et 1.0x
  Future<void> toggleSpeed() async {
    final newSpeed = state.speed == 1.0 ? 0.75 : 1.0;
    await setSpeed(newSpeed);
  }

  Future<void> setSpeed(double speed) async {
    try {
      await _audioPlayer.setSpeed(speed);
      state = state.copyWith(speed: speed);
    } catch (e) {
      debugPrint('MediaPlayerController.setSpeed error: $e');
    }
  }

  /// Basculer le mode boucle
  void toggleLoop() {
    final newLoop = !state.isLooping;
    _audioPlayer.setLoopMode(newLoop ? LoopMode.one : LoopMode.off);
    state = state.copyWith(isLooping: newLoop);
  }

  /// Changer le mode de traduction (arabe, français, aucune)
  void setTranslationMode(TranslationDisplayMode mode) {
    state = state.copyWith(translationMode: mode);
  }

  void cycleTranslationMode() {
    switch (state.translationMode) {
      case TranslationDisplayMode.arabe:
        setTranslationMode(TranslationDisplayMode.francais);
        break;
      case TranslationDisplayMode.francais:
        setTranslationMode(TranslationDisplayMode.aucune);
        break;
      case TranslationDisplayMode.aucune:
        setTranslationMode(TranslationDisplayMode.arabe);
        break;
    }
  }

  /// Mode « Écoute d'abord » : masque le texte allemand
  void toggleListenFirstMode() {
    final next = !state.isListenFirstMode;
    state = state.copyWith(
      isListenFirstMode: next,
      isGermanRevealed: !next,
    );
  }

  /// Dévoiler manuellement le texte allemand en mode écoute d'abord
  void revealGermanText() {
    state = state.copyWith(isGermanRevealed: true);
  }

  // Persistance de la dernière position d'écoute par lot & type
  String _posKey(MediaItem item) => 'media_last_pos_${item.lotId}_${item.type.value}';

  Future<void> _saveLastPosition(Duration pos) async {
    if (state.currentItem == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_posKey(state.currentItem!), pos.inMilliseconds);
    } catch (_) {}
  }

  Future<Duration> _getLastSavedPosition(MediaItem item) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ms = prefs.getInt(_posKey(item)) ?? 0;
      return Duration(milliseconds: ms);
    } catch (_) {
      return Duration.zero;
    }
  }

  @override
  void dispose() {
    if (state.currentItem != null) {
      _saveLastPosition(state.position);
    }
    _positionSub?.cancel();
    _playerStateSub?.cancel();
    _durationSub?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }
}
