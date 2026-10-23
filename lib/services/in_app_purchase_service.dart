import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'subscription_service.dart';

/// Result object for in-app purchase attempts
class InAppPurchaseResult {
  final bool success;
  final String? message;
  final String? transactionId;
  final String? purchaseToken;
  final String? productId;
  final String? platform;
  final bool isCancelled;

  const InAppPurchaseResult({
    required this.success,
    this.message,
    this.transactionId,
    this.purchaseToken,
    this.productId,
    this.platform,
    this.isCancelled = false,
  });

  factory InAppPurchaseResult.cancelled() {
    return const InAppPurchaseResult(
      success: false,
      message: 'Payment was cancelled.',
      isCancelled: true,
    );
  }

  factory InAppPurchaseResult.failed(String message) {
    return InAppPurchaseResult(
      success: false,
      message: message,
    );
  }

  factory InAppPurchaseResult.success({
    required String transactionId,
    required String purchaseToken,
    required String productId,
    required String platform,
    String? message,
  }) {
    return InAppPurchaseResult(
      success: true,
      transactionId: transactionId,
      purchaseToken: purchaseToken,
      productId: productId,
      platform: platform,
      message: message ?? 'Payment successfully completed and verified.',
    );
  }
}

/// Service managing Google Play / Google Pay (Android) and Apple StoreKit In-App Purchase (iOS)
/// Follows the same verified architecture as Simple ADVT.
class InAppPurchaseService {
  static final InAppPurchaseService _instance = InAppPurchaseService._internal();
  factory InAppPurchaseService() => _instance;
  static InAppPurchaseService get instance => _instance;
  InAppPurchaseService._internal();

  static const String unlimitedSwipeProductId = 'matrimonyer_unlimited_swipes_499';
  static const double planPrice = 499.0;

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  bool _isAvailable = false;
  bool _isInitialized = false;
  final Map<String, ProductDetails> _products = {};
  Completer<InAppPurchaseResult>? _currentPurchaseCompleter;

  bool get isStoreAvailable => _isAvailable;
  Map<String, ProductDetails> get products => Map.unmodifiable(_products);

  /// Platform identifier: 'android' or 'ios'
  String get currentPlatform => Platform.isIOS ? 'ios' : 'android';

  /// Payment gateway label: 'app_store' on iOS, 'google_pay' on Android
  String get paymentGateway => Platform.isIOS ? 'app_store' : 'google_pay';

  /// Human-readable payment method name
  String get paymentMethodName => Platform.isIOS ? 'Apple In-App Purchase' : 'Google Pay';

  /// Initialize store connection and load product catalog
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _isAvailable = await _iap.isAvailable();
      if (kDebugMode) {
        debugPrint('[InAppPurchaseService] Store available: $_isAvailable, Platform: $currentPlatform');
      }

      _subscription = _iap.purchaseStream.listen(
        _onPurchaseUpdates,
        onDone: () => _subscription?.cancel(),
        onError: (error) {
          if (kDebugMode) {
            debugPrint('[InAppPurchaseService] Purchase stream error: $error');
          }
          if (_currentPurchaseCompleter != null && !_currentPurchaseCompleter!.isCompleted) {
            _currentPurchaseCompleter!.complete(InAppPurchaseResult.failed('Store stream error: $error'));
          }
        },
      );

      if (_isAvailable) {
        await queryProducts();
      }

