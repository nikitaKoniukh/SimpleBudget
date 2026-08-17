import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/models.dart';

class AuthService {
  AuthService({FirebaseAuth? auth, FirebaseFirestore? firestore})
      : _auth = auth ?? FirebaseAuth.instance,
        _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

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

  Future<void> signOut() => _auth.signOut();

  Future<AppUser> ensureUserDoc(User firebaseUser) async {
    final ref = _db.collection('users').doc(firebaseUser.uid);
    final snap = await ref.get();
    if (!snap.exists) {
      final user = AppUser(
        id: firebaseUser.uid,
        email: firebaseUser.email ?? '',
        displayName: firebaseUser.displayName,
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

  Future<void> updateLocale(String uid, String localeCode) async {
    await _db.collection('users').doc(uid).update({'localeCode': localeCode});
  }

  Future<void> setHouseholdId(String uid, String householdId) async {
    await _db.collection('users').doc(uid).update({'householdId': householdId});
  }
}
