// FCM Service stub - no Firebase Messaging dependency
import 'package:flutter/foundation.dart';
import '../models/notification_model.dart';

class FcmService {
  Future<void> initialize(String userId) async {
    debugPrint('FCM: offline mode - no push notifications');
  }

  Future<void> markAsRead(String notificationId) async {}

  Stream<List<NotificationModel>> streamNotifications(String recipientId) {
    return Stream.value([]);
  }
}
