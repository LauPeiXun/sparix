import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Email/Password Login
  Future<UserCredential?> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'An unexpected error occurred: $e';
    }
  }

  // Email/Password Registration
  Future<UserCredential?> createUserWithEmailPassword({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Update display name
      await result.user?.updateDisplayName(displayName);
      
      return result;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'An unexpected error occurred: $e';
    }
  }

  // Password Reset
  Future<void> sendPasswordResetEmail({required String email}) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'An unexpected error occurred: $e';
    }
  }

  // Sign Out
  Future<void> signOut() async {
    try {
      await Future.wait([
        _auth.signOut(),
      ]);
    } catch (e) {
      throw 'Failed to sign out: $e';
    }
  }

  // Update the current user's password
  Future<void> resetPasswordFromCurrentSession({
    required String oldPassword,
    required String newPassword,
  }) async {
    User? user = _auth.currentUser;

    if (user == null || user.email == null) {
      throw FirebaseAuthException(
        code: 'no-user',
        message: 'No user is currently signed in.',
      );
    }

    AuthCredential credential = EmailAuthProvider.credential(
      email: user.email!,
      password: oldPassword,
    );
    await user.reauthenticateWithCredential(credential);

    return await user.updatePassword(newPassword);
  }

  // Handle Firebase Auth Exceptions
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email address.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'invalid-credential':
        return 'Invalid email or password. Please check your credentials.';
      case 'email-already-in-use':
        return 'An account already exists with this email address.';
      case 'weak-password':
        return 'Password should be at least 6 characters long.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Please check your connection.';
      case 'operation-not-allowed':
        return 'Email/password sign-in is not enabled. Please contact support.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'requires-recent-login':
        return 'Please log in again to perform this action.';
      case 'internal-error':
        return 'Internal server error. Please try again later or contact support.';
      default:
        return 'Authentication failed (${e.code}): ${e.message}';
    }
  }

  // Check if user is logged in
  bool get isLoggedIn => currentUser != null;

  // Get user email
  String? get userEmail => currentUser?.email;

  // Get user display name
  String? get userDisplayName => currentUser?.displayName;

  // Get user UID
  String? get userUID => currentUser?.uid;
}