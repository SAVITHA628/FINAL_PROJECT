import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/notification_model.dart';

class FcmService {
  static const String projectId = 'foundit-6bc8a';
  static const String baseUrl =
      'https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents';

  Future<void> initialize(String userId) async {
    debugPrint('FCM: Initialized in-app notification sync for $userId');
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      final payload = {
        'fields': {
          'isRead': {'booleanValue': true},
        }
      };
      await http.patch(
        Uri.parse('$baseUrl/notifications/$notificationId?updateMask.fieldPaths=isRead'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }

  Stream<List<NotificationModel>> streamNotifications(String recipientId) async* {
    while (true) {
      try {
        final res = await http
            .get(Uri.parse('$baseUrl/notifications'))
            .timeout(const Duration(seconds: 4));

        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          final docs = (data['documents'] as List<dynamic>?) ?? [];
          final notifs = docs.map((d) {
            final fields = d['fields'] as Map<String, dynamic>? ?? {};
            final id = (d['name'] as String).split('/').last;
            return NotificationModel(
              id: id,
              recipientId: fields['recipientId']?['stringValue'] ?? '',
              title: fields['title']?['stringValue'] ?? '',
              body: fields['body']?['stringValue'] ?? '',
              type: fields['type']?['stringValue'] ?? 'general',
              itemId: fields['itemId']?['stringValue'],
              isRead: fields['isRead']?['booleanValue'] ?? false,
              createdAt: fields['createdAt']?['timestampValue'] != null
                  ? DateTime.tryParse(fields['createdAt']['timestampValue']) ?? DateTime.now()
                  : DateTime.now(),
            );
          }).where((n) => n.recipientId == recipientId || n.recipientId.isEmpty).toList();

          yield notifs;
        } else {
          yield [];
        }
      } catch (_) {
        yield [];
      }
      await Future.delayed(const Duration(seconds: 5));
    }
  }
}
