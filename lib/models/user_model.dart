/// Current logged in user model for Matrimony App
class UserModel {
  final String id;
  final String email;
  final String fullName;
  final String phone;
  final String profilePhotoUrl;
  final String activeProfileId;
  final bool hasPublishedProfile;

  /// Alias for phone for backwards compatibility
  String get phoneNumber => phone;

  UserModel({
    required this.id,
    required this.email,
    required this.fullName,
    required this.phone,
    required this.profilePhotoUrl,
    required this.activeProfileId,
    this.hasPublishedProfile = true,
  });

  UserModel copyWith({
    String? id,
    String? email,
    String? fullName,
    String? phone,
    String? profilePhotoUrl,
    String? activeProfileId,
    bool? hasPublishedProfile,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      profilePhotoUrl: profilePhotoUrl ?? this.profilePhotoUrl,
      activeProfileId: activeProfileId ?? this.activeProfileId,
      hasPublishedProfile: hasPublishedProfile ?? this.hasPublishedProfile,
    );
  }
}
