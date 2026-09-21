import '../models/user_model.dart';
import 'auth_service_interface.dart';

class FirebaseAuthService implements AuthServiceInterface {
  Stream<dynamic> get authStateChanges => Stream.value(null);

  @override
  Future<UserModel?> getCurrentUser() async {
    return null;
  }

  @override
  Future<UserModel> login(String email, String password) async {
    throw UnimplementedError('No Firebase Auth');
  }

  @override
  Future<UserModel> register(
      String name, String email, String password, String? phone) async {
    throw UnimplementedError('No Firebase Auth');
  }

  @override
  Future<void> sendPasswordReset(String email) async {}

  @override
  Future<void> resetPassword(String email, String newPassword) async {}

  @override
  Future<void> logout() async {}

  @override
  Future<void> toggleFavourite(String userId, String itemId) async {}
}
