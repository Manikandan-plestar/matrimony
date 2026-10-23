import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../config/constants.dart';
import '../config/theme.dart';
import '../config/worldwide_locations.dart';
import '../providers/discovery_provider.dart';
import '../providers/profile_provider.dart';
import '../services/country_code_data.dart';
import '../services/device_image_picker_service.dart';
import '../services/location_service.dart';
import '../utils/app_image_helper.dart';
import '../widgets/common/country_code_picker_widget.dart';
import '../widgets/common/searchable_custom_dropdown.dart';
import '../widgets/common/searchable_location_picker.dart';
import '../widgets/modals/profile_image_crop_modal.dart';

/// Redesigned 3-Phase Matrimonial Profile Publishing & Registration Wizard
/// Supports Worldwide locations, 5-option dropdowns with manual-entry fallbacks,
/// and a modern 3-step progress indicator.
class PublishWizardScreen extends StatefulWidget {
  const PublishWizardScreen({super.key});

  @override
  State<PublishWizardScreen> createState() => _PublishWizardScreenState();
}

class _PublishWizardScreenState extends State<PublishWizardScreen> {
  final _formKey1 = GlobalKey<FormState>();
  final _formKey2 = GlobalKey<FormState>();
  final _formKey3 = GlobalKey<FormState>();

  // Text controllers for input fields
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _communityController;
  late TextEditingController _companyController;
  late TextEditingController _familyBgController;
  late TextEditingController _expectationsController;
  late TextEditingController _bioController;

  late CountryCodeModel _selectedCountry;
  bool _isFetchingAddress = false;

