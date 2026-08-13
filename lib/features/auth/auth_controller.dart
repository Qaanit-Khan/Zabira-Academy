import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'data/auth_repository.dart';
import 'data/user_repository.dart';
import 'models/user_model.dart';
import 'models/user_role.dart';

/// Zabira Academy — Auth State
enum AuthStatus {
  /// Initial / unknown — checking auth state
  initial,

  /// Firebase says user is authenticated + profile loaded
  authenticated,

  /// Not signed in
  unauthenticated,

  /// Auth operation in progress
  loading,

  /// An error occurred
  error,
}

/// Zabira Academy — Auth Controller
///
/// Manages authentication state using ChangeNotifier (Provider).
/// Connects AuthRepository (Firebase) and UserRepository (Firestore).
/// Never exposes Firebase types to the UI layer.
class AuthController extends ChangeNotifier {
  AuthController({required AuthRepository authRepository, required UserRepository userRepository})
    : _auth = authRepository,
      _userRepo = userRepository {
    _init();
  }

  final AuthRepository _auth;
  final UserRepository _userRepo;

  // ─── State ────────────────────────────────────────────────────────────────
  AuthStatus _status = AuthStatus.initial;
  UserModel? _user;
  String? _errorMessage;

  AuthStatus get status => _status;
  UserModel? get user => _user;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isLoading => _status == AuthStatus.loading;

  // ─── Init ─────────────────────────────────────────────────────────────────
  void _init() {
    _status = _auth.currentUser == null ? AuthStatus.unauthenticated : AuthStatus.initial;
    _auth.authStateChanges.listen(_onAuthStateChanged);
  }

  Future<void> _onAuthStateChanged(User? firebaseUser) async {
    if (firebaseUser == null) {
      _status = AuthStatus.unauthenticated;
      _user = null;
      notifyListeners();
      return;
    }

    // User is signed in — load their profile
    try {
      final userModel = await _userRepo.getUser(firebaseUser.uid);
      if (userModel == null) {
        // Profile doesn't exist — sign out
        await _auth.signOut();
        return;
      }
      _user = userModel;
      _status = AuthStatus.authenticated;
    } catch (_) {
      _status = AuthStatus.unauthenticated;
      _user = null;
    }
    notifyListeners();
  }

  // ─── Sign In ──────────────────────────────────────────────────────────────
  Future<bool> signIn({required String email, required String password}) async {
    _setLoading();
    try {
      await _auth.signInWithEmail(email: email, password: password);
      // _onAuthStateChanged will update state
      return true;
    } on FirebaseAuthException catch (e) {
      _setError(AuthRepository.mapFirebaseError(e));
      return false;
    } catch (_) {
      _setError('Something went wrong. Please try again.');
      return false;
    }
  }

  // ─── Teacher Sign In ──────────────────────────────────────────────────────
  Future<bool> signInAsTeacher({required String email, required String password}) async {
    _setLoading();
    try {
      final credential = await _auth.signInWithEmail(email: email, password: password);
      final uid = credential.user?.uid;
      if (uid == null) {
        _setError('Authentication failed.');
        return false;
      }

      // Validate teacher role
      final isTeacher = await _userRepo.validateRole(uid, UserRole.teacher);
      if (!isTeacher) {
        await _auth.signOut();
        _setError('This account is not a teacher account. Please use the standard login.');
        return false;
      }
      return true;
    } on FirebaseAuthException catch (e) {
      _setError(AuthRepository.mapFirebaseError(e));
      return false;
    } catch (_) {
      _setError('Something went wrong. Please try again.');
      return false;
    }
  }

  // ─── Register ─────────────────────────────────────────────────────────────
  Future<bool> register({
    required String email,
    required String password,
    required String displayName,
    required UserRole role,
  }) async {
    _setLoading();
    try {
      final credential = await _auth.createUserWithEmail(
        email: email,
        password: password,
        displayName: displayName,
      );

      if (credential.user == null) {
        _setError('Registration failed. Please try again.');
        return false;
      }

      // Create Firestore profile
      await _userRepo.createUser(
        firebaseUser: credential.user!,
        role: role,
        displayName: displayName,
      );

      return true;
    } on FirebaseAuthException catch (e) {
      _setError(AuthRepository.mapFirebaseError(e));
      return false;
    } catch (_) {
      _setError('Something went wrong. Please try again.');
      return false;
    }
  }

  // ─── Forgot Password ──────────────────────────────────────────────────────
  Future<bool> sendPasswordReset(String email) async {
    _setLoading();
    try {
      await _auth.sendPasswordResetEmail(email);
      _status = AuthStatus.unauthenticated;
      _errorMessage = null;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _setError(AuthRepository.mapFirebaseError(e));
      return false;
    } catch (_) {
      _setError('Something went wrong. Please try again.');
      return false;
    }
  }

  // ─── Sign Out ─────────────────────────────────────────────────────────────
  Future<void> signOut() async {
    await _auth.signOut();
    // _onAuthStateChanged handles state reset
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────
  void _setLoading() {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();
  }

  void _setError(String message) {
    _status = AuthStatus.error;
    _errorMessage = message;
    notifyListeners();
  }

  void clearError() {
    if (_status == AuthStatus.error) {
      _status = _auth.isSignedIn ? AuthStatus.authenticated : AuthStatus.unauthenticated;
      _errorMessage = null;
      notifyListeners();
    }
  }
}
