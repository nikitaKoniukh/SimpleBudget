import 'locale_lookup.dart';

class LanguageOption {
  const LanguageOption({
    required this.code,
    required this.label,
    required this.flag,
  });

  final String code;
  final String label;
  final String flag;
}

const languageOptions = <LanguageOption>[
  LanguageOption(code: 'en', label: 'English', flag: '🇺🇸'),
  LanguageOption(code: 'ru', label: 'Русский', flag: '🇷🇺'),
  LanguageOption(code: 'he', label: 'עברית', flag: '🇮🇱'),
  LanguageOption(code: 'es', label: 'Español', flag: '🇪🇸'),
  LanguageOption(code: 'fr', label: 'Français', flag: '🇫🇷'),
  LanguageOption(code: 'uk', label: 'Українська', flag: '🇺🇦'),
  LanguageOption(code: 'ar', label: 'العربية', flag: '🇸🇦'),
  LanguageOption(code: 'de', label: 'Deutsch', flag: '🇩🇪'),
];

LanguageOption languageOptionFor(String code) {
  for (final option in languageOptions) {
    if (option.code == code) return option;
  }
  return languageOptions.first;
}

/// Options in [supportedLocaleCodes] order (falls back if lists diverge).
List<LanguageOption> get orderedLanguageOptions => supportedLocaleCodes
    .map((code) => languageOptions.where((o) => o.code == code).firstOrNull)
    .whereType<LanguageOption>()
    .toList();
