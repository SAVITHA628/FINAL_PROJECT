import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/user_model.dart';
import 'app_providers.dart';

class RouterNotifier extends ChangeNotifier {
  final Ref _ref;

  RouterNotifier(this._ref) {
    _ref.listen<AsyncValue<UserModel?>>(currentUserProvider, (_, __) {
      notifyListeners();
    });
  }
}

final routerNotifierProvider = Provider<RouterNotifier>((ref) {
  return RouterNotifier(ref);
});

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
      await _ref.read(userRepositoryProvider).sendPasswordReset(email);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> resetPassword(String email, String newPassword) async {
    try {
      await _ref.read(userRepositoryProvider).resetPassword(email, newPassword);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> logout() async {
    state = const AsyncValue.loading();
    try {
      await _ref.read(userRepositoryProvider).logout();
      state = const AsyncValue.data(null);
      _ref.invalidate(currentUserProvider);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }
}
