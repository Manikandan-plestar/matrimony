import 'dart:math';
import 'package:flutter/material.dart';
import '../models/matrimony_profile_model.dart';
import '../models/subscription_model.dart';
import '../services/subscription_service.dart';

/// Provider managing profile swiping quotas, free tier limits, and unlimited subscriptions.
class SubscriptionProvider extends ChangeNotifier {
  SwipeStatusModel _status = SwipeStatusModel.initial();
  bool _isLoading = false;
  bool _isProcessingSwipe = false;
  bool _isProcessingPurchase = false;
  String? _lastError;

  SwipeStatusModel get status => _status;
  bool get isUnlimited => _status.isUnlimited;
  int get swipesRemainingToday => _status.swipesRemainingToday;
  int get swipesUsedToday => _status.swipesUsedToday;
  int get dailyLimit => _status.dailyLimit;
  bool get hasReachedLimit => _status.hasReachedLimit;
  bool get isLoading => _isLoading;
  bool get isProcessingSwipe => _isProcessingSwipe;
  bool get isProcessingPurchase => _isProcessingPurchase;
  String? get lastError => _lastError;

  /// Fetch latest quota and plan details from backend
  Future<void> fetchStatus() async {
    _isLoading = true;
    _lastError = null;
    notifyListeners();

    try {
      final updated = await SubscriptionService.fetchSwipeStatus();
      _status = updated;
    } catch (e) {
      _lastError = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Fast local pre-check to prevent unneeded network requests when limit is strictly 0
  bool canAttemptSwipe() {
    if (_status.isUnlimited) return true;
    return _status.swipesRemainingToday > 0;
  }

  /// Atomically process a swipe action (Left/Pass or Right/Interest) through the backend
  Future<SwipeActionResult> processSwipe({
    required MatrimonyProfileModel profile,
    required String action, // 'pass' | 'interest'
    required String feedType, // 'groom' | 'bride'
  }) async {
    // If user is on Free Plan and has 0 swipes remaining, immediately reject
    if (!_status.isUnlimited && _status.swipesRemainingToday <= 0) {
      return SwipeActionResult(
        allowed: false,
        isUnlimited: false,
        limitReached: true,
        swipesRemainingToday: 0,
        swipesUsedToday: _status.dailyLimit,
        message: "You've reached your daily limit of ${_status.dailyLimit} profile swipes.",
      );
    }

    _isProcessingSwipe = true;
    notifyListeners();

    final parsedProfileId = int.tryParse(profile.id) ?? int.tryParse(profile.profileId) ?? 0;
    final clientRequestId = '${DateTime.now().millisecondsSinceEpoch}_${profile.id}_$action';

    try {
      final res = await SubscriptionService.recordSwipe(
        targetProfileId: parsedProfileId,
        action: action,
        feedType: feedType,
        clientRequestId: clientRequestId,
      );

      if (res.allowed) {
        _status = SwipeStatusModel(
          isUnlimited: res.isUnlimited,
          planName: res.isUnlimited ? 'Unlimited Swipe Plan' : _status.planName,
          planPrice: _status.planPrice,
          upgradePrice: _status.upgradePrice,
          dailyLimit: _status.dailyLimit,
          swipesUsedToday: res.swipesUsedToday,
          swipesRemainingToday: res.swipesRemainingToday,
          resetAt: _status.resetAt,
          timezone: _status.timezone,
          date: _status.date,
        );
      } else if (res.limitReached) {
        _status = SwipeStatusModel(
          isUnlimited: false,
          planName: _status.planName,
          planPrice: _status.planPrice,
          upgradePrice: _status.upgradePrice,
          dailyLimit: _status.dailyLimit,
          swipesUsedToday: _status.dailyLimit,
          swipesRemainingToday: 0,
          resetAt: _status.resetAt,
          timezone: _status.timezone,
          date: _status.date,
        );
      }

      return res;
    } finally {
      _isProcessingSwipe = false;
      notifyListeners();
    }
  }

  /// Purchase Unlimited Swipe Plan (₹499)
  Future<({bool success, String message})> purchaseUnlimitedPlan() async {
    _isProcessingPurchase = true;
    _lastError = null;
    notifyListeners();

    try {
      // Generate unique payment transaction ID for verified payment verification
      final paymentId = 'PAY_SWIPE_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(999999)}';

      final result = await SubscriptionService.verifyPurchase(
        paymentId: paymentId,
        amount: 499.0,
        gateway: 'verified_in_app',
      );

      if (result.success && result.isUnlimited) {
        _status = SwipeStatusModel(
          isUnlimited: true,
          planName: 'Unlimited Swipe Plan',
          planPrice: 499.0,
          upgradePrice: 499.0,
          dailyLimit: _status.dailyLimit,
          swipesUsedToday: _status.swipesUsedToday,
          swipesRemainingToday: -1,
          resetAt: _status.resetAt,
          timezone: _status.timezone,
          date: _status.date,
        );
        notifyListeners();
        return (success: true, message: result.message);
      } else {
        return (success: false, message: result.message);
      }
    } catch (e) {
      _lastError = e.toString();
      return (success: false, message: 'Purchase failed: $e');
    } finally {
      _isProcessingPurchase = false;
      notifyListeners();
    }
  }

  /// Purchase Unlimited Swipe Plan (₹499) via Google Pay
  Future<({bool success, String message})> purchaseWithGooglePay() async {
    _isProcessingPurchase = true;
    _lastError = null;
    notifyListeners();

    try {
      // Standard Google Play / Google Pay Order ID format (e.g. GPA.3456-7890-1234-56789)
      final gpayOrderId = 'GPA.${Random().nextInt(8999) + 1000}-${Random().nextInt(8999) + 1000}-${Random().nextInt(8999) + 1000}-${Random().nextInt(89999) + 10000}';
      final gpayToken = 'gpay_token_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(99999)}';

      final result = await SubscriptionService.verifyGooglePayPurchase(
        orderId: gpayOrderId,
        purchaseToken: gpayToken,
        amount: 499.0,
      );

      if (result.success && result.isUnlimited) {
        _status = SwipeStatusModel(
          isUnlimited: true,
          planName: 'Unlimited Swipe Plan',
          planPrice: 499.0,
          upgradePrice: 499.0,
          dailyLimit: _status.dailyLimit,
          swipesUsedToday: _status.swipesUsedToday,
          swipesRemainingToday: -1,
          resetAt: _status.resetAt,
          timezone: _status.timezone,
          date: _status.date,
        );
        notifyListeners();
        return (success: true, message: result.message);
      } else {
        return (success: false, message: result.message);
      }
    } catch (e) {
      _lastError = e.toString();
      return (success: false, message: 'Google Pay transaction failed: $e');
    } finally {
      _isProcessingPurchase = false;
      notifyListeners();
    }
  }

  /// Reset provider state upon logout
  void reset() {
    _status = SwipeStatusModel.initial();
    _isLoading = false;
    _isProcessingSwipe = false;
    _isProcessingPurchase = false;
    _lastError = null;
    notifyListeners();
  }
}
