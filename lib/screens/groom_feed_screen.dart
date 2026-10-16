import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/matrimony_profile_model.dart';
import '../../providers/discovery_provider.dart';
import '../../providers/interaction_provider.dart';
import '../../providers/search_filter_provider.dart';
import '../../widgets/cards/matrimony_tinder_deck.dart';
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

          // Main Swipe Deck
          Expanded(
            child: MatrimonyTinderDeck(
              profiles: filteredGrooms,
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
