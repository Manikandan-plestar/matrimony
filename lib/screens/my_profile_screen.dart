import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../config/constants.dart';
import '../config/theme.dart';
import '../models/matrimony_profile_model.dart';
import '../providers/profile_provider.dart';
import '../services/country_code_data.dart';
import '../services/device_image_picker_service.dart';
import '../services/location_service.dart';
import '../widgets/common/country_code_picker_widget.dart';
import '../widgets/common/searchable_custom_dropdown.dart';
import '../widgets/modals/profile_image_crop_modal.dart';

/// User's Own Matrimony Profile Screen (Image-First with Inline Edit Mode)
class MyProfileScreen extends StatefulWidget {
  const MyProfileScreen({super.key});

  @override
  State<MyProfileScreen> createState() => _MyProfileScreenState();
}

class _MyProfileScreenState extends State<MyProfileScreen> {
  bool _isEditing = false;
  bool _showAllDetails = false;

  // Controllers for edit mode
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _companyController;
  late TextEditingController _cityController;
  late TextEditingController _bioController;
  late TextEditingController _communityController;
  late TextEditingController _familyBgController;

  late CountryCodeModel _selectedCountry;
  String _editingPhotoUrl = '';
  bool _isFetchingAddress = false;
  String _editingHeight = '';
  String _editingMotherTongue = '';
  String _editingReligion = '';
  String _editingHighestEducation = '';
  String _editingOccupation = '';

  @override
  void initState() {
    super.initState();
    final p = context.read<ProfileProvider>().myProfile;
    _initControllers(p);
  }

  void _initControllers(MatrimonyProfileModel? p) {
    _nameController = TextEditingController(text: p?.fullName ?? '');
    _phoneController = TextEditingController(text: p?.phone ?? '');
    _addressController = TextEditingController(text: p?.address ?? '');
    _companyController = TextEditingController(text: p?.company ?? '');
    _cityController = TextEditingController(text: p?.city ?? '');
    _bioController = TextEditingController(text: p?.bio ?? '');
    _communityController = TextEditingController(text: p?.community ?? '');
    _familyBgController = TextEditingController(text: p?.familyBackground ?? '');
    _selectedCountry = CountryCodeData.findByCode(p?.countryCode ?? '+91');
    _editingPhotoUrl = p?.profilePhotoUrl ?? '';
    _editingHeight = p?.height ?? '';
    _editingMotherTongue = p?.motherTongue ?? '';
    _editingReligion = p?.religion ?? '';
    _editingHighestEducation = p?.highestEducation ?? '';
    _editingOccupation = p?.occupation ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _companyController.dispose();
    _cityController.dispose();
    _bioController.dispose();
    _communityController.dispose();
    _familyBgController.dispose();
    super.dispose();
  }

