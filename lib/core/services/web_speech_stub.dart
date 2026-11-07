/// Stub non-web pour la reconnaissance vocale et les sons Web Audio.
class WebSpeechPlatform {
  static bool get isSupported => false;
  static bool get isSpeechRecognitionAvailable => false;

  static void playSuccessChime() {}
  static void playFailureChime() {}

  static bool startGermanSpeechRecognition({
    required Function(String text, bool isFinal) onResult,
    required Function(String error) onError,
    required Function(String text) onEnd,
  }) {
    return false;
  }

  static void stopGermanSpeechRecognition() {}
}
