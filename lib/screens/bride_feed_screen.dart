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

/// Bride Discovery Feed Screen
class BrideFeedScreen extends StatelessWidget {
  const BrideFeedScreen({super.key});

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
        onExpressInterest: () async {
          final inter = context.read<InteractionProvider>();
          if (inter.isConnected(profile.id)) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: AppTheme.burgundy,
                content: Text('You are already connected with ${profile.fullName}.'),
              ),
            );
            return;
          }
          if (inter.isInterestSentOrPending(profile.id)) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: AppTheme.burgundy,
                content: Text('Interest request already sent to ${profile.fullName}.'),
              ),
            );
            return;
          }
          final res = await inter.expressInterest(profile);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: res.success ? AppTheme.burgundy : AppTheme.error,
                content: Text(res.message.isNotEmpty
                    ? res.message
                    : (res.success
                        ? 'Interest expressed in ${profile.fullName}!'
                        : 'Could not send interest.')),
              ),
            );
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final discovery = context.watch<DiscoveryProvider>();
    final filter = context.watch<SearchFilterProvider>();
    final interaction = context.watch<InteractionProvider>();

    // Apply active filters on bride profiles
    final filteredBrides = filter.filterProfiles(discovery.brideProfiles);

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
                    '${filteredBrides.length} Bride Profiles Matching Filter',
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

          // Main Swipe Deck
          Builder(
            builder: (_) {
              for (final p in filteredBrides) {
                final isPending = interaction.isInterestSentOrPending(p.id);
                final isConn = interaction.isConnected(p.id);
                if (!isPending && !isConn && p.isInterestSent) {
                  p.isInterestSent = false;
                } else if ((isPending || isConn) && !p.isInterestSent) {
                  p.isInterestSent = true;
                }
              }
              return const SizedBox.shrink();
            },
          ),
          Expanded(
            child: MatrimonyTinderDeck(
              profiles: filteredBrides,
              onSwipe: (p, action) async {
                if (action == 'interest') {
                  if (interaction.isConnected(p.id)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: AppTheme.burgundy,
                        content: Text('You are already connected with ${p.fullName}.'),
                      ),
                    );
                    return false;
                  }
                  if (interaction.isInterestSentOrPending(p.id)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: AppTheme.burgundy,
                        content: Text('Interest request already sent to ${p.fullName}.'),
                      ),
                    );
                    return false;
                  }
                }
                final subProvider = context.read<SubscriptionProvider>();
                if (!subProvider.canAttemptSwipe()) {
                  DailyLimitModal.show(context);
                  return false;
                }
                final res = await subProvider.processSwipe(
                  profile: p,
                  action: action,
                  feedType: 'bride',
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
              onExpressInterest: (p) async {
                if (interaction.isConnected(p.id)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: AppTheme.burgundy,
                      content: Text('You are already connected with ${p.fullName}.'),
                    ),
                  );
                  return;
                }
                if (interaction.isInterestSentOrPending(p.id)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: AppTheme.burgundy,
                      content: Text('Interest request already sent to ${p.fullName}.'),
                    ),
                  );
                  return;
                }
                final res = await interaction.expressInterest(p);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: res.success ? AppTheme.burgundy : AppTheme.error,
                      content: Text(res.message.isNotEmpty
                          ? res.message
                          : (res.success
                              ? 'Interest expressed in ${p.fullName}! ❤️'
                              : 'Could not send interest.')),
                    ),
                  );
                }
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
