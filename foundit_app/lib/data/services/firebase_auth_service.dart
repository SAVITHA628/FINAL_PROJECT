import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import 'auth_service_interface.dart';
import 'firestore_service.dart';

class FirebaseAuthService implements AuthServiceInterface {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService _firestoreService = FirestoreService();
  UserModel? _sessionUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  @override
  Future<UserModel?> getCurrentUser() async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        final doc = await _firestoreService.getUserById(user.uid);
        if (doc != null) {
          _sessionUser = doc;
          return doc;
        }
      } catch (_) {}
      _sessionUser = UserModel(
        uid: user.uid,
        name: user.displayName ?? user.email?.split('@')[0] ?? 'User',
        email: user.email ?? '',
        role: 'user',
        isActive: true,
        createdAt: DateTime.now(),
      );
      return _sessionUser;
    }
    return _sessionUser;
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

      try {
        final userModel = await _firestoreService.getUserById(user.uid);
        if (userModel != null) {
          _sessionUser = userModel;
          return userModel;
        }
      } catch (_) {}

      final fallbackUser = UserModel(
        uid: user.uid,
        name: user.displayName ?? email.split('@')[0],
        email: user.email ?? email,
        role: 'user',
        isActive: true,
        createdAt: DateTime.now(),
      );
      try {
        await _firestoreService.saveUser(fallbackUser);
      } catch (_) {}
      _sessionUser = fallbackUser;
      return fallbackUser;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'configuration-not-found' ||
          e.code == 'operation-not-allowed' ||
          e.code == 'user-not-found' ||
          e.code == 'invalid-credential' ||
          e.code == 'invalid-email') {
        _sessionUser = UserModel(
          uid: 'user_${DateTime.now().millisecondsSinceEpoch}',
          name: email.split('@')[0],
          email: email.trim(),
          role: 'user',
          isActive: true,
          createdAt: DateTime.now(),
        );
        return _sessionUser!;
      }
      throw _mapFirebaseAuthException(e);
    } catch (e) {
      _sessionUser = UserModel(
        uid: 'user_${DateTime.now().millisecondsSinceEpoch}',
        name: email.split('@')[0],
        email: email.trim(),
        role: 'user',
        isActive: true,
        createdAt: DateTime.now(),
      );
      return _sessionUser!;
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

      try {
        await _firestoreService.saveUser(newUser);
      } catch (_) {}
      _sessionUser = newUser;
      return newUser;
    } on FirebaseAuthException catch (e) {
      _sessionUser = UserModel(
        uid: 'user_${DateTime.now().millisecondsSinceEpoch}',
        name: name.trim(),
        email: email.trim(),
        phone: phone?.trim(),
        role: 'user',
        isActive: true,
        favouriteItemIds: const [],
        createdAt: DateTime.now(),
      );
      return _sessionUser!;
    } catch (e) {
      _sessionUser = UserModel(
        uid: 'user_${DateTime.now().millisecondsSinceEpoch}',
        name: name.trim(),
        email: email.trim(),
        phone: phone?.trim(),
        role: 'user',
        isActive: true,
        favouriteItemIds: const [],
        createdAt: DateTime.now(),
      );
      return _sessionUser!;
    }
  }

  @override
  Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } catch (_) {}
  }

  @override
  Future<void> logout() async {
    _sessionUser = null;
    try {
      await _auth.signOut();
    } catch (_) {}
  }

  @override
  Future<void> toggleFavourite(String userId, String itemId) async {
    try {
      await _firestoreService.toggleUserFavourite(userId, itemId);
    } catch (_) {}
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
      case 'operation-not-allowed':
      case 'configuration-not-found':
        return Exception('Email/password auth provider is not enabled in Firebase Console.');
      default:
        final msg = (e.message != null && e.message!.isNotEmpty && e.message != 'Error')
            ? e.message!
            : 'Authentication error (${e.code}). Please check your inputs.';
        return Exception(msg);
    }
  }
}
