import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../models/notification_model.dart';
import '../providers/notification_provider.dart';
import '../widgets/modals/profile_details_modal.dart';

/// Notifications Inbox Screen
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  IconData _getIconForType(NotificationType type) {
    switch (type) {
      case NotificationType.interestReceived:
        return Icons.favorite_rounded;
      case NotificationType.profileLiked:
        return Icons.thumb_up_rounded;
      case NotificationType.newMatchFound:
        return Icons.stars_rounded;
      case NotificationType.profileViewed:
        return Icons.visibility_rounded;
      case NotificationType.profileUpdated:
        return Icons.update_rounded;
    }
  }

  Color _getColorForType(NotificationType type) {
    switch (type) {
      case NotificationType.interestReceived:
        return AppTheme.rose;
      case NotificationType.profileLiked:
        return Colors.pinkAccent;
      case NotificationType.newMatchFound:
        return AppTheme.gold;
      case NotificationType.profileViewed:
        return Colors.blueAccent;
      case NotificationType.profileUpdated:
        return AppTheme.burgundy;
    }
  }

  @override
  Widget build(BuildContext context) {
    final notifProvider = context.watch<NotificationProvider>();
    final notifications = notifProvider.notifications;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (notifications.isNotEmpty)
            TextButton(
              onPressed: () {
                notifProvider.markAllAsRead();
              },
              child: const Text('Mark all read', style: TextStyle(color: AppTheme.burgundy)),
            ),
        ],
      ),
      body: notifications.isEmpty ? const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.notifications_none_rounded, size: 64, color: AppTheme.textMuted),
                  SizedBox(height: 16),
                  Text(
                    'No Notifications Yet',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'You will be notified when matches like or view your profile.',
                    style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              itemCount: notifications.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final item = notifications[index];
                return Dismissible(
                  key: Key(item.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    padding: const EdgeInsets.only(right: 20),
                    alignment: Alignment.centerRight,
                    decoration: BoxDecoration(
                      color: AppTheme.error,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
                  ),
                  onDismissed: (_) {
                    notifProvider.removeNotification(item.id);
                  },
                  child: InkWell(
                    onTap: () {
                      notifProvider.markAsRead(item.id);
                      if (item.relatedProfile != null) {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) => ProfileDetailsModal(
                            profile: item.relatedProfile!,
                            onToggleSave: () {},
                            onExpressInterest: () {},
                          ),
                        );
                      }
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: item.isRead ? Colors.white : AppTheme.roseLight.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: item.isRead ? AppTheme.cardBorder : AppTheme.rose.withValues(alpha: 0.3),
                          width: 1.2,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: _getColorForType(item.type).withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(_getIconForType(item.type), color: _getColorForType(item.type), size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Flexible(
                                      child: Text(
                                        item.title,
                                        style: TextStyle(
                                          fontWeight: item.isRead ? FontWeight.w600 : FontWeight.w800,
                                          fontSize: 14,
                                          color: AppTheme.textPrimary,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (!item.isRead)
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: const BoxDecoration(
                                          color: AppTheme.rose,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  item.message,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: AppTheme.textSecondary,
                                    height: 1.35,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '${item.timestamp.hour}:${item.timestamp.minute.toString().padLeft(2, '0')} â€¢ Tap to view',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppTheme.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}


