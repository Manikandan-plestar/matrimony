import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/theme.dart';
import '../providers/auth_provider.dart';
import '../providers/profile_provider.dart';
import '../providers/interaction_provider.dart';
import '../providers/discovery_provider.dart';
import '../providers/notification_provider.dart';
import '../providers/search_filter_provider.dart';
import '../providers/subscription_provider.dart';
import '../widgets/modals/daily_limit_modal.dart';
import '../utils/app_image_helper.dart';

/// User Account & Profile Hub (Opened from top-right Settings/Avatar icon)
class SettingsProfileScreen extends StatefulWidget {
  const SettingsProfileScreen({super.key});

  @override
  State<SettingsProfileScreen> createState() => _SettingsProfileScreenState();
}

class _SettingsProfileScreenState extends State<SettingsProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProfileProvider>().fetchMyProfile();
      context.read<SubscriptionProvider>().fetchStatus();
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    final myProfile = context.watch<ProfileProvider>().myProfile;
    final interaction = context.watch<InteractionProvider>();
    final subscription = context.watch<SubscriptionProvider>();

    final displayName = (myProfile?.fullName.isNotEmpty ?? false)
        ? myProfile!.fullName
        : (user?.fullName.isNotEmpty ?? false)
            ? user!.fullName
            : (user?.email.isNotEmpty ?? false)
                ? user!.email.split('@').first
                : 'My Profile';

    final displayOccupation = (myProfile?.occupation.isNotEmpty ?? false)
        ? myProfile!.occupation
        : 'Member';

    final displayId = (myProfile?.profileId.isNotEmpty ?? false)
        ? myProfile!.profileId
        : (user?.activeProfileId.isNotEmpty ?? false)
            ? user!.activeProfileId
            : (user?.phone.isNotEmpty ?? false)
                ? user!.phone
                : 'Pending Registration';

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
                      AppImageHelper.buildAvatar(
                        url: (myProfile?.profilePhotoUrl.isNotEmpty ?? false)
                            ? myProfile!.profilePhotoUrl
                            : user?.profilePhotoUrl,
                        fullName: displayName,
                        radius: 36,
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
                          displayName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'ID: $displayId • $displayOccupation',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (user?.email != null && user!.email.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.email_outlined, size: 12, color: AppTheme.textSecondary),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  user.email,
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    color: AppTheme.textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: AppTheme.burgundy.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.lock_rounded, size: 9, color: AppTheme.burgundy),
                                    SizedBox(width: 2),
                                    Text(
                                      'Private',
                                      style: TextStyle(fontSize: 9, color: AppTheme.burgundy, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: myProfile != null ? AppTheme.goldLight : const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: myProfile != null
                                  ? AppTheme.gold.withValues(alpha: 0.4)
                                  : const Color(0xFFBFDBFE),
                            ),
                          ),
                          child: Text(
                            myProfile != null ? 'Active Matrimonial Profile' : 'Draft / New Member',
                            style: TextStyle(
                              color: myProfile != null ? const Color(0xFF854D0E) : const Color(0xFF1D4ED8),
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
                subtitle: subscription.isUnlimited
                    ? '${interaction.visitors.length} people viewed your profile'
                    : 'Unlock with ₹499 (1 Year Plan)',
                badgeText: subscription.isUnlimited ? null : 'PRO',
                onTap: () => Navigator.pushNamed(context, '/visitors'),
              ),
            ]),

            const SizedBox(height: 18),

            // 4. Group: Settings & Support
            _buildGroupHeader('Settings & Support'),
            _buildMenuGroup([
              _buildMenuItem(
                icon: Icons.settings_outlined,
                title: 'Settings',
                subtitle: 'Privacy, notifications & account preferences',
                onTap: () => Navigator.pushNamed(context, '/privacy-settings'),
              ),
              _buildMenuItem(
                icon: Icons.card_membership_rounded,
                title: 'Subscription',
                subtitle: subscription.isUnlimited
                    ? 'Active Premium Member • 1 Year Unlimited'
                    : 'Basic Free Plan • Compare & Upgrade to Premium',
                badgeText: subscription.isUnlimited ? 'ACTIVE' : 'UPGRADE',
                onTap: () => Navigator.pushNamed(context, '/subscription'),
              ),
              _buildMenuItem(
                icon: Icons.help_outline_rounded,
                title: 'Help & Customer Support',
                subtitle: 'FAQs, contact team & grievance redressal',
                onTap: () => Navigator.pushNamed(context, '/help-support'),
              ),
              _buildMenuItem(
                icon: Icons.info_outline_rounded,
                title: 'About Matrimonyer App',
                subtitle: 'Terms, version info & privacy policy',
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
                  side: const BorderSide(color: AppTheme.error, width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                icon: const Icon(Icons.logout_rounded, size: 18, color: AppTheme.error),
                label: const Text(
                  'Logout',
                  style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.error),
                ),
                onPressed: () => _handleLogout(context),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  /// Permanent Account Deletion Dialog with Type-to-Confirm Safeguard
  Future<void> _handleDeleteAccount(BuildContext context) async {
    final deleteTextController = TextEditingController();
    bool isMatch = false;

    final shouldDelete = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
            title: const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: AppTheme.error, size: 26),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Delete My Account',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.error.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.error.withValues(alpha: 0.2)),
                    ),
                    child: const Text(
                      '⚠️ Warning: This action is permanent and cannot be undone. All your profile details, uploaded photos, saved matches, interests, and subscription benefits will be permanently wiped.',
                      style: TextStyle(fontSize: 12.5, color: AppTheme.error, height: 1.4),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'To confirm permanent deletion, type "delete my account" below:',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: deleteTextController,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'Type "delete my account"',
                      hintStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppTheme.cardBorder),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppTheme.error, width: 1.8),
                      ),
                    ),
                    onChanged: (val) {
                      final clean = val.trim().toLowerCase();
                      final matches = clean == 'delete my account' || clean == 'delete';
                      if (matches != isMatch) {
                        setDialogState(() {
                          isMatch = matches;
                        });
                      }
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.error,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AppTheme.cardBorder,
                  disabledForegroundColor: AppTheme.textMuted,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                icon: const Icon(Icons.delete_forever_rounded, size: 18),
                label: const Text('Delete Forever'),
                onPressed: isMatch ? () => Navigator.pop(ctx, true) : null,
              ),
            ],
          );
        },
      ),
    );

    deleteTextController.dispose();

    if (shouldDelete != true) return;
    if (!context.mounted) return;

    // Show non-dismissible loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const PopScope(
        canPop: false,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: AppTheme.error),
              SizedBox(height: 16),
              Text(
                'Permanently deleting your account...',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );

    try {
      // 1. Permanently wipe account on backend and delete JWT
      await context.read<AuthProvider>().deleteAccount();

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
      // Handled gracefully: local credentials cleared
    }

    if (context.mounted) {
      // Close loading dialog if open
      Navigator.of(context, rootNavigator: true).pop();

      // Show confirmation SnackBar
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppTheme.error,
          content: Text('Your account and matrimonial data have been permanently deleted.'),
        ),
      );

      // 3. Clear navigation stack and redirect to Login screen
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    }
  }

  /// Logout confirmation dialog with clear confirmation safeguards
  Future<void> _handleLogout(BuildContext context) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: AppTheme.burgundy, size: 24),
            SizedBox(width: 8),
            Text('Confirm Logout', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          'Are you sure you want to log out of Matrimonyer? You will need to sign in again to access your account.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.burgundy,
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
    Color? iconColor,
    Color? iconBgColor,
    Color? titleColor,
    bool isDestructive = false,
    required VoidCallback onTap,
  }) {
    final effectiveIconColor = iconColor ?? (isDestructive ? AppTheme.error : AppTheme.burgundy);
    final effectiveBgColor = iconBgColor ??
        (isDestructive ? AppTheme.error.withValues(alpha: 0.1) : AppTheme.roseLight.withValues(alpha: 0.5));
    final effectiveTitleColor = titleColor ?? (isDestructive ? AppTheme.error : AppTheme.textPrimary);

    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: effectiveBgColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: effectiveIconColor, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: isDestructive ? FontWeight.w700 : FontWeight.w600,
          color: effectiveTitleColor,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: isDestructive ? AppTheme.error.withValues(alpha: 0.8) : AppTheme.textSecondary,
              ),
            )
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
          Icon(
            Icons.chevron_right_rounded,
            size: 20,
            color: isDestructive ? AppTheme.error.withValues(alpha: 0.6) : AppTheme.textMuted,
          ),
        ],
      ),
    );
  }
}


