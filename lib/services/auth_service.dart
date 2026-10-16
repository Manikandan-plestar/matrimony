/// Authentication Service — wraps the OTP request and verify flow
library;

import 'api_service.dart';
import '../models/user_model.dart';
import '../models/matrimony_profile_model.dart';

class AuthService {
  /// Request an OTP for the given email.
  static Future<({bool success, String message, bool isTestOtp})>
      requestOtp(String email) async {
    final result = await ApiService.post('/api/mat/auth/request-otp',
        body: {'email': email});
    return (
      success: result['success'] == true,
      message: result['message'] as String? ?? 'Error sending OTP.',
      isTestOtp: result['isTestOtp'] == true,
    );
  }

  /// Verify an OTP and return the authenticated session or an error.
  static Future<
      ({
        bool success,
        String message,
        String? token,
        UserModel? user,
        MatrimonyProfileModel? profile,
        bool isNewUser,
      })> verifyOtp(String email, String otp) async {
    final result = await ApiService.post('/api/mat/auth/verify-otp',
        body: {'email': email, 'otp': otp});

    if (result['success'] != true) {
      return (
        success: false,
        message: result['message'] as String? ?? 'Verification failed.',
        token: null,
        user: null,
        profile: null,
        isNewUser: false,
      );
    }

    final token = result['token'] as String?;
    if (token != null) {
      await ApiService.saveToken(token);
    }

    UserModel? user;
    final uData = result['user'];
    if (uData is Map<String, dynamic>) {
      user = UserModel(
        id: '${uData['id']}',
        email: uData['email'] as String? ?? '',
        fullName: uData['fullName'] as String? ?? '',
        phone: uData['phone'] as String? ?? '',
        profilePhotoUrl: uData['profilePhotoUrl'] as String? ?? '',
        activeProfileId: uData['activeProfileId'] != null
            ? '${uData['activeProfileId']}'
            : '',
        hasPublishedProfile: uData['hasPublishedProfile'] == true,
      );
    }

    MatrimonyProfileModel? profile;
    final pData = result['profile'];
    if (pData is Map<String, dynamic>) {
      profile = profileFromApi(pData);
    }

    return (
      success: true,
      message: result['message'] as String? ?? 'Success.',
      token: token,
      user: user,
      profile: profile,
      isNewUser: result['isNewUser'] == true,
    );
  }

  /// Fetch the current authenticated user's account + profile.
  static Future<({UserModel? user, MatrimonyProfileModel? profile})>
      fetchMe() async {
    final result = await ApiService.get('/api/mat/me');
    if (result['success'] != true) return (user: null, profile: null);

    UserModel? user;
    final uData = result['user'];
    if (uData is Map<String, dynamic>) {
      user = UserModel(
        id: '${uData['id']}',
        email: uData['email'] as String? ?? '',
        fullName: uData['fullName'] as String? ?? '',
        phone: uData['phone'] as String? ?? '',
        profilePhotoUrl: uData['profilePhotoUrl'] as String? ?? '',
        activeProfileId: uData['activeProfileId'] != null
            ? '${uData['activeProfileId']}'
            : '',
        hasPublishedProfile: uData['hasPublishedProfile'] == true,
      );
    }

    MatrimonyProfileModel? profile;
    final pData = result['profile'];
    if (pData is Map<String, dynamic>) {
      profile = profileFromApi(pData);
    }

    return (user: user, profile: profile);
  }

  /// Log out: notify backend to invalidate active session, and always clear local credentials.
  static Future<void> logout() async {
    try {
      await ApiService.post('/api/mat/auth/logout');
    } catch (_) {
      // If network fails, proceed with client cleanup to protect local user data
    } finally {
      await ApiService.clearToken();
    }
  }
}

/// Parse a MatrimonyProfileModel from API response map.
MatrimonyProfileModel profileFromApi(Map<String, dynamic> d) {
  DateTime dob;
  try {
    dob = DateTime.parse(d['dateOfBirth'] as String? ?? '1997-01-01');
  } catch (_) {
    dob = DateTime(1997, 1, 1);
  }

  return MatrimonyProfileModel(
    id: '${d['id'] ?? ''}',
    profileId: d['profileCode'] as String? ?? '',
    createdFor: d['createdFor'] as String? ?? 'Self',
    fullName: d['fullName'] as String? ?? '',
    gender: d['gender'] as String? ?? 'Groom',
    dateOfBirth: dob,
    age: (d['age'] as num?)?.toInt() ?? 0,
    maritalStatus: d['maritalStatus'] as String? ?? '',
    height: d['height'] as String? ?? '',
    motherTongue: d['motherTongue'] as String? ?? '',
    religion: d['religion'] as String? ?? '',
    community: d['community'] as String? ?? '',
    dietaryPreference: d['dietaryPreference'] as String? ?? '',
    profilePhotoUrl: d['profilePhotoUrl'] as String? ?? '',
    highestEducation: d['highestEducation'] as String? ?? '',
    occupation: d['occupation'] as String? ?? '',
    company: d['company'] as String? ?? '',
    annualIncome: d['annualIncome'] as String? ?? '',
    country: d['country'] as String? ?? '',
    state: d['state'] as String? ?? '',
    city: d['city'] as String? ?? '',
    locality: d['locality'] as String? ?? '',
    familyType: d['familyType'] as String? ?? '',
    familyBackground: d['familyBackground'] as String? ?? '',
    familyValues: d['familyValues'] as String? ?? '',
    prefAgeMin: (d['prefAgeMin'] as num?)?.toInt() ?? 21,
    prefAgeMax: (d['prefAgeMax'] as num?)?.toInt() ?? 40,
    prefMaritalStatus: d['prefMaritalStatus'] as String? ?? '',
    prefLocation: d['prefLocation'] as String? ?? 'Any Worldwide Location',
    prefEducation: d['prefEducation'] as String? ?? '',
    prefOccupation: d['prefOccupation'] as String? ?? '',
    prefIncome: d['prefIncome'] as String? ?? '',
    partnerExpectations: d['partnerExpectations'] as String? ?? '',
    bio: d['bio'] as String? ?? '',
    countryCode: d['countryCode'] as String? ?? '+91',
    phone: d['phone'] as String? ?? '',
    address: d['address'] as String? ?? '',
    isVerified: d['isVerified'] == true,
    isPremium: d['isPremium'] == true,
    compatibilityScore: (d['compatibilityScore'] as num?)?.toInt() ?? 85,
    lastActive: d['lastActive'] as String? ?? 'Active recently',
    isSaved: d['isSaved'] == true,
    isInterestSent: d['isInterestSent'] == true,
    interestStatus: d['interestStatus'] as String?,
  );
}
