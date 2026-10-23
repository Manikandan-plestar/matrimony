import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/subscription_provider.dart';

/// Modal displayed when a Free Plan user exhausts their 10 daily profile swipes
class DailyLimitModal extends StatefulWidget {
  const DailyLimitModal({super.key});

  /// Helper to display modal cleanly
  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const DailyLimitModal(),
    );
  }

  @override
  State<DailyLimitModal> createState() => _DailyLimitModalState();
}

class _DailyLimitModalState extends State<DailyLimitModal> {
  bool _isPurchasing = false;
  String? _purchasingMethod;

  Future<void> _handlePlatformPurchase() async {
    setState(() {
      _isPurchasing = true;
      _purchasingMethod = 'platform';
    });
    final subProvider = context.read<SubscriptionProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);

    final result = await subProvider.purchasePlatformPayment();

    if (mounted) {
      setState(() {
        _isPurchasing = false;
        _purchasingMethod = null;
      });
      if (result.success) {
        nav.pop();
        messenger.showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF1F1F1F),
            content: Row(
              children: [
                Icon(
                  Platform.isIOS ? Icons.apple : Icons.check_circle_rounded,
                  color: Platform.isIOS ? Colors.white : const Color(0xFF34A853),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(child: Text(result.message)),
              ],
            ),
          ),
        );
      } else if (!result.isCancelled) {
        messenger.showSnackBar(
          SnackBar(
            backgroundColor: AppTheme.error,
            content: Text(result.message),
          ),
        );
      }
    }
  }

  Future<void> _handleSubscribe() async {
    setState(() {
      _isPurchasing = true;
      _purchasingMethod = 'standard';
    });
    final subProvider = context.read<SubscriptionProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);

    final result = await subProvider.purchaseUnlimitedPlan();

    if (mounted) {
      setState(() {
        _isPurchasing = false;
        _purchasingMethod = null;
      });
      if (result.success) {
        nav.pop();
        messenger.showSnackBar(
          SnackBar(
            backgroundColor: AppTheme.burgundy,
            content: Row(
              children: [
                const Icon(Icons.stars_rounded, color: AppTheme.gold, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text(result.message)),
              ],
            ),
          ),
        );
      } else {
        messenger.showSnackBar(
          SnackBar(
            backgroundColor: AppTheme.error,
            content: Text(result.message),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        top: 24,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 28,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 44,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Glowing Crown / Fire Icon
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF8B1A4A), Color(0xFFC43D75)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.burgundy.withValues(alpha: 0.35),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Icon(
              Icons.bolt_rounded,
              size: 38,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 18),

          // Primary Limit Message
          const Text(
            "You've reached your daily limit of 10 profile swipes.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 10),

          // Subtitle / Reset notice
          const Text(
            'Your free daily swipe quota resets tomorrow at midnight, or you can unlock unlimited swiping right now.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),

          // Plan Highlight Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFF7ED), Color(0xFFFEF2F2)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFFDBA74), width: 1.2),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Unlimited Swipe Plan',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF9A3412),
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'One-time upgrade • Never resets',
                          style: TextStyle(fontSize: 12, color: Color(0xFFC2410C)),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF9A3412),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        '₹499',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Divider(color: Color(0xFFFED7AA), height: 1),
                const SizedBox(height: 14),
                _buildBenefitRow(Icons.all_inclusive_rounded, 'Swipe unlimited profiles without a daily limit.'),
                const SizedBox(height: 8),
                _buildBenefitRow(Icons.sync_alt_rounded, 'Applies across both Groom and Bride discovery feeds.'),
                const SizedBox(height: 8),
                _buildBenefitRow(Icons.check_circle_outline_rounded, 'Persists across logout, login, and app reinstalls.'),
              ],
            ),
          ),
          const SizedBox(height: 22),

          // 1. Native Platform Primary CTA Button (Google Pay on Android, Apple IAP on iOS)
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _isPurchasing ? null : _handlePlatformPurchase,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1F1F1F),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: Color(0xFF334155), width: 1.2),
                ),
                elevation: 4,
              ),
              child: (_isPurchasing && _purchasingMethod == 'platform')
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (Platform.isIOS) ...[
                          const Icon(Icons.apple, size: 24, color: Colors.white),
                          const SizedBox(width: 8),
                          const Text(
                            'Pay with Apple In-App Purchase • ₹499',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ] else ...[
                          // Google "G" Badge
                          Container(
                            width: 24,
                            height: 24,
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: Text(
                                'G',
                                style: TextStyle(
                                  color: Color(0xFF4285F4),
                                  fontWeight: FontWeight.w900,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'Pay with Google Pay • ₹499',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 10),

          // 2. Alternative Payment Methods (UPI / Card / NetBanking)
          SizedBox(
            width: double.infinity,
            height: 46,
            child: OutlinedButton(
              onPressed: _isPurchasing ? null : _handleSubscribe,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.burgundy,
                side: const BorderSide(color: AppTheme.burgundy, width: 1.2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: (_isPurchasing && _purchasingMethod == 'standard')
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.burgundy),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.credit_card_rounded, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Other Payment Options (UPI / Card)',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 8),

          // Secondary Maybe Later
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Maybe Later / Continue Tomorrow',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: const Color(0xFFC2410C)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF7C2D12),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
