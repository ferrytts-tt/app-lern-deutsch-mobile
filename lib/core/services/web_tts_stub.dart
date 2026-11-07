/// Stub implementation for non-web platforms.
class WebTtsAudio {
  static bool get isSupported => false;

  static Future<bool> play(
    String text,
    double rate, {
    String? phraseId,
    String? voiceGender,
  }) async => false;

  static void stop() {}
}
