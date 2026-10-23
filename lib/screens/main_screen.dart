import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/discovery_provider.dart';
import '../providers/search_filter_provider.dart';
import '../widgets/common/curved_bottom_nav.dart';
import '../widgets/common/custom_app_bar.dart';
import '../widgets/modals/search_filter_sheet.dart';
import '../providers/profile_provider.dart';
import 'groom_feed_screen.dart';
import 'bride_feed_screen.dart';

/// Main Application Shell with Persistent Curved Bottom Navigation
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  bool _isCheckingProfile = false;

  Future<void> _handleAddProfileTap() async {
    if (_isCheckingProfile) return;
    setState(() => _isCheckingProfile = true);

    try {
      final profileProvider = context.read<ProfileProvider>();
      // Backend is authoritative source of truth
      await profileProvider.fetchMyProfile();

      if (!mounted) return;

      if (profileProvider.hasProfile) {
        // User already has a matrimony profile -> display existing profile
        Navigator.pushNamed(context, '/my-profile');
      } else {
        // User has not created a profile -> open 3-phase wizard
        Navigator.pushNamed(context, '/publish-wizard').then((_) {
          if (mounted) {
            context.read<ProfileProvider>().fetchMyProfile();
          }
        });
      }
    } catch (_) {
      if (mounted) {
        final profileProvider = context.read<ProfileProvider>();
        if (profileProvider.hasProfile) {
          Navigator.pushNamed(context, '/my-profile');
        } else {
          Navigator.pushNamed(context, '/publish-wizard');
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isCheckingProfile = false);
      }
    }
  }

  void _openFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const SearchFilterSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final discovery = context.watch<DiscoveryProvider>();
    final filter = context.watch<SearchFilterProvider>();

    final selectedIndex = discovery.selectedTabIndex;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: MatrimonyAppBar(
        title: selectedIndex == 0 ? 'Groom Profiles' : 'Bride Profiles',
        onFilterTap: _openFilterSheet,
        activeFiltersCount: filter.activeFilterCount,
      ),
      body: IndexedStack(
        index: selectedIndex == 0 ? 0 : 1,
        children: const [
          GroomFeedScreen(),
          BrideFeedScreen(),
        ],
      ),
      bottomNavigationBar: CurvedMatrimonyBottomNav(
        currentIndex: selectedIndex,
        onTap: (index) {
          discovery.setTabIndex(index);
        },
        onCenterTap: _handleAddProfileTap,
      ),
    );
  }
}
