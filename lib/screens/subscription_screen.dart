import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/auth_provider.dart';
import '../providers/subscription_provider.dart';

/// Screen displaying subscription details, comparing Basic Free Plan vs Premium Plan,
/// styled with the unified Matrimonyer brand theme (Burgundy, Rose, and Gold).
class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  bool _isPurchasing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SubscriptionProvider>().fetchStatus();
    });
  }

  Future<void> _handlePurchase() async {
    final auth = context.read<AuthProvider>();
    final subProvider = context.read<SubscriptionProvider>();
    final user = auth.currentUser;

    setState(() => _isPurchasing = true);

    try {
      final res = await subProvider.purchasePlatformPayment(
        userId: user?.id,
        userEmail: user?.email,
      );

      if (!mounted) return;

      if (res.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppTheme.burgundy,
            duration: const Duration(seconds: 4),
            content: Row(
              children: [
                const Icon(Icons.stars_rounded, color: AppTheme.gold, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    res.message,
                    style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        );
      } else if (!res.isCancelled) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppTheme.error,
            duration: const Duration(seconds: 4),
            content: Text(res.message),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppTheme.error,
            content: Text('Payment failed: $e'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isPurchasing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final sub = context.watch<SubscriptionProvider>();
    final isPremium = sub.isUnlimited;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Subscription'),
        elevation: 0,
        backgroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── 1. Hero Header Banner ──
            _buildHeroBanner(isPremium),

            const SizedBox(height: 20),

            // ── 2. Plan Summary Cards: Basic vs Premium ──
            Row(
              children: [
                Expanded(
                  child: _buildPlanSummaryCard(
                    title: 'Basic Plan',
                    price: 'Free',
                    period: 'Lifetime',
                    isCurrent: !isPremium,
                    accentColor: AppTheme.burgundy,
                    badge: !isPremium ? 'CURRENT' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildPlanSummaryCard(
                    title: 'Premium Plan',
                    price: '₹499',
                    period: 'for 1 Year',
                    isCurrent: isPremium,
                    accentColor: AppTheme.burgundy,
                    badge: isPremium ? 'ACTIVE' : 'POPULAR',
                    isPopular: true,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // ── 3. Plan Feature Differentiation Table ──
            _buildSectionHeader('Plan Comparison'),
            const SizedBox(height: 10),
            _buildComparisonCard(),

            const SizedBox(height: 24),

            // ── 4. Bottom Action Area ──
            // If already premium -> display active confirmation
            // If not premium -> show unlock premium payment button
            if (isPremium)
              _buildAlreadyPremiumCard()
            else
              _buildUnlockPremiumSection(),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  /// Hero Banner styled with Burgundy gradient and Gold accents
  Widget _buildHeroBanner(bool isPremium) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.burgundy, Color(0xFF9E1B42), AppTheme.burgundyDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: isPremium ? Border.all(color: AppTheme.gold.withValues(alpha: 0.6), width: 1.5) : null,
        boxShadow: [
          BoxShadow(
            color: AppTheme.burgundy.withValues(alpha: 0.3),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isPremium ? Icons.workspace_premium_rounded : Icons.star_border_rounded,
                      size: 16,
                      color: isPremium ? AppTheme.gold : Colors.white,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      isPremium ? 'PREMIUM MEMBER' : 'FREE BASIC ACCOUNT',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isPremium ? AppTheme.goldLight : Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              if (isPremium)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.goldLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.gold.withValues(alpha: 0.5)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle_rounded, size: 13, color: AppTheme.burgundy),
                      SizedBox(width: 4),
                      Text(
                        'Active 👑',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.burgundy,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            isPremium
                ? 'Unlimited Premium Active'
                : 'Upgrade to Premium Membership',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isPremium
                ? 'You have unrestricted access to all candidate profiles, full visitor insights, and direct verified contacts for 1 full year.'
                : 'Connect with your life partner faster with Unlimited Daily Swipes, Full Visitor Access, and Direct Contact Numbers.',
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.92),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  /// Plan Cards matching theme colors
  Widget _buildPlanSummaryCard({
    required String title,
    required String price,
    required String period,
    required bool isCurrent,
    required Color accentColor,
    String? badge,
    bool isPopular = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isPopular ? AppTheme.goldLight.withValues(alpha: 0.4) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isPopular
              ? AppTheme.burgundy
              : (isCurrent ? AppTheme.burgundy.withValues(alpha: 0.5) : AppTheme.cardBorder),
          width: isPopular ? 1.8 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isPopular
                ? AppTheme.burgundy.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (badge != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
              decoration: BoxDecoration(
                color: isPopular ? AppTheme.burgundy : AppTheme.roseLight,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                badge,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: isPopular ? Colors.white : AppTheme.burgundy,
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                price,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: isPopular ? AppTheme.burgundy : AppTheme.textPrimary,
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  period,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Comparison Table Card
  Widget _buildComparisonCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // Table Header styled with RoseLight background & Burgundy text
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.roseLight.withValues(alpha: 0.45),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: const Row(
              children: [
                Expanded(
                  flex: 5,
                  child: Text(
                    'Feature',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    'Basic',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    'Premium',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.burgundy,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppTheme.cardBorder),

          // Feature Rows
          _buildComparisonRow(
            icon: Icons.swipe_rounded,
            feature: 'Daily Profile Swipes',
            basic: '10 / day',
            premium: 'Unlimited',
            highlightPremium: true,
          ),
          _buildComparisonRow(
            icon: Icons.visibility_rounded,
            feature: 'Profile Visitors',
            basic: 'Locked 🔒',
            premium: 'Full Access',
            highlightPremium: true,
          ),
          _buildComparisonRow(
            icon: Icons.phone_rounded,
            feature: 'Contact Numbers',
            basic: 'Mutual Only',
            premium: 'Direct Verified',
            highlightPremium: true,
          ),
          _buildComparisonRow(
            icon: Icons.send_rounded,
            feature: 'Express Interests',
            basic: 'Daily Quota',
            premium: 'Unlimited',
            highlightPremium: true,
          ),
          _buildComparisonRow(
            icon: Icons.stars_rounded,
            feature: 'Match Compatibility',
            basic: 'Standard',
            premium: '80%+ Alerts',
            highlightPremium: true,
          ),
          _buildComparisonRow(
            icon: Icons.workspace_premium_rounded,
            feature: 'Crown Badge on Profile',
            basic: 'None',
            premium: 'Gold Crown 👑',
            highlightPremium: true,
          ),
          _buildComparisonRow(
            icon: Icons.support_agent_rounded,
            feature: 'Customer Support',
            basic: 'Standard',
            premium: 'VIP Priority',
            highlightPremium: true,
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonRow({
    required IconData icon,
    required String feature,
    required String basic,
    required String premium,
    bool highlightPremium = false,
    bool isLast = false,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          child: Row(
            children: [
              Expanded(
                flex: 5,
                child: Row(
                  children: [
                    Icon(icon, size: 16, color: AppTheme.burgundy),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        feature,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  basic,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                  decoration: BoxDecoration(
                    color: highlightPremium ? AppTheme.roseLight : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    premium,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: highlightPremium ? AppTheme.burgundy : AppTheme.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (!isLast)
          const Divider(height: 1, indent: 16, endIndent: 16, color: Color(0xFFF1F5F9)),
      ],
    );
  }

  /// Card shown if user is ALREADY Premium styled in Regal Burgundy & Gold
  Widget _buildAlreadyPremiumCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppTheme.goldLight.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.gold.withValues(alpha: 0.6), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppTheme.gold.withValues(alpha: 0.12),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.burgundy, Color(0xFF9E1B42)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.workspace_premium_rounded,
              color: AppTheme.gold,
              size: 28,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Already Premium Member',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: AppTheme.burgundy,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Your 1-Year Premium Membership is active! You can view unlimited profiles every day, see who visited your profile, and enjoy all VIP benefits.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.textPrimary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.gold.withValues(alpha: 0.5)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.stars_rounded, size: 16, color: AppTheme.gold),
                SizedBox(width: 6),
                Text(
                  'Plan: Premium Membership (₹499 / 1 Year)',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.burgundy,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Section with Unlock Premium button styled in Burgundy theme
  Widget _buildUnlockPremiumSection() {
    return Column(
      children: [
        // Primary Burgundy CTA Button
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: _isPurchasing ? null : _handlePurchase,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.burgundy,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 4,
              shadowColor: AppTheme.burgundy.withValues(alpha: 0.35),
            ),
            child: _isPurchasing
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
                          'Unlock Premium • Pay ₹499',
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
                          'Unlock Premium • Pay ₹499',
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
        const SizedBox(height: 12),
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_rounded, size: 12, color: AppTheme.burgundy),
            SizedBox(width: 4),
            Text(
              '100% Secure • 1 Year Unlimited Validity • Instant Activation',
              style: TextStyle(fontSize: 11, color: AppTheme.textSecondary, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: AppTheme.textPrimary,
        ),
      ),
    );
  }
}
