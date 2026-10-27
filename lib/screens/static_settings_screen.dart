import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/theme.dart';
import '../providers/auth_provider.dart';
import '../providers/profile_provider.dart';
import '../providers/discovery_provider.dart';
import '../providers/interaction_provider.dart';
import '../providers/notification_provider.dart';
import '../providers/search_filter_provider.dart';
import '../providers/subscription_provider.dart';

enum SettingsScreenType {
  privacy,
  notifications,
  help,
  about,
}

/// Generic Settings & Support Screen
class StaticSettingsScreen extends StatefulWidget {
  final SettingsScreenType type;

  const StaticSettingsScreen({super.key, required this.type});

  @override
  State<StaticSettingsScreen> createState() => _StaticSettingsScreenState();
}

class _StaticSettingsScreenState extends State<StaticSettingsScreen> {
  // Settings Toggles with local persistence
  bool _profileDiscoverable = true;
  bool _hideContactNumber = true;
  bool _pushNotifications = true;
  bool _onlineStatusVisible = true;
  bool _blurPhotosUntilAccept = false;
  bool _weeklyMatchDigest = true;
  bool _emailAlerts = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _profileDiscoverable = prefs.getBool('settings_discoverable') ?? true;
        _hideContactNumber = prefs.getBool('settings_privacy_mode') ?? true;
        _pushNotifications = prefs.getBool('settings_notifications') ?? true;
        _onlineStatusVisible = prefs.getBool('settings_online_status') ?? true;
        _blurPhotosUntilAccept = prefs.getBool('settings_blur_photo') ?? false;
        _weeklyMatchDigest = prefs.getBool('settings_weekly_digest') ?? true;
        _emailAlerts = prefs.getBool('settings_email_alerts') ?? true;
      });
    }
  }

  Future<void> _savePreference(String key, bool val) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, val);
  }

  @override
  Widget build(BuildContext context) {
    switch (widget.type) {
      case SettingsScreenType.privacy:
        return _buildSettingsView();
      case SettingsScreenType.notifications:
        return _buildNotificationsView();
      case SettingsScreenType.help:
        return _buildHelpView();
      case SettingsScreenType.about:
        return _buildAboutView();
    }
  }

  /// Full Settings view: Displays setting toggle options with "Delete My Account" placed below
  Widget _buildSettingsView() {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        children: [
          _buildSectionHeader('Preferences & Privacy Toggles'),

          // 1. Profile Discoverability
          _buildSwitchTile(
            icon: Icons.visibility_rounded,
            title: 'Profile Discoverability',
            subtitle: _profileDiscoverable
                ? 'Visible in Groom & Bride discovery feeds'
                : 'Profile paused from public discovery feeds',
            value: _profileDiscoverable,
            onChanged: (v) {
              setState(() => _profileDiscoverable = v);
              _savePreference('settings_discoverable', v);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  duration: const Duration(seconds: 2),
                  backgroundColor: v ? AppTheme.burgundy : AppTheme.textSecondary,
                  content: Text(v ? 'Profile is now discoverable.' : 'Profile paused from discovery feeds.'),
                ),
              );
            },
          ),

          // 2. Protect Contact Number
          _buildSwitchTile(
            icon: Icons.phonelink_lock_rounded,
            title: 'Protect Contact Number',
            subtitle: _hideContactNumber
                ? 'Only mutual accepted matches can view phone number'
                : 'Contact number visible to all registered members',
            value: _hideContactNumber,
            onChanged: (v) {
              setState(() => _hideContactNumber = v);
              _savePreference('settings_privacy_mode', v);
            },
          ),

          // 3. Match & Interest Alerts
          _buildSwitchTile(
            icon: Icons.notifications_active_outlined,
            title: 'Match & Interest Alerts',
            subtitle: 'Push notifications for views, interests & connections',
            value: _pushNotifications,
            onChanged: (v) {
              setState(() => _pushNotifications = v);
              _savePreference('settings_notifications', v);
            },
          ),

          // 4. Online Activity Status
          _buildSwitchTile(
            icon: Icons.access_time_rounded,
            title: 'Online Activity Status',
            subtitle: 'Show prospective partners when you were recently active',
            value: _onlineStatusVisible,
            onChanged: (v) {
              setState(() => _onlineStatusVisible = v);
              _savePreference('settings_online_status', v);
            },
          ),

          // 5. Photo Privacy Shield
          _buildSwitchTile(
            icon: Icons.photo_filter_rounded,
            title: 'Photo Privacy Shield',
            subtitle: 'Blur photograph for unverified visitors until interest is accepted',
            value: _blurPhotosUntilAccept,
            onChanged: (v) {
              setState(() => _blurPhotosUntilAccept = v);
              _savePreference('settings_blur_photo', v);
            },
          ),

          // 6. Weekly Match Digest
          _buildSwitchTile(
            icon: Icons.email_outlined,
            title: 'Weekly Match Digest',
            subtitle: 'Email summary of high-compatibility matches in your city',
            value: _weeklyMatchDigest,
            onChanged: (v) {
              setState(() => _weeklyMatchDigest = v);
              _savePreference('settings_weekly_digest', v);
            },
          ),

          const SizedBox(height: 24),

          // ── Danger Zone: Delete My Account Placed Below Settings Options ──
          _buildSectionHeader('Account Actions'),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppTheme.error.withValues(alpha: 0.25)),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.error.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: AppTheme.error, size: 22),
                    SizedBox(width: 8),
                    Text(
                      'Danger Zone',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.error,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Permanently delete your matrimony profile, photos, matches, and account records. This action cannot be reversed.',
                  style: TextStyle(fontSize: 12.5, color: AppTheme.textSecondary, height: 1.4),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.error,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: const Icon(Icons.delete_forever_rounded, size: 20),
                    label: const Text(
                      'Delete My Account',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    onPressed: () => _handleDeleteAccount(context),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  /// Permanent Account Deletion Safeguard
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
                      '⚠️ Warning: This action is permanent and cannot be undone. All your profile details, uploaded photos, saved matches, interests, and subscription benefits will be permanently erased.',
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
      // Handled gracefully
    }

    if (context.mounted) {
      // Close loading dialog
      Navigator.of(context, rootNavigator: true).pop();

      // Show confirmation SnackBar
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppTheme.error,
          content: Text('Your account and matrimonial data have been permanently deleted.'),
        ),
      );

      // Redirect to Login screen
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    }
  }

  Widget _buildNotificationsView() {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('Notification Preferences')),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        children: [
          _buildSwitchTile(
            icon: Icons.notifications_active_outlined,
            title: 'New Matches & Invitations',
            subtitle: 'Receive alerts when someone expresses interest or likes your bio.',
            value: _pushNotifications,
            onChanged: (v) {
              setState(() => _pushNotifications = v);
              _savePreference('settings_notifications', v);
            },
          ),
          _buildSwitchTile(
            icon: Icons.email_outlined,
            title: 'Weekly Digest',
            subtitle: 'Email summary of high-compatibility matches in your city.',
            value: _weeklyMatchDigest,
            onChanged: (v) {
              setState(() => _weeklyMatchDigest = v);
              _savePreference('settings_weekly_digest', v);
            },
          ),
          _buildSwitchTile(
            icon: Icons.security_rounded,
            title: 'Email Security Notices',
            subtitle: 'Account login alerts and security confirmations.',
            value: _emailAlerts,
            onChanged: (v) {
              setState(() => _emailAlerts = v);
              _savePreference('settings_email_alerts', v);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHelpView() {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('Help & Customer Support')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppTheme.cardBorder),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dedicated Matrimonial Support',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.burgundy),
                ),
                SizedBox(height: 8),
                Text(
                  'Our matchmaking support team is available 7 days a week to assist with profile verification, partner searches, and matchmaking inquiries.',
                  style: TextStyle(fontSize: 13, color: AppTheme.textSecondary, height: 1.4),
                ),
                SizedBox(height: 14),
                Row(
                  children: [
                    Icon(Icons.email_outlined, color: AppTheme.rose, size: 18),
                    SizedBox(width: 8),
                    Text('support@matrimonyer.com', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  ],
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.phone_outlined, color: AppTheme.rose, size: 18),
                    SizedBox(width: 8),
                    Text('+91 1800 200 4567 (Toll Free)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutView() {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('About Matrimonyer')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Spacer(),
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.rose, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.burgundy.withValues(alpha: 0.12),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipOval(
                child: Padding(
                  padding: const EdgeInsets.all(2.0),
                  child: Image.asset(
                    'assets/images/matrimonyer_icon.png',
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Image.asset(
                      'assets/images/spouse_spotter_icon.png',
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Center(
                        child: Icon(Icons.favorite_rounded, color: AppTheme.burgundy, size: 48),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Matrimonyer',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppTheme.burgundy),
            ),
            const SizedBox(height: 6),
            const Text('Version 1.0.0', style: TextStyle(color: AppTheme.textSecondary)),
            const SizedBox(height: 16),
            const Text(
              'Designed for genuine relationship discovery, image-first matchmaking, and seamless family harmony.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textPrimary, fontSize: 14, height: 1.5),
            ),
            const Spacer(flex: 2),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
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
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.roseLight.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppTheme.burgundy, size: 20),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: Text(subtitle, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
        trailing: Switch.adaptive(
          value: value,
          activeColor: AppTheme.burgundy,
          activeTrackColor: AppTheme.roseLight,
          onChanged: onChanged,
        ),
      ),
    );
  }
}
