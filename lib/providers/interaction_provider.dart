import 'package:flutter/material.dart';
import '../models/matrimony_profile_model.dart';
import '../models/interaction_model.dart';
import '../services/interaction_service.dart';

/// Interaction Provider managing Saved Profiles, Interests, Matches, and Visitors.
/// All data is fetched from the real backend.
class InteractionProvider extends ChangeNotifier {
  List<MatrimonyProfileModel> _savedProfiles = [];
  List<InterestItem> _sentInterests = [];
  List<InterestItem> _receivedInterests = [];
  List<MatchItem> _matches = [];
  List<VisitorItem> _visitors = [];

  bool _isLoading = false;
  String? _error;

  List<MatrimonyProfileModel> get savedProfiles => _savedProfiles;
  List<InterestItem> get sentInterests => _sentInterests;
  List<InterestItem> get receivedInterests => _receivedInterests;
  List<MatchItem> get matches => _matches;
  List<VisitorItem> get visitors => _visitors;
  bool get isLoading => _isLoading;
  String? get error => _error;

  int get pendingReceivedCount =>
      _receivedInterests.where((i) => i.status == InterestStatus.pending).length;
  int get pendingSentCount =>
      _sentInterests.where((i) => i.status == InterestStatus.pending).length;

  bool isProfileSaved(String profileId) =>
      _savedProfiles.any((p) => p.profileId == profileId || p.id == profileId);

  // ─── Load all interaction data ─────────────────────────────────────────────

  Future<void> fetchAll() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await Future.wait([
        _fetchSaved(),
        _fetchInterests(),
        _fetchMatches(),
        _fetchVisitors(),
      ]);
    } catch (_) {
      _error = 'Could not load interaction data.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _fetchSaved() async {
    _savedProfiles = await InteractionService.fetchSavedProfiles();
  }

  Future<void> _fetchInterests() async {
    _sentInterests = await InteractionService.fetchSentInterests();
    _receivedInterests = await InteractionService.fetchReceivedInterests();
  }

  Future<void> _fetchMatches() async {
    _matches = await InteractionService.fetchMatches();
  }

  Future<void> _fetchVisitors() async {
    _visitors = await InteractionService.fetchVisitors();
  }

  // ─── Saved profiles ────────────────────────────────────────────────────────

  Future<void> toggleSaveProfile(MatrimonyProfileModel profile) async {
    final profileDbId = profile.id;
    final wasSaved = isProfileSaved(profile.profileId);

    // Optimistic update
    if (wasSaved) {
      _savedProfiles.removeWhere((p) => p.profileId == profile.profileId || p.id == profile.id);
      profile.isSaved = false;
    } else {
      _savedProfiles.insert(0, profile);
      profile.isSaved = true;
    }
    notifyListeners();

    // Sync with backend
    final ok = wasSaved
        ? await InteractionService.unsaveProfile(profileDbId)
        : await InteractionService.saveProfile(profileDbId);

    if (!ok) {
      // Revert on failure
      if (wasSaved) {
        _savedProfiles.insert(0, profile);
        profile.isSaved = true;
      } else {
        _savedProfiles.removeWhere((p) => p.profileId == profile.profileId || p.id == profile.id);
        profile.isSaved = false;
      }
      notifyListeners();
    }
  }

  // ─── Express interest ──────────────────────────────────────────────────────

  Future<({bool success, String message})> expressInterest(
      MatrimonyProfileModel profile) async {
    // Optimistic
    profile.isInterestSent = true;
    notifyListeners();

    final result = await InteractionService.sendInterest(profile.id);

    if (result.success) {
      // Add to sent interests list if not already there
      final exists = _sentInterests.any((i) =>
          i.profile.profileId == profile.profileId || i.profile.id == profile.id);
      if (!exists) {
        _sentInterests.insert(
          0,
          InterestItem(
            id: '',
            profile: profile,
            timestamp: DateTime.now(),
            isReceived: false,
            status: InterestStatus.pending,
          ),
        );
      }
    } else {
      // Revert on failure
      profile.isInterestSent = false;
    }
    notifyListeners();
    return (success: result.success, message: result.message);
  }

  /// Withdraw a pending sent interest.
  Future<bool> withdrawInterest(InterestItem item) async {
    if (item.status != InterestStatus.pending || item.isReceived) return false;

    // Optimistic
    item.status = InterestStatus.withdrawn;
    item.withdrawnAt = DateTime.now();
    item.profile.isInterestSent = false;
    notifyListeners();

    final result = await InteractionService.withdrawInterest(item.id);
    if (!result.success) {
      // Revert
      item.status = InterestStatus.pending;
      item.withdrawnAt = null;
      item.profile.isInterestSent = true;
      notifyListeners();
      return false;
    }
    return true;
  }

  Future<void> acceptInterest(InterestItem item) async {
    if (item.status != InterestStatus.pending) return;
    item.status = InterestStatus.accepted;
    notifyListeners();

    final result = await InteractionService.acceptInterest(item.id);
    if (result.success) {
      // Refresh matches
      _matches = await InteractionService.fetchMatches();
      notifyListeners();
    } else {
      item.status = InterestStatus.pending;
      notifyListeners();
    }
  }

  Future<void> declineInterest(InterestItem item) async {
    if (item.status != InterestStatus.pending) return;
    item.status = InterestStatus.declined;
    notifyListeners();

    final result = await InteractionService.rejectInterest(item.id);
    if (!result.success) {
      item.status = InterestStatus.pending;
      notifyListeners();
    }
  }

  /// Check if the viewer has an accepted interest / match relationship with this profile.
  bool isAuthorizedForFullProfile(String profileId) {
    if (profileId.isEmpty) return false;
    final inMatches = _matches.any((m) => m.profile.id == profileId || m.profile.profileId == profileId);
    if (inMatches) return true;

    final inSent = _sentInterests.any((i) =>
        (i.profile.id == profileId || i.profile.profileId == profileId) &&
        i.status == InterestStatus.accepted);
    if (inSent) return true;

    final inReceived = _receivedInterests.any((i) =>
        (i.profile.id == profileId || i.profile.profileId == profileId) &&
        i.status == InterestStatus.accepted);
    return inReceived;
  }

  /// Reset interaction state on logout
  void clear() {
    _savedProfiles = [];
    _sentInterests = [];
    _receivedInterests = [];
    _matches = [];
    _visitors = [];
    _isLoading = false;
    _error = null;
    notifyListeners();
  }
}
