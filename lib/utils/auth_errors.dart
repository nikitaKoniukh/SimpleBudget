import 'package:firebase_auth/firebase_auth.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../l10n/app_localizations.dart';

/// Returns a user-facing auth error, or null if it should be ignored (e.g. cancelled).
String? friendlyAuthError(Object error, AppLocalizations l10n) {
  if (error is FirebaseAuthException) {
    return l10n.authErrorForCode(error.code);
  }
  if (error is SignInWithAppleAuthorizationException) {
    if (error.code == AuthorizationErrorCode.canceled) return null;
    return l10n.authAppleSignInFailed;
  }
  if (error is StateError) {
    final message = error.message;
    if (message.isEmpty || message == 'cancelled') return null;
    if (message.contains('different sign-in method')) {
      return l10n.authAccountExistsDifferentCredential;
    }
    if (message.contains('Google Sign-In')) {
      return l10n.authGoogleSignInFailed;
    }
    return message;
  }
  final text = error.toString();
  if (text.contains('cancelled')) return null;
  return l10n.errorGeneric;
}
