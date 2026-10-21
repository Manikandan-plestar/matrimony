import 'matrimony_profile_model.dart';

enum InterestStatus { pending, accepted, declined, withdrawn, removed }

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
  final String? interestId;
  final MatrimonyProfileModel profile;
  final int compatibilityScore; // e.g. 94%
  final List<String> matchingFactors; // e.g. ["Location: Chennai", "Education: Master's", "Diet: Vegetarian"]
  final DateTime matchedDate;

  MatchItem({
    required this.id,
    this.interestId,
    required this.profile,
    required this.compatibilityScore,
    required this.matchingFactors,
    required this.matchedDate,
  });
}

class AnalyticsPeriodStats {
  final int views;
  final int saves;

  const AnalyticsPeriodStats({required this.views, required this.saves});

  factory AnalyticsPeriodStats.fromJson(Map<String, dynamic> json) =>
      AnalyticsPeriodStats(
        views: (json['views'] as num?)?.toInt() ?? 0,
        saves: (json['saves'] as num?)?.toInt() ?? 0,
      );
}

class ProfileAnalyticsModel {
  final int totalViews;
  final int totalSaves;
  final int periodViews;
  final int periodSaves;
  final String currentPeriod; // 'day', 'week', 'month'
  final AnalyticsPeriodStats daily;
  final AnalyticsPeriodStats weekly;
  final AnalyticsPeriodStats monthly;

  const ProfileAnalyticsModel({
    required this.totalViews,
    required this.totalSaves,
    required this.periodViews,
    required this.periodSaves,
    required this.currentPeriod,
    required this.daily,
    required this.weekly,
    required this.monthly,
  });

  factory ProfileAnalyticsModel.empty() => const ProfileAnalyticsModel(
    totalViews: 0,
    totalSaves: 0,
    periodViews: 0,
    periodSaves: 0,
    currentPeriod: 'day',
    daily: AnalyticsPeriodStats(views: 0, saves: 0),
    weekly: AnalyticsPeriodStats(views: 0, saves: 0),
    monthly: AnalyticsPeriodStats(views: 0, saves: 0),
  );

  factory ProfileAnalyticsModel.fromJson(Map<String, dynamic> json, String period) {
    final a = json['analytics'] as Map<String, dynamic>? ?? json;
    return ProfileAnalyticsModel(
      totalViews: (a['totalViews'] as num?)?.toInt() ?? 0,
      totalSaves: (a['totalSaves'] as num?)?.toInt() ?? 0,
      periodViews: (a['periodViews'] as num?)?.toInt() ?? 0,
      periodSaves: (a['periodSaves'] as num?)?.toInt() ?? 0,
      currentPeriod: period,
      daily: AnalyticsPeriodStats.fromJson(a['daily'] as Map<String, dynamic>? ?? {}),
      weekly: AnalyticsPeriodStats.fromJson(a['weekly'] as Map<String, dynamic>? ?? {}),
      monthly: AnalyticsPeriodStats.fromJson(a['monthly'] as Map<String, dynamic>? ?? {}),
    );
  }
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
