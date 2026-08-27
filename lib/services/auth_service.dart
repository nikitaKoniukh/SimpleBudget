import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../config/oauth_config.dart';
import '../l10n/locale_lookup.dart';
import '../models/models.dart';

class AuthService {
  AuthService({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;
  bool _googleReady = false;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<void> _ensureGoogleInitialized() async {
    if (_googleReady) return;
    await GoogleSignIn.instance.initialize(
      clientId: OAuthConfig.googleIosClientId,
      serverClientId: OAuthConfig.googleServerClientId,
    );
    _googleReady = true;
  }

  Future<AppUser> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    await cred.user!.updateDisplayName(displayName.trim());
    final user = AppUser(
      id: cred.user!.uid,
      email: email.trim(),
      displayName: displayName.trim(),
      localeCode: deviceLocaleCode(),
    );
    await _db.collection('users').doc(user.id).set(user.toMap());
    return user;
  }

  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    return ensureUserDoc(cred.user!);
  }

  Future<void> sendPasswordReset(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  Future<AppUser> signInWithGoogle() async {
    await _ensureGoogleInitialized();
    try {
      final account = await GoogleSignIn.instance.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null) {
        throw StateError('Google Sign-In did not return an ID token.');
      }
      final credential = GoogleAuthProvider.credential(idToken: idToken);
      final cred = await _auth.signInWithCredential(credential);
      return ensureUserDoc(cred.user!);
    } on FirebaseAuthException catch (e) {
      _mapAccountExists(e);
    } on GoogleSignInException catch (e) {
      _mapGoogleSignInException(e);
    }
  }

  Future<AppUser> signInWithApple() async {
    final rawNonce = _generateNonce();
    final nonce = _sha256ofString(rawNonce);

    final appleCredential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
      nonce: nonce,
    );

    final oauthCredential = OAuthProvider('apple.com').credential(
      idToken: appleCredential.identityToken,
      rawNonce: rawNonce,
      accessToken: appleCredential.authorizationCode,
    );

