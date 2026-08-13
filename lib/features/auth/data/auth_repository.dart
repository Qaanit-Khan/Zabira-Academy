import 'package:firebase_auth/firebase_auth.dart';

/// Zabira Academy — Auth Repository
///
/// All Firebase Authentication operations.
/// The UI layer never imports firebase_auth directly.
class AuthRepository {
  AuthRepository({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;

  // ─── Auth State ───────────────────────────────────────────────────────────
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  bool get isSignedIn => _auth.currentUser != null;

  // ─── Email / Password ─────────────────────────────────────────────────────
  Future<UserCredential> signInWithEmail({required String email, required String password}) async {
    return _auth.signInWithEmailAndPassword(email: email.trim(), password: password);
  }

  Future<UserCredential> createUserWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    // Set display name immediately
    await credential.user?.updateDisplayName(displayName.trim());
    return credential;
  }

  // ─── Password Reset ───────────────────────────────────────────────────────
  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  // ─── Sign Out ─────────────────────────────────────────────────────────────
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // ─── Error Mapping ────────────────────────────────────────────────────────
  /// Converts Firebase error codes to user-friendly messages
  static String mapFirebaseError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Invalid email or password. Please try again.';
      case 'email-already-in-use':
        return 'This email is already registered.';
      case 'weak-password':
        return 'Password is too weak. Use at least 8 characters.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-disabled':
        return 'This account has been disabled. Please contact support.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Please check your connection.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }
}

/// Teacher Auth Repository
///
/// Teacher login uses the same Firebase Auth but validates the Firestore role.
/// Separating this keeps teacher-specific logic isolated.
class TeacherAuthRepository extends AuthRepository {
  TeacherAuthRepository({super.auth});

  Future<UserCredential> signInAsTeacher({required String email, required String password}) async {
    // Firebase Auth sign-in — role validation happens in UserRepository
    return signInWithEmail(email: email, password: password);
  }
}
