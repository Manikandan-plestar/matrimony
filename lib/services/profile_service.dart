/// Profile Service — CRUD operations for the authenticated user's own profile
/// and discovery of groom/bride profiles.
library;

import 'dart:io';
import 'api_service.dart';
import 'auth_service.dart';
import '../models/matrimony_profile_model.dart';

class ProfileService {
  /// Fetch the authenticated user's own full profile.
  static Future<MatrimonyProfileModel?> fetchMyProfile() async {
    final result = await ApiService.get('/api/mat/profiles/me');
    if (result['success'] != true) return null;
    final d = result['profile'];
    if (d is Map<String, dynamic>) return profileFromApi(d);
    return null;
  }

  /// Create or update the authenticated user's profile.
  static Future<({bool success, String message, MatrimonyProfileModel? profile})>
      saveProfile(Map<String, dynamic> profileData) async {
    final result = await ApiService.post('/api/mat/profiles', body: profileData);
    if (result['success'] != true) {
      return (
        success: false,
        message: result['message'] as String? ?? 'Error saving profile.',
        profile: null
      );
    }
    final p = result['profile'];
    return (
      success: true,
      message: 'Profile saved successfully.',
      profile: p is Map<String, dynamic> ? profileFromApi(p) : null,
    );
  }

  /// Publish the user's profile (make it discoverable).
  static Future<bool> publishProfile() async {
    final result = await ApiService.patch('/api/mat/profiles/me/status',
        body: {'status': 'published'});
    return result['success'] == true;
  }

  /// Unpublish / set to draft.
  static Future<bool> unpublishProfile() async {
    final result = await ApiService.patch('/api/mat/profiles/me/status',
        body: {'status': 'draft'});
    return result['success'] == true;
  }

  /// Delete the authenticated user's profile.
  static Future<bool> deleteProfile() async {
    final result = await ApiService.delete('/api/mat/profiles/me');
    return result['success'] == true;
  }

  /// Fetch the public view of any profile by ID.
  static Future<MatrimonyProfileModel?> fetchPublicProfile(String profileId) async {
    final result = await ApiService.get('/api/mat/profiles/$profileId/public');
    if (result['success'] != true) return null;
    final d = result['profile'];
    if (d is Map<String, dynamic>) return profileFromApi(d);
    return null;
  }

  /// Fetch full profile details (requires accepted interest or ownership).
  static Future<MatrimonyProfileModel?> fetchFullProfile(String profileId) async {
    final result = await ApiService.get('/api/mat/profiles/$profileId/full');
    if (result['success'] != true) return null;
    final d = result['profile'];
    if (d is Map<String, dynamic>) return profileFromApi(d);
    return null;
  }

  /// Fetch discovery feed for a specific gender.
  static Future<List<MatrimonyProfileModel>> fetchProfiles({
    required String gender,
    int page = 1,
    int limit = 20,
  }) async {
    final result = await ApiService.get('/api/mat/profiles', queryParams: {
      'gender': gender,
      'page': '$page',
      'limit': '$limit',
    });
    if (result['success'] != true) return [];
    final list = result['profiles'];
    if (list is! List) return [];
    return list
        .whereType<Map<String, dynamic>>()
        .map(profileFromApi)
        .toList();
  }

  /// Upload a profile photo and return the server URL.
  static Future<String?> uploadProfilePhoto(File file) async {
    final result = await ApiService.uploadFile(
        '/api/mat/upload/profile-photo', file, 'photo');
    if (result['success'] != true) return null;
    return result['url'] as String?;
  }

  /// Record a profile view (More Info interaction).
  static Future<void> recordView(String profileId) async {
    try {
      await ApiService.post('/api/mat/profiles/$profileId/view');
    } catch (_) {
      // Non-critical — swallow errors silently
    }
  }
}
