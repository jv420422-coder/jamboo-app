import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  AuthService._();

  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Current logged in user
  static User? get currentUser => _auth.currentUser;

  /// User logged in?
  static bool get isLoggedIn => _auth.currentUser != null;

  /// Auth state changes
  static Stream<User?> get authStateChanges =>
      _auth.authStateChanges();

  /// Logout
  static Future<void> signOut() async {
    await _auth.signOut();
  }
}