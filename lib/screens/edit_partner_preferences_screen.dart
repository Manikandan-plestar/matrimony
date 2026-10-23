import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../config/worldwide_locations.dart';
import '../models/matrimony_profile_model.dart';
import '../providers/profile_provider.dart';
import '../widgets/common/searchable_custom_dropdown.dart';
import '../widgets/common/searchable_location_picker.dart';

/// Dedicated Screen for Editing Partner Preferences ONLY.
/// Does NOT display or overwrite Personal Details or Location/Residence data.
class EditPartnerPreferencesScreen extends StatefulWidget {
  const EditPartnerPreferencesScreen({super.key});

  @override
  State<EditPartnerPreferencesScreen> createState() => _EditPartnerPreferencesScreenState();
}

class _EditPartnerPreferencesScreenState extends State<EditPartnerPreferencesScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _expectationsController;
  late TextEditingController _bioController;

  int _prefAgeMin = 21;
  int _prefAgeMax = 35;
  String _prefMaritalStatus = 'Never Married';
  String _prefLocation = 'Any Worldwide Location';
  String _prefEducation = 'Any Education';
  String _prefOccupation = 'Any Working Professional';
  String _prefIncome = 'Any Income Range';
  String _prefDietaryPreference = 'Does Not Matter';

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final p = context.read<ProfileProvider>().myProfile;
    _initFromProfile(p);
  }

  void _initFromProfile(MatrimonyProfileModel? p) {
    _prefAgeMin = p?.prefAgeMin ?? 21;
    _prefAgeMax = p?.prefAgeMax ?? 35;
    if (_prefAgeMin < 18) _prefAgeMin = 18;
    if (_prefAgeMax > 60) _prefAgeMax = 60;
    if (_prefAgeMin > _prefAgeMax) _prefAgeMax = _prefAgeMin;

    _prefMaritalStatus = p?.prefMaritalStatus.isNotEmpty == true ? p!.prefMaritalStatus : 'Never Married';
    _prefLocation = p?.prefLocation.isNotEmpty == true ? p!.prefLocation : 'Any Worldwide Location';
    _prefEducation = p?.prefEducation.isNotEmpty == true ? p!.prefEducation : 'Any Education';
    _prefOccupation = p?.prefOccupation.isNotEmpty == true ? p!.prefOccupation : 'Any Working Professional';
    _prefIncome = p?.prefIncome.isNotEmpty == true ? p!.prefIncome : 'Any Income Range';
    _prefDietaryPreference = p?.prefDietaryPreference.isNotEmpty == true ? p!.prefDietaryPreference : 'Does Not Matter';

    _expectationsController = TextEditingController(text: p?.partnerExpectations ?? '');
    _bioController = TextEditingController(text: p?.bio ?? '');
  }

  @override
  void dispose() {
    _expectationsController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final Map<String, dynamic> preferenceData = {
      'prefAgeMin': _prefAgeMin,
      'prefAgeMax': _prefAgeMax,
      'prefMaritalStatus': _prefMaritalStatus,
      'prefLocation': _prefLocation,
      'prefEducation': _prefEducation,
      'prefOccupation': _prefOccupation,
      'prefIncome': _prefIncome,
      'prefDietaryPreference': _prefDietaryPreference,
      'partnerExpectations': _expectationsController.text.trim(),
      'bio': _bioController.text.trim(),
    };

    final result = await context.read<ProfileProvider>().updateProfileSection(preferenceData);

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppTheme.burgundy,
          content: Text('Partner preferences saved successfully!'),
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
        title: const Text('Partner Preference'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader('Partner Criteria'),

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
                            '$_prefAgeMin - $_prefAgeMax Yrs',
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
                      values: RangeValues(_prefAgeMin.toDouble(), _prefAgeMax.toDouble()),
                      min: 18,
                      max: 60,
                      divisions: 42,
                      activeColor: AppTheme.burgundy,
                      inactiveColor: const Color(0xFFE2E8F0),
                      onChanged: (values) {
                        setState(() {
                          _prefAgeMin = values.start.round();
                          _prefAgeMax = values.end.round();
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
                currentValue: _prefMaritalStatus,
                options: const [
                  'Never Married',
                  'Divorced',
                  'Awaiting Divorce',
                  'Widowed',
                  'Does Not Matter'
                ],
                prefixIcon: Icons.favorite_border_rounded,
                onSelected: (val) => setState(() => _prefMaritalStatus = val),
              ),
              const SizedBox(height: 14),

              // Preferred Location
              InkWell(
                onTap: () {
                  SearchableLocationPicker.show(
                    context: context,
                    title: 'Select Preferred Country / Location',
                    items: [
                      'Any Worldwide Location',
                      ...WorldwideLocations.countries.map((c) => c.name),
                    ],
                    selectedItem: _prefLocation,
                    isCountryPicker: true,
                    onSelected: (selected) {
                      setState(() => _prefLocation = selected);
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
                    _prefLocation.isNotEmpty ? _prefLocation : 'Any Worldwide Location',
                    style: const TextStyle(fontSize: 15),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Preferred Education
              SearchableCustomDropdown(
                label: 'Preferred Education',
                currentValue: _prefEducation,
                options: const [
                  'Any Education',
                  'B.E / B.Tech / Engineering',
                  'Masters / M.Tech / MBA',
                  'Medicine / MBBS / MD',
                  'Chartered Accountant / Finance',
                  'Doctorate / Ph.D',
                  'Bachelor Degree'
                ],
                prefixIcon: Icons.school_outlined,
                onSelected: (val) => setState(() => _prefEducation = val),
              ),
              const SizedBox(height: 14),

              // Preferred Occupation
              SearchableCustomDropdown(
                label: 'Preferred Occupation',
                currentValue: _prefOccupation,
                options: const [
                  'Any Working Professional',
                  'Software / IT Professional',
                  'Doctor / Healthcare Professional',
                  'Business Owner / Entrepreneur',
                  'Government / Civil Services',
                  'Banking / Finance Professional',
                  'Educator / Professor'
                ],
                prefixIcon: Icons.work_outline_rounded,
                onSelected: (val) => setState(() => _prefOccupation = val),
              ),
              const SizedBox(height: 14),

              // Preferred Income
              SearchableCustomDropdown(
                label: 'Preferred Annual Income',
                currentValue: _prefIncome,
                options: const [
                  'Any Income Range',
                  '₹5 - 10 Lakhs',
                  '₹10 - 20 Lakhs',
                  '₹20 - 35 Lakhs',
                  '₹35 - 50 Lakhs',
                  '₹50 Lakhs & Above'
                ],
                prefixIcon: Icons.currency_rupee_rounded,
                onSelected: (val) => setState(() => _prefIncome = val),
              ),
              const SizedBox(height: 14),

              // Dietary Preference
              SearchableCustomDropdown(
                label: 'Dietary Preference',
                currentValue: _prefDietaryPreference,
                options: const [
                  'Does Not Matter',
                  'Vegetarian',
                  'Non-Vegetarian',
                  'Eggetarian',
                  'Vegan',
                  'Jain Vegetarian',
                ],
                prefixIcon: Icons.restaurant_menu_rounded,
                hint: 'Select diet preference...',
                onSelected: (val) => setState(() => _prefDietaryPreference = val),
              ),
              const SizedBox(height: 22),

              _buildSectionHeader('Expectations & Bio'),

              // Partner Expectations
              TextFormField(
                controller: _expectationsController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Partner Expectations',
                  hintText: 'Describe values, lifestyle compatibility, personality traits...',
                  prefixIcon: Icon(Icons.handshake_outlined),
                ),
              ),
              const SizedBox(height: 14),

              // Short Bio
              TextFormField(
                controller: _bioController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'About Candidate (Short Bio)',
                  hintText: 'Introduce personal interests, worldview, outlook on marriage...',
                  prefixIcon: Icon(Icons.info_outline_rounded),
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
                          'Save Partner Preferences',
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
