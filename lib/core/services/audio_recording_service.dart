import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

/// Service de gestion du microphone pour le shadowing et la lecture de la voix.
class AudioRecordingService {
  static AudioRecordingService? _instance;
  final AudioRecorder _audioRecorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();

  final ValueNotifier<bool> isRecordingNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<bool> isPlayingRecordingNotifier = ValueNotifier<bool>(false);

  String? _lastRecordedPath;

  AudioRecordingService._();

  static AudioRecordingService get instance {
    _instance ??= AudioRecordingService._();
    return _instance!;
  }

  bool get isRecording => isRecordingNotifier.value;
  bool get isPlayingRecording => isPlayingRecordingNotifier.value;
  String? get lastRecordedPath => _lastRecordedPath;

  /// Vérifie ou demande la permission d'accès au micro.
  Future<bool> requestMicPermission() async {
    if (kIsWeb) return true;
    try {
      if (Platform.isAndroid || Platform.isIOS) {
        final status = await Permission.microphone.request();
        return status.isGranted;
      }
      return true;
    } catch (_) {
      return true;
    }
  }

  /// Démarre l'enregistrement audio.
  Future<bool> startRecording() async {
    try {
      final hasPermission = await requestMicPermission();
      if (!hasPermission) return false;

      // Arrêter toute lecture en cours
      await stopPlayback();

      final tempDir = await getTemporaryDirectory();
      final filePath = p.join(
        tempDir.path,
        'shadow_${DateTime.now().millisecondsSinceEpoch}.m4a',
      );

      const config = RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 128000,
        sampleRate: 44100,
      );

      await _audioRecorder.start(config, path: filePath);
      _lastRecordedPath = filePath;
      isRecordingNotifier.value = true;
      return true;
    } catch (e) {
      debugPrint('startRecording error: $e');
      isRecordingNotifier.value = false;
      return false;
    }
  }

  /// Arrête l'enregistrement audio et renvoie le chemin du fichier enregistré.
  Future<String?> stopRecording() async {
    try {
      if (!isRecordingNotifier.value) return _lastRecordedPath;
      final path = await _audioRecorder.stop();
      isRecordingNotifier.value = false;
      _lastRecordedPath = path ?? _lastRecordedPath;
      return _lastRecordedPath;
    } catch (e) {
      debugPrint('stopRecording error: $e');
      isRecordingNotifier.value = false;
      return null;
    }
  }

  /// Lit l'enregistrement de l'utilisateur avec just_audio.
  Future<void> playRecording({String? path, VoidCallback? onDone}) async {
    final filePath = path ?? _lastRecordedPath;
    if (filePath == null) {
      onDone?.call();
      return;
    }

    try {
      await _audioPlayer.stop();
      await _audioPlayer.setFilePath(filePath);
      isPlayingRecordingNotifier.value = true;

      // Écouter la fin de lecture
      final subscription = _audioPlayer.playerStateStream.listen(null);
      subscription.onData((state) {
        if (state.processingState == ProcessingState.completed) {
          isPlayingRecordingNotifier.value = false;
          subscription.cancel();
          onDone?.call();
        }
      });

      await _audioPlayer.play();
    } catch (e) {
      debugPrint('playRecording error: $e');
      isPlayingRecordingNotifier.value = false;
      onDone?.call();
    }
  }

  /// Arrête la lecture audio.
  Future<void> stopPlayback() async {
    try {
      await _audioPlayer.stop();
      isPlayingRecordingNotifier.value = false;
    } catch (_) {}
  }

  void dispose() {
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    isRecordingNotifier.dispose();
    isPlayingRecordingNotifier.dispose();
  }
}
