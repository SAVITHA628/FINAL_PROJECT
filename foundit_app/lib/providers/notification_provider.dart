import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/notification_model.dart';
import '../data/services/fcm_service.dart';
import 'app_providers.dart';

final fcmServiceProvider = Provider<FcmService>((ref) => FcmService());

final userNotificationsProvider =
    StreamProvider<List<NotificationModel>>((ref) async* {
  final user = await ref.watch(currentUserProvider.future);
  final fcm = ref.watch(fcmServiceProvider);
  if (user == null) {
    yield [];
    return;
  }
  yield* fcm.streamNotifications(user.uid);
});

final unreadNotificationCountProvider = Provider<int>((ref) {
  final notifsAsync = ref.watch(userNotificationsProvider);
  return notifsAsync.when(
    data: (list) => list.where((n) => !n.isRead).length,
    loading: () => 0,
    error: (_, __) => 0,
  );
});
