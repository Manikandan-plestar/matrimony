import 'matrimony_profile_model.dart';

enum NotificationType {
  interestReceived,
  profileLiked,
  newMatchFound,
  profileViewed,
  profileUpdated,
}

class NotificationItem {
  final String id;
  final NotificationType type;
  final String title;
  final String message;
  final DateTime timestamp;
  final MatrimonyProfileModel? relatedProfile;
  bool isRead;

  NotificationItem({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.timestamp,
    this.relatedProfile,
    this.isRead = false,
  });
}
