import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import '../models/notification_model.dart';

class FcmService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _notifications =>
      _db.collection('notifications');
  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection('users');

  /// Initialize FCM permissions and store user device token securely
  Future<void> initialize(String userId) async {
    try {
      final settings = await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        final token = await _fcm.getToken();
        if (token != null) {
          await _saveFcmToken(userId, token);
        }

        // Token refresh listener
        _fcm.onTokenRefresh.listen((newToken) {
          _saveFcmToken(userId, newToken);
        });
      }

      // Foreground message listener
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('FCM Foreground Message: ${message.notification?.title}');
      });
    } catch (e) {
      debugPrint('FCM Initialization Warning: $e');
    }
  }

  Future<void> _saveFcmToken(String userId, String token) async {
    try {
      await _users.doc(userId).set({
        'fcmToken': token,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {}
  }

  /// Create notification payload in Firestore (can be listened to or pushed via FCM HTTP v1 / Cloud Functions)
  Future<void> sendNotification({
    required String recipientId,
    required String title,
    required String body,
    required String type,
    String? itemId,
  }) async {
    final notif = NotificationModel(
      id: 'notif_${DateTime.now().millisecondsSinceEpoch}',
      recipientId: recipientId,
      title: title,
      body: body,
      type: type,
      itemId: itemId,
      isRead: false,
      createdAt: DateTime.now(),
    );
    await _notifications.add(notif.toMap());
  }

  // 1. Scenario 1: Ownership Verification Result
  Future<void> sendVerificationResult({
    required String recipientId,
    required String itemId,
    required bool isVerified,
    String? adminNotes,
  }) async {
    final title = isVerified
        ? '✅ Claim Ownership Verified!'
        : '❌ Ownership Verification Rejected';
    final body = isVerified
        ? 'Your item claim has been verified by the campus admin.'
        : 'Verification details did not match. ${adminNotes ?? ""}';

    await sendNotification(
      recipientId: recipientId,
      title: title,
      body: body,
      type: 'VERIFICATION_RESULT',
      itemId: itemId,
    );
  }

  // 2. Scenario 2: Item Status Changed
  Future<void> sendStatusChanged({
    required String recipientId,
    required String itemId,
    required String itemTitle,
    required String newStatus,
  }) async {
    await sendNotification(
      recipientId: recipientId,
      title: '📦 Item Status Updated',
      body: 'Status for "$itemTitle" changed to ${newStatus.toUpperCase()}.',
      type: 'STATUS_CHANGED',
      itemId: itemId,
    );
  }

  // 3. Scenario 3: Item Claimed
  Future<void> sendItemClaimed({
    required String recipientId,
    required String itemId,
    required String itemTitle,
    required String claimantName,
  }) async {
    await sendNotification(
      recipientId: recipientId,
      title: '🎯 Someone Claimed Your Item!',
      body: '$claimantName submitted a claim request for "$itemTitle".',
      type: 'ITEM_CLAIMED',
      itemId: itemId,
    );
  }

  // 4. Scenario 4: Item Returned
  Future<void> sendItemReturned({
    required String recipientId,
    required String itemId,
    required String itemTitle,
  }) async {
    await sendNotification(
      recipientId: recipientId,
      title: '🎉 Item Returned!',
      body: '"$itemTitle" has been marked as returned to its owner.',
      type: 'ITEM_RETURNED',
      itemId: itemId,
    );
  }

  // 5. Scenario 5: Future Possible-Match Notification (AI/ML Python system integration point)
  Future<void> sendPossibleMatch({
    required String recipientId,
    required String lostItemId,
    required String matchItemTitle,
    required double confidenceScore,
  }) async {
    final scorePct = (confidenceScore * 100).round();
    await sendNotification(
      recipientId: recipientId,
      title: '🔍 AI Possible Match Found ($scorePct%)',
      body: 'A found item "$matchItemTitle" looks similar to your reported item.',
      type: 'POSSIBLE_MATCH',
      itemId: lostItemId,
    );
  }

  /// Stream notifications for authenticated user
  Stream<List<NotificationModel>> streamNotifications(String recipientId) {
    return _notifications
        .where('recipientId', isEqualTo: recipientId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => NotificationModel.fromMap(d.id, d.data())).toList());
  }

  Future<void> markAsRead(String notificationId) async {
    await _notifications.doc(notificationId).update({'isRead': true});
  }
}
