import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../models/user_role.dart';

/// Zabira Academy — User Repository
///
/// All Firestore operations for user/profile data.
/// Collection: `users/{uid}`
class UserRepository {
  UserRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _userDoc(String uid) =>
      _firestore.collection('users').doc(uid);

  // ─── Create ───────────────────────────────────────────────────────────────
  /// Creates a new user document after registration.
  Future<void> createUser({
    required User firebaseUser,
    required UserRole role,
    String? displayName,
  }) async {
    final userModel = UserModel(
      uid: firebaseUser.uid,
      email: firebaseUser.email ?? '',
      displayName: displayName ?? firebaseUser.displayName ?? '',
      role: role,
      createdAt: DateTime.now(),
      isEmailVerified: firebaseUser.emailVerified,
    );

    await _userDoc(firebaseUser.uid).set(userModel.toFirestore());
  }

  // ─── Read ─────────────────────────────────────────────────────────────────
  /// Fetches user profile from Firestore by UID.
  Future<UserModel?> getUser(String uid) async {
    final doc = await _userDoc(uid).get();
    if (!doc.exists || doc.data() == null) return null;
    return UserModel.fromFirestore(doc);
  }

  /// Real-time stream of user profile changes.
  Stream<UserModel?> userStream(String uid) {
    return _userDoc(uid).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return UserModel.fromFirestore(doc);
    });
  }

  // ─── Update ───────────────────────────────────────────────────────────────
  Future<void> updateUser(String uid, Map<String, dynamic> fields) async {
    await _userDoc(uid).update(fields);
  }

  // ─── Role Validation ──────────────────────────────────────────────────────
  /// Confirms that the signed-in user has the expected role.
  Future<bool> validateRole(String uid, UserRole expectedRole) async {
    final user = await getUser(uid);
    return user?.role == expectedRole;
  }
}