  @override
  void initState() {
    super.initState();
    final p = context.read<ProfileProvider>();
    _nameController = TextEditingController(text: p.draftFullName);
    _phoneController = TextEditingController(text: p.draftPhone);
    _addressController = TextEditingController(text: p.draftAddress);
    _communityController = TextEditingController(text: p.draftCommunity);
    _companyController = TextEditingController(text: p.draftCompany);
    _familyBgController = TextEditingController(text: p.draftFamilyBackground);
    _expectationsController = TextEditingController(text: p.draftPartnerExpectations);
    _bioController = TextEditingController(text: p.draftBio);
    _selectedCountry = CountryCodeData.findByCode(p.draftCountryCode);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _communityController.dispose();
    _companyController.dispose();
    _familyBgController.dispose();
    _expectationsController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  void _saveCurrentFieldsToProvider() {
    final p = context.read<ProfileProvider>();
    p.draftFullName = _nameController.text;
    p.draftPhone = _phoneController.text.trim();
    p.draftCountryCode = _selectedCountry.phoneCode;
    p.draftAddress = _addressController.text.trim();
    p.draftCommunity = _communityController.text;
    p.draftCompany = _companyController.text;
    p.draftFamilyBackground = _familyBgController.text;
    p.draftPartnerExpectations = _expectationsController.text;
    p.draftBio = _bioController.text;
  }

  Widget _buildImagePreviewWidget(String path, {double width = 70, double height = 70, double borderRadius = 12}) {
    return AppImageHelper.buildProfileImage(
      url: path,
      fullName: _nameController.text.trim().isNotEmpty ? _nameController.text.trim() : 'M',
      width: width,
      height: height,
      borderRadius: BorderRadius.circular(borderRadius),
    );
  }

  Future<void> _fetchGPSAddress(ProfileProvider p) async {
    if (_isFetchingAddress) return;
    setState(() => _isFetchingAddress = true);

    try {
      final locationService = context.read<LocationService>();
      final location = await locationService.fetchCurrentLocation();

      if (location != null && mounted) {
        setState(() {
          _addressController.text = location.formattedAddress;
          p.draftAddress = location.formattedAddress;
          if (location.city.isNotEmpty) {
            p.draftCity = location.city;
          }
          if (location.state.isNotEmpty) {
            p.draftState = location.state;
          }
          if (location.country.isNotEmpty) {
            p.draftCountry = location.country;
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
            content: Text('Could not fetch GPS address. Please ensure location service is enabled.'),
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

  Future<void> _handlePickAndCropImage(ProfileProvider p) async {
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
        p.draftPhotoUrl = croppedPath;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppTheme.burgundy,
          content: Text('Profile photograph successfully updated and cropped!'),
        ),
      );
    }
  }

  String? _validateCustomHeight(String? v) {
    if (v == null || v.trim().isEmpty) {
      return 'Please specify height (e.g. 5\' 7" or 170 cm)';
    }
    if (AppConstants.normalizeHeight(v) == null) {
      return 'Please enter a valid height (e.g. 5\' 8" or 173 cm)';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProfileProvider>();
    final currentPhase = provider.wizardCurrentPhase;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Register / Publish Profile'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () {
            _saveCurrentFieldsToProvider();
            Navigator.pop(context);
          },
        ),
      ),
      body: Column(
        children: [
          // 1. Connected Three-Phase Step Progress Indicator
          _buildStepProgressIndicator(currentPhase),

          // 2. Active Phase Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 280),
                child: currentPhase == 1
                    ? _buildPhase1(provider)
                    : currentPhase == 2
                        ? _buildPhase2(provider)
                        : _buildPhase3(provider),
              ),
            ),
          ),

          // 3. Bottom Navigation Controls (Back & Continue / Publish)
          _buildBottomActionButtons(provider, currentPhase),
        ],
      ),
    );
  }

  /// Modern Connected 3-Phase Step Progress Bar
  Widget _buildStepProgressIndicator(int currentPhase) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppTheme.dividerColor)),
      ),
      child: Row(
        children: [
          _buildStepItem(1, 'Personal', currentPhase),
          _buildStepConnector(1, currentPhase),
          _buildStepItem(2, 'Background', currentPhase),
          _buildStepConnector(2, currentPhase),
          _buildStepItem(3, 'Partner Preferences', currentPhase),
        ],
      ),
    );
  }

  Widget _buildStepItem(int stepNumber, String title, int currentPhase) {
    final isCompleted = stepNumber < currentPhase;
    final isActive = stepNumber == currentPhase;

    Color circleColor;
    Color borderColor;
    Color textColor;
    Widget child;

    if (isCompleted) {
      circleColor = AppTheme.burgundy;
      borderColor = AppTheme.burgundy;
      textColor = AppTheme.burgundy;
      child = const Icon(Icons.check_rounded, color: Colors.white, size: 16);
    } else if (isActive) {
      circleColor = AppTheme.roseLight;
      borderColor = AppTheme.burgundy;
      textColor = AppTheme.burgundy;
      child = Text(
        '$stepNumber',
        style: const TextStyle(
          color: AppTheme.burgundy,
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
      );
    } else {
      circleColor = const Color(0xFFF1F5F9);
      borderColor = const Color(0xFFCBD5E1);
      textColor = AppTheme.textMuted;
      child = Text(
        '$stepNumber',
        style: const TextStyle(
          color: AppTheme.textMuted,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
      );
    }

    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: circleColor,
              shape: BoxShape.circle,
              border: Border.all(color: borderColor, width: isActive ? 2 : 1),
            ),
            child: Center(child: child),
          ),
          const SizedBox(height: 5),
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
              color: textColor,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildStepConnector(int stepNumber, int currentPhase) {
    final isPassed = stepNumber < currentPhase;
    return Container(
      width: 24,
      height: 2,
      margin: const EdgeInsets.only(bottom: 16),
      color: isPassed ? AppTheme.burgundy : const Color(0xFFE2E8F0),
    );
  }

  // ==========================================
  // PHASE 1: Personal Details & Identity
  // ==========================================
  Widget _buildPhase1(ProfileProvider p) {
    return Form(
      key: _formKey1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('1. Personal Details & Identity'),

          // Candidate Full Name (Required)
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Candidate Full Name *',
              hintText: 'e.g. Subramanian Venkatesh',
              prefixIcon: Icon(Icons.person_outline_rounded),
            ),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Please enter candidate full name' : null,
          ),
          const SizedBox(height: 14),

          // Mobile Number with Country Calling Code Selector (Required)
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
                    labelText: 'Mobile Number *',
                    hintText: '98765 43210',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Please enter mobile number';
                    }
                    final clean = v.replaceAll(RegExp(r'[\s\-]'), '');
                    if (clean.length < 7 || clean.length > 15 || !RegExp(r'^[0-9]+$').hasMatch(clean)) {
                      return 'Enter a valid mobile number';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Gender Selection (Groom vs Bride)
          const Text('Gender *', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ChoiceChip(
                  label: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.male_rounded, size: 18),
                      SizedBox(width: 6),
                      Text('Groom'),
                    ],
                  ),
                  selected: p.draftGender == 'Groom',
                  selectedColor: AppTheme.roseLight,
                  onSelected: (val) {
                    if (val) setState(() => p.draftGender = 'Groom');
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ChoiceChip(
                  label: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.female_rounded, size: 18),
                      SizedBox(width: 6),
                      Text('Bride'),
                    ],
                  ),
                  selected: p.draftGender == 'Bride',
                  selectedColor: AppTheme.roseLight,
                  onSelected: (val) {
                    if (val) setState(() => p.draftGender = 'Bride');
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Date of Birth & Calculated Age Picker (Required)
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: const BorderSide(color: AppTheme.dividerColor),
            ),
            tileColor: const Color(0xFFFBF9F6),
            leading: const Icon(Icons.calendar_today_rounded, color: AppTheme.burgundy),
            title: Text(
              p.draftDateOfBirth == null
                  ? 'Select Date of Birth *'
                  : 'DOB: ${p.draftDateOfBirth!.day}/${p.draftDateOfBirth!.month}/${p.draftDateOfBirth!.year} (${p.draftAge} yrs)',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: p.draftDateOfBirth ?? DateTime(1997, 1, 1),
                firstDate: DateTime(1965),
                lastDate: DateTime(2006),
              );
              if (picked != null) {
                final calculatedAge = DateTime.now().year - picked.year;
                setState(() {
                  p.draftDateOfBirth = picked;
                  p.draftAge = calculatedAge;
                });
              }
            },
          ),
          const SizedBox(height: 14),

          // GPS-Based Address Field (Read-only + Action buttons below)
          TextFormField(
            controller: _addressController,
            readOnly: true,
            maxLines: 2,
            minLines: 1,
            onTap: () => _fetchGPSAddress(p),
            decoration: InputDecoration(
              labelText: 'Current Address (GPS Verified) *',
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
                      onPressed: () => _fetchGPSAddress(p),
                    ),
            ),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Please fetch or specify address' : null,
          ),
          const SizedBox(height: 4),

          // Action Buttons: Left "Get Address" and Right "Clear"
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton.icon(
                onPressed: _isFetchingAddress ? null : () => _fetchGPSAddress(p),
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
                    p.draftAddress = '';
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

          // Marital Status Dropdown (Required)
          DropdownButtonFormField<String>(
            value: p.draftMaritalStatus,
            decoration: const InputDecoration(
              labelText: 'Marital Status *',
              prefixIcon: Icon(Icons.favorite_border_rounded),
            ),
            items: AppConstants.maritalStatusOptions
                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                .toList(),
            onChanged: (val) {
              if (val != null) setState(() => p.draftMaritalStatus = val);
            },
          ),
          const SizedBox(height: 14),

          // Height with Searchable Dropdown & Custom Entry (Required)
          SearchableCustomDropdown(
            label: 'Height *',
            currentValue: p.draftHeight,
            options: AppConstants.heightOptions,
            prefixIcon: Icons.height_rounded,
            hint: 'Select or enter height (e.g. 5\' 7" or 170 cm)...',
            searchHint: 'Search height or type (e.g. 172 cm, 5\' 9")...',
            customValidator: _validateCustomHeight,
            customNormalizer: AppConstants.normalizeHeight,
            onSelected: (val) {
              setState(() => p.draftHeight = val);
            },
          ),
          const SizedBox(height: 18),

          // Profile Photograph Preview with Interactive Device Picker & Cropper
          _buildSectionTitle('Profile Photograph'),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFBF9F6),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.cardBorder),
            ),
            child: Row(
              children: [
                _buildImagePreviewWidget(
                  p.draftPhotoUrl,
                  width: 72,
                  height: 72,
                  borderRadius: 12,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Primary Candidate Photo',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Pinch, zoom & crop to portrait card ratio.',
                        style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                      ),
                      const SizedBox(height: 6),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.roseLight,
                          foregroundColor: AppTheme.burgundy,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        onPressed: () => _handlePickAndCropImage(p),
                        icon: const Icon(Icons.crop_rotate_rounded, size: 16),
                        label: const Text('Change & Crop Photo'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // PHASE 2: Background, Career & Family
  // ==========================================
  Widget _buildPhase2(ProfileProvider p) {
    return Form(
      key: _formKey2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('2. Cultural Background & Beliefs'),

          // Mother Tongue with Searchable Dropdown & Custom Entry (Required)
          SearchableCustomDropdown(
            label: 'Mother Tongue *',
            currentValue: p.draftMotherTongue,
            options: AppConstants.motherTongueOptions,
            prefixIcon: Icons.language_rounded,
            hint: 'Select or enter your native language...',
            searchHint: 'Search language or type custom (e.g. Tulu, French)...',
            onSelected: (val) {
              setState(() => p.draftMotherTongue = val);
            },
          ),
          const SizedBox(height: 14),

          // Religion with Searchable Dropdown & Custom Entry (Optional/Flexible)
          SearchableCustomDropdown(
            label: 'Religion',
            isRequired: false,
            currentValue: p.draftReligion,
            options: AppConstants.religionOptions,
            prefixIcon: Icons.auto_awesome_rounded,
            hint: 'Select or enter faith / worldview (Optional)...',
            searchHint: 'Search faith or type custom...',
            onSelected: (val) {
              setState(() => p.draftReligion = val);
            },
          ),
          const SizedBox(height: 14),

          // Community / Caste / Sub-caste (Optional)
          TextFormField(
            controller: _communityController,
            decoration: const InputDecoration(
              labelText: 'Community / Denomination / Caste (Optional)',
              hintText: 'e.g. Iyer, Catholic, Sunni, General',
              prefixIcon: Icon(Icons.people_alt_outlined),
            ),
          ),
          const SizedBox(height: 20),

          _buildSectionTitle('Education & Profession'),

          // Highest Education with Searchable Dropdown & Custom Entry (Required)
          SearchableCustomDropdown(
            label: 'Highest Education *',
            currentValue: p.draftHighestEducation,
            options: AppConstants.educationOptions,
            prefixIcon: Icons.school_outlined,
            hint: 'Select or enter highest qualification...',
            searchHint: 'Search qualification or type custom (e.g. B.Tech, MS)...',
            onSelected: (val) {
              setState(() => p.draftHighestEducation = val);
            },
          ),
          const SizedBox(height: 14),

          // Occupation / Profession with Searchable Dropdown & Custom Entry (Required)
          SearchableCustomDropdown(
            label: 'Occupation / Profession *',
            currentValue: p.draftOccupation,
            options: AppConstants.occupationOptions,
            prefixIcon: Icons.work_outline_rounded,
            hint: 'Select or enter profession...',
            searchHint: 'Search profession or type custom...',
            onSelected: (val) {
              setState(() => p.draftOccupation = val);
            },
          ),
          const SizedBox(height: 14),

          // Company (Optional)
          TextFormField(
            controller: _companyController,
            decoration: const InputDecoration(
              labelText: 'Company / Workplace (Optional)',
              hintText: 'e.g. Microsoft, NHS, Private Practice',
              prefixIcon: Icon(Icons.business_outlined),
            ),
          ),
          const SizedBox(height: 14),

          // Annual Income (Required)
          DropdownButtonFormField<String>(
            value: p.draftAnnualIncome,
            decoration: const InputDecoration(
              labelText: 'Annual Income *',
              prefixIcon: Icon(Icons.payments_outlined),
            ),
            items: AppConstants.annualIncomeOptions
                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                .toList(),
            onChanged: (val) {
              if (val != null) setState(() => p.draftAnnualIncome = val);
            },
          ),
          const SizedBox(height: 20),

          _buildSectionTitle('Family Details'),

          // Family Type (Required)
          DropdownButtonFormField<String>(
            value: p.draftFamilyType,
            decoration: const InputDecoration(
              labelText: 'Family Type *',
              prefixIcon: Icon(Icons.family_restroom_rounded),
            ),
            items: AppConstants.familyTypeOptions
                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                .toList(),
            onChanged: (val) {
              if (val != null) setState(() => p.draftFamilyType = val);
            },
          ),
          const SizedBox(height: 14),

          // Family Background (Optional)
          TextFormField(
            controller: _familyBgController,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Family Background Summary (Optional)',
              hintText: 'e.g. Father: Architect, Mother: Teacher, 1 Brother married in London.',
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // PHASE 3: Partner Preferences
  // ==========================================
  Widget _buildPhase3(ProfileProvider p) {
    return Form(
      key: _formKey3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('3. Partner Preferences'),

          // Preferred Age Range
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.cardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Preferred Age Range',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.roseLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${p.draftPrefAgeMin} - ${p.draftPrefAgeMax} Yrs',
                        style: const TextStyle(
                          color: AppTheme.burgundy,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                RangeSlider(
                  values: RangeValues(p.draftPrefAgeMin.toDouble(), p.draftPrefAgeMax.toDouble()),
                  min: 18,
                  max: 60,
                  divisions: 42,
                  activeColor: AppTheme.burgundy,
                  inactiveColor: const Color(0xFFE2E8F0),
                  onChanged: (values) {
                    setState(() {
                      p.draftPrefAgeMin = values.start.round();
                      p.draftPrefAgeMax = values.end.round();
                    });
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Preferred Marital Status
          SearchableCustomDropdown(
            label: 'Preferred Marital Status',
            currentValue: p.draftPrefMaritalStatus,
            options: const [
              'Never Married',
              'Divorced',
              'Awaiting Divorce',
              'Widowed',
              'Does Not Matter',
            ],
            prefixIcon: Icons.favorite_border_rounded,
            onSelected: (val) => setState(() => p.draftPrefMaritalStatus = val),
          ),
          const SizedBox(height: 14),

          // Preferred Location (Country or Region)
          InkWell(
            onTap: () {
              SearchableLocationPicker.show(
                context: context,
                title: 'Select Preferred Country / Location',
                items: [
                  'Any Worldwide Location',
                  ...WorldwideLocations.countries.map((c) => c.name),
                ],
                selectedItem: p.draftPrefLocation,
                isCountryPicker: true,
                onSelected: (selected) {
                  setState(() => p.draftPrefLocation = selected);
                },
              );
            },
            borderRadius: BorderRadius.circular(14),
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Preferred Location / Country *',
                prefixIcon: Icon(Icons.travel_explore_rounded),
                suffixIcon: Icon(Icons.arrow_drop_down_rounded, size: 28),
              ),
              child: Text(
                p.draftPrefLocation.isNotEmpty ? p.draftPrefLocation : 'Any Worldwide Location',
                style: const TextStyle(fontSize: 15),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Preferred Education
          SearchableCustomDropdown(
            label: 'Preferred Education',
            currentValue: p.draftPrefEducation,
            options: const [
              'Any Education',
              'B.E / B.Tech / Engineering',
              'Masters / M.Tech / MBA',
              'Medicine / MBBS / MD',
              'Chartered Accountant / Finance',
              'Doctorate / Ph.D',
              'Bachelor Degree',
            ],
            prefixIcon: Icons.school_outlined,
            onSelected: (val) => setState(() => p.draftPrefEducation = val),
          ),
          const SizedBox(height: 14),

          // Preferred Occupation
          SearchableCustomDropdown(
            label: 'Preferred Occupation',
            currentValue: p.draftPrefOccupation,
            options: const [
              'Any Working Professional',
              'Software / IT Professional',
              'Doctor / Healthcare Professional',
              'Business Owner / Entrepreneur',
              'Government / Civil Services',
              'Banking / Finance Professional',
              'Educator / Professor',
            ],
            prefixIcon: Icons.work_outline_rounded,
            onSelected: (val) => setState(() => p.draftPrefOccupation = val),
          ),
          const SizedBox(height: 14),

          // Preferred Annual Income
          SearchableCustomDropdown(
            label: 'Preferred Annual Income',
            currentValue: p.draftPrefIncome,
            options: const [
              'Any Income Range',
              '₹5 - 10 Lakhs',
              '₹10 - 20 Lakhs',
              '₹20 - 35 Lakhs',
              '₹35 - 50 Lakhs',
              '₹50 Lakhs & Above',
            ],
            prefixIcon: Icons.currency_rupee_rounded,
            onSelected: (val) => setState(() => p.draftPrefIncome = val),
          ),
          const SizedBox(height: 14),

          // Preferred Dietary Preference
          SearchableCustomDropdown(
            label: 'Dietary Preference',
            currentValue: p.draftPrefDietaryPreference,
            options: const [
              'Does Not Matter',
              'Vegetarian',
              'Non-Vegetarian',
              'Eggetarian',
              'Vegan',
              'Jain Vegetarian',
            ],
            prefixIcon: Icons.restaurant_menu_rounded,
            hint: 'Select preferred diet (e.g. Vegetarian, Any)...',
            searchHint: 'Search dietary preference...',
            onSelected: (val) {
              setState(() => p.draftPrefDietaryPreference = val);
            },
          ),
          const SizedBox(height: 14),

          // Partner Expectations
          TextFormField(
            controller: _expectationsController,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Partner Expectations (Optional)',
              hintText: 'Describe values, lifestyle compatibility, personality traits...',
              prefixIcon: Icon(Icons.handshake_outlined),
            ),
          ),
          const SizedBox(height: 14),

          // Short Bio (Required)
          TextFormField(
            controller: _bioController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'About Candidate (Short Bio) *',
              hintText: 'Introduce personal interests, lifestyle, values, and outlook...',
              prefixIcon: Icon(Icons.info_outline_rounded),
            ),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Please write a short bio about yourself' : null,
          ),
          const SizedBox(height: 24),

          // Live Profile Preview Card
          _buildSectionTitle('Live Profile Preview'),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.cream,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppTheme.gold, width: 1.2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _buildImagePreviewWidget(p.draftPhotoUrl, width: 50, height: 50, borderRadius: 10),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _nameController.text.trim().isEmpty
                                ? 'Candidate Name'
                                : _nameController.text.trim(),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          Text(
                            '${p.draftAge} yrs • ${p.draftOccupation}',
                            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.verified_rounded, color: Color(0xFF38BDF8), size: 22),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'Location: ${p.draftCity.isNotEmpty ? p.draftCity : (p.draftCountry.isNotEmpty ? p.draftCountry : "Worldwide")} • ${p.draftHighestEducation}',
                  style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Bottom Navigation Controls
  Widget _buildBottomActionButtons(ProfileProvider p, int currentPhase) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppTheme.dividerColor)),
      ),
      child: Row(
        children: [
          // Back Button
          if (currentPhase > 1)
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  _saveCurrentFieldsToProvider();
                  p.setWizardPhase(currentPhase - 1);
                },
                child: const Text('Back'),
              ),
            ),
          if (currentPhase > 1) const SizedBox(width: 14),

          // Next or Publish Button
          Expanded(
            flex: currentPhase > 1 ? 2 : 1,
            child: ElevatedButton(
              onPressed: p.isPublishing
                  ? null
                  : () async {
                      _saveCurrentFieldsToProvider();

                      if (currentPhase == 1) {
                        if (_formKey1.currentState?.validate() ?? false) {
                          p.setWizardPhase(2);
                        }
                      } else if (currentPhase == 2) {
                        if (_formKey2.currentState?.validate() ?? false) {
                          p.setWizardPhase(3);
                        }
                      } else {
                        // Phase 3: Submit and Publish!
                        if (_formKey3.currentState?.validate() ?? false) {
                          final newProfile = await p.publishWizardProfile();
                          if (mounted) {
                            if (newProfile != null) {
                              // Insert into discovery feed
                              context.read<DiscoveryProvider>().addNewProfile(newProfile);

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  backgroundColor: AppTheme.burgundy,
                                  content: Text(
                                    'Profile ${newProfile.profileId} (${newProfile.fullName}) published successfully!',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ),
                              );
                              Navigator.pop(context);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  backgroundColor: Colors.red,
                                  content: Text('Failed to publish profile. Please verify your details and try again.'),
                                ),
                              );
                            }
                          }
                        }
                      }
                    },
              child: p.isPublishing
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : Text(currentPhase == 3
                      ? 'Publish Profile'
                      : 'Continue to Phase ${currentPhase + 1}'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          color: AppTheme.burgundy,
          fontSize: 16,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
