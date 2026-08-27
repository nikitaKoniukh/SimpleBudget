/// Supported UI locale codes.
const supportedLocaleCodes = [
  'en',
  'ru',
  'he',
  'es',
  'fr',
  'uk',
  'ar',
  'de',
];

typedef L10nTable = Map<String, String>;

String lookup(L10nTable table, String localeCode) {
  return table[localeCode] ?? table['en']!;
}

L10nTable l10nRow(
  String en,
  String ru,
  String he,
  String es,
  String fr,
  String uk,
  String ar,
  String de,
) {
  return {
    'en': en,
    'ru': ru,
    'he': he,
    'es': es,
    'fr': fr,
    'uk': uk,
    'ar': ar,
    'de': de,
  };
}