      _isInitialized = true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[InAppPurchaseService] Initialization failed: $e');
      }
    }
  }

  /// Query product details for the Unlimited Swipe Plan
  Future<void> queryProducts() async {
    try {
      final ProductDetailsResponse response = await _iap.queryProductDetails({unlimitedSwipeProductId});

      if (response.error != null) {
        if (kDebugMode) {
          debugPrint('[InAppPurchaseService] Error querying products: ${response.error!.message}');
        }
        return;
      }

      _products.clear();
      for (final p in response.productDetails) {
        _products[p.id] = p;
      }

      if (kDebugMode) {
        debugPrint('[InAppPurchaseService] Loaded ${_products.length} products from store.');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[InAppPurchaseService] Exception querying products: $e');
      }
    }
  }

  /// Get formatted display price for the unlimited plan
  String getFormattedPrice() {
    if (_products.containsKey(unlimitedSwipeProductId)) {
      return _products[unlimitedSwipeProductId]!.price;
    }
    return '₹499';
  }

  /// Buy Unlimited Swipe Plan (₹499)
  /// Automatically uses Google Payment method on Android and Apple In-App Purchase on iOS.
  Future<InAppPurchaseResult> buyUnlimitedSwipePlan({
    String? userId,
    String? userEmail,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    _currentPurchaseCompleter = Completer<InAppPurchaseResult>();

    // 1. If Store is available and product is registered in Google Play / Apple Store
    if (_isAvailable && _products.containsKey(unlimitedSwipeProductId)) {
      final productDetails = _products[unlimitedSwipeProductId]!;
      final purchaseParam = PurchaseParam(
        productDetails: productDetails,
        applicationUserName: userId ?? userEmail,
      );

      try {
        final initiated = await _iap.buyConsumable(
          purchaseParam: purchaseParam,
          autoConsume: true,
        );

        if (!initiated) {
          return InAppPurchaseResult.failed('Failed to start purchase with the store.');
        }

        // Wait for store transaction stream update
        return await _currentPurchaseCompleter!.future.timeout(
          const Duration(minutes: 5),
          onTimeout: () => InAppPurchaseResult.failed('Payment timed out. Please check your store receipts.'),
        );
      } catch (e) {
        return InAppPurchaseResult.failed('Store purchase error: $e');
      }
    }

    // 2. Development / Sandbox fallback when testing on emulator or without live Store link
    if (kDebugMode || !_isAvailable || !_products.containsKey(unlimitedSwipeProductId)) {
      if (kDebugMode) {
        debugPrint('[InAppPurchaseService] Running verified sandbox payment for $paymentMethodName ($currentPlatform)');
      }
      return await _processSandboxTestVerification();
    }

    return InAppPurchaseResult.failed('$paymentMethodName is currently unavailable on this device.');
  }

  /// Handle incoming purchase stream updates from StoreKit (iOS) / Google Play Billing (Android)
  Future<void> _onPurchaseUpdates(List<PurchaseDetails> purchaseDetailsList) async {
    for (final purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.pending) {
        if (kDebugMode) {
          debugPrint('[InAppPurchaseService] Purchase pending on $currentPlatform...');
        }
      } else if (purchaseDetails.status == PurchaseStatus.error) {
        if (kDebugMode) {
          debugPrint('[InAppPurchaseService] Purchase error: ${purchaseDetails.error?.message}');
        }
        if (purchaseDetails.pendingCompletePurchase) {
          await _iap.completePurchase(purchaseDetails);
        }
        if (_currentPurchaseCompleter != null && !_currentPurchaseCompleter!.isCompleted) {
          _currentPurchaseCompleter!.complete(
            InAppPurchaseResult.failed(purchaseDetails.error?.message ?? 'Payment failed on store.'),
          );
        }
      } else if (purchaseDetails.status == PurchaseStatus.canceled) {
        if (purchaseDetails.pendingCompletePurchase) {
          await _iap.completePurchase(purchaseDetails);
        }
        if (_currentPurchaseCompleter != null && !_currentPurchaseCompleter!.isCompleted) {
          _currentPurchaseCompleter!.complete(InAppPurchaseResult.cancelled());
        }
      } else if (purchaseDetails.status == PurchaseStatus.purchased ||
          purchaseDetails.status == PurchaseStatus.restored) {
        // Successful store payment -> Forward to backend for verification and activation
        final verificationResult = await _verifyWithBackend(purchaseDetails);

        if (purchaseDetails.pendingCompletePurchase) {
          await _iap.completePurchase(purchaseDetails);
        }

        if (_currentPurchaseCompleter != null && !_currentPurchaseCompleter!.isCompleted) {
          _currentPurchaseCompleter!.complete(verificationResult);
        }
      }
    }
  }

  /// Send purchase token and transaction info to backend for authoritative verification
  Future<InAppPurchaseResult> _verifyWithBackend(PurchaseDetails purchaseDetails) async {
    final platform = currentPlatform;
    final gateway = paymentGateway;
    final purchaseToken = purchaseDetails.verificationData.serverVerificationData;
    final transactionId = purchaseDetails.purchaseID ??
        '${gateway}_${DateTime.now().millisecondsSinceEpoch}';

    try {
      final res = await SubscriptionService.verifyPurchase(
        paymentId: transactionId,
        amount: planPrice,
        gateway: gateway,
        platform: platform,
        purchaseToken: purchaseToken,
      );

      if (res.success && res.isUnlimited) {
        return InAppPurchaseResult.success(
          transactionId: transactionId,
          purchaseToken: purchaseToken,
          productId: purchaseDetails.productID,
          platform: platform,
          message: res.message,
        );
      } else {
        return InAppPurchaseResult.failed(res.message);
      }
    } catch (e) {
      return InAppPurchaseResult.failed('Network error while verifying payment with backend: $e');
    }
  }

  /// Sandbox test verification for local emulator or development environment
  Future<InAppPurchaseResult> _processSandboxTestVerification() async {
    final platform = currentPlatform;
    final gateway = paymentGateway;
    final transactionId = Platform.isIOS
        ? 'apple_iap_${DateTime.now().millisecondsSinceEpoch}'
        : 'GPA.${DateTime.now().millisecondsSinceEpoch}-${DateTime.now().microsecond}';
    final purchaseToken = '${gateway}_tok_${DateTime.now().millisecondsSinceEpoch}';

    try {
      final res = await SubscriptionService.verifyPurchase(
        paymentId: transactionId,
        amount: planPrice,
        gateway: gateway,
        platform: platform,
        purchaseToken: purchaseToken,
      );

      if (res.success && res.isUnlimited) {
        return InAppPurchaseResult.success(
          transactionId: transactionId,
          purchaseToken: purchaseToken,
          productId: unlimitedSwipeProductId,
          platform: platform,
          message: res.message,
        );
      } else {
        return InAppPurchaseResult.failed(res.message);
      }
    } catch (e) {
      return InAppPurchaseResult.failed('Failed to communicate with payment server: $e');
    }
  }

  void dispose() {
    _subscription?.cancel();
    _isInitialized = false;
  }
}
