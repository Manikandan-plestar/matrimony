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
import '../utils/app_image_helper.dart';
import '../widgets/common/country_code_picker_widget.dart';
import '../widgets/common/searchable_custom_dropdown.dart';
import '../widgets/modals/profile_image_crop_modal.dart';

/// Dedicated Screen for Editing Phase 1: Personal Details & Identity ONLY.
/// Does NOT display or overwrite Phase 2 or Phase 3 data.
class EditPersonalDetailsScreen extends StatefulWidget {
  const EditPersonalDetailsScreen({super.key});

  @override
  State<EditPersonalDetailsScreen> createState() => _EditPersonalDetailsScreenState();
}

class _EditPersonalDetailsScreenState extends State<EditPersonalDetailsScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _communityController;

  late CountryCodeModel _selectedCountry;
  String _editingPhotoUrl = '';
  String _selectedGender = 'Groom';
  DateTime? _selectedDob;
  int _calculatedAge = 28;
  String _selectedMaritalStatus = 'Never Married';
  String _selectedHeight = '5\' 10" (178 cm)';
  String _selectedDietaryPreference = 'Vegetarian';

  bool _isFetchingAddress = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final p = context.read<ProfileProvider>().myProfile;
    _initFromProfile(p);
  }

  void _initFromProfile(MatrimonyProfileModel? p) {
    _nameController = TextEditingController(text: p?.fullName ?? '');
    _phoneController = TextEditingController(text: p?.phone ?? '');
    _addressController = TextEditingController(text: p?.address ?? '');
    _communityController = TextEditingController(text: p?.community ?? '');
    _selectedCountry = CountryCodeData.findByCode(p?.countryCode ?? '+91');
    _editingPhotoUrl = p?.profilePhotoUrl ?? '';
    _selectedGender = p?.gender.isNotEmpty == true ? p!.gender : 'Groom';
    _selectedDob = p?.dateOfBirth ?? DateTime(1997, 1, 1);
    _calculatedAge = p?.age ?? 28;
    _selectedMaritalStatus = p?.maritalStatus.isNotEmpty == true ? p!.maritalStatus : 'Never Married';
    _selectedHeight = p?.height.isNotEmpty == true ? p!.height : '5\' 10" (178 cm)';
    _selectedDietaryPreference = p?.dietaryPreference.isNotEmpty == true ? p!.dietaryPreference : 'Vegetarian';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _communityController.dispose();
    super.dispose();
  }

  Widget _buildProfilePhoto() {
    return AppImageHelper.buildProfileImage(
      url: _editingPhotoUrl,
      fullName: _nameController.text.trim().isNotEmpty ? _nameController.text.trim() : 'M',
      width: 120,
      height: 120,
      fit: BoxFit.cover,
    );
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
                'Select Profile Photo Source',
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
            content: Text('Could not fetch GPS address. Please verify location permissions.'),
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

  Future<void> _selectDateOfBirth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDob ?? DateTime(1997, 1, 1),
      firstDate: DateTime(1960),
      lastDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.burgundy,
              onPrimary: Colors.white,
              onSurface: AppTheme.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && mounted) {
      setState(() {
        _selectedDob = picked;
        final now = DateTime.now();
        int age = now.year - picked.year;
        if (now.month < picked.month || (now.month == picked.month && now.day < picked.day)) {
          age--;
        }
        _calculatedAge = age;
      });
    }
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final Map<String, dynamic> personalData = {
      'fullName': _nameController.text.trim(),
      'gender': _selectedGender,
      'dateOfBirth': _selectedDob?.toIso8601String().substring(0, 10) ?? '1997-01-01',
      'age': _calculatedAge,
      'maritalStatus': _selectedMaritalStatus,
      'height': _selectedHeight,
      'community': _communityController.text.trim(),
      'dietaryPreference': _selectedDietaryPreference,
      'profilePhotoUrl': _editingPhotoUrl,
      'countryCode': _selectedCountry.phoneCode,
      'phone': _phoneController.text.trim(),
      'address': _addressController.text.trim(),
    };

    final result = await context.read<ProfileProvider>().updateProfileSection(personalData);

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppTheme.burgundy,
          content: Text('Personal details updated successfully!'),
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppTheme.error,
          content: Text(result.message),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Edit Personal Details'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Photo Avatar Card
              Center(
                child: Column(
                  children: [
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: SizedBox(
                            width: 120,
                            height: 120,
                            child: _buildProfilePhoto(),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: InkWell(
                            onTap: _pickAndCropPhoto,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: AppTheme.burgundy,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 18),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: _pickAndCropPhoto,
                      icon: const Icon(Icons.edit_rounded, size: 16),
                      label: const Text('Change Photograph'),
                      style: TextButton.styleFrom(foregroundColor: AppTheme.burgundy),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),
              _buildSectionHeader('Personal Identity'),

              // Full Name
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Candidate Full Name *',
                  hintText: 'e.g. Subramanian Venkatesh',
                  prefixIcon: Icon(Icons.person_outline_rounded),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Please enter full name' : null,
              ),
              const SizedBox(height: 14),

              // Gender Selector
              InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Candidate Gender *',
                  prefixIcon: Icon(Icons.wc_rounded),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        label: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.man_rounded, size: 18),
                            SizedBox(width: 4),
                            Text('Groom'),
                          ],
                        ),
                        selected: _selectedGender == 'Groom',
                        selectedColor: AppTheme.burgundy,
                        labelStyle: TextStyle(
                          color: _selectedGender == 'Groom' ? Colors.white : AppTheme.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                        onSelected: (sel) {
                          if (sel) setState(() => _selectedGender = 'Groom');
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ChoiceChip(
                        label: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.woman_rounded, size: 18),
                            SizedBox(width: 4),
                            Text('Bride'),
                          ],
                        ),
                        selected: _selectedGender == 'Bride',
                        selectedColor: AppTheme.rose,
                        labelStyle: TextStyle(
                          color: _selectedGender == 'Bride' ? Colors.white : AppTheme.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                        onSelected: (sel) {
                          if (sel) setState(() => _selectedGender = 'Bride');
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Date of Birth & Age
              InkWell(
                onTap: _selectDateOfBirth,
                borderRadius: BorderRadius.circular(14),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Date of Birth *',
                    prefixIcon: Icon(Icons.cake_outlined),
                    suffixIcon: Icon(Icons.calendar_month_rounded),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _selectedDob != null
                            ? '${_selectedDob!.day}/${_selectedDob!.month}/${_selectedDob!.year}'
                            : 'Select Date of Birth',
                        style: const TextStyle(fontSize: 15),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.roseLight,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$_calculatedAge Years',
                          style: const TextStyle(
                            color: AppTheme.burgundy,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Marital Status
              SearchableCustomDropdown(
                label: 'Marital Status',
                currentValue: _selectedMaritalStatus,
                options: AppConstants.maritalStatusOptions,
                prefixIcon: Icons.favorite_border_rounded,
                onSelected: (val) => setState(() => _selectedMaritalStatus = val),
              ),
              const SizedBox(height: 14),

              // Height
              SearchableCustomDropdown(
                label: 'Height',
                currentValue: _selectedHeight,
                options: AppConstants.heightOptions,
                prefixIcon: Icons.height_rounded,
                onSelected: (val) => setState(() => _selectedHeight = val),
              ),
              const SizedBox(height: 14),

              // Community
              TextFormField(
                controller: _communityController,
                decoration: const InputDecoration(
                  labelText: 'Community / Sub-Caste (Optional)',
                  hintText: 'e.g. Iyer, Mudaliar, Nair, Brahmin',
                  prefixIcon: Icon(Icons.account_balance_outlined),
                ),
              ),
              const SizedBox(height: 14),

              // Dietary Preference
              SearchableCustomDropdown(
                label: 'Dietary Preference',
                currentValue: _selectedDietaryPreference,
                options: const ['Vegetarian', 'Non-Vegetarian', 'Eggetarian', 'Vegan'],
                prefixIcon: Icons.restaurant_outlined,
                onSelected: (val) => setState(() => _selectedDietaryPreference = val),
              ),
              const SizedBox(height: 22),

              _buildSectionHeader('Contact & Verification'),

              // Phone with Country Calling Code
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
                        if (v.trim().replaceAll(RegExp(r'\D'), '').length < 7) {
                          return 'Please enter a valid mobile number';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Address with GPS Autofill
              TextFormField(
                controller: _addressController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Residential Address',
                  hintText: 'Street address, apartment, locality...',
                  prefixIcon: const Icon(Icons.home_outlined),
                  suffixIcon: IconButton(
                    tooltip: 'Autofill with GPS',
                    icon: _isFetchingAddress
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.my_location_rounded, color: AppTheme.burgundy),
                    onPressed: _fetchGPSAddress,
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // Save Action Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _handleSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.burgundy,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.2),
                        )
                      : const Text(
                          'Save Personal Details',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
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
