import 'package:flutter/foundation.dart';
import 'data/auth_repository.dart';
import 'models/user_model.dart';

/// Zabira Academy — Auth State
enum AuthStatus {
  /// Initial / unknown — checking auth state
  initial,

  /// User is authenticated + profile loaded
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
/// Connects AuthRepository (Zabira API & secure token persistence).
class AuthController extends ChangeNotifier {
  AuthController({required AuthRepository authRepository})
      : _auth = authRepository {
    _init();
  }

  final AuthRepository _auth;

  // ─── State ────────────────────────────────────────────────────────────────
  AuthStatus _status = AuthStatus.initial;
  UserModel? _user;
  String? _errorMessage;
  String? _pendingReturnTo;

  AuthStatus get status => _status;
  UserModel? get user => _user;
  String? get errorMessage => _errorMessage;
  String? get currentToken => _auth.currentToken;
  bool get isAuthenticated => _status == AuthStatus.authenticated && _user != null;
  bool get isLoading => _status == AuthStatus.loading;
  String? get pendingReturnTo => _pendingReturnTo;

  void setPendingReturnTo(String? route) {
    _pendingReturnTo = route;
  }

  String? consumePendingReturnTo() {
    final route = _pendingReturnTo;
    _pendingReturnTo = null;
    return route;
  }

  // ─── Init ─────────────────────────────────────────────────────────────────
  Future<void> _init() async {
    try {
      final restoredUser = await _auth.initSession();
      if (restoredUser != null) {
        _user = restoredUser;
        _status = AuthStatus.authenticated;
      } else {
        _user = null;
        _status = AuthStatus.unauthenticated;
      }
    } catch (_) {
      _user = null;
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  // ─── Sign In (Official Zabira API) ────────────────────────────────────────
  Future<bool> signIn({
    required String email,
    required String password,
    String portal = 'student',
  }) async {
    if (_status == AuthStatus.loading) return false;
    _setLoading();
    try {
      final user = await _auth.signInWithApi(
        email: email,
        password: password,
        portal: portal,
      );
      _user = user;
      _status = AuthStatus.authenticated;
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (e) {
      _user = null;
      _setError(e.toString());
      return false;
    }
  }

  // ─── Teacher Sign In (Official Zabira API) ────────────────────────────────
  Future<bool> signInAsTeacher({required String email, required String password}) async {
    return signIn(email: email, password: password, portal: 'teacher');
  }

  // ─── Google Sign In (Official Zabira API) ─────────────────────────────────
  Future<bool> signInWithGoogle({String portal = 'student'}) async {
    if (_status == AuthStatus.loading) return false;
    _setLoading();
    try {
      final user = await _auth.signInWithGoogle(portal: portal);
      _user = user;
      _status = AuthStatus.authenticated;
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (e) {
      _user = null;
      _setError(e.toString());
      return false;
    }
  }

  // ─── Register (Official Zabira API) ───────────────────────────────────────
  Future<bool> register({
    required String fullName,
    required String email,
    required String password,
    required String confirmPassword,
    String? mobile,
    String? gender,
    String? dateOfBirth,
    String? country,
    String? state,
    String? city,
    bool acceptTerms = true,
  }) async {
    if (_status == AuthStatus.loading) return false;
    _setLoading();
    try {
      await _auth.registerWithApi(
        fullName: fullName,
        email: email,
        password: password,
        confirmPassword: confirmPassword,
        mobile: mobile,
        gender: gender,
        dateOfBirth: dateOfBirth,
        country: country,
        state: state,
        city: city,
        acceptTerms: acceptTerms,
      );

      if (_auth.isSignedIn) {
        _user = _auth.currentUser;
        _status = AuthStatus.authenticated;
      } else {
        _user = null;
        _status = AuthStatus.unauthenticated;
      }
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (e) {
      _user = null;
      _setError(e.toString());
      return false;
    }
  }

  // ─── Forgot Password ──────────────────────────────────────────────────────
  Future<bool> sendPasswordReset(String email) async {
    if (_status == AuthStatus.loading) return false;
    _setLoading();
    try {
      await _auth.sendPasswordResetEmail(email);
      _status = AuthStatus.unauthenticated;
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  // ─── Validate Reset Token ─────────────────────────────────────────────────
  Future<bool> validateResetToken(String token) async {
    if (_status == AuthStatus.loading) return false;
    _setLoading();
    try {
      final isValid = await _auth.validateResetToken(token);
      _errorMessage = null;
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return isValid;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  // ─── Reset Password ───────────────────────────────────────────────────────
  Future<bool> resetPassword({
    required String token,
    required String password,
    required String confirmPassword,
  }) async {
    if (_status == AuthStatus.loading) return false;
    _setLoading();
    try {
      await _auth.resetPassword(
        token: token,
        password: password,
        confirmPassword: confirmPassword,
      );
      _status = AuthStatus.unauthenticated;
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  // ─── Refresh Profile ──────────────────────────────────────────────────────
  Future<void> refreshProfile() async {
    if (!isAuthenticated) return;
    try {
      final user = await _auth.refreshProfile();
      _user = user;
      notifyListeners();
    } catch (_) {}
  }

  // ─── Sign Out ─────────────────────────────────────────────────────────────
  Future<void> signOut() async {
    await _auth.signOut();
    _user = null;
    _pendingReturnTo = null;
    _status = AuthStatus.unauthenticated;
    _errorMessage = null;
    notifyListeners();
  }

  // ─── State Mutators ───────────────────────────────────────────────────────
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
