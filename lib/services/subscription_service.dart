import '../models/subscription_model.dart';
import 'api_service.dart';

/// Service for subscription status, swipe quota enforcement, and purchase verification.
class SubscriptionService {
  /// Fetch current user's swipe quota, plan tier, and daily reset info.
  static Future<SwipeStatusModel> fetchSwipeStatus() async {
    try {
      final res = await ApiService.get('/api/mat/subscriptions/swipe-status');
      if (res['success'] == true) {
        return SwipeStatusModel.fromJson(res);
      }
    } catch (_) {}
    return SwipeStatusModel.initial();
  }

  /// Process and atomically record a swipe action (Pass or Interest).
  static Future<SwipeActionResult> recordSwipe({
    required int targetProfileId,
    required String action, // 'pass' | 'interest'
    required String feedType, // 'groom' | 'bride'
    required String clientRequestId,
  }) async {
    try {
      final res = await ApiService.post(
        '/api/mat/swipes',
        body: {
          'targetProfileId': targetProfileId,
          'action': action,
          'feedType': feedType,
          'clientRequestId': clientRequestId,
        },
      );

      return SwipeActionResult.fromJson(res);
    } catch (e) {
      // In case of network error, do not grant swipe if uncertain
      return const SwipeActionResult(
        allowed: false,
        isUnlimited: false,
        limitReached: false,
        swipesRemainingToday: 0,
        swipesUsedToday: 10,
        message: 'Network error. Please try again.',
      );
    }
  }

  /// Verify and activate Unlimited Swipe Plan (₹499)
  static Future<({bool success, String message, bool isUnlimited})> verifyPurchase({
    required String paymentId,
    double amount = 499.0,
    String gateway = 'google_pay',
    String? purchaseToken,
  }) async {
    try {
      final res = await ApiService.post(
        '/api/mat/subscriptions/verify-purchase',
        body: {
          'planId': 'unlimited_swipes',
          'amount': amount,
          'currency': 'INR',
          'paymentId': paymentId,
          'gateway': gateway,
          'purchaseToken': purchaseToken,
          'packageName': 'matrimonyer.matrimony.com',
          'productId': 'matrimonyer_unlimited_swipes_499',
        },
      );

      final success = res['success'] == true;
      final message = res['message']?.toString() ?? (success ? 'Plan activated successfully!' : 'Purchase failed');
      final isUnlimited = res['isUnlimited'] == true;

      return (success: success, message: message, isUnlimited: isUnlimited);
    } catch (e) {
      return (success: false, message: 'Payment verification failed: $e', isUnlimited: false);
    }
  }

  /// Specialized Google Pay / Google Play Billing purchase verification
  static Future<({bool success, String message, bool isUnlimited})> verifyGooglePayPurchase({
    required String orderId,
    String? purchaseToken,
    double amount = 499.0,
  }) async {
    return verifyPurchase(
      paymentId: orderId,
      amount: amount,
      gateway: 'google_pay',
      purchaseToken: purchaseToken,
    );
  }
}
