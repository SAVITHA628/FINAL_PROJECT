import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  final String id;
  final String recipientId;
  final String title;
  final String body;
  final String type; // VERIFICATION_RESULT, STATUS_CHANGED, ITEM_CLAIMED, ITEM_RETURNED, POSSIBLE_MATCH
  final String? itemId;
  final bool isRead;
  final DateTime? createdAt;

  const NotificationModel({
    required this.id,
    required this.recipientId,
    required this.title,
    required this.body,
    required this.type,
    this.itemId,
    this.isRead = false,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'notificationId': id,
      'recipientId': recipientId,
      'title': title,
      'body': body,
      'type': type,
      'itemId': itemId,
      'isRead': isRead,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
    };
  }

  factory NotificationModel.fromMap(String docId, Map<String, dynamic> map) {
    DateTime? parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val);
      return null;
    }

    return NotificationModel(
      id: docId,
      recipientId: map['recipientId'] ?? '',
      title: map['title'] ?? '',
      body: map['body'] ?? '',
      type: map['type'] ?? 'GENERAL',
      itemId: map['itemId'],
      isRead: map['isRead'] ?? false,
      createdAt: parseDate(map['createdAt']),
    );
  }
}
