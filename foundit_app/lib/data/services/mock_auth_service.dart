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

String _hashPassword(String password) {
  const seed = 0x4F;
  final bytes = password.codeUnits.map((c) => c ^ seed).toList();
  return base64Encode(bytes);
}

class MockAuthService implements AuthServiceInterface {
  static const String projectId = 'foundit-6bc8a';
  static const String baseUrl =
      'https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents';

  UserModel? _currentUser;

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
    final role =
        _parseString(fields['role']).isEmpty ? 'user' : _parseString(fields['role']);

    final favArray = fields['favouriteItemIds']?['arrayValue']?['values'] as List<dynamic>? ?? [];
    final favIds = favArray
        .map((v) => (v as Map<String, dynamic>)['stringValue'] as String? ?? '')
        .where((fId) => fId.isNotEmpty)
        .toList();

    return UserModel(
      uid: id,
      name: name,
      email: email,
      phone: regPhone,
      registrationPhone: regPhone,
      role: role,
      isActive: true,
      favouriteItemIds: favIds,
      createdAt: DateTime.now(),
    );
  }

  Future<void> _saveUserToFirestore(UserModel user, [String? hashedPassword]) async {
    try {
      final favValues = user.favouriteItemIds
          .map((id) => {'stringValue': id})
          .toList();

      final Map<String, dynamic> fieldsMap = {
        'uid': {'stringValue': user.uid},
        'name': {'stringValue': user.name},
        'email': {'stringValue': user.email},
        'phone': {'stringValue': user.registrationPhone ?? user.phone ?? ''},
        'registrationPhone': {'stringValue': user.registrationPhone ?? user.phone ?? ''},
        'role': {'stringValue': user.role},
        'isActive': {'booleanValue': user.isActive},
        'favouriteItemIds': {'arrayValue': {'values': favValues}},
        'createdAt': {'timestampValue': DateTime.now().toUtc().toIso8601String()},
      };

      if (hashedPassword != null && hashedPassword.isNotEmpty) {
        fieldsMap['passwordHash'] = {'stringValue': hashedPassword};
      }

      final payload = {'fields': fieldsMap};

      await http.patch(
        Uri.parse('$baseUrl/users/${user.uid}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

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
          'body': {
            'stringValue':
                'Hi $name, your campus Lost & Found account is active. '
                    'Report lost items and receive real-time match alerts.'
          },
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

  Future<Map<String, dynamic>?> _fetchUserDocByEmail(String email) async {
    try {
      final res = await http
          .get(Uri.parse('$baseUrl/users'))
          .timeout(const Duration(seconds: 6));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final docs = (data['documents'] as List<dynamic>?) ?? [];
        for (final d in docs) {
          final fields = (d['fields'] as Map<String, dynamic>?) ?? {};
          final docEmail = _parseString(fields['email']).toLowerCase();
          if (docEmail == email.toLowerCase()) {
            return d as Map<String, dynamic>;
          }
        }
      }
    } catch (e) {
      debugPrint('Firestore fetch user error: $e');
    }
    return null;
  }

  Future<bool> _emailAlreadyRegistered(String email) async {
    final doc = await _fetchUserDocByEmail(email);
    return doc != null;
  }

  @override
  Future<UserModel?> getCurrentUser() async => _currentUser;

  @override
  Future<UserModel> login(String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 200));

    if (password.isEmpty) {
      throw Exception('Please enter your password.');
    }
    if (password.length < 6) {
      throw Exception('Password must be at least 6 characters.');
    }

    final doc = await _fetchUserDocByEmail(email);

    if (doc == null) {
      throw Exception(
        'No account found for "$email".\n'
        'Please register a new account first, or check your email address.',
      );
    }

    final fields = (doc['fields'] as Map<String, dynamic>?) ?? {};
    final storedHash = _parseString(fields['passwordHash']);
    final incomingHash = _hashPassword(password);

    if (storedHash.isNotEmpty && storedHash != incomingHash) {
      throw Exception(
        'Incorrect password. Please try again.\n'
        'If you forgot your password, use "Forgot Password?" below.',
      );
    }

    final isAdminEmail = ADMIN_EMAILS.contains(email.toLowerCase());
    _currentUser = _docToUserModel(doc).copyWith(
      role: isAdminEmail ? 'admin' : _docToUserModel(doc).role,
    );

    return _currentUser!;
  }

  @override
  Future<UserModel> register(
      String name, String email, String password, String? phone) async {
    await Future.delayed(const Duration(milliseconds: 200));

    final alreadyExists = await _emailAlreadyRegistered(email);
    if (alreadyExists) {
      throw Exception(
        'An account already exists for "$email". Please sign in instead.',
      );
    }

    final isAdminEmail = ADMIN_EMAILS.contains(email.toLowerCase());
    final regPhone =
        (phone != null && phone.trim().isNotEmpty) ? phone.trim() : '+911111111111';
    final docId = 'user_${DateTime.now().millisecondsSinceEpoch}';
    final hashedPassword = _hashPassword(password);

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

    await _saveUserToFirestore(_currentUser!, hashedPassword);

    return _currentUser!;
  }

  @override
  Future<void> sendPasswordReset(String email) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final doc = await _fetchUserDocByEmail(email);
    if (doc == null) {
      throw Exception('No registered account found with email address "$email".');
    }
  }

  @override
  Future<void> resetPassword(String email, String newPassword) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final doc = await _fetchUserDocByEmail(email);
    if (doc == null) {
      throw Exception('No registered account found with email address "$email".');
    }

    final namePath = doc['name'] as String? ?? '';
    final docId = namePath.split('/').last;

    final hashedPassword = _hashPassword(newPassword);

    final payload = {
      'fields': {
        'passwordHash': {'stringValue': hashedPassword},
      }
    };

    // Update passwordHash field in Cloud Firestore user document
    await http.patch(
      Uri.parse('$baseUrl/users/$docId?updateMask.fieldPaths=passwordHash'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );
  }

  @override
  Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 100));
    _currentUser = null;
  }

  @override
  Future<void> toggleFavourite(String userId, String itemId) async {
    if (_currentUser == null) return;
    final favs = List<String>.from(_currentUser!.favouriteItemIds);
    if (favs.contains(itemId)) {
      favs.remove(itemId);
    } else {
      favs.add(itemId);
    }
    _currentUser = _currentUser!.copyWith(favouriteItemIds: favs);

    await _saveUserToFirestore(_currentUser!);
  }
}
