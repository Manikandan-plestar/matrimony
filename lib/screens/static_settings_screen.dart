import 'package:flutter/material.dart';
import '../config/theme.dart';

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
  // Mock switches for interactive settings
  bool _hideContactNumber = true;
  bool _onlyPremiumCanView = false;
  bool _blurPhotosUntilAccept = false;

  bool _pushNotifications = true;
  bool _emailAlerts = true;
  bool _weeklyMatchDigest = true;

  @override
  Widget build(BuildContext context) {
    switch (widget.type) {
      case SettingsScreenType.privacy:
        return _buildPrivacyView();
      case SettingsScreenType.notifications:
        return _buildNotificationsView();
      case SettingsScreenType.help:
        return _buildHelpView();
      case SettingsScreenType.about:
        return _buildAboutView();
    }
  }

  Widget _buildPrivacyView() {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy & Visibility')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSwitchTile(
            title: 'Protect Contact Number',
            subtitle: 'Only share phone number with matches whose interest you accepted.',
            value: _hideContactNumber,
            onChanged: (v) => setState(() => _hideContactNumber = v),
          ),
          _buildSwitchTile(
            title: 'Photo Privacy Shield',
            subtitle: 'Blur photograph for unverified visitors until you accept interest.',
            value: _blurPhotosUntilAccept,
            onChanged: (v) => setState(() => _blurPhotosUntilAccept = v),
          ),
          _buildSwitchTile(
            title: 'Premium-Only Visibility',
            subtitle: 'Restrict full horoscope and family details to verified members.',
            value: _onlyPremiumCanView,
            onChanged: (v) => setState(() => _onlyPremiumCanView = v),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsView() {
    return Scaffold(
      appBar: AppBar(title: const Text('Notification Preferences')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSwitchTile(
            title: 'New Matches & Invitations',
            subtitle: 'Receive alerts when someone expresses interest or likes your bio.',
            value: _pushNotifications,
            onChanged: (v) => setState(() => _pushNotifications = v),
          ),
          _buildSwitchTile(
            title: 'Weekly Digest',
            subtitle: 'Email summary of high-compatibility matches in your city.',
            value: _weeklyMatchDigest,
            onChanged: (v) => setState(() => _weeklyMatchDigest = v),
          ),
          _buildSwitchTile(
            title: 'Email Security Notices',
            subtitle: 'Account login alerts and security confirmations.',
            value: _emailAlerts,
            onChanged: (v) => setState(() => _emailAlerts = v),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpView() {
    return Scaffold(
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
            child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
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
                  padding: const EdgeInsets.all(10.0),
                  child: Image.asset(
                    'assets/images/spouse_spotter_icon.png',
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Center(
                      child: Icon(Icons.favorite_rounded, color: AppTheme.burgundy, size: 48),
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
            const Text('Version 1.0.0 (Phase 1 Frontend Prototype)', style: TextStyle(color: AppTheme.textSecondary)),
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

  Widget _buildSwitchTile({
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
      child: SwitchListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: Text(subtitle, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
        value: value,
        activeTrackColor: AppTheme.burgundy,
        onChanged: onChanged,
      ),
    );
  }
}


