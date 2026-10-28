import 'package:flutter/material.dart';
import '../../config/theme.dart';

/// Shows an interactive, full-featured Terms of Service & Privacy Policy Modal Bottom Sheet.
Future<void> showTermsConditionsModal(
  BuildContext context, {
  int initialTab = 0,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => TermsConditionsModal(initialTab: initialTab),
  );
}

class TermsConditionsModal extends StatefulWidget {
  final int initialTab; // 0 = Terms of Service, 1 = Privacy Policy

  const TermsConditionsModal({
    super.key,
    this.initialTab = 0,
  });

  @override
  State<TermsConditionsModal> createState() => _TermsConditionsModalState();
}

class _TermsConditionsModalState extends State<TermsConditionsModal> {
  late int _selectedTab;

  @override
  void initState() {
    super.initState();
    _selectedTab = widget.initialTab;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // ── Drag Handle ──
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 44,
              height: 4.5,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // ── Header ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.roseLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.verified_user_rounded,
                        color: AppTheme.burgundy,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Legal & Policies',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        Text(
                          'Matrimonyer • Version 1.0.0',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, size: 22, color: AppTheme.textSecondary),
                  splashRadius: 20,
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ── Tab Switcher: Terms of Service vs Privacy Policy ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildTabButton(
                      title: 'Terms of Service',
                      index: 0,
                    ),
                  ),
                  Expanded(
                    child: _buildTabButton(
                      title: 'Privacy Policy',
                      index: 1,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 14),
          const Divider(height: 1, color: AppTheme.dividerColor),

          // ── Scrollable Content ──
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: _selectedTab == 0 ? _buildTermsContent() : _buildPrivacyContent(),
            ),
          ),

          // ── Bottom Action Button ──
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.burgundy,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'I Understand & Agree',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton({required String title, required int index}) {
    final isSelected = _selectedTab == index;
    return InkWell(
      onTap: () => setState(() => _selectedTab = index),
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? AppTheme.burgundy : AppTheme.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTermsContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildIntroNotice(
          'Please read these Terms & Conditions carefully before creating an account or using Matrimonyer. By proceeding, you agree to comply with and be bound by these provisions.',
        ),
        const SizedBox(height: 16),
        _buildSectionCard(
          icon: Icons.cake_rounded,
          number: '1',
          title: 'Eligibility & Legal Age',
          content:
              'Matrimonyer is strictly for individuals legally eligible for matrimony. You must be at least 18 years of age (female) or 21 years of age (male) under the applicable law of your jurisdiction. Accounts created on behalf of minors or for casual dating are strictly prohibited.',
        ),
        _buildSectionCard(
          icon: Icons.person_pin_rounded,
          number: '2',
          title: 'Profile Authenticity & Verification',
          content:
              'You represent and warrant that all details provided (name, age, marital status, community, education, and profession) are accurate and truthful. Uploaded photos must depict the actual individual. Impersonation, stock photography, or fraudulent profiles will result in immediate termination.',
        ),
        _buildSectionCard(
          icon: Icons.favorite_border_rounded,
          number: '3',
          title: 'Marital Purpose & Conduct',
          content:
              'This application is dedicated solely to matrimonial matchmaking. You agree not to use this service for commercial solicitation, harassment, offensive communication, extramarital dating, or financial exploitation.',
        ),
        _buildSectionCard(
          icon: Icons.workspace_premium_rounded,
          number: '4',
          title: 'Premium Membership & Payments',
          content:
              'Free accounts enjoy standard daily profile swipes. Premium Membership (₹499 / 1 Year) unlocks unlimited profile discovery, full visitor insights, and verified direct contact numbers. All purchases are processed securely through Google Play or Apple App Store and are subject to store policies.',
        ),
        _buildSectionCard(
          icon: Icons.delete_forever_rounded,
          number: '5',
          title: 'Account Deletion & Cancellation',
          content:
              'You retain absolute right to permanently delete your account, images, and matchmaking records at any time directly through the app settings. Permanent deletion permanently wipes all stored personal data from our active servers.',
        ),
        _buildSectionCard(
          icon: Icons.gavel_rounded,
          number: '6',
          title: 'Governing Law & Jurisdiction',
          content:
              'These terms shall be governed by and interpreted in accordance with the laws of India. Any disputes arising out of the use of this service shall be subject to the exclusive jurisdiction of the competent courts in Tamil Nadu, India.',
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildPrivacyContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildIntroNotice(
          'Your privacy is sacred. We enforce strict data protection protocols, protected phone visibility, and end-to-end HTTPS encryption to ensure your matchmaking journey is safe and respectful.',
        ),
        const SizedBox(height: 16),
        _buildSectionCard(
          icon: Icons.folder_shared_rounded,
          number: '1',
          title: 'Information We Collect',
          content:
              'We collect information required to build your matrimonial biodata: full name, verified email, mobile number, birth date, mother tongue, religion, community, education, occupation, and uploaded profile photographs.',
        ),
        _buildSectionCard(
          icon: Icons.my_location_rounded,
          number: '2',
          title: 'Location Data Usage',
          content:
              'We use GPS location exclusively with your explicit permission to auto-detect your current City, State, and Country for geographic matching. We never track your real-time whereabouts or background location continuously.',
        ),
        _buildSectionCard(
          icon: Icons.phonelink_lock_rounded,
          number: '3',
          title: 'Phone Number Protection',
          content:
              'Your mobile number is never made publicly accessible on search engines or visible to unverified users. Mobile details are only visible to active verified members according to your configured privacy settings.',
        ),
        _buildSectionCard(
          icon: Icons.security_rounded,
          number: '4',
          title: 'Zero Third-Party Data Sale',
          content:
              'We do not sell, rent, or trade your personal data, biodata, or photos to third-party marketing companies, advertisers, or lead generators.',
        ),
        _buildSectionCard(
          icon: Icons.lock_clock_rounded,
          number: '5',
          title: 'Data Retention & Right to be Forgotten',
          content:
              'Whenever you initiate an account deletion from Settings, your profile records, preferences, visitor logs, and uploaded photos are completely purged from our active databases in compliance with global data safety regulations.',
        ),
        _buildSectionCard(
          icon: Icons.mail_outline_rounded,
          number: '6',
          title: 'Grievance & Privacy Inquiries',
          content:
              'For any privacy concerns, data deletion inquiries, or support requests, you can contact our Grievance Officer at: support@plestarinc.com.',
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildIntroNotice(String text) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.roseLight.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.rose.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded, color: AppTheme.burgundy, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.burgundyDark,
                height: 1.45,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required IconData icon,
    required String number,
    required String title,
    required String content,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppTheme.roseLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: AppTheme.burgundy),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '$number. $title',
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(
              fontSize: 12.2,
              color: AppTheme.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
