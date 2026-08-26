import '../mock/mock_data.dart';
import '../models/user_model.dart';
import 'auth_service_interface.dart';

const ADMIN_EMAILS = [
  'admin@foundit.com',
  'admin@foundit.app',
  'jashrishi@gmail.com',
  'savitha609@gmail.com',
];

class MockAuthService implements AuthServiceInterface {
  UserModel? _currentUser; // Default unauthenticated until user logs in or registers

  @override
  Future<UserModel?> getCurrentUser() async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _currentUser;
  }

  @override
  Future<UserModel> login(String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (password.length < 6) {
      throw Exception('Password must be at least 6 characters.');
    }
    final isAdminEmail = ADMIN_EMAILS.contains(email.toLowerCase());
    _currentUser = MockData.currentUser.copyWith(
      email: email,
      name: email.split('@')[0],
      role: isAdminEmail ? 'admin' : 'user',
    );
    return _currentUser!;
  }

  @override
  Future<UserModel> register(
      String name, String email, String password, String? phone) async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (email.contains('alreadyused')) {
      throw Exception('An account already exists for this email address.');
    }
    final isAdminEmail = ADMIN_EMAILS.contains(email.toLowerCase());
    _currentUser = UserModel(
      uid: 'user_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      email: email,
      phone: phone,
      role: isAdminEmail ? 'admin' : 'user',
      isActive: true,
      favouriteItemIds: [],
      createdAt: DateTime.now(),
    );
    return _currentUser!;
  }

  @override
  Future<void> sendPasswordReset(String email) async {
    await Future.delayed(const Duration(milliseconds: 300));
  }

  @override
  Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 150));
    _currentUser = null;
  }

  @override
  Future<void> toggleFavourite(String userId, String itemId) async {
    await Future.delayed(const Duration(milliseconds: 150));
    if (_currentUser == null) return;
    final currentFavs = List<String>.from(_currentUser!.favouriteItemIds);
    if (currentFavs.contains(itemId)) {
      currentFavs.remove(itemId);
    } else {
      currentFavs.add(itemId);
    }
    _currentUser = _currentUser!.copyWith(favouriteItemIds: currentFavs);
  }
}
