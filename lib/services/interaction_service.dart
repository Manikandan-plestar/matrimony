/// Interaction Service — saved profiles, interests, matches, visitors
library;

import 'api_service.dart';
import 'auth_service.dart';
import '../models/matrimony_profile_model.dart';
import '../models/interaction_model.dart';

class InteractionService {
  // ─── Saved Profiles ────────────────────────────────────────────────────────

  static Future<List<MatrimonyProfileModel>> fetchSavedProfiles() async {
    final result = await ApiService.get('/api/mat/saved');
    if (result['success'] != true) return [];
    final list = result['profiles'];
    if (list is! List) return [];
    return list.whereType<Map<String, dynamic>>().map(profileFromApi).toList();
  }

  static Future<bool> saveProfile(String profileId) async {
    final result = await ApiService.post('/api/mat/saved/$profileId');
    return result['success'] == true;
  }

  static Future<bool> unsaveProfile(String profileId) async {
    final result = await ApiService.delete('/api/mat/saved/$profileId');
    return result['success'] == true;
  }

  // ─── Interests ─────────────────────────────────────────────────────────────

  static Future<List<InterestItem>> fetchSentInterests() async {
    final result = await ApiService.get('/api/mat/interests', queryParams: {'type': 'sent'});
    return _parseInterests(result, isReceived: false);
  }

  static Future<List<InterestItem>> fetchReceivedInterests() async {
    final result = await ApiService.get('/api/mat/interests', queryParams: {'type': 'received'});
    return _parseInterests(result, isReceived: true);
  }

  static List<InterestItem> _parseInterests(Map<String, dynamic> result, {required bool isReceived}) {
    if (result['success'] != true) return [];
    final list = result['interests'];
    if (list is! List) return [];
    return list.whereType<Map<String, dynamic>>().map((d) {
      final profileData = d['profile'];
      MatrimonyProfileModel profile = profileData is Map<String, dynamic>
          ? profileFromApi(profileData)
          : _emptyProfile();

      InterestStatus status;
      switch (d['status'] as String? ?? 'pending') {
        case 'accepted':
          status = InterestStatus.accepted;
        case 'rejected':
        case 'declined':
          status = InterestStatus.declined;
        case 'withdrawn':
          status = InterestStatus.withdrawn;
        default:
          status = InterestStatus.pending;
      }

      DateTime? withdrawnAt;
      if (d['withdrawnAt'] != null) {
        try { withdrawnAt = DateTime.parse(d['withdrawnAt'] as String); } catch (_) {}
      }

      return InterestItem(
        id: '${d['id']}',
        profile: profile,
        timestamp: _parseDate(d['timestamp']),
        isReceived: isReceived,
        status: status,
        withdrawnAt: withdrawnAt,
      );
    }).toList();
  }

  /// Send an interest to a profile. profileId is the numeric DB id.
  static Future<({bool success, String message, String? status})>
      sendInterest(String profileId) async {
    final result = await ApiService.post('/api/mat/interests/$profileId');
    return (
      success: result['success'] == true,
      message: result['message'] as String? ?? 'Error sending interest.',
      status: result['status'] as String?,
    );
  }

  static Future<({bool success, String message})> respondToInterest(
      String interestId, String action) async {
    final result = await ApiService.patch('/api/mat/interests/$interestId',
        body: {'action': action});
    return (
      success: result['success'] == true,
      message: result['message'] as String? ?? 'Error updating interest.',
    );
  }

  static Future<({bool success, String message})> withdrawInterest(
      String interestId) =>
      respondToInterest(interestId, 'withdraw');

  static Future<({bool success, String message})> acceptInterest(
      String interestId) =>
      respondToInterest(interestId, 'accept');

  static Future<({bool success, String message})> rejectInterest(
      String interestId) =>
      respondToInterest(interestId, 'reject');

  // ─── Matches ───────────────────────────────────────────────────────────────

  static Future<List<MatchItem>> fetchMatches() async {
    final result = await ApiService.get('/api/mat/matches');
    if (result['success'] != true) return [];
    final list = result['matches'];
    if (list is! List) return [];
    return list.whereType<Map<String, dynamic>>().map((d) {
      final profileData = d['profile'];
      final profile = profileData is Map<String, dynamic>
          ? profileFromApi(profileData)
          : _emptyProfile();
      return MatchItem(
        id: '${d['id']}',
        profile: profile,
        compatibilityScore: (d['compatibilityScore'] as num?)?.toInt() ?? 85,
        matchingFactors:
            (d['matchingFactors'] as List?)?.map((e) => '$e').toList() ??
                ['Mutual Interest Accepted'],
        matchedDate: _parseDate(d['matchedDate']),
      );
    }).toList();
  }

  // ─── Visitors ──────────────────────────────────────────────────────────────

  static Future<List<VisitorItem>> fetchVisitors() async {
    final result = await ApiService.get('/api/mat/visitors');
    if (result['success'] != true) return [];
    final list = result['visitors'];
    if (list is! List) return [];
    return list.whereType<Map<String, dynamic>>().map((d) {
      final profileData = d['profile'];
      final profile = profileData is Map<String, dynamic>
          ? profileFromApi(profileData)
          : _emptyProfile();
      return VisitorItem(
        id: '${d['id']}',
        profile: profile,
        visitedAt: _parseDate(d['visitedAt']),
        visitCount: (d['visitCount'] as num?)?.toInt() ?? 1,
      );
    }).toList();
  }

  // ─── Helpers ───────────────────────────────────────────────────────────────

  static DateTime _parseDate(dynamic raw) {
    if (raw == null) return DateTime.now();
    try { return DateTime.parse(raw as String); } catch (_) { return DateTime.now(); }
  }

  static MatrimonyProfileModel _emptyProfile() => MatrimonyProfileModel(
    id: '', profileId: '', createdFor: '', fullName: 'Unknown',
    gender: 'Groom', dateOfBirth: DateTime(1990), age: 30,
    maritalStatus: '', height: '', motherTongue: '', religion: '',
    community: '', dietaryPreference: '', profilePhotoUrl: '',
    highestEducation: '', occupation: '', company: '', annualIncome: '',
    country: '', state: '', city: '', locality: '',
    familyType: '', familyBackground: '', familyValues: '',
    prefAgeMin: 21, prefAgeMax: 40, prefMaritalStatus: '', prefLocation: '',
    prefEducation: '', prefOccupation: '', prefIncome: '',
    partnerExpectations: '', bio: '',
  );
}
