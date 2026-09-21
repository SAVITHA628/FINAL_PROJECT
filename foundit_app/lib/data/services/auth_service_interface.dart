import '../models/user_model.dart';

abstract class AuthServiceInterface {
  Future<UserModel?> getCurrentUser();
  Future<UserModel> login(String email, String password);
  Future<UserModel> register(String name, String email, String password, String? phone);
  Future<void> sendPasswordReset(String email);
  Future<void> resetPassword(String email, String newPassword);
  Future<void> logout();
  Future<void> toggleFavourite(String userId, String itemId);
}
