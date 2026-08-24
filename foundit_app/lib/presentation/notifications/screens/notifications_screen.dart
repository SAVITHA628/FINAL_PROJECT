import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../providers/notification_provider.dart';
import '../../common/widgets/empty_state.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'VERIFICATION_RESULT':
        return Icons.verified_user_rounded;
      case 'STATUS_CHANGED':
        return Icons.swap_horizontal_circle_rounded;
      case 'ITEM_CLAIMED':
        return Icons.touch_app_rounded;
      case 'ITEM_RETURNED':
        return Icons.assignment_turned_in_rounded;
      case 'POSSIBLE_MATCH':
        return Icons.auto_awesome_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'VERIFICATION_RESULT':
        return AppColors.primary;
      case 'STATUS_CHANGED':
        return AppColors.info;
      case 'ITEM_CLAIMED':
        return AppColors.warning;
      case 'ITEM_RETURNED':
        return AppColors.success;
      case 'POSSIBLE_MATCH':
        return AppColors.secondary;
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifsAsync = ref.watch(userNotificationsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Notifications'),
      ),
      body: notifsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (notifs) {
          if (notifs.isEmpty) {
            return const EmptyState(
              icon: Icons.notifications_none_rounded,
              title: 'No notifications',
              message:
                  'You will receive updates when items are verified, claimed, returned, or matched.',
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: notifs.length,
            itemBuilder: (context, index) {
              final n = notifs[index];
              final icon = _getNotificationIcon(n.type);
              final color = _getNotificationColor(n.type);

              return GestureDetector(
                onTap: () {
                  ref.read(fcmServiceProvider).markAsRead(n.id);
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: n.isRead ? AppColors.surface : AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: n.isRead
                          ? AppColors.border
                          : color.withOpacity(0.4),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(icon, size: 20, color: color),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    n.title,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: n.isRead
                                          ? FontWeight.w600
                                          : FontWeight.w800,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                                if (!n.isRead) ...[
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: AppColors.primary,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                ],
                                Text(
                                  DateFormatter.timeAgo(n.createdAt),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              n.body,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
