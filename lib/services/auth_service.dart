import 'package:expense_tracker_app/models/user_model.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  AuthService({GoogleSignIn? googleSignIn})
    : _googleSignIn = googleSignIn ?? GoogleSignIn();

  final GoogleSignIn _googleSignIn;

  Future<UserModel?> signInWithGoogle() async {
    final account = await _googleSignIn.signIn();

    if (account == null) {
      return null;
    }

    return UserModel(
      id: account.id,
      name: account.displayName ?? 'Unknown User',
      email: account.email,
      avatarUrl: account.photoUrl,
    );
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
  }
}
