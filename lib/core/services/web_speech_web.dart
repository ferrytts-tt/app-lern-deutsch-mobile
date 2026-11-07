import 'dart:js_interop';
import 'package:flutter/foundation.dart';

@JS('playSuccessChime')
external void _jsPlaySuccessChime();

@JS('playFailureChime')
external void _jsPlayFailureChime();

@JS('isSpeechRecognitionAvailable')
external JSBoolean _jsIsSpeechRecognitionAvailable();

@JS('startGermanSpeechRecognition')
external JSBoolean _jsStartGermanSpeechRecognition(
  JSFunction onResult,
  JSFunction onError,
  JSFunction onEnd,
);

@JS('stopGermanSpeechRecognition')
external void _jsStopGermanSpeechRecognition();

/// Implémentation Web utilisant Web Audio API et Web Speech API directement dans le navigateur.
class WebSpeechPlatform {
  static bool get isSupported => kIsWeb;

  static bool get isSpeechRecognitionAvailable {
    if (!kIsWeb) return false;
    try {
      return _jsIsSpeechRecognitionAvailable().toDart;
    } catch (_) {
      return false;
    }
  }

  static void playSuccessChime() {
    try {
      _jsPlaySuccessChime();
    } catch (e) {
      debugPrint('[WebSpeechPlatform] playSuccessChime error: $e');
    }
  }

  static void playFailureChime() {
    try {
      _jsPlayFailureChime();
    } catch (e) {
      debugPrint('[WebSpeechPlatform] playFailureChime error: $e');
    }
  }

  static bool startGermanSpeechRecognition({
    required Function(String text, bool isFinal) onResult,
    required Function(String error) onError,
    required Function(String text) onEnd,
  }) {
    if (!kIsWeb) return false;
    try {
      final jsOnResult = ((JSString text, JSBoolean isFinal) {
        onResult(text.toDart, isFinal.toDart);
      }).toJS;

      final jsOnError = ((JSString error) {
        onError(error.toDart);
      }).toJS;

      final jsOnEnd = ((JSString text) {
        onEnd(text.toDart);
      }).toJS;

      return _jsStartGermanSpeechRecognition(jsOnResult, jsOnError, jsOnEnd).toDart;
    } catch (e) {
      debugPrint('[WebSpeechPlatform] startGermanSpeechRecognition error: $e');
      return false;
    }
  }

  static void stopGermanSpeechRecognition() {
    if (!kIsWeb) return;
    try {
      _jsStopGermanSpeechRecognition();
    } catch (_) {}
  }
}
