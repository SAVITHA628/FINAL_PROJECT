import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/user_model.dart';
import 'app_providers.dart';

// Firebase Auth state stream listener
final authStateStreamProvider = StreamProvider<User?>((ref) {
  final isFirebase = ref.watch(isFirebaseInitializedProvider);
  if (!isFirebase) return Stream.value(null);
  return FirebaseAuth.instance.authStateChanges();
});

// Auth notifier state management for login, register, logout, password reset
final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<UserModel?>>((ref) {
  return AuthNotifier(ref);
});

class AuthNotifier extends StateNotifier<AsyncValue<UserModel?>> {
  final Ref _ref;

  AuthNotifier(this._ref) : super(const AsyncValue.data(null)) {
    _initUser();
  }

  Future<void> _initUser() async {
    state = const AsyncValue.loading();
    try {
      final user = await _ref.read(userRepositoryProvider).getCurrentUser();
      state = AsyncValue.data(user);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> login(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final repo = _ref.read(userRepositoryProvider);
      final user = await repo.login(email, password);
      state = AsyncValue.data(user);
      _ref.invalidate(currentUserProvider);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
    String? phone,
  }) async {
    state = const AsyncValue.loading();
    try {
      final repo = _ref.read(userRepositoryProvider);
      // Default registration creates normal user (role fixed to 'user')
      final user = await repo.register(name, email, password, phone);
      state = AsyncValue.data(user);
      _ref.invalidate(currentUserProvider);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  Future<void> sendPasswordReset(String email) async {
    try {
      final repo = _ref.read(userRepositoryProvider);
      await repo.sendPasswordReset(email);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> logout() async {
    state = const AsyncValue.loading();
    try {
      final repo = _ref.read(userRepositoryProvider);
      await repo.logout();
      state = const AsyncValue.data(null);
      _ref.invalidate(currentUserProvider);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }
}