    try {
      final cred = await _auth.signInWithCredential(oauthCredential);
      final user = cred.user!;
      final fullName = [
        appleCredential.givenName,
        appleCredential.familyName,
      ].whereType<String>().where((s) => s.isNotEmpty).join(' ');
      if (fullName.isNotEmpty &&
          (user.displayName == null || user.displayName!.isEmpty)) {
        await user.updateDisplayName(fullName);
      }
      return ensureUserDoc(user);
    } on FirebaseAuthException catch (e) {
      _mapAccountExists(e);
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        throw StateError('cancelled');
      }
      rethrow;
    }
  }

  Never _mapGoogleSignInException(GoogleSignInException e) {
    debugPrint(
      'GoogleSignInException code=${e.code} description=${e.description} '
      'details=${e.details}',
    );
    if (e.code == GoogleSignInExceptionCode.canceled) {
      if (_looksLikeGoogleConfigFailure(e.description)) {
        throw StateError(_googleConfigFailureMessage);
      }
      throw StateError('cancelled');
    }
    throw StateError(_googleSignInUserMessage(e));
  }

  static const String _googleConfigFailureMessage =
      'Google Sign-In is not configured for this Android build. '
      'Add the debug SHA-1 to the Firebase Android app and reinstall.';

  bool _looksLikeGoogleConfigFailure(String? description) {
    if (description == null || description.isEmpty) return false;
    final text = description.toLowerCase();
    return text.contains('account reauth failed') ||
        text.contains('[16]') ||
        text.contains('[10]') ||
        text.contains('developer_error') ||
        text.contains('apiexception: 10');
  }

  String _googleSignInUserMessage(GoogleSignInException e) {
    switch (e.code) {
      case GoogleSignInExceptionCode.clientConfigurationError:
      case GoogleSignInExceptionCode.providerConfigurationError:
        return _googleConfigFailureMessage;
      case GoogleSignInExceptionCode.unknownError:
        final desc = (e.description ?? '').toLowerCase();
        if (desc.contains('no credential')) {
          return 'Google Sign-In could not find an account. '
              'Sign in to a Google account on this device, or check that the '
              'Android SHA-1 is registered in Firebase.';
        }
        return 'Google Sign-In failed. Sign in to a Google account on this '
            'device, or check that the Android SHA-1 is registered in Firebase.';
      default:
        return 'Google Sign-In failed. Sign in to a Google account on this '
            'device, or check that the Android SHA-1 is registered in Firebase.';
    }
  }

  Never _mapAccountExists(FirebaseAuthException e) {
    if (e.code == 'account-exists-with-different-credential') {
      throw StateError(
        'An account already exists with this email using a different sign-in method. '
        'Sign in with email/password first.',
      );
    }
    throw e;
  }

  List<String> get providerIds =>
      _auth.currentUser?.providerData.map((p) => p.providerId).toList() ??
      const [];

  Future<void> signOut() async {
    await _auth.signOut();
    if (!_googleReady) return;
    try {
      await GoogleSignIn.instance.signOut();
    } catch (_) {
      // Ignore if Google sign-out is unavailable.
    }
  }

  Future<void> deleteUserDoc(String uid) async {
    await _db.collection('users').doc(uid).delete();
  }

  Future<void> deleteAuthUser({String? password}) async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('Not signed in');
    try {
      await user.delete();
    } on FirebaseAuthException catch (e) {
      if (e.code != 'requires-recent-login') rethrow;
      await reauthenticate(password: password);
      await user.delete();
    }
    if (!_googleReady) return;
    try {
      await GoogleSignIn.instance.signOut();
    } catch (_) {}
  }

  Future<void> reauthenticate({String? password}) async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('Not signed in');
    final ids = providerIds;
    if (ids.contains('google.com')) {
      await _reauthenticateGoogle(user);
      return;
    }
    if (ids.contains('apple.com')) {
      await _reauthenticateApple(user);
      return;
    }
    if (ids.contains('password')) {
      if (password == null || password.isEmpty) {
        throw FirebaseAuthException(code: 'requires-recent-login');
      }
      final email = user.email;
      if (email == null || email.isEmpty) {
        throw StateError('No email on account');
      }
      await user.reauthenticateWithCredential(
        EmailAuthProvider.credential(email: email, password: password),
      );
      return;
    }
    throw FirebaseAuthException(code: 'requires-recent-login');
  }

  Future<void> _reauthenticateGoogle(User user) async {
    await _ensureGoogleInitialized();
    try {
      final account = await GoogleSignIn.instance.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null) {
        throw StateError('Google Sign-In did not return an ID token.');
      }
      await user.reauthenticateWithCredential(
        GoogleAuthProvider.credential(idToken: idToken),
      );
    } on GoogleSignInException catch (e) {
      _mapGoogleSignInException(e);
    }
  }

  Future<void> _reauthenticateApple(User user) async {
    final rawNonce = _generateNonce();
    final nonce = _sha256ofString(rawNonce);
    try {
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: const [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: nonce,
      );
      await user.reauthenticateWithCredential(
        OAuthProvider('apple.com').credential(
          idToken: appleCredential.identityToken,
          rawNonce: rawNonce,
          accessToken: appleCredential.authorizationCode,
        ),
      );
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        throw StateError('cancelled');
      }
      rethrow;
    }
  }

  Future<AppUser> ensureUserDoc(User firebaseUser) async {
    final ref = _db.collection('users').doc(firebaseUser.uid);
    final snap = await ref.get();
    if (!snap.exists) {
      final user = AppUser(
        id: firebaseUser.uid,
        email: firebaseUser.email ?? '',
        displayName: firebaseUser.displayName,
        localeCode: deviceLocaleCode(),
      );
      await ref.set(user.toMap());
      return user;
    }
    return AppUser.fromMap(snap.id, snap.data()!);
  }

  Stream<AppUser?> watchAppUser(String uid) {
    return _db.collection('users').doc(uid).snapshots().map((snap) {
      if (!snap.exists || snap.data() == null) return null;
      return AppUser.fromMap(snap.id, snap.data()!);
    });
  }

  Future<Map<String, String>> getMemberLabels(List<String> uids) async {
    final labels = <String, String>{};
    for (final uid in uids) {
      final snap = await _db.collection('users').doc(uid).get();
      final data = snap.data();
      if (data == null) continue;
      final user = AppUser.fromMap(uid, data);
      final name = user.displayName?.trim();
      if (name != null && name.isNotEmpty) {
        labels[uid] = name;
        continue;
      }
      final email = user.email.trim();
      if (email.isNotEmpty) {
        labels[uid] = email;
      }
    }
    return labels;
  }

  Future<void> updateLocale(String uid, String localeCode) async {
    await _db.collection('users').doc(uid).update({'localeCode': localeCode});
  }

  Future<void> addHouseholdMembership(String uid, String householdId) async {
    await _db.collection('users').doc(uid).update({
      'householdIds': FieldValue.arrayUnion([householdId]),
      'activeHouseholdId': householdId,
    });
  }

  Future<void> setActiveHouseholdId(String uid, String householdId) async {
    final snap = await _db.collection('users').doc(uid).get();
    final ids = List<String>.from(
      snap.data()?['householdIds'] as List? ?? const [],
    );
    if (!ids.contains(householdId)) {
      throw StateError('Not a member of this household');
    }
    await _db.collection('users').doc(uid).update({
      'activeHouseholdId': householdId,
    });
  }

  /// Removes [householdId] from the user's membership index and fixes active.
  Future<void> removeHouseholdMembership(String uid, String householdId) async {
    final ref = _db.collection('users').doc(uid);
    final snap = await ref.get();
    final data = snap.data() ?? {};
    final ids = List<String>.from(data['householdIds'] as List? ?? const []);
    ids.remove(householdId);
    final active = data['activeHouseholdId'] as String?;
    final newActive =
        ids.contains(active) ? active : (ids.isEmpty ? null : ids.first);
    await ref.update({
      'householdIds': ids,
      if (newActive == null)
        'activeHouseholdId': FieldValue.delete()
      else
        'activeHouseholdId': newActive,
    });
  }

  static String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(
      length,
      (_) => charset[random.nextInt(charset.length)],
    ).join();
  }

  static String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Apple Sign In is required on iOS; Android needs extra Services ID setup.
  bool get isAppleSignInAvailable =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;
}
