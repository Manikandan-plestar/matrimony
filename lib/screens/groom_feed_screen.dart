import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/matrimony_profile_model.dart';
import '../../providers/discovery_provider.dart';
import '../../providers/interaction_provider.dart';
import '../../providers/search_filter_provider.dart';
import '../../providers/subscription_provider.dart';
import '../../widgets/cards/matrimony_tinder_deck.dart';
import '../../widgets/modals/daily_limit_modal.dart';
import '../../widgets/modals/profile_details_modal.dart';

/// Groom Discovery Feed Screen
class GroomFeedScreen extends StatelessWidget {
  const GroomFeedScreen({super.key});

  void _openDetails(BuildContext context, MatrimonyProfileModel profile) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ProfileDetailsModal(
        profile: profile,
        onToggleSave: () {
          context.read<InteractionProvider>().toggleSaveProfile(profile);
        },
        onExpressInterest: () {
          context.read<InteractionProvider>().expressInterest(profile);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: AppTheme.burgundy,
              content: Text('Interest expressed in ${profile.fullName}!'),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final discovery = context.watch<DiscoveryProvider>();
    final filter = context.watch<SearchFilterProvider>();
    final interaction = context.watch<InteractionProvider>();
    final subscription = context.watch<SubscriptionProvider>();

    // Apply active filters on groom profiles
    final filteredGrooms = filter.filterProfiles(discovery.groomProfiles);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Column(
        children: [
          // Filter Chips Bar (if filters active)
          if (filter.hasActiveFilters)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.white,
              child: Row(
                children: [
                  const Icon(Icons.tune_rounded, size: 16, color: AppTheme.burgundy),
                  const SizedBox(width: 6),
                  Text(
                    '${filteredGrooms.length} Groom Profiles Matching Filter',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.burgundy,
                    ),
                  ),
                  const Spacer(),
                  InkWell(
                    onTap: () => filter.clearAllFilters(),
                    child: const Text(
                      'Clear',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.rose,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Daily Swipe Quota / Subscription Pill Indicator
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 2),
            child: subscription.isUnlimited
                ? Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFFFFFBEB), Color(0xFFFEF3C7)]),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFFDE68A)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.bolt_rounded, size: 16, color: Color(0xFFB45309)),
                        SizedBox(width: 6),
                        Text(
                          'Unlimited Swipes Active ✨',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF92400E)),
                        ),
                      ],
                    ),
                  )
                : Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: subscription.hasReachedLimit
                            ? AppTheme.error.withValues(alpha: 0.5)
                            : AppTheme.cardBorder,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          subscription.hasReachedLimit ? Icons.lock_clock_rounded : Icons.swipe_rounded,
                          size: 15,
                          color: subscription.hasReachedLimit ? AppTheme.error : AppTheme.burgundy,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          subscription.hasReachedLimit
                              ? '0 swipes remaining today'
                              : '${subscription.swipesRemainingToday} swipes remaining today',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: subscription.hasReachedLimit ? AppTheme.error : AppTheme.textPrimary,
                          ),
                        ),
                        if (subscription.hasReachedLimit) ...[
                          const SizedBox(width: 8),
                          InkWell(
                            onTap: () => DailyLimitModal.show(context),
                            child: const Text(
                              'Upgrade',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.burgundy,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
          ),

          // Main Swipe Deck
          Expanded(
            child: MatrimonyTinderDeck(
              profiles: filteredGrooms,
              onSwipe: (p, action) async {
                final subProvider = context.read<SubscriptionProvider>();
                if (!subProvider.canAttemptSwipe()) {
                  DailyLimitModal.show(context);
                  return false;
                }
                final res = await subProvider.processSwipe(
                  profile: p,
                  action: action,
                  feedType: 'groom',
                );
                if (!res.allowed) {
                  if (context.mounted && (res.limitReached || subProvider.hasReachedLimit)) {
                    DailyLimitModal.show(context);
                  }
                  return false;
                }
                return true;
              },
              onToggleSave: (p) {
                interaction.toggleSaveProfile(p);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    duration: const Duration(milliseconds: 1000),
                    content: Text(
                      p.isSaved ? 'Saved ${p.fullName} to favorites' : 'Removed from saved profiles',
                    ),
                  ),
                );
              },
              onExpressInterest: (p) {
                interaction.expressInterest(p);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: AppTheme.burgundy,
                    content: Text('Interest expressed in ${p.fullName}! ❤️'),
                  ),
                );
              },
              onViewDetails: (p) => _openDetails(context, p),
              onReset: () => filter.clearAllFilters(),
            ),
          ),
        ],
      ),
    );
  }
}
