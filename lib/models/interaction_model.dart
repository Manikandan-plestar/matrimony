import 'matrimony_profile_model.dart';

enum InterestStatus { pending, accepted, declined, withdrawn }

/// Interest Model for Sent & Received requests
class InterestItem {
  final String id;
  final MatrimonyProfileModel profile;
  final DateTime timestamp;
  final bool isReceived; // true = Received, false = Sent
  InterestStatus status;
  DateTime? withdrawnAt;

  InterestItem({
    required this.id,
    required this.profile,
    required this.timestamp,
    required this.isReceived,
    this.status = InterestStatus.pending,
    this.withdrawnAt,
  });
}

/// Mutual Match model
class MatchItem {
  final String id;
  final MatrimonyProfileModel profile;
  final int compatibilityScore; // e.g. 94%
  final List<String> matchingFactors; // e.g. ["Location: Chennai", "Education: Master's", "Diet: Vegetarian"]
  final DateTime matchedDate;

  MatchItem({
    required this.id,
    required this.profile,
    required this.compatibilityScore,
    required this.matchingFactors,
    required this.matchedDate,
  });
}

/// Profile Visitor record
class VisitorItem {
  final String id;
  final MatrimonyProfileModel profile;
  final DateTime visitedAt;
  final int visitCount;

  VisitorItem({
    required this.id,
    required this.profile,
    required this.visitedAt,
    this.visitCount = 1,
  });
}
