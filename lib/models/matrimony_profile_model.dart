/// Comprehensive Matrimonial Profile Data Model
class MatrimonyProfileModel {
  final String id;
  final String profileId;
  final String createdFor;
  final String fullName;
  final String gender; // 'Groom' or 'Bride'
  final DateTime dateOfBirth;
  final int age;
  final String maritalStatus;
  final String height;
  final String motherTongue;
  final String religion;
  final String community;
  final String dietaryPreference;
  final String profilePhotoUrl;
  final List<String> galleryImages;

  // Education & Career
  final String highestEducation;
  final String occupation;
  final String company;
  final String annualIncome;

  // Contact & Address Details
  final String countryCode;
  final String phone;
  final String address;

  // Location
  final String country;
  final String state;
  final String city;
  final String locality;

  // Family
  final String familyType;
  final String familyBackground;
  final String familyValues;

  // Partner Preferences
  final int prefAgeMin;
  final int prefAgeMax;
  final String prefMaritalStatus;
  final String prefLocation;
  final String prefEducation;
  final String prefOccupation;
  final String prefIncome;
  final String prefDietaryPreference;
  final String partnerExpectations;

  // Biography & Badges
  final String bio;
  final bool isVerified;
  final bool isPremium;
  final int compatibilityScore;
  final String lastActive;

  // State flags for interactive UI
  bool isSaved;
  bool isInterestSent;
  final String? interestStatus;

  // Privacy & Shield flags
  final bool isPhotoShielded;
  final bool photoShield;
  final bool isDiscoverable;
  final bool protectPhone;

  MatrimonyProfileModel({
    required this.id,
    required this.profileId,
    required this.createdFor,
    required this.fullName,
    required this.gender,
    required this.dateOfBirth,
    required this.age,
    required this.maritalStatus,
    required this.height,
    required this.motherTongue,
    required this.religion,
    required this.community,
    required this.dietaryPreference,
    required this.profilePhotoUrl,
    this.galleryImages = const [],
    required this.highestEducation,
    required this.occupation,
    required this.company,
    required this.annualIncome,
    required this.country,
    required this.state,
    required this.city,
    required this.locality,
    required this.familyType,
    required this.familyBackground,
    required this.familyValues,
    required this.prefAgeMin,
    required this.prefAgeMax,
    required this.prefMaritalStatus,
    required this.prefLocation,
    required this.prefEducation,
    required this.prefOccupation,
    required this.prefIncome,
    this.prefDietaryPreference = 'Does Not Matter',
    required this.partnerExpectations,
    required this.bio,
    this.countryCode = '+91',
    this.phone = '',
    this.address = '',
    this.isVerified = true,
    this.isPremium = false,
    this.compatibilityScore = 85,
    this.lastActive = 'Active recently',
    this.isSaved = false,
    this.isInterestSent = false,
    this.interestStatus,
    this.isPhotoShielded = false,
    this.photoShield = false,
    this.isDiscoverable = true,
    this.protectPhone = true,
  });

  MatrimonyProfileModel copyWith({
    String? id,
    String? profileId,
    String? createdFor,
    String? fullName,
    String? gender,
    DateTime? dateOfBirth,
    int? age,
    String? maritalStatus,
    String? height,
    String? motherTongue,
    String? religion,
    String? community,
    String? dietaryPreference,
    String? profilePhotoUrl,
    List<String>? galleryImages,
    String? highestEducation,
    String? occupation,
    String? company,
    String? annualIncome,
    String? countryCode,
    String? phone,
    String? address,
    String? country,
    String? state,
    String? city,
    String? locality,
    String? familyType,
    String? familyBackground,
    String? familyValues,
    int? prefAgeMin,
    int? prefAgeMax,
    String? prefMaritalStatus,
    String? prefLocation,
    String? prefEducation,
    String? prefOccupation,
    String? prefIncome,
    String? prefDietaryPreference,
    String? partnerExpectations,
    String? bio,
    bool? isVerified,
    bool? isPremium,
    int? compatibilityScore,
    String? lastActive,
    bool? isSaved,
    bool? isInterestSent,
  }) {
    return MatrimonyProfileModel(
      id: id ?? this.id,
      profileId: profileId ?? this.profileId,
      createdFor: createdFor ?? this.createdFor,
      fullName: fullName ?? this.fullName,
      gender: gender ?? this.gender,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      age: age ?? this.age,
      maritalStatus: maritalStatus ?? this.maritalStatus,
      height: height ?? this.height,
      motherTongue: motherTongue ?? this.motherTongue,
      religion: religion ?? this.religion,
      community: community ?? this.community,
      dietaryPreference: dietaryPreference ?? this.dietaryPreference,
      profilePhotoUrl: profilePhotoUrl ?? this.profilePhotoUrl,
      galleryImages: galleryImages ?? this.galleryImages,
      highestEducation: highestEducation ?? this.highestEducation,
      occupation: occupation ?? this.occupation,
      company: company ?? this.company,
      annualIncome: annualIncome ?? this.annualIncome,
      countryCode: countryCode ?? this.countryCode,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      country: country ?? this.country,
      state: state ?? this.state,
      city: city ?? this.city,
      locality: locality ?? this.locality,
      familyType: familyType ?? this.familyType,
      familyBackground: familyBackground ?? this.familyBackground,
      familyValues: familyValues ?? this.familyValues,
      prefAgeMin: prefAgeMin ?? this.prefAgeMin,
      prefAgeMax: prefAgeMax ?? this.prefAgeMax,
      prefMaritalStatus: prefMaritalStatus ?? this.prefMaritalStatus,
      prefLocation: prefLocation ?? this.prefLocation,
      prefEducation: prefEducation ?? this.prefEducation,
      prefOccupation: prefOccupation ?? this.prefOccupation,
      prefIncome: prefIncome ?? this.prefIncome,
      prefDietaryPreference: prefDietaryPreference ?? this.prefDietaryPreference,
      partnerExpectations: partnerExpectations ?? this.partnerExpectations,
      bio: bio ?? this.bio,
      isVerified: isVerified ?? this.isVerified,
      isPremium: isPremium ?? this.isPremium,
      compatibilityScore: compatibilityScore ?? this.compatibilityScore,
      lastActive: lastActive ?? this.lastActive,
      isSaved: isSaved ?? this.isSaved,
      isInterestSent: isInterestSent ?? this.isInterestSent,
    );
  }
}
