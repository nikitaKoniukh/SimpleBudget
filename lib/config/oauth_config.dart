/// OAuth client IDs for Google Sign-In.
///
/// Filled from Firebase / GoogleService-Info.plist after FlutterFire configure
/// for bundle ID `com.yetzira.syncmonth`.
///
/// After adding Android SHA-1 on the SyncMonth Firebase Android app, re-download
/// `google-services.json` if OAuth clients change.
class OAuthConfig {
  /// iOS OAuth client ID (GoogleService-Info.plist `CLIENT_ID`).
  static const String googleIosClientId =
      '339787672116-gh10imd92oavvqn1bqu8c5bore73kati.apps.googleusercontent.com';

  /// Web client ID used as serverClientId for Firebase ID tokens.
  static const String googleServerClientId =
      '339787672116-laasbhap1jh520nj8i6iqlks2kmmcc7e.apps.googleusercontent.com';

  /// GoogleService-Info.plist `REVERSED_CLIENT_ID` (also in Info.plist URL scheme).
  static const String googleIosReversedClientId =
      'com.googleusercontent.apps.339787672116-gh10imd92oavvqn1bqu8c5bore73kati';
}
