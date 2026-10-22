import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/matrimony_profile_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/interaction_provider.dart';
import '../../services/profile_service.dart';
import '../../utils/app_image_helper.dart';

/// Image-First Profile Details Modal Sheet with Privacy-Enforced Field Visibility
class ProfileDetailsModal extends StatefulWidget {
  final MatrimonyProfileModel profile;
  final VoidCallback onToggleSave;
  final VoidCallback onExpressInterest;

  const ProfileDetailsModal({
    super.key,
    required this.profile,
    required this.onToggleSave,
    required this.onExpressInterest,
  });

  @override
  State<ProfileDetailsModal> createState() => _ProfileDetailsModalState();
}

class _ProfileDetailsModalState extends State<ProfileDetailsModal> {
  MatrimonyProfileModel? _fullProfile;
  bool _isLoadingFull = false;

  @override
  void initState() {
    super.initState();
    _checkAndFetchFullProfile();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && widget.profile.id.isNotEmpty) {
        context.read<InteractionProvider>().recordProfileView(widget.profile.id);
      }
    });
  }

  Future<void> _checkAndFetchFullProfile() async {
    final currentUserId = context.read<AuthProvider>().currentUser?.activeProfileId;
    final isOwner = currentUserId != null &&
        (widget.profile.id == currentUserId || widget.profile.profileId == currentUserId);
    final isAuthorized = isOwner ||
        context.read<InteractionProvider>().isAuthorizedForFullProfile(widget.profile.id) ||
        widget.profile.interestStatus == 'accepted';

    if (isAuthorized) {
      setState(() => _isLoadingFull = true);
      try {
        final full = await ProfileService.fetchFullProfile(widget.profile.id);
        if (mounted && full != null) {
          setState(() {
            _fullProfile = full;
          });
        }
      } catch (_) {
        // Fallback silently if offline
      } finally {
        if (mounted) setState(() => _isLoadingFull = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = context.watch<AuthProvider>().currentUser;
    final interaction = context.watch<InteractionProvider>();

    final isOwner = currentUser?.activeProfileId != null &&
        (widget.profile.id == currentUser!.activeProfileId ||
            widget.profile.profileId == currentUser.activeProfileId);

    final isAuthorized = isOwner ||
        interaction.isAuthorizedForFullProfile(widget.profile.id) ||
        widget.profile.interestStatus == 'accepted';

    // Active profile: use loaded full profile if authorized, otherwise public profile DTO
    final p = (isAuthorized && _fullProfile != null) ? _fullProfile! : widget.profile;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Stack(
        children: [
          DraggableScrollableSheet(
            initialChildSize: 0.88,
            minChildSize: 0.5,
            maxChildSize: 0.96,
            expand: false,
            builder: (context, scrollController) {
              return CustomScrollView(
                controller: scrollController,
                slivers: [
                  // Top Drag Handle & Back Bar
                  SliverToBoxAdapter(
                    child: Center(
                      child: Container(
                        margin: const EdgeInsets.only(top: 12, bottom: 8),
                        width: 44,
                        height: 5,
                        decoration: BoxDecoration(
                          color: const Color(0xFFCBD5E1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),

                  // Image Header & Identity Banner
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Large Photograph with badges (PUBLIC)
                          Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: AspectRatio(
                                  aspectRatio: 1.1,
                                  child: AppImageHelper.buildProfileImage(
                                    url: p.profilePhotoUrl,
                                    fullName: p.fullName,
                                    gender: p.gender,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),

                              // Compatibility Pill
                              Positioned(
                                top: 14,
                                left: 14,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.65),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: AppTheme.gold, width: 1.2),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.stars_rounded, color: AppTheme.gold, size: 16),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${p.compatibilityScore}% Compatibility',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              // Close / Dismiss button
                              Positioned(
                                top: 14,
                                right: 14,
                                child: InkWell(
                                  onTap: () => Navigator.pop(context),
                                  borderRadius: BorderRadius.circular(20),
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(alpha: 0.55),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          // Name, Age & Verified Header (PUBLIC)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            '${p.fullName}, ${p.age}',
                                            style: const TextStyle(
                                              color: AppTheme.textPrimary,
                                              fontSize: 22,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        ),
                                        if (p.isVerified) ...[
                                          const SizedBox(width: 6),
                                          const Icon(Icons.verified_rounded, color: Color(0xFF38BDF8), size: 20),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Profile ID: ${p.profileId} • Created for ${isAuthorized ? p.createdFor : "Self"}',
                                      style: const TextStyle(
                                        color: AppTheme.textSecondary,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Save Bookmark Icon
                              IconButton(
                                icon: Icon(
                                  p.isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                                  color: p.isSaved ? AppTheme.gold : AppTheme.textSecondary,
                                  size: 28,
                                ),
                                onPressed: widget.onToggleSave,
                              ),
                            ],
                          ),

                          const Divider(height: 24, color: AppTheme.dividerColor),
                        ],
                      ),
                    ),
                  ),

                  // Comprehensive Matrimonial Sections
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1. Privacy Protection Notice Banner (When details are restricted)
                          if (!isAuthorized) _buildPrivacyBanner(),
                          if (_isLoadingFull)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8),
                              child: Center(
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.burgundy),
                                ),
                              ),
                            ),

                          // 2. Section 1: About Me / Bio (PUBLIC)
                          if (p.bio.isNotEmpty)
                            _buildSectionCard(
                              icon: Icons.person_pin_rounded,
                              title: 'About',
                              hasHiddenFields: false,
                              children: [
                                Text(
                                  p.bio,
                                  style: const TextStyle(
                                    color: AppTheme.textPrimary,
                                    fontSize: 14,
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),

                          // 3. Section 2: Personal Details (Public + Private)
                          _buildSectionCard(
                            icon: Icons.badge_outlined,
                            title: 'Personal Details',
                            hasHiddenFields: !isAuthorized,
                            children: [
                              _buildDetailRow('Gender', p.gender, isPrivate: false, isAuthorized: isAuthorized),
                              _buildDetailRow('Age', '${p.age} years', isPrivate: false, isAuthorized: isAuthorized),
                              _buildDetailRow('Mother Tongue', p.motherTongue, isPrivate: false, isAuthorized: isAuthorized),
                              _buildDetailRow('Date of Birth', isAuthorized ? '${p.dateOfBirth.day}/${p.dateOfBirth.month}/${p.dateOfBirth.year}' : null, isPrivate: true, isAuthorized: isAuthorized),
                              _buildDetailRow('Marital Status', isAuthorized ? p.maritalStatus : null, isPrivate: true, isAuthorized: isAuthorized),
                              _buildDetailRow('Height', isAuthorized ? p.height : null, isPrivate: true, isAuthorized: isAuthorized),
                              _buildDetailRow('Religion', isAuthorized ? p.religion : null, isPrivate: true, isAuthorized: isAuthorized),
                              _buildDetailRow('Community / Caste', isAuthorized ? p.community : null, isPrivate: true, isAuthorized: isAuthorized),
                              _buildDetailRow('Dietary Preference', isAuthorized ? p.dietaryPreference : null, isPrivate: true, isAuthorized: isAuthorized),
                            ],
                          ),

                          // 4. Section 3: Location & Residence (Moved immediately below Personal Details)
                          _buildSectionCard(
                            icon: Icons.location_on_outlined,
                            title: 'Location & Residence',
                            hasHiddenFields: !isAuthorized,
                            children: [
                              _buildDetailRow('District / City', p.city, isPrivate: false, isAuthorized: isAuthorized),
                              _buildDetailRow('Locality', isAuthorized ? p.locality : null, isPrivate: true, isAuthorized: isAuthorized),
                              _buildDetailRow('State', isAuthorized ? p.state : null, isPrivate: true, isAuthorized: isAuthorized),
                              _buildDetailRow('Country', isAuthorized ? p.country : null, isPrivate: true, isAuthorized: isAuthorized),
                            ],
                          ),

                          // 5. Section 4: Education & Career (Public + Private)
                          _buildSectionCard(
                            icon: Icons.school_outlined,
                            title: 'Education & Career',
                            hasHiddenFields: !isAuthorized,
                            children: [
                              _buildDetailRow('Highest Education', p.highestEducation, isPrivate: false, isAuthorized: isAuthorized),
                              _buildDetailRow('Occupation', p.occupation, isPrivate: false, isAuthorized: isAuthorized),
                              _buildDetailRow('Company / Workplace', isAuthorized ? p.company : null, isPrivate: true, isAuthorized: isAuthorized),
                              _buildDetailRow('Annual Income', isAuthorized ? p.annualIncome : null, isPrivate: true, isAuthorized: isAuthorized),
                            ],
                          ),

                          // 6. Section 5: Family Details (ALL PRIVATE)
                          _buildSectionCard(
                            icon: Icons.family_restroom_rounded,
                            title: 'Family Background',
                            hasHiddenFields: !isAuthorized,
                            children: [
                              _buildDetailRow('Family Type', isAuthorized ? p.familyType : null, isPrivate: true, isAuthorized: isAuthorized),
                              _buildDetailRow('Family Values', isAuthorized ? p.familyValues : null, isPrivate: true, isAuthorized: isAuthorized),
                              _buildDetailRow('Background', isAuthorized ? p.familyBackground : null, isPrivate: true, isAuthorized: isAuthorized),
                            ],
                          ),

                          // 7. Section 6: Partner Preferences (PRIVATE)
                          _buildSectionCard(
                            icon: Icons.favorite_border_rounded,
                            title: 'Partner Preferences',
                            hasHiddenFields: !isAuthorized,
                            children: [
                              _buildDetailRow('Preferred Age', isAuthorized ? '${p.prefAgeMin} to ${p.prefAgeMax} years' : null, isPrivate: true, isAuthorized: isAuthorized),
                              _buildDetailRow('Marital Status', isAuthorized ? p.prefMaritalStatus : null, isPrivate: true, isAuthorized: isAuthorized),
                              _buildDetailRow('Preferred Location', isAuthorized ? p.prefLocation : null, isPrivate: true, isAuthorized: isAuthorized),
                              _buildDetailRow('Education Preference', isAuthorized ? p.prefEducation : null, isPrivate: true, isAuthorized: isAuthorized),
                              _buildDetailRow('Occupation Preference', isAuthorized ? p.prefOccupation : null, isPrivate: true, isAuthorized: isAuthorized),
                              _buildDetailRow('Annual Income', isAuthorized ? p.prefIncome : null, isPrivate: true, isAuthorized: isAuthorized),
                              _buildDetailRow('Expectations', isAuthorized ? p.partnerExpectations : null, isPrivate: true, isAuthorized: isAuthorized),
                            ],
                          ),

                          // 8. Section 7: Contact Information (PRIVATE - Unlocked when authorized)
                          if (isAuthorized)
                            _buildSectionCard(
                              icon: Icons.contact_phone_outlined,
                              title: 'Contact Details',
                              hasHiddenFields: false,
                              children: [
                                _buildDetailRow('Mobile Number', '${p.countryCode} ${p.phone}', isPrivate: false, isAuthorized: isAuthorized),
                                if (p.address.isNotEmpty)
                                  _buildDetailRow('Full Address', p.address, isPrivate: false, isAuthorized: isAuthorized),
                              ],
                            ),

                          const SizedBox(height: 90), // Spacing for bottom action bar
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),

          // Bottom Action Bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: isOwner
                    ? OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.pushNamed(context, '/my-profile');
                        },
                        icon: const Icon(Icons.edit_rounded),
                        label: const Text('Edit My Profile'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.burgundy,
                          side: const BorderSide(color: AppTheme.burgundy),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      )
                    : ElevatedButton.icon(
                        onPressed: (p.isInterestSent || isAuthorized)
                            ? null
                            : () {
                                widget.onExpressInterest();
                                setState(() {
                                  p.isInterestSent = true;
                                });
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isAuthorized
                              ? const Color(0xFF0D9488)
                              : p.isInterestSent
                                  ? AppTheme.textMuted
                                  : AppTheme.burgundy,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        icon: Icon(
                          isAuthorized
                              ? Icons.verified_user_rounded
                              : p.isInterestSent
                                  ? Icons.favorite_rounded
                                  : Icons.favorite_border_rounded,
                          size: 20,
                        ),
                        label: Text(
                          isAuthorized
                              ? 'Mutual Match (Full Details Unlocked)'
                              : p.isInterestSent
                                  ? 'Interest Sent (Pending Acceptance)'
                                  : 'Express Interest to Connect',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacyBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.roseLight.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.rose.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: AppTheme.burgundy,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.shield_outlined, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Private Profile Details Protected',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.burgundy,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Contact, family background, and personal details are restricted. Express interest to connect — full details unlock once your request is accepted.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required IconData icon,
    required String title,
    required List<Widget> children,
    bool hasHiddenFields = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFBF9F6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppTheme.burgundy, size: 19),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: AppTheme.burgundy,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...children,
          if (hasHiddenFields) ...[
            const SizedBox(height: 6),
            const Row(
              children: [
                Icon(Icons.lock_outline_rounded, size: 13, color: AppTheme.textMuted),
                SizedBox(width: 6),
                Text(
                  'Hidden – Send Request to View',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textMuted,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String? value, {
    bool isPrivate = false,
    bool isAuthorized = true,
  }) {
    // Hide the field completely if it's restricted and not authorized
    final isHidden = isPrivate && !isAuthorized;
    if (isHidden) {
      return const SizedBox.shrink();
    }

    // Hide the field if it has no value (null, empty, or 'Not Specified')
    if (value == null || value.trim().isEmpty || value.trim().toLowerCase() == 'not specified') {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
