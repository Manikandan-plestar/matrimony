/// Models for Subscription and Daily Profile Swipe Quota
class SwipeStatusModel {
  final bool isUnlimited;
  final String planName;
  final double planPrice;
  final double upgradePrice;
  final int dailyLimit;
  final int swipesUsedToday;
  final int swipesRemainingToday;
  final DateTime? resetAt;
  final String timezone;
  final String date;

  const SwipeStatusModel({
    required this.isUnlimited,
    required this.planName,
    required this.planPrice,
    required this.upgradePrice,
    required this.dailyLimit,
    required this.swipesUsedToday,
    required this.swipesRemainingToday,
    this.resetAt,
    required this.timezone,
    required this.date,
  });

  bool get hasReachedLimit => !isUnlimited && swipesRemainingToday <= 0;

  factory SwipeStatusModel.initial() {
    return const SwipeStatusModel(
      isUnlimited: false,
      planName: 'Free Plan',
      planPrice: 0.0,
      upgradePrice: 499.0,
      dailyLimit: 10,
      swipesUsedToday: 0,
      swipesRemainingToday: 10,
      timezone: 'Asia/Kolkata',
      date: '',
    );
  }

  factory SwipeStatusModel.fromJson(Map<String, dynamic> json) {
    DateTime? parsedResetAt;
    if (json['resetAt'] != null) {
      parsedResetAt = DateTime.tryParse(json['resetAt'].toString());
    }

    return SwipeStatusModel(
      isUnlimited: json['isUnlimited'] == true,
      planName: json['planName']?.toString() ?? 'Free Plan',
      planPrice: (json['planPrice'] as num?)?.toDouble() ?? 0.0,
      upgradePrice: (json['upgradePrice'] as num?)?.toDouble() ?? 499.0,
      dailyLimit: (json['dailyLimit'] as num?)?.toInt() ?? 10,
      swipesUsedToday: (json['swipesUsedToday'] as num?)?.toInt() ?? 0,
      swipesRemainingToday: (json['swipesRemainingToday'] as num?)?.toInt() ?? 10,
      resetAt: parsedResetAt,
      timezone: json['timezone']?.toString() ?? 'Asia/Kolkata',
      date: json['date']?.toString() ?? '',
    );
  }
}

class SwipeActionResult {
  final bool allowed;
  final bool isUnlimited;
  final bool limitReached;
  final int swipesRemainingToday;
  final int swipesUsedToday;
  final String? message;

  const SwipeActionResult({
    required this.allowed,
    required this.isUnlimited,
    this.limitReached = false,
    required this.swipesRemainingToday,
    required this.swipesUsedToday,
    this.message,
  });

  factory SwipeActionResult.fromJson(Map<String, dynamic> json) {
    return SwipeActionResult(
      allowed: json['allowed'] == true,
      isUnlimited: json['isUnlimited'] == true,
      limitReached: json['limitReached'] == true,
      swipesRemainingToday: (json['swipesRemainingToday'] as num?)?.toInt() ?? 0,
      swipesUsedToday: (json['swipesUsedToday'] as num?)?.toInt() ?? 0,
      message: json['message']?.toString(),
    );
  }
}
