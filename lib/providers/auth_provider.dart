import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/matrimony_profile_model.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';

/// Authentication and Session State Provider
/// Uses real JWT-based auth via the Matrimony backend.
class AuthProvider extends ChangeNotifier {
  UserModel? _currentUser;
  bool _isLoggedIn = false;
  bool _isLoading = false;
  String? _errorMessage;

  UserModel? get currentUser => _currentUser;
  bool get isLoggedIn => _isLoggedIn;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Called once at app start to restore session from stored token.
  Future<MatrimonyProfileModel?> restoreSession() async {
    final token = await ApiService.getToken();
    if (token == null) return null;

    _isLoading = true;
    notifyListeners();

    try {
      final result = await AuthService.fetchMe();
      if (result.user != null) {
        _currentUser = result.user;
        _isLoggedIn = true;
        notifyListeners();
        return result.profile;
      }
    } catch (_) {
      // Token may be expired — clear it
      await ApiService.clearToken();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return null;
  }

  /// Request an OTP for the given email address.
  Future<({bool success, String message, String? code})> requestOtp(String email, {String? action}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await AuthService.requestOtp(email, action: action);
      if (!result.success) {
        _errorMessage = result.message;
      }
      return (success: result.success, message: result.message, code: result.code);
    } catch (e) {
      _errorMessage = 'Network error. Please check your connection.';
      return (success: false, message: _errorMessage!, code: null);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Verify an OTP and log in.
  Future<({bool success, String message, MatrimonyProfileModel? profile, bool isNewUser, String? code})>
      verifyOtp(String email, String otp, {String? action}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await AuthService.verifyOtp(email, otp, action: action);
      if (result.success && result.user != null) {
        _currentUser = result.user;
        _isLoggedIn = true;
      } else {
        _errorMessage = result.message;
      }
      return (
        success: result.success,
        message: result.message,
        profile: result.profile,
        isNewUser: result.isNewUser,
        code: result.code,
      );
    } catch (e) {
      _errorMessage = 'Network error. Please check your connection.';
      return (
        success: false,
        message: _errorMessage!,
        profile: null,
        isNewUser: false,
        code: null,
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Update local user state after account or profile photo changes.
  void updateUserProfile({
    String? fullName,
    String? phone,
    String? profilePhotoUrl,
    bool? hasPublishedProfile,
  }) {
    if (_currentUser == null) return;
    _currentUser = _currentUser!.copyWith(
      fullName: fullName ?? _currentUser!.fullName,
      phone: phone ?? _currentUser!.phone,
      profilePhotoUrl: profilePhotoUrl ?? _currentUser!.profilePhotoUrl,
      hasPublishedProfile: hasPublishedProfile ?? _currentUser!.hasPublishedProfile,
    );
    notifyListeners();
  }

  Future<void> logout() async {
    await AuthService.logout();
    _isLoggedIn = false;
    _currentUser = null;
    _errorMessage = null;
    notifyListeners();
  }

  // ── Backward-compatible demo method (used in dev when no backend is reachable) ──
  void loginDemo() {
    _isLoggedIn = true;
    notifyListeners();
  }
}
