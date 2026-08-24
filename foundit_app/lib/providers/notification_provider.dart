// Notification provider - Firestore-free stub for offline build
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/notification_model.dart';
import '../data/services/fcm_service.dart';

final fcmServiceProvider = Provider<FcmService>((ref) => FcmService());

final userNotificationsProvider =
    StreamProvider<List<NotificationModel>>((ref) async* {
  yield [];
});

final unreadNotificationCountProvider = Provider<int>((ref) {
  final notifsAsync = ref.watch(userNotificationsProvider);
  return notifsAsync.when(
    data: (list) => list.where((n) => !n.isRead).length,
    loading: () => 0,
    error: (_, __) => 0,
  );
});
