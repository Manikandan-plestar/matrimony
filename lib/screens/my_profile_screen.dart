import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/profile_provider.dart';
import '../utils/app_image_helper.dart';

/// My Matrimony Profile Screen
/// Read-only presentation organized strictly according to the 3-phase registration structure.
class MyProfileScreen extends StatefulWidget {
  const MyProfileScreen({super.key});

  @override
  State<MyProfileScreen> createState() => _MyProfileScreenState();
}

class _MyProfileScreenState extends State<MyProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProfileProvider>().fetchMyProfile();
    });
  }

  Widget _buildProfilePhoto(String url) {
    return AppImageHelper.buildProfileImage(
      url: url,
      fullName: '',
      fit: BoxFit.cover,
    );
  }

  @override
  Widget build(BuildContext context) {
    final profileProvider = context.watch<ProfileProvider>();
    final p = profileProvider.myProfile;

    if (p == null) {
      return Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(title: const Text('My Matrimony Profile')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.person_outline, size: 72, color: AppTheme.burgundy),
                const SizedBox(height: 16),
                const Text(
                  'No Matrimony Profile Yet',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Complete the 3-phase registration to publish your profile.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => Navigator.pushNamed(context, '/publish-wizard'),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Create Profile Now'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.burgundy,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('My Matrimony Profile'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Hero Card: Photograph & Quick Bio
            Container(
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
                        child: AspectRatio(
                          aspectRatio: 1.25,
                          child: _buildProfilePhoto(p.profilePhotoUrl),
                        ),
                      ),
                      Positioned(
                        top: 14,
                        left: 14,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.65),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'ID: ${p.profileId.isNotEmpty ? p.profileId : p.id}',
                            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 14,
                        right: 14,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: p.gender == 'Bride' ? AppTheme.rose : AppTheme.burgundy,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            p.gender,
                            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                p.fullName,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppTheme.goldLight,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${p.age} Yrs',
                                style: const TextStyle(
                                  color: Color(0xFF854D0E),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${p.occupation} • ${p.city}, ${p.country}',
                          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                        ),
                        if (p.bio.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Text(
                            p.bio,
                            style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary, height: 1.4),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // PHASE 1: Personal Details & Identity
            _buildPhaseCard(
              phaseNumber: 1,
              title: 'Personal Details & Identity',
              icon: Icons.person_outline_rounded,
              items: [
                _buildInfoRow('Full Name', p.fullName),
                _buildInfoRow('Gender', p.gender),
                _buildInfoRow('Date of Birth', '${p.dateOfBirth.day}/${p.dateOfBirth.month}/${p.dateOfBirth.year} (${p.age} yrs)'),
                _buildInfoRow('Marital Status', p.maritalStatus),
                _buildInfoRow('Height', p.height),
                _buildInfoRow('Community / Caste', p.community.isNotEmpty ? p.community : 'Not Specified'),
                _buildInfoRow('Dietary Preference', p.dietaryPreference),
                _buildInfoRow('Mobile Number', '${p.countryCode} ${p.phone}'),
                _buildInfoRow('Residential Address', p.address.isNotEmpty ? p.address : 'Not Specified'),
              ],
            ),

            const SizedBox(height: 16),

            // PHASE 2: Background, Career & Family
            _buildPhaseCard(
              phaseNumber: 2,
              title: 'Background, Career & Family',
              icon: Icons.work_outline_rounded,
              items: [
                _buildInfoRow('Mother Tongue', p.motherTongue),
                _buildInfoRow('Religion / Faith', p.religion.isNotEmpty ? p.religion : 'Not Specified'),
                _buildInfoRow('Highest Education', p.highestEducation),
                _buildInfoRow('Occupation', p.occupation),
                _buildInfoRow('Company / Organization', p.company.isNotEmpty ? p.company : 'Not Specified'),
                _buildInfoRow('Annual Income', p.annualIncome),
                _buildInfoRow('Family Type', p.familyType),
                _buildInfoRow('Family Values', p.familyValues),
                _buildInfoRow('Family Background', p.familyBackground.isNotEmpty ? p.familyBackground : 'Not Specified'),
              ],
            ),

            const SizedBox(height: 16),

            // PHASE 3: Location, Residence & Partner Preferences
            _buildPhaseCard(
              phaseNumber: 3,
              title: 'Location & Partner Preferences',
              icon: Icons.favorite_border_rounded,
              items: [
                _buildInfoRow('Country of Residence', p.country),
                _buildInfoRow('State / Region', p.state),
                _buildInfoRow('City / Town', p.city),
                _buildInfoRow('Locality / Area', p.locality.isNotEmpty ? p.locality : 'Not Specified'),
                _buildInfoRow('Preferred Age Range', '${p.prefAgeMin} - ${p.prefAgeMax} Years'),
                _buildInfoRow('Preferred Marital Status', p.prefMaritalStatus.isNotEmpty ? p.prefMaritalStatus : 'Never Married'),
                _buildInfoRow('Preferred Location', p.prefLocation.isNotEmpty ? p.prefLocation : 'Any Worldwide Location'),
                _buildInfoRow('Preferred Education', p.prefEducation.isNotEmpty ? p.prefEducation : 'Any Education'),
                _buildInfoRow('Preferred Occupation', p.prefOccupation.isNotEmpty ? p.prefOccupation : 'Any Working Professional'),
                _buildInfoRow('Preferred Income', p.prefIncome.isNotEmpty ? p.prefIncome : 'Any Income Range'),
                _buildInfoRow('Preferred Diet', p.prefDietaryPreference.isNotEmpty ? p.prefDietaryPreference : 'Does Not Matter'),
                _buildInfoRow('Partner Expectations', p.partnerExpectations.isNotEmpty ? p.partnerExpectations : 'Not Specified'),
              ],
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildPhaseCard({
    required int phaseNumber,
    required String title,
    required IconData icon,
    required List<Widget> items,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Phase Header Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: AppTheme.cream,
              borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
              border: Border(bottom: BorderSide(color: Color(0xFFF1EAE0))),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: AppTheme.roseLight,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 16, color: AppTheme.burgundy),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Phase $phaseNumber: $title',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.burgundy,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              children: items,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value.isNotEmpty ? value : '—',
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
