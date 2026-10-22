import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/auth_provider.dart';
import '../providers/profile_provider.dart';
import '../providers/interaction_provider.dart';
import '../providers/discovery_provider.dart';
import '../providers/notification_provider.dart';
import '../providers/search_filter_provider.dart';
import '../providers/subscription_provider.dart';
import '../widgets/modals/daily_limit_modal.dart';

/// User Account & Profile Hub (Opened from top-right Settings/Avatar icon)
class SettingsProfileScreen extends StatelessWidget {
  const SettingsProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    final myProfile = context.watch<ProfileProvider>().myProfile;
    final interaction = context.watch<InteractionProvider>();
    final sub = context.watch<SubscriptionProvider>();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('My Account & Profile'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          children: [
            // 1. User Profile Header Card with Photograph & Identity
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: AppTheme.cardBorder),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // User Photo
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 36,
                        backgroundImage: (user?.profilePhotoUrl.isNotEmpty ?? false)
                            ? NetworkImage(user!.profilePhotoUrl)
                            : (myProfile?.profilePhotoUrl.isNotEmpty ?? false)
                                ? NetworkImage(myProfile!.profilePhotoUrl)
                                : null,
                        backgroundColor: AppTheme.roseLight,
                        child: (user?.profilePhotoUrl.isEmpty ?? true) && (myProfile?.profilePhotoUrl.isEmpty ?? true)
                            ? Text(
                                (user?.fullName.isNotEmpty ?? false)
                                    ? user!.fullName[0].toUpperCase()
                                    : (myProfile?.fullName.isNotEmpty ?? false)
                                        ? myProfile!.fullName[0].toUpperCase()
                                        : 'U',
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.burgundy,
                                ),
                              )
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: AppTheme.burgundy,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.verified_rounded, size: 14, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),

                  // Name, ID & Status
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.fullName ?? myProfile?.fullName ?? 'User',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'ID: ${myProfile?.profileId ?? user?.activeProfileId ?? user?.phone ?? "N/A"} • ${myProfile?.occupation ?? "Member"}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppTheme.goldLight,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.gold.withValues(alpha: 0.4)),
                          ),
                          child: const Text(
                            'Active Matrimonial Profile',
                            style: TextStyle(
                              color: Color(0xFF854D0E),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // Subscription & Membership Status Card
            _buildSubscriptionCard(context, sub),

            const SizedBox(height: 18),

            // 2. Group: Profile Management
            _buildGroupHeader('Profile Management'),
            _buildMenuGroup([
              _buildMenuItem(
                icon: Icons.person_outline_rounded,
                title: 'My Matrimony Profile',
                subtitle: 'Preview profile organized across the 3 phases',
                onTap: () => Navigator.pushNamed(context, '/my-profile'),
              ),
              _buildMenuItem(
                icon: Icons.edit_note_rounded,
                title: 'Edit Personal Details',
                subtitle: 'Update identity, contact & photograph only',
                onTap: () => Navigator.pushNamed(context, '/edit-personal-details'),
              ),
              _buildMenuItem(
                icon: Icons.favorite_border_rounded,
                title: 'Partner Preference',
                subtitle: 'Age, location, education & lifestyle criteria',
                onTap: () => Navigator.pushNamed(context, '/edit-partner-preferences'),
              ),
            ]),

            const SizedBox(height: 18),

            // 3. Group: Activity & Matchmaking Hub
            _buildGroupHeader('Activity & Matchmaking'),
            _buildMenuGroup([
              _buildMenuItem(
                icon: Icons.bookmark_border_rounded,
                title: 'Saved Profiles',
                subtitle: '${interaction.savedProfiles.length} bookmarked candidates',
                badgeText: '${interaction.savedProfiles.length}',
                onTap: () => Navigator.pushNamed(context, '/saved-profiles'),
              ),
              _buildMenuItem(
                icon: Icons.swap_horiz_rounded,
                title: 'Interests & Connections',
                subtitle: '${interaction.connectionCount} Connected • ${interaction.sentInterests.length} Sent • ${interaction.receivedInterests.length} Requests',
                badgeText: interaction.pendingReceivedCount > 0
                    ? '${interaction.pendingReceivedCount} new'
                    : null,
                onTap: () => Navigator.pushNamed(context, '/interests'),
              ),
              _buildMenuItem(
                icon: Icons.stars_rounded,
                title: 'My Matches',
                subtitle: '${interaction.matches.length} mutual high-compatibility matches',
                onTap: () => Navigator.pushNamed(context, '/matches'),
              ),
              _buildMenuItem(
                icon: Icons.visibility_outlined,
                title: 'Profile Visitors',
                subtitle: '${interaction.visitors.length} people viewed your profile',
                onTap: () => Navigator.pushNamed(context, '/visitors'),
              ),
            ]),

            const SizedBox(height: 18),

            // 4. Group: Privacy, Settings & Support
            _buildGroupHeader('Settings & Support'),
            _buildMenuGroup([
              _buildMenuItem(
                icon: Icons.lock_outline_rounded,
                title: 'Privacy & Visibility Settings',
                onTap: () => Navigator.pushNamed(context, '/privacy-settings'),
              ),
              _buildMenuItem(
                icon: Icons.notifications_none_rounded,
                title: 'Notification Preferences',
                onTap: () => Navigator.pushNamed(context, '/notification-settings'),
              ),
              _buildMenuItem(
                icon: Icons.help_outline_rounded,
                title: 'Help & Customer Support',
                onTap: () => Navigator.pushNamed(context, '/help-support'),
              ),
              _buildMenuItem(
                icon: Icons.info_outline_rounded,
                title: 'About Spouse Spotter App',
                onTap: () => Navigator.pushNamed(context, '/about-app'),
              ),
            ]),

            const SizedBox(height: 20),

            // Logout Action
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.error,
                  side: const BorderSide(color: AppTheme.error),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                icon: const Icon(Icons.logout_rounded, size: 18),
                label: const Text('Logout'),
                onPressed: () => _handleLogout(context),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: AppTheme.error, size: 24),
            SizedBox(width: 8),
            Text('Logout', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          'Are you sure you want to log out of Spouse Spotter? You will need to sign in again to access your account.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (shouldLogout != true) return;
    if (!context.mounted) return;

    // Show non-dismissible loading spinner to block duplicate interactions
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const PopScope(
        canPop: false,
        child: Center(
          child: CircularProgressIndicator(color: AppTheme.burgundy),
        ),
      ),
    );

    try {
      // 1. Invalidate session on backend and clear JWT from SharedPreferences
      await context.read<AuthProvider>().logout();

      // 2. Clear in-memory cached state across all providers
      if (context.mounted) {
        context.read<ProfileProvider>().clear();
        context.read<DiscoveryProvider>().clear();
        context.read<InteractionProvider>().clear();
        context.read<NotificationProvider>().clear();
        context.read<SubscriptionProvider>().reset();
        context.read<SearchFilterProvider>().clearAllFilters();
      }
    } catch (_) {
      // Offline/network failure handled gracefully: local credentials cleared
    }

    if (context.mounted) {
      // 3. Clear navigation stack and redirect to Login screen
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    }
  }

  Widget _buildGroupHeader(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 8),
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppTheme.textSecondary,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }

  Widget _buildMenuGroup(List<Widget> items) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        children: items,
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    String? subtitle,
    String? badgeText,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppTheme.roseLight.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppTheme.burgundy, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
      ),
      subtitle: subtitle != null
          ? Text(subtitle, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary))
          : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (badgeText != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppTheme.roseLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                badgeText,
                style: const TextStyle(color: AppTheme.burgundy, fontWeight: FontWeight.bold, fontSize: 11),
              ),
            ),
            const SizedBox(width: 6),
          ],
          const Icon(Icons.chevron_right_rounded, size: 20, color: AppTheme.textMuted),
        ],
      ),
    );
  }

  Widget _buildSubscriptionCard(BuildContext context, SubscriptionProvider sub) {
    final isUnlimited = sub.isUnlimited;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isUnlimited ? const Color(0xFFFFFBEB) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isUnlimited ? const Color(0xFFFDE68A) : AppTheme.cardBorder,
          width: isUnlimited ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isUnlimited
                          ? const Color(0xFFFEF3C7)
                          : AppTheme.burgundy.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isUnlimited ? Icons.stars_rounded : Icons.swipe_rounded,
                      color: isUnlimited ? const Color(0xFFB45309) : AppTheme.burgundy,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isUnlimited ? 'Unlimited Swipe Plan' : 'Free Plan',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      Text(
                        isUnlimited
                            ? 'Unlimited discovery swipes active'
                            : '${sub.swipesRemainingToday} of 10 swipes remaining today',
                        style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isUnlimited ? const Color(0xFFFEF3C7) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isUnlimited ? const Color(0xFFF59E0B) : const Color(0xFFCBD5E1),
                  ),
                ),
                child: Text(
                  isUnlimited ? 'ACTIVE' : 'FREE',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: isUnlimited ? const Color(0xFFB45309) : const Color(0xFF475569),
                  ),
                ),
              ),
            ],
          ),
          if (!isUnlimited) ...[
            const SizedBox(height: 12),
            const Divider(height: 1, color: AppTheme.cardBorder),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Upgrade for unlimited swipes',
                  style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.w500),
                ),
                TextButton(
                  onPressed: () => DailyLimitModal.show(context),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'Upgrade ₹499',
                    style: TextStyle(
                      color: AppTheme.burgundy,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
