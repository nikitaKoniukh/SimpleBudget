/// OAuth client IDs for Google Sign-In.
///
/// After enabling Google in Firebase Console and adding your Android SHA-1,
/// re-download `GoogleService-Info.plist` / `google-services.json` and fill:
/// - [googleIosClientId] from plist `CLIENT_ID`
/// - [googleServerClientId] from the Web client ID (type 3) in Firebase Google provider
/// - [googleIosReversedClientId] from plist `REVERSED_CLIENT_ID` (also put in Info.plist)
///
/// Leave null to rely on native defaults where available (Android after SHA-1).
class OAuthConfig {
  static const String? googleIosClientId = null;
  static const String? googleServerClientId = null;
  static const String? googleIosReversedClientId = null;
}
