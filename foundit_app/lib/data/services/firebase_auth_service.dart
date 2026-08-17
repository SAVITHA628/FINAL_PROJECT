import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import 'auth_service_interface.dart';
import 'firestore_service.dart';

class FirebaseAuthService implements AuthServiceInterface {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService _firestoreService = FirestoreService();

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  @override
  Future<UserModel?> getCurrentUser() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    return _firestoreService.getUserById(user.uid);
  }

  @override
  Future<UserModel> login(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = credential.user;
      if (user == null) throw Exception('Login failed: User record is empty.');

      final userModel = await _firestoreService.getUserById(user.uid);
      if (userModel != null) return userModel;

      // Fallback if Firestore doc wasn't created yet
      final fallbackUser = UserModel(
        uid: user.uid,
        name: user.displayName ?? email.split('@')[0],
        email: user.email ?? email,
        role: 'user',
        isActive: true,
        createdAt: DateTime.now(),
      );
      await _firestoreService.saveUser(fallbackUser);
      return fallbackUser;
    } on FirebaseAuthException catch (e) {
      throw _mapFirebaseAuthException(e);
    }
  }

  @override
  Future<UserModel> register(
      String name, String email, String password, String? phone) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = credential.user;
      if (user == null) throw Exception('Registration failed: User record empty.');

      // Default registration creates normal user (role fixed to 'user')
      final newUser = UserModel(
        uid: user.uid,
        name: name.trim(),
        email: email.trim(),
        phone: phone?.trim(),
        role: 'user',
        isActive: true,
        favouriteItemIds: const [],
        createdAt: DateTime.now(),
      );

      await _firestoreService.saveUser(newUser);
      return newUser;
    } on FirebaseAuthException catch (e) {
      throw _mapFirebaseAuthException(e);
    }
  }

  @override
  Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw _mapFirebaseAuthException(e);
    }
  }

  @override
  Future<void> logout() async {
    await _auth.signOut();
  }

  @override
  Future<void> toggleFavourite(String userId, String itemId) async {
    await _firestoreService.toggleUserFavourite(userId, itemId);
  }

  Exception _mapFirebaseAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return Exception('Invalid email or password. Please try again.');
      case 'email-already-in-use':
        return Exception('An account already exists for this email address.');
      case 'invalid-email':
        return Exception('The email address format is invalid.');
      case 'weak-password':
        return Exception('The password is too weak. Please use at least 6 characters.');
      case 'user-disabled':
        return Exception('This user account has been disabled.');
      case 'too-many-requests':
        return Exception('Too many unsuccessful login attempts. Please try again later.');
      case 'network-request-failed':
        return Exception('Network error. Please check your internet connection.');
      default:
        return Exception(e.message ?? 'Authentication error occurred.');
    }
  }
}
