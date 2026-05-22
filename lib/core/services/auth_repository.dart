import 'package:chatapp/core/models/chat_user.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthRepository {
  AuthRepository(this._auth, this._firestore);

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<UserCredential> signUp({
    required String email,
    required String password,
    String? displayName,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final uid = credential.user?.uid;
    if (uid == null) {
      return credential;
    }

    await _firestore.collection('users').doc(uid).set({
      'uid': uid,
      'email': email,
      'displayName': displayName ?? '',
      'displayNameLower': (displayName ?? '').toLowerCase(),
      'photoUrl': null,
      'photoBase64': null,
      'photoMimeType': null,
      'isOnline': true,
      'createdAt': FieldValue.serverTimestamp(),
      'lastSeen': FieldValue.serverTimestamp(),
      'fcmToken': null,
    }, SetOptions(merge: true));

    return credential;
  }

  Future<void> signOut() => _auth.signOut();

  Stream<ChatUser?> watchUser(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .snapshots()
        .map(
          (snapshot) => snapshot.data() == null
              ? null
              : ChatUser.fromMap(snapshot.data()!),
        );
  }
}
