/// Capitalizes the first character, leaving the rest of the text as typed.
/// `parking` → `Parking`, `house renting` → `House renting`.
String sentenceCase(String value) {
  final text = value.trim();
  if (text.isEmpty) return text;
  return '${text[0].toUpperCase()}${text.substring(1)}';
}
