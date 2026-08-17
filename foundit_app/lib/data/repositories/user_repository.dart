import '../models/user_model.dart';
import '../services/auth_service_interface.dart';
import '../services/mock_auth_service.dart';

class UserRepository {
  final AuthServiceInterface _service;

  UserRepository({AuthServiceInterface? service})
      : _service = service ?? MockAuthService();

  Future<UserModel?> getCurrentUser() => _service.getCurrentUser();

  Future<UserModel> login(String email, String password) =>
      _service.login(email, password);

  Future<UserModel> register(
          String name, String email, String password, String? phone) =>
      _service.register(name, email, password, phone);

  Future<void> sendPasswordReset(String email) =>
      _service.sendPasswordReset(email);

  Future<void> logout() => _service.logout();

  Future<void> toggleFavourite(String userId, String itemId) =>
      _service.toggleFavourite(userId, itemId);
}
