import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';

/// Notification Provider managing user in-app notifications.
/// Fetches real notifications from the backend.
class NotificationProvider extends ChangeNotifier {
  List<NotificationItem> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = false;
  String? _error;

  List<NotificationItem> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchNotifications() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final result = await MatNotificationService.fetchNotifications();
      _notifications = result.notifications;
      _unreadCount = result.unreadCount;
    } catch (_) {
      _error = 'Could not load notifications.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markAsRead(String id) async {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index < 0) return;

    // Optimistic
    if (!_notifications[index].isRead) {
      _notifications[index].isRead = true;
      _unreadCount = (_unreadCount - 1).clamp(0, _unreadCount);
      notifyListeners();
    }

    await MatNotificationService.markAsRead(id);
  }

  Future<void> markAllAsRead() async {
    for (var n in _notifications) {
      n.isRead = true;
    }
    _unreadCount = 0;
    notifyListeners();
    await MatNotificationService.markAllAsRead();
  }

  Future<void> removeNotification(String id) async {
    final wasUnread = _notifications.any((n) => n.id == id && !n.isRead);
    _notifications.removeWhere((n) => n.id == id);
    if (wasUnread && _unreadCount > 0) _unreadCount--;
    notifyListeners();
    await MatNotificationService.deleteNotification(id);
  }

  /// Reset notification state on logout
  void clear() {
    _notifications = [];
    _unreadCount = 0;
    _isLoading = false;
    _error = null;
    notifyListeners();
  }
}
