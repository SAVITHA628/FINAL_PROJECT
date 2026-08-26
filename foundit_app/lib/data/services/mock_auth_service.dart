import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/user_model.dart';
import 'auth_service_interface.dart';

// ignore: constant_identifier_names
const ADMIN_EMAILS = [
  'admin@foundit.com',
  'admin@foundit.app',
  'jashrishi@gmail.com',
  'savitha609@gmail.com',
];

class MockAuthService implements AuthServiceInterface {
  static const String projectId = 'foundit-6bc8a';
  static const String baseUrl =
      'https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents';

  UserModel? _currentUser;

  // ── Helper to parse Firestore REST field format for User document ────
  String _parseString(Map<String, dynamic>? field) {
    if (field == null) return '';
    return field['stringValue'] ?? field['integerValue']?.toString() ?? '';
  }

  UserModel _docToUserModel(Map<String, dynamic> docJson) {
    final namePath = docJson['name'] as String? ?? '';
    final id = namePath.split('/').last;
    final fields = (docJson['fields'] as Map<String, dynamic>?) ?? {};

    final name = _parseString(fields['name']);
    final email = _parseString(fields['email']);
    final regPhone = _parseString(fields['registrationPhone']).isNotEmpty
        ? _parseString(fields['registrationPhone'])
        : _parseString(fields['phone']);
    final role = _parseString(fields['role']).isEmpty ? 'user' : _parseString(fields['role']);

    return UserModel(
      uid: id,
      name: name,
      email: email,
      phone: regPhone,
      registrationPhone: regPhone,
      role: role,
      isActive: true,
      favouriteItemIds: [],
      createdAt: DateTime.now(),
    );
  }

  // ── Save User Profile to Firestore collection `users/{userId}` ────────
  Future<void> _saveUserToFirestore(UserModel user) async {
    try {
      final docId = user.uid;
      final payload = {
        'fields': {
          'uid': {'stringValue': user.uid},
          'name': {'stringValue': user.name},
          'email': {'stringValue': user.email},
          'phone': {'stringValue': user.registrationPhone ?? user.phone ?? ''},
          'registrationPhone': {'stringValue': user.registrationPhone ?? user.phone ?? ''},
          'role': {'stringValue': user.role},
          'isActive': {'booleanValue': user.isActive},
          'createdAt': {'timestampValue': DateTime.now().toUtc().toIso8601String()},
        }
      };

      await http.patch(
        Uri.parse('$baseUrl/users/$docId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      // Save a welcome notification into Firestore for this user
      await _createWelcomeNotification(user.uid, user.name);
    } catch (e) {
      debugPrint('Firestore save user profile error: $e');
    }
  }

  Future<void> _createWelcomeNotification(String userId, String name) async {
    try {
      final payload = {
        'fields': {
          'recipientId': {'stringValue': userId},
          'title': {'stringValue': 'Welcome to FoundIt! 👋'},
          'body': {'stringValue': 'Hi $name, your campus Lost & Found account is active. Report lost items and receive real-time match alerts.'},
          'type': {'stringValue': 'WELCOME'},
          'itemId': {'stringValue': ''},
          'isRead': {'booleanValue': false},
          'createdAt': {'timestampValue': DateTime.now().toUtc().toIso8601String()},
        }
      };
      await http.post(
        Uri.parse('$baseUrl/notifications'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );
    } catch (_) {}
  }

  // ── Fetch User Profile from Firestore collection `users` ──────────────
  Future<UserModel?> _fetchUserFromFirestoreByEmail(String email) async {
    try {
      final res = await http
          .get(Uri.parse('$baseUrl/users'))
          .timeout(const Duration(seconds: 4));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final docs = (data['documents'] as List<dynamic>?) ?? [];
        for (final d in docs) {
          final fields = (d['fields'] as Map<String, dynamic>?) ?? {};
          final docEmail = _parseString(fields['email']).toLowerCase();
          if (docEmail == email.toLowerCase()) {
            return _docToUserModel(d as Map<String, dynamic>);
          }
        }
      }
    } catch (e) {
      debugPrint('Firestore fetch user profile error: $e');
    }
    return null;
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    return _currentUser;
  }

  @override
  Future<UserModel> login(String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 200));
    if (password.length < 6) {
      throw Exception('Password must be at least 6 characters.');
    }

    final isAdminEmail = ADMIN_EMAILS.contains(email.toLowerCase());
    final existingUser = await _fetchUserFromFirestoreByEmail(email);

    if (existingUser != null) {
      _currentUser = existingUser.copyWith(
        role: isAdminEmail ? 'admin' : existingUser.role,
      );
    } else {
      final docId = 'user_${email.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}';
      _currentUser = UserModel(
        uid: docId,
        name: email.split('@')[0],
        email: email,
        phone: '+911111111111',
        registrationPhone: '+911111111111',
        role: isAdminEmail ? 'admin' : 'user',
        isActive: true,
        favouriteItemIds: [],
        createdAt: DateTime.now(),
      );
      await _saveUserToFirestore(_currentUser!);
    }

    return _currentUser!;
  }

  @override
  Future<UserModel> register(
      String name, String email, String password, String? phone) async {
    await Future.delayed(const Duration(milliseconds: 200));
    if (email.contains('alreadyused')) {
      throw Exception('An account already exists for this email address.');
    }

    final isAdminEmail = ADMIN_EMAILS.contains(email.toLowerCase());
    final regPhone = (phone != null && phone.trim().isNotEmpty) ? phone.trim() : '+911111111111';
    final docId = 'user_${DateTime.now().millisecondsSinceEpoch}';

    _currentUser = UserModel(
      uid: docId,
      name: name,
      email: email,
      phone: regPhone,
      registrationPhone: regPhone,
      role: isAdminEmail ? 'admin' : 'user',
      isActive: true,
      favouriteItemIds: [],
      createdAt: DateTime.now(),
    );

    // Save registration profile to Firestore collection `users/{userId}`
    await _saveUserToFirestore(_currentUser!);

    return _currentUser!;
  }

  @override
  Future<void> sendPasswordReset(String email) async {
    await Future.delayed(const Duration(milliseconds: 200));
  }

  @override
  Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 100));
    _currentUser = null;
  }

  @override
  Future<void> toggleFavourite(String userId, String itemId) async {
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
