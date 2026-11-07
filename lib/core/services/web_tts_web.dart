import 'dart:async';
import 'dart:js_interop';
import 'package:flutter/foundation.dart';

@JS('playGermanAudio')
external JSPromise<JSBoolean>? _jsPlayGermanAudio(
  JSString text,
  JSNumber rate,
  JSString? phraseId,
  JSString? voiceGender,
);

@JS('stopGermanAudio')
external void _jsStopGermanAudio();

/// Web implementation using HTML5 Audio stream directly in the browser.
class WebTtsAudio {
  static bool get isSupported => kIsWeb;

  static Future<bool> play(
    String text,
    double rate, {
    String? phraseId,
    String? voiceGender,
  }) async {
    try {
      final promise = _jsPlayGermanAudio(
        text.toJS,
        rate.toJS,
        phraseId?.toJS,
        voiceGender?.toJS,
      );
      if (promise == null) return false;
      final result = await promise.toDart;
      return result.toDart;
    } catch (e) {
      debugPrint('[WebTtsAudio] play error: $e');
      return false;
    }
  }

  static void stop() {
    try {
      _jsStopGermanAudio();
    } catch (_) {}
  }
}
