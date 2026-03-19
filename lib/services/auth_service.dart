import 'package:expense_tracker_app/models/user_model.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  AuthService({GoogleSignIn? googleSignIn}) : _googleSignIn = googleSignIn ?? GoogleSignIn.instance;

  final GoogleSignIn _googleSignIn;

  Future<UserModel?> signInWithGoogle() async {
    await _googleSignIn.initialize();
    final account = await _googleSignIn.authenticate();

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
