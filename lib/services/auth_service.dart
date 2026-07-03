import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Firebase Auth only supports email/password natively, so registered
/// accounts use a synthetic email (`username@huddle.app`) built from the
/// username the user actually picks. Guests never touch Firebase Auth at
/// all -- they're just a doc under an event's participants subcollection.
class AuthService {
  AuthService._();
  static final instance = AuthService._();

  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  String _emailFor(String username) => '${username.trim().toLowerCase()}@huddle.app';

  Future<void> signUp({
    required String username,
    required String password,
    String? photoUrl,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: _emailFor(username),
      password: password,
    );
    final uid = credential.user!.uid;
    await _db.collection('users').doc(uid).set({
      'username': username.trim(),
      'photoUrl': photoUrl,
      'createdAt': FieldValue.serverTimestamp(),
      'eventIds': <String>[],
    });
  }

  Future<void> updateProfilePhoto(String uid, String url) {
    return _db.collection('users').doc(uid).update({'photoUrl': url});
  }

  Future<void> updateUsername(String uid, String username) {
    return _db.collection('users').doc(uid).update({'username': username.trim()});
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _auth.currentUser!;
    final credential = EmailAuthProvider.credential(email: user.email!, password: currentPassword);
    await user.reauthenticateWithCredential(credential);
    await user.updatePassword(newPassword);
  }

  Future<void> signIn({required String username, required String password}) {
    return _auth.signInWithEmailAndPassword(email: _emailFor(username), password: password);
  }

  Future<void> signOut() => _auth.signOut();

  Future<Map<String, dynamic>?> currentUserProfile() async {
    final uid = currentUser?.uid;
    if (uid == null) return null;
    final doc = await _db.collection('users').doc(uid).get();
    return doc.data();
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> userProfileStream(String uid) {
    return _db.collection('users').doc(uid).snapshots();
  }
}
