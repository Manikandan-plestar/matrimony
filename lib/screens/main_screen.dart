import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/discovery_provider.dart';
import '../providers/search_filter_provider.dart';
import '../widgets/common/curved_bottom_nav.dart';
import '../widgets/common/custom_app_bar.dart';
import '../widgets/modals/search_filter_sheet.dart';
import 'groom_feed_screen.dart';
import 'bride_feed_screen.dart';

/// Main Application Shell with Persistent Curved Bottom Navigation
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  void _openPublishWizard() {
    Navigator.pushNamed(context, '/publish-wizard');
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
        onCenterTap: _openPublishWizard,
      ),
    );
  }
}
