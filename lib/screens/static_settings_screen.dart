import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/theme.dart';
import '../services/profile_service.dart';
import '../providers/auth_provider.dart';
import '../providers/profile_provider.dart';
import '../providers/discovery_provider.dart';
import '../providers/interaction_provider.dart';
import '../providers/notification_provider.dart';
import '../providers/search_filter_provider.dart';
import '../providers/subscription_provider.dart';
import '../widgets/modals/terms_conditions_modal.dart';

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
  // ── Privacy Settings (synced with backend + local prefs) ──
  bool _profileDiscoverable = true;
  bool _protectContactNumber = true;
  bool _photoPrivacyShield = false;

  // ── Notification Settings ──
  bool _matchAlert80 = true; // High compatibility (80%+) alert (backend synced)
  bool _interestAlerts = true; // Instant interest & connection alerts (UI toggle)
  bool _visitorDigest = true; // Profile visitor & activity digest (UI toggle)

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    // 1. Initial load from local prefs for instant UI response
    if (mounted) {
      setState(() {
        _profileDiscoverable = prefs.getBool('settings_discoverable') ?? true;
        _protectContactNumber = prefs.getBool('settings_protect_phone') ?? true;
        _photoPrivacyShield = prefs.getBool('settings_photo_shield') ?? false;
        _matchAlert80 = prefs.getBool('settings_match_alert_80') ?? true;
        _interestAlerts = prefs.getBool('settings_interest_alerts') ?? true;
        _visitorDigest = prefs.getBool('settings_visitor_digest') ?? true;
      });
    }

    // 2. Fetch and sync from backend
    try {
      final backendSettings = await ProfileService.fetchSettings();
      if (backendSettings != null && mounted) {
        setState(() {
          if (backendSettings['profileDiscoverable'] is bool) {
            _profileDiscoverable = backendSettings['profileDiscoverable'] as bool;
            prefs.setBool('settings_discoverable', _profileDiscoverable);
          }
          if (backendSettings['protectPhone'] is bool) {
            _protectContactNumber = backendSettings['protectPhone'] as bool;
            prefs.setBool('settings_protect_phone', _protectContactNumber);
          }
          if (backendSettings['photoShield'] is bool) {
            _photoPrivacyShield = backendSettings['photoShield'] as bool;
            prefs.setBool('settings_photo_shield', _photoPrivacyShield);
          }
          if (backendSettings['notifyHighMatch'] is bool) {
            _matchAlert80 = backendSettings['notifyHighMatch'] as bool;
            prefs.setBool('settings_match_alert_80', _matchAlert80);
          }
          if (backendSettings['notifyInterests'] is bool) {
            _interestAlerts = backendSettings['notifyInterests'] as bool;
            prefs.setBool('settings_interest_alerts', _interestAlerts);
          }
          if (backendSettings['notifyVisitors'] is bool) {
            _visitorDigest = backendSettings['notifyVisitors'] as bool;
            prefs.setBool('settings_visitor_digest', _visitorDigest);
          }
        });
      }
    } catch (_) {}
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

  /// Full Settings view: Displays split Privacy and Notification sections with Delete My Account below
  Widget _buildSettingsView() {
    final user = context.watch<AuthProvider>().currentUser;
    final userEmail = (user?.email.isNotEmpty ?? false) ? user!.email : null;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        children: [
          // ════════════════════════════════════════════════════════
          // 0. LOGGED-IN ACCOUNT (Private to user only)
          // ════════════════════════════════════════════════════════
          _buildSectionHeader('Account Information'),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppTheme.cardBorder),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.burgundy.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.email_outlined, color: AppTheme.burgundy, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Logged-in Email',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        userEmail ?? 'Not logged in',
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          Icon(Icons.lock_rounded, size: 12, color: AppTheme.burgundy.withValues(alpha: 0.8)),
                          const SizedBox(width: 4),
                          const Expanded(
                            child: Text(
                              'Private to you • Never shown to other profiles',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppTheme.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      const Divider(height: 1, color: AppTheme.cardBorder),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () => Navigator.pushNamed(context, '/subscription'),
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Icon(
                                context.watch<SubscriptionProvider>().isUnlimited
                                    ? Icons.workspace_premium_rounded
                                    : Icons.card_membership_rounded,
                                size: 16,
                                color: context.watch<SubscriptionProvider>().isUnlimited
                                    ? const Color(0xFFB45309)
                                    : AppTheme.burgundy,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  context.watch<SubscriptionProvider>().isUnlimited
                                      ? 'Subscription: Unlimited Premium (Active)'
                                      : 'Subscription: Basic Plan • Upgrade to Premium',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: context.watch<SubscriptionProvider>().isUnlimited
                                        ? const Color(0xFFB45309)
                                        : AppTheme.burgundy,
                                  ),
                                ),
                              ),
                              const Icon(Icons.chevron_right_rounded, size: 18, color: AppTheme.textSecondary),
                            ],
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

          // ════════════════════════════════════════════════════════
          // 1. PRIVACY SETTINGS
          // ════════════════════════════════════════════════════════
          _buildSectionHeader('Privacy Settings'),

          // 1. Profile Discoverability
          _buildSwitchTile(
            icon: Icons.visibility_rounded,
            title: 'Profile Discoverability',
            subtitle: _profileDiscoverable
                ? 'Visible — Profile is shown in discovery feeds'
                : 'Hidden — Profile is temporarily not shown to anyone in the app',
            value: _profileDiscoverable,
            onChanged: (v) {
              setState(() => _profileDiscoverable = v);
              _savePreference('settings_discoverable', v);
              ProfileService.updateSettings({'profileDiscoverable': v});
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  duration: const Duration(seconds: 2),
                  backgroundColor: v ? AppTheme.burgundy : AppTheme.textSecondary,
                  content: Text(v
                      ? 'Profile is now discoverable in feeds.'
                      : 'Profile paused. It is temporarily not shown to anyone in the application.'),
                ),
              );
            },
          ),

          // 2. Protect Mobile Number
          _buildSwitchTile(
            icon: Icons.phonelink_lock_rounded,
            title: 'Protect Mobile Number',
            subtitle: _protectContactNumber
                ? 'Protected — Only verified account holders can view mobile number'
                : 'Hidden — Mobile number not shown to anyone (even mutual connections)',
            value: _protectContactNumber,
            onChanged: (v) {
              setState(() => _protectContactNumber = v);
              _savePreference('settings_protect_phone', v);
              ProfileService.updateSettings({'protectPhone': v});
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  duration: const Duration(seconds: 2),
                  backgroundColor: AppTheme.burgundy,
                  content: Text(v
                      ? 'Mobile number visible only to verified accounts.'
                      : 'Mobile number hidden from everyone, even mutually connected users.'),
                ),
              );
            },
          ),

          // 3. Photo Privacy Shield
          _buildSwitchTile(
            icon: Icons.shield_outlined,
            title: 'Photo Privacy Shield',
            subtitle: _photoPrivacyShield
                ? 'Shield ON — Photos hidden from normal users; only verified & mutual connects can view'
                : 'Shield OFF — Profile photographs visible to registered members',
            value: _photoPrivacyShield,
            onChanged: (v) {
              setState(() => _photoPrivacyShield = v);
              _savePreference('settings_photo_shield', v);
              ProfileService.updateSettings({'photoShield': v});
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  duration: const Duration(seconds: 2),
                  backgroundColor: AppTheme.burgundy,
                  content: Text(v
                      ? 'Photo Privacy Shield active. Standard users cannot view your photos.'
                      : 'Photo Privacy Shield deactivated.'),
                ),
              );
            },
          ),

          const SizedBox(height: 18),

          // ════════════════════════════════════════════════════════
          // 2. NOTIFICATION SETTINGS
          // ════════════════════════════════════════════════════════
          _buildSectionHeader('Notification Settings'),

          // 1. High Compatibility Match Alert (80%+)
          _buildSwitchTile(
            icon: Icons.stars_rounded,
            title: 'Match Alert (80%+ Compatibility)',
            subtitle: _matchAlert80
                ? 'Active — Instant notification when a candidate profile is 80%+ match'
                : 'Paused — Do not alert for high compatibility matches',
            value: _matchAlert80,
            onChanged: (v) {
              setState(() => _matchAlert80 = v);
              _savePreference('settings_match_alert_80', v);
              ProfileService.updateSettings({'notifyHighMatch': v});
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  duration: const Duration(seconds: 2),
                  backgroundColor: AppTheme.burgundy,
                  content: Text(v
                      ? '80%+ Match Alert active. You will be notified for high matches.'
                      : 'High compatibility match alerts paused.'),
                ),
              );
            },
          ),

          // 2. Instant Interest & Connection Alerts (synced with backend)
          _buildSwitchTile(
            icon: Icons.notifications_active_outlined,
            title: 'Instant Interest & Connection Alerts',
            subtitle: _interestAlerts
                ? 'Active — Instant alerts for new interest requests and accepted matches'
                : 'Paused — Interest and connection alerts disabled',
            value: _interestAlerts,
            onChanged: (v) {
              setState(() => _interestAlerts = v);
              _savePreference('settings_interest_alerts', v);
              ProfileService.updateSettings({'notifyInterests': v});
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  duration: const Duration(seconds: 2),
                  backgroundColor: AppTheme.burgundy,
                  content: Text(v
                      ? 'Instant interest & connection alerts enabled.'
                      : 'Interest and connection alerts paused.'),
                ),
              );
            },
          ),

          // 3. Profile Visitor Digest (synced with backend: notifies when viewed > 2 times/day)
          _buildSwitchTile(
            icon: Icons.visibility_outlined,
            title: 'Profile Visitor Digest',
            subtitle: _visitorDigest
                ? 'Active — Notify when the same person views your profile more than 2 times a day'
                : 'Paused — Visitor notifications disabled',
            value: _visitorDigest,
            onChanged: (v) {
              setState(() => _visitorDigest = v);
              _savePreference('settings_visitor_digest', v);
              ProfileService.updateSettings({'notifyVisitors': v});
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  duration: const Duration(seconds: 2),
                  backgroundColor: AppTheme.burgundy,
                  content: Text(v
                      ? 'Visitor alerts enabled (notifies when viewed more than 2 times a day).'
                      : 'Visitor notifications paused.'),
                ),
              );
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
            icon: Icons.stars_rounded,
            title: 'Match Alert (80%+ Compatibility)',
            subtitle: _matchAlert80
                ? 'Active — Instant notification when a candidate profile is 80%+ match'
                : 'Paused — Do not alert for high compatibility matches',
            value: _matchAlert80,
            onChanged: (v) {
              setState(() => _matchAlert80 = v);
              _savePreference('settings_match_alert_80', v);
              ProfileService.updateSettings({'notifyHighMatch': v});
            },
          ),
          _buildSwitchTile(
            icon: Icons.notifications_active_outlined,
            title: 'Instant Interest & Connection Alerts',
            subtitle: _interestAlerts
                ? 'Active — Instant alerts for new interest requests and accepted matches'
                : 'Paused — Interest and connection alerts disabled',
            value: _interestAlerts,
            onChanged: (v) {
              setState(() => _interestAlerts = v);
              _savePreference('settings_interest_alerts', v);
              ProfileService.updateSettings({'notifyInterests': v});
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  duration: const Duration(seconds: 2),
                  backgroundColor: AppTheme.burgundy,
                  content: Text(v
                      ? 'Instant interest & connection alerts enabled.'
                      : 'Interest and connection alerts paused.'),
                ),
              );
            },
          ),
          _buildSwitchTile(
            icon: Icons.visibility_outlined,
            title: 'Profile Visitor Digest',
            subtitle: _visitorDigest
                ? 'Active — Notify when the same person views your profile more than 2 times a day'
                : 'Paused — Visitor notifications disabled',
            value: _visitorDigest,
            onChanged: (v) {
              setState(() => _visitorDigest = v);
              _savePreference('settings_visitor_digest', v);
              ProfileService.updateSettings({'notifyVisitors': v});
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  duration: const Duration(seconds: 2),
                  backgroundColor: AppTheme.burgundy,
                  content: Text(v
                      ? 'Visitor alerts enabled (notifies when viewed more than 2 times a day).'
                      : 'Visitor notifications paused.'),
                ),
              );
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
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: () => showTermsConditionsModal(context, initialTab: 0),
                  icon: const Icon(Icons.description_outlined, size: 16, color: AppTheme.burgundy),
                  label: const Text('Terms of Service', style: TextStyle(color: AppTheme.burgundy, fontSize: 13, fontWeight: FontWeight.w600)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppTheme.rose),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: () => showTermsConditionsModal(context, initialTab: 1),
                  icon: const Icon(Icons.privacy_tip_outlined, size: 16, color: AppTheme.burgundy),
                  label: const Text('Privacy Policy', style: TextStyle(color: AppTheme.burgundy, fontSize: 13, fontWeight: FontWeight.w600)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppTheme.rose),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
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
