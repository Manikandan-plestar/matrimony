/// Notification Service — fetch, mark read, delete notifications
library;

import 'api_service.dart';
import 'auth_service.dart';
import '../models/notification_model.dart';
import '../models/matrimony_profile_model.dart';

class MatNotificationService {
  static Future<
      ({
        List<NotificationItem> notifications,
        int unreadCount,
      })> fetchNotifications({int page = 1, int limit = 30}) async {
    final result = await ApiService.get('/api/mat/notifications', queryParams: {
      'page': '$page',
      'limit': '$limit',
    });

    if (result['success'] != true) {
      return (notifications: <NotificationItem>[], unreadCount: 0);
    }

    final unread = (result['unreadCount'] as num?)?.toInt() ?? 0;
    final list = result['notifications'];
    if (list is! List) return (notifications: <NotificationItem>[], unreadCount: unread);

    final notifications = list.whereType<Map<String, dynamic>>().map((d) {
      NotificationType type;
      switch (d['type'] as String? ?? '') {
        case 'interest_received':
          type = NotificationType.interestReceived;
        case 'interest_accepted':
        case 'new_match':
          type = NotificationType.newMatchFound;
        case 'interest_rejected':
          type = NotificationType.profileLiked; // closest generic type
        case 'profile_viewed':
          type = NotificationType.profileViewed;
        default:
          type = NotificationType.profileUpdated;
      }

      MatrimonyProfileModel? relatedProfile;
      final pData = d['relatedProfile'];
      if (pData is Map<String, dynamic>) {
        relatedProfile = profileFromApi(pData);
      }

      DateTime ts;
      try {
        ts = DateTime.parse(d['timestamp'] as String? ?? '');
      } catch (_) {
        ts = DateTime.now();
      }

      return NotificationItem(
        id: '${d['id']}',
        type: type,
        title: d['title'] as String? ?? '',
        message: d['message'] as String? ?? '',
        timestamp: ts,
        relatedProfile: relatedProfile,
        isRead: d['isRead'] == true,
      );
    }).toList();

    return (notifications: notifications, unreadCount: unread);
  }

  static Future<bool> markAsRead(String notificationId) async {
    final result = await ApiService.put('/api/mat/notifications/$notificationId/read');
    return result['success'] == true;
  }

  static Future<bool> markAllAsRead() async {
    final result = await ApiService.put('/api/mat/notifications/mark-all-read');
    return result['success'] == true;
  }

  static Future<bool> deleteNotification(String notificationId) async {
    final result = await ApiService.delete('/api/mat/notifications/$notificationId');
    return result['success'] == true;
  }
}
