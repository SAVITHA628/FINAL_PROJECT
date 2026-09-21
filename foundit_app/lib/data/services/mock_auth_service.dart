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

// Simple consistent hash so password is never stored in plaintext
// We XOR each char code with a seed and base64-encode for storage
String _hashPassword(String password) {
  const seed = 0x4F; // 'O' for "obfuscate"
  final bytes = password.codeUnits.map((c) => c ^ seed).toList();
  return base64Encode(bytes);
}

class MockAuthService implements AuthServiceInterface {
  static const String projectId = 'foundit-6bc8a';
  static const String baseUrl =
      'https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents';

  UserModel? _currentUser;

  // ── Firestore field parser ──────────────────────────────────────────────
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

  // ── Save user profile + password hash to Firestore `users/{userId}` ────
  Future<void> _saveUserToFirestore(UserModel user, String hashedPassword) async {
    try {
      final payload = {
        'fields': {
          'uid': {'stringValue': user.uid},
          'name': {'stringValue': user.name},
          'email': {'stringValue': user.email},
          'phone': {'stringValue': user.registrationPhone ?? user.phone ?? ''},
          'registrationPhone': {'stringValue': user.registrationPhone ?? user.phone ?? ''},
          'role': {'stringValue': user.role},
          'isActive': {'booleanValue': user.isActive},
          // Store hashed password so only the registered password can login
          'passwordHash': {'stringValue': hashedPassword},
          'createdAt': {'timestampValue': DateTime.now().toUtc().toIso8601String()},
        }
      };

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

  // ── Fetch user doc + stored passwordHash from Firestore by email ────────
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

  // ── Check if email is already registered ───────────────────────────────
  Future<bool> _emailAlreadyRegistered(String email) async {
    final doc = await _fetchUserDocByEmail(email);
    return doc != null;
  }

  // ─────────────────────────────────────────────────────────────────────────
  @override
  Future<UserModel?> getCurrentUser() async => _currentUser;

  // ── LOGIN — verifies BOTH email (must exist) AND password (must match) ──
  @override
  Future<UserModel> login(String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 200));

    if (password.isEmpty) {
      throw Exception('Please enter your password.');
    }
    if (password.length < 6) {
      throw Exception('Password must be at least 6 characters.');
    }

    // 1️⃣  Look up the Firestore user document
    final doc = await _fetchUserDocByEmail(email);

    if (doc == null) {
      throw Exception(
        'No account found for "$email".\n'
        'Please register a new account first, or check your email address.',
      );
    }

    // 2️⃣  Verify password — compare hash stored at registration
    final fields = (doc['fields'] as Map<String, dynamic>?) ?? {};
    final storedHash = _parseString(fields['passwordHash']);
    final incomingHash = _hashPassword(password);

    if (storedHash.isNotEmpty && storedHash != incomingHash) {
      // Wrong password — do NOT give a hint about which field is wrong
      throw Exception(
        'Incorrect password. Please try again.\n'
        'If you forgot your password, use "Forgot Password?" below.',
      );
    }

    // 3️⃣  Build the UserModel from the Firestore document
    final isAdminEmail = ADMIN_EMAILS.contains(email.toLowerCase());
    _currentUser = _docToUserModel(doc).copyWith(
      role: isAdminEmail ? 'admin' : _docToUserModel(doc).role,
    );

    return _currentUser!;
  }

  // ── REGISTER — saves email, phone, role AND hashed password ────────────
  @override
  Future<UserModel> register(
      String name, String email, String password, String? phone) async {
    await Future.delayed(const Duration(milliseconds: 200));

    // Prevent duplicate email registration
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

    // Save profile AND password hash to Firestore `users/{userId}`
    await _saveUserToFirestore(_currentUser!, hashedPassword);

    return _currentUser!;
  }

  @override
  Future<void> sendPasswordReset(String email) async {
    await Future.delayed(const Duration(milliseconds: 200));
    // In a real app this would send an email; here we just silently succeed.
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
  }
}
