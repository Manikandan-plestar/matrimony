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
  ProfileAnalyticsModel? _analytics;
  String _selectedPeriod = 'day';
  bool _isLoadingAnalytics = false;

  final Set<String> _viewedProfileIdsInSession = {};

  bool _isLoading = false;
  String? _error;

  List<MatrimonyProfileModel> get savedProfiles => _savedProfiles;
  List<InterestItem> get sentInterests => _sentInterests;
  List<InterestItem> get receivedInterests => _receivedInterests;
  List<MatchItem> get matches => _matches;
  List<VisitorItem> get visitors => _visitors;
  ProfileAnalyticsModel get analytics => _analytics ?? ProfileAnalyticsModel.empty();
  String get selectedPeriod => _selectedPeriod;
  bool get isLoadingAnalytics => _isLoadingAnalytics;
  bool get isLoading => _isLoading;
  String? get error => _error;

  int get pendingReceivedCount =>
      _receivedInterests.where((i) => i.status == InterestStatus.pending).length;
  int get pendingSentCount =>
      _sentInterests.where((i) => i.status == InterestStatus.pending).length;
  int get connectionCount => _matches.length;

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
        fetchAnalytics(_selectedPeriod),
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

  Future<void> fetchAnalytics([String? period]) async {
    if (period != null) _selectedPeriod = period;
    _isLoadingAnalytics = true;
    notifyListeners();
    try {
      _analytics = await InteractionService.fetchProfileAnalytics(_selectedPeriod);
    } catch (_) {
      // Fallback
    } finally {
      _isLoadingAnalytics = false;
      notifyListeners();
    }
  }

  /// Deduplicated in-session profile view recorder
  Future<void> recordProfileView(String profileId) async {
    if (profileId.isEmpty || _viewedProfileIdsInSession.contains(profileId)) return;
    _viewedProfileIdsInSession.add(profileId);
    await InteractionService.recordProfileView(profileId);
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

  /// Withdraw a pending sent interest and remove it immediately from active Sent tab.
  Future<bool> withdrawInterest(InterestItem item) async {
    if (item.status != InterestStatus.pending || item.isReceived) return false;

    // Immediately remove from Sent tab list
    final prevIndex = _sentInterests.indexOf(item);
    _sentInterests.removeWhere((i) => i.id == item.id);
    item.status = InterestStatus.withdrawn;
    item.withdrawnAt = DateTime.now();
    item.profile.isInterestSent = false;
    notifyListeners();

    final result = await InteractionService.withdrawInterest(item.id);
    if (!result.success) {
      // Revert if API failed
      item.status = InterestStatus.pending;
      item.withdrawnAt = null;
      item.profile.isInterestSent = true;
      if (prevIndex >= 0 && prevIndex <= _sentInterests.length) {
        _sentInterests.insert(prevIndex, item);
      } else {
        _sentInterests.add(item);
      }
      notifyListeners();
      return false;
    }
    return true;
  }

  /// Accept an incoming interest request: removes from Request tab, adds to Connection.
  Future<bool> acceptInterest(InterestItem item) async {
    if (item.status != InterestStatus.pending) return false;

    final prevIndex = _receivedInterests.indexOf(item);
    _receivedInterests.removeWhere((i) => i.id == item.id);
    item.status = InterestStatus.accepted;
    notifyListeners();

    final result = await InteractionService.acceptInterest(item.id);
    if (result.success) {
      // Refresh connections and sent lists
      _matches = await InteractionService.fetchMatches();
      notifyListeners();
      return true;
    } else {
      item.status = InterestStatus.pending;
      if (prevIndex >= 0 && prevIndex <= _receivedInterests.length) {
        _receivedInterests.insert(prevIndex, item);
      } else {
        _receivedInterests.add(item);
      }
      notifyListeners();
      return false;
    }
  }

  /// Decline an incoming interest request: removes from Request tab without creating connection.
  Future<bool> declineInterest(InterestItem item) async {
    if (item.status != InterestStatus.pending) return false;

    final prevIndex = _receivedInterests.indexOf(item);
    _receivedInterests.removeWhere((i) => i.id == item.id);
    item.status = InterestStatus.declined;
    notifyListeners();

    final result = await InteractionService.rejectInterest(item.id);
    if (!result.success) {
      item.status = InterestStatus.pending;
      if (prevIndex >= 0 && prevIndex <= _receivedInterests.length) {
        _receivedInterests.insert(prevIndex, item);
      } else {
        _receivedInterests.add(item);
      }
      notifyListeners();
      return false;
    }
    return true;
  }

  /// Remove an accepted connection and sync with backend.
  Future<bool> removeConnection(MatchItem match) async {
    final prevIndex = _matches.indexOf(match);
    _matches.removeWhere((m) => m.id == match.id);
    notifyListeners();

    final targetId = match.interestId ?? match.id;
    final result = await InteractionService.removeConnection(targetId);
    if (!result.success) {
      // Revert on failure
      if (prevIndex >= 0 && prevIndex <= _matches.length) {
        _matches.insert(prevIndex, match);
      } else {
        _matches.add(match);
      }
      notifyListeners();
      return false;
    }
    return true;
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
    _analytics = null;
    _viewedProfileIdsInSession.clear();
    _isLoading = false;
    _error = null;
    notifyListeners();
  }
}
