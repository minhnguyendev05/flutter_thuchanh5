import 'package:expense_tracker_app/models/user_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  AuthService({FirebaseAuth? firebaseAuth, GoogleSignIn? googleSignIn})
      : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn(scopes: ['email', 'profile']);

  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;

  UserModel? getCurrentUser() {
    final currentUser = _firebaseAuth.currentUser;
    if (currentUser == null) {
      return null;
    }
    return _toUserModel(currentUser);
  }

  Future<UserModel?> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        // Web: Use Firebase signInWithPopup
        final userCredential = await _firebaseAuth.signInWithPopup(GoogleAuthProvider());
        final firebaseUser = userCredential.user;
        if (firebaseUser == null) return null;
        return _toUserModel(firebaseUser);
      } else {
        // Android/iOS: Use google_sign_in package (in-app native auth)
        final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
        if (googleUser == null) return null;

        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        final userCredential = await _firebaseAuth.signInWithCredential(credential);
        final firebaseUser = userCredential.user;
        if (firebaseUser == null) return null;
        return _toUserModel(firebaseUser);
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<UserModel?> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    final credential = await _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = credential.user;
    if (user == null) return null;
    return _toUserModel(user);
  }

  Future<UserModel?> registerWithEmailPassword({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final credential = await _firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = credential.user;
    if (user == null) return null;

    if (displayName.trim().isNotEmpty) {
      await user.updateDisplayName(displayName.trim());
      await user.reload();
    }

    final refreshedUser = _firebaseAuth.currentUser;
    if (refreshedUser == null) return null;
    return _toUserModel(refreshedUser);
  }

  Future<void> signOut() async {
    await _firebaseAuth.signOut();
    if (!kIsWeb) {
      await _googleSignIn.signOut();
    }
  }

  UserModel _toUserModel(User user) {
    return UserModel(
      id: user.uid,
      name: (user.displayName == null || user.displayName!.trim().isEmpty)
          ? (user.email?.split('@').first ?? 'Unknown User')
          : user.displayName!,
      email: user.email ?? '',
      avatarUrl: user.photoURL,
    );
  }
}
