/// Configuration des langues supportées par Hoppla! / Deutsch Fast.
class AppLanguage {
  final String code;
  final String name;
  final String nativeName;
  final String flag;
  final bool isRtl;

  const AppLanguage({
    required this.code,
    required this.name,
    required this.nativeName,
    required this.flag,
    this.isRtl = false,
  });

  static const List<AppLanguage> supportedLanguages = [
    AppLanguage(code: 'fr', name: 'Français', nativeName: 'Français', flag: '🇫🇷'),
    AppLanguage(code: 'en', name: 'Anglais', nativeName: 'English', flag: '🇬🇧'),
    AppLanguage(code: 'ar', name: 'Arabe', nativeName: 'العربية', flag: '🇸🇦', isRtl: true),
    AppLanguage(code: 'ro', name: 'Roumain', nativeName: 'Română', flag: '🇷🇴'),
    AppLanguage(code: 'ru', name: 'Russe', nativeName: 'Русский', flag: '🇷🇺'),
    AppLanguage(code: 'tr', name: 'Turc', nativeName: 'Türkçe', flag: '🇹🇷'),
    AppLanguage(code: 'es', name: 'Espagnol', nativeName: 'Español', flag: '🇪🇸'),
    AppLanguage(code: 'hi', name: 'Hindi', nativeName: 'हिन्दी', flag: '🇮🇳'),
    AppLanguage(code: 'de', name: 'Allemand', nativeName: 'Deutsch', flag: '🇩🇪'),
  ];

  static AppLanguage fromCode(String code) {
    return supportedLanguages.firstWhere(
      (l) => l.code == code,
      orElse: () => supportedLanguages.first, // 'fr' fallback
    );
  }
}