  Widget _buildProfilePhoto(String url) {
    final isNetwork = url.startsWith('http://') || url.startsWith('https://');
    if (isNetwork) {
      return Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          color: const Color(0xFFF1EAE0),
          child: const Center(child: Icon(Icons.person, size: 64, color: AppTheme.textMuted)),
        ),
      );
    } else {
      return Image.file(
        File(url),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          color: const Color(0xFFF1EAE0),
          child: const Center(child: Icon(Icons.person, size: 64, color: AppTheme.textMuted)),
        ),
      );
    }
  }

  Future<void> _pickAndCropPhoto() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select Profile Image Source',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.burgundy),
              ),
              const SizedBox(height: 14),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: AppTheme.roseLight,
                  child: Icon(Icons.photo_library_rounded, color: AppTheme.burgundy),
                ),
                title: const Text('Choose from Gallery', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Select a high-resolution photo from device storage'),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: AppTheme.roseLight,
                  child: Icon(Icons.camera_alt_rounded, color: AppTheme.burgundy),
                ),
                title: const Text('Take a Photo', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Use camera to take a new portrait photograph'),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
            ],
          ),
        ),
      ),
    );

    if (source == null) return;

    final pickedPath = await DeviceImagePickerService.pickSingleImage(source: source);
    if (pickedPath == null || !mounted) return;

    final croppedPath = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => ProfileImageCropModal(imagePath: pickedPath),
      ),
    );

    if (croppedPath != null && mounted) {
      setState(() {
        _editingPhotoUrl = croppedPath;
      });
      // If currently in view mode, persist directly to user profile
      if (!_isEditing) {
        final currentP = context.read<ProfileProvider>().myProfile;
        if (currentP != null) {
          context.read<ProfileProvider>().updateMyProfile(currentP.copyWith(profilePhotoUrl: croppedPath));
        }
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppTheme.burgundy,
          content: Text('Profile photograph successfully updated and cropped!'),
        ),
      );
    }
  }

  Future<void> _fetchGPSAddress() async {
    if (_isFetchingAddress) return;
    setState(() => _isFetchingAddress = true);

    try {
      final locationService = context.read<LocationService>();
      final location = await locationService.fetchCurrentLocation();

      if (location != null && mounted) {
        setState(() {
          _addressController.text = location.formattedAddress;
          if (_cityController.text.trim().isEmpty && location.city.isNotEmpty) {
            _cityController.text = location.city;
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppTheme.burgundy,
            content: Text('Address fetched: ${location.city}, ${location.state}'),
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not fetch GPS address. Please check device location settings.'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Location error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isFetchingAddress = false);
      }
    }
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
                  'Create your profile now to connect with matches and be discovered.',
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
        title: Text(_isEditing ? 'Edit Profile' : 'My Matrimony Profile'),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit_rounded, color: AppTheme.burgundy),
              tooltip: 'Edit Profile',
              onPressed: () {
                _initControllers(p);
                setState(() => _isEditing = true);
              },
            )
          else
            TextButton(
              onPressed: () {
                setState(() => _isEditing = false);
              },
              child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: _isEditing ? _buildEditForm(p, profileProvider) : _buildImageFirstView(p),
      ),
    );
  }

  // 1. Image-First View (View Mode)
  Widget _buildImageFirstView(MatrimonyProfileModel p) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Dominant Profile Photograph
        Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: AspectRatio(
                aspectRatio: 1.05,
                child: _buildProfilePhoto(p.profilePhotoUrl),
              ),
            ),
            Positioned(
              top: 14,
              left: 14,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Profile ID: ${p.profileId}',
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            Positioned(
              bottom: 14,
              right: 14,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black.withValues(alpha: 0.7),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                icon: const Icon(Icons.camera_alt_outlined, size: 16),
                label: const Text('Change Photo', style: TextStyle(fontSize: 12)),
                onPressed: _pickAndCropPhoto,
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Quick Identity Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.verified_rounded, color: Color(0xFF38BDF8), size: 20),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${p.occupation} • ${p.city}, ${p.state}',
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Toggle Expand Full Matrimonial Information
        InkWell(
          onTap: () {
            setState(() => _showAllDetails = !_showAllDetails);
          },
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.roseLight,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.rose.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _showAllDetails ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                  color: AppTheme.burgundy,
                ),
                const SizedBox(width: 8),
                Text(
                  _showAllDetails ? 'Hide Full Details' : 'Reveal Full Matrimonial Details',
                  style: const TextStyle(color: AppTheme.burgundy, fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Expanded Details Sections
        if (_showAllDetails) ...[
          _buildInfoCard(
            title: 'Personal Info',
            rows: {
              'Gender': p.gender,
              'Marital Status': p.maritalStatus,
              'Height': p.height,
              'Mobile': p.phone.isNotEmpty ? '${p.countryCode} ${p.phone}' : 'Not specified',
              'Address': p.address.isNotEmpty ? p.address : '${p.city}, ${p.state}, ${p.country}',
              'Mother Tongue': p.motherTongue,
              'Religion & Caste': '${p.religion} - ${p.community}',
              'Diet': p.dietaryPreference,
            },
          ),
          _buildInfoCard(
            title: 'Education & Career',
            rows: {
              'Education': p.highestEducation,
              'Occupation': p.occupation,
              'Company': p.company,
              'Income': p.annualIncome,
            },
          ),
          _buildInfoCard(
            title: 'Family Details',
            rows: {
              'Family Type': p.familyType,
              'Background': p.familyBackground,
            },
          ),
          _buildInfoCard(
            title: 'Partner Preferences',
            rows: {
              'Preferred Age': '${p.prefAgeMin} to ${p.prefAgeMax} yrs',
              'Location': p.prefLocation,
              'Expectations': p.partnerExpectations,
            },
          ),
        ],

        const SizedBox(height: 20),
      ],
    );
  }

  // 2. Inline Edit Form
  Widget _buildEditForm(MatrimonyProfileModel p, ProfileProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Edit Your Matrimony Details',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.burgundy),
        ),
        const SizedBox(height: 16),

        // Profile Photo Avatar with Edit Badge
        Center(
          child: Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: SizedBox(
                  width: 100,
                  height: 120,
                  child: _buildProfilePhoto(_editingPhotoUrl),
                ),
              ),
              Positioned(
                bottom: 4,
                right: 4,
                child: InkWell(
                  onTap: _pickAndCropPhoto,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppTheme.burgundy,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(Icons.crop_rotate_rounded, color: Colors.white, size: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        TextFormField(
          controller: _nameController,
          decoration: const InputDecoration(labelText: 'Full Name', prefixIcon: Icon(Icons.person_outline_rounded)),
        ),
        const SizedBox(height: 14),

        // Country calling code + Mobile number row
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CountryCodePickerWidget(
              selectedCountry: _selectedCountry,
              onCountryChanged: (c) => setState(() => _selectedCountry = c),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Mobile Number',
                  hintText: '98765 43210',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // GPS-Based Address Field
        TextFormField(
          controller: _addressController,
          readOnly: true,
          maxLines: 2,
          minLines: 1,
          onTap: _fetchGPSAddress,
          decoration: InputDecoration(
            labelText: 'Current Address (GPS Verified)',
            hintText: 'Tap "Get Address" to fetch location via GPS',
            prefixIcon: const Icon(Icons.location_on_outlined),
            suffixIcon: _isFetchingAddress
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.burgundy),
                    ),
                  )
                : IconButton(
                    icon: const Icon(Icons.gps_fixed_rounded, color: AppTheme.burgundy),
                    tooltip: 'Fetch GPS Location',
                    onPressed: _fetchGPSAddress,
                  ),
          ),
        ),
        const SizedBox(height: 4),

        // Action Buttons: Left "Get Address" and Right "Clear"
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton.icon(
              onPressed: _isFetchingAddress ? null : _fetchGPSAddress,
              icon: _isFetchingAddress
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.burgundy),
                    )
                  : const Icon(Icons.my_location_rounded, size: 16),
              label: Text(
                _isFetchingAddress ? 'Locating...' : 'Get Address',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _addressController.clear();
                });
              },
              icon: const Icon(Icons.clear_rounded, size: 16, color: AppTheme.textMuted),
              label: const Text(
                'Clear',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Height with Searchable Dropdown & Custom Entry
        SearchableCustomDropdown(
          label: 'Height',
          currentValue: _editingHeight,
          options: AppConstants.heightOptions,
          prefixIcon: Icons.height_rounded,
          hint: 'Select or enter height (e.g. 5\' 7" or 170 cm)...',
          searchHint: 'Search height or type (e.g. 172 cm, 5\' 9")...',
          customNormalizer: AppConstants.normalizeHeight,
          onSelected: (val) {
            setState(() => _editingHeight = val);
          },
        ),
        const SizedBox(height: 14),

        // Highest Education with Searchable Dropdown & Custom Entry
        SearchableCustomDropdown(
          label: 'Highest Education',
          currentValue: _editingHighestEducation,
          options: AppConstants.educationOptions,
          prefixIcon: Icons.school_outlined,
          hint: 'Select or enter highest qualification...',
          searchHint: 'Search qualification or type custom...',
          onSelected: (val) {
            setState(() => _editingHighestEducation = val);
          },
        ),
        const SizedBox(height: 14),

        // Occupation / Profession with Searchable Dropdown & Custom Entry
        SearchableCustomDropdown(
          label: 'Occupation / Profession',
          currentValue: _editingOccupation,
          options: AppConstants.occupationOptions,
          prefixIcon: Icons.work_outline_rounded,
          hint: 'Select or enter profession...',
          searchHint: 'Search profession or type custom...',
          onSelected: (val) {
            setState(() => _editingOccupation = val);
          },
        ),
        const SizedBox(height: 14),

        // Mother Tongue with Searchable Dropdown & Custom Entry
        SearchableCustomDropdown(
          label: 'Mother Tongue',
          currentValue: _editingMotherTongue,
          options: AppConstants.motherTongueOptions,
          prefixIcon: Icons.language_rounded,
          hint: 'Select or enter mother tongue...',
          searchHint: 'Search language or type custom...',
          onSelected: (val) {
            setState(() => _editingMotherTongue = val);
          },
        ),
        const SizedBox(height: 14),

        // Religion with Searchable Dropdown & Custom Entry (Optional)
        SearchableCustomDropdown(
          label: 'Religion',
          isRequired: false,
          currentValue: _editingReligion,
          options: AppConstants.religionOptions,
          prefixIcon: Icons.auto_awesome_rounded,
          hint: 'Select or enter faith (Optional)...',
          searchHint: 'Search faith or type custom...',
          onSelected: (val) {
            setState(() => _editingReligion = val);
          },
        ),
        const SizedBox(height: 14),

        TextFormField(
          controller: _companyController,
          decoration: const InputDecoration(labelText: 'Company / Workplace', prefixIcon: Icon(Icons.business_rounded)),
        ),
        const SizedBox(height: 12),

        TextFormField(
          controller: _cityController,
          decoration: const InputDecoration(labelText: 'City / District', prefixIcon: Icon(Icons.location_city_rounded)),
        ),
        const SizedBox(height: 12),

        TextFormField(
          controller: _communityController,
          decoration: const InputDecoration(labelText: 'Community / Caste', prefixIcon: Icon(Icons.groups_outlined)),
        ),
        const SizedBox(height: 12),

        TextFormField(
          controller: _familyBgController,
          maxLines: 2,
          decoration: const InputDecoration(labelText: 'Family Background'),
        ),
        const SizedBox(height: 12),

        TextFormField(
          controller: _bioController,
          maxLines: 3,
          decoration: const InputDecoration(labelText: 'Bio / About Yourself'),
        ),
        const SizedBox(height: 20),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              final updated = p.copyWith(
                fullName: _nameController.text.trim(),
                countryCode: _selectedCountry.phoneCode,
                phone: _phoneController.text.trim(),
                address: _addressController.text.trim(),
                profilePhotoUrl: _editingPhotoUrl,
                height: _editingHeight.isNotEmpty ? _editingHeight : p.height,
                highestEducation: _editingHighestEducation.isNotEmpty ? _editingHighestEducation : p.highestEducation,
                occupation: _editingOccupation.isNotEmpty ? _editingOccupation : p.occupation,
                motherTongue: _editingMotherTongue.isNotEmpty ? _editingMotherTongue : p.motherTongue,
                religion: _editingReligion.isNotEmpty ? _editingReligion : p.religion,
                company: _companyController.text.trim(),
                city: _cityController.text.trim(),
                community: _communityController.text.trim(),
                familyBackground: _familyBgController.text.trim(),
                bio: _bioController.text.trim(),
              );
              provider.updateMyProfile(updated);
              setState(() => _isEditing = false);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  backgroundColor: AppTheme.burgundy,
                  content: Text('Profile details updated successfully!'),
                ),
              );
            },
            child: const Text('Save Changes'),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard({required String title, required Map<String, String> rows}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.burgundy)),
          const SizedBox(height: 8),
          ...rows.entries.map((e) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 120,
                      child: Text(e.key, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                    ),
                    Expanded(
                      child: Text(
                        e.value.isEmpty ? 'Not specified' : e.value,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
