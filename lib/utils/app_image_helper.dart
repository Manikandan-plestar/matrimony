import 'dart:io';
import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../services/api_service.dart';

/// Helper to reliably resolve and render profile images across network, local cache, and fallback states.
class AppImageHelper {
  /// Converts a photo URL or local path to a fully qualified URL or local path.
  static String normalizePhotoUrl(String? url) {
    if (url == null) return '';
    final trimmed = url.trim();
    if (trimmed.isEmpty) return '';
    if (trimmed.startsWith('/uploads/')) {
      return '${ApiService.baseUrl}$trimmed';
    }
    return trimmed;
  }

  /// Returns an ImageProvider (NetworkImage or FileImage) or null if invalid/empty.
  static ImageProvider? resolveImageProvider(String? url) {
    final normalized = normalizePhotoUrl(url);
    if (normalized.isEmpty) return null;

    if (normalized.startsWith('http://') || normalized.startsWith('https://')) {
      return NetworkImage(normalized);
    }

    try {
      final file = File(normalized);
      if (file.existsSync()) {
        return FileImage(file);
      }
    } catch (_) {}

    return null;
  }

  /// Builds a profile photo widget with graceful error handling and gender/initial fallback.
  static Widget buildProfileImage({
    required String? url,
    required String fullName,
    String gender = 'Groom',
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    BorderRadius? borderRadius,
  }) {
    final normalized = normalizePhotoUrl(url);

    Widget fallbackWidget() {
      final initial = fullName.trim().isNotEmpty ? fullName.trim()[0].toUpperCase() : 'M';
      final effectiveDimension = height ?? width ?? 100.0;
      final fontSize = (effectiveDimension * 0.38).clamp(12.0, 56.0);

      return Container(
        width: width,
        height: height,
        color: AppTheme.roseLight,
        alignment: Alignment.center,
        child: Text(
          initial,
          style: TextStyle(
            color: AppTheme.burgundy,
            fontWeight: FontWeight.bold,
            fontSize: fontSize,
          ),
        ),
      );
    }

    if (normalized.isEmpty) {
      return ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.zero,
        child: fallbackWidget(),
      );
    }

    Widget imageWidget;
    if (normalized.startsWith('http://') || normalized.startsWith('https://')) {
      imageWidget = Image.network(
        normalized,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, __, ___) => fallbackWidget(),
      );
    } else {
      try {
        final file = File(normalized);
        if (file.existsSync()) {
          imageWidget = Image.file(
            file,
            width: width,
            height: height,
            fit: fit,
            errorBuilder: (_, __, ___) => fallbackWidget(),
          );
        } else {
          imageWidget = fallbackWidget();
        }
      } catch (_) {
        imageWidget = fallbackWidget();
      }
    }

    if (borderRadius != null) {
      return ClipRRect(
        borderRadius: borderRadius,
        child: imageWidget,
      );
    }
    return imageWidget;
  }

  /// Builds a circular avatar that renders the profile photo, or falls back to
  /// the first letter of the name if no photo exists or image fails to load.
  /// Never overlays the initial letter on top of the image.
  static Widget buildAvatar({
    required String? url,
    required String fullName,
    double radius = 20,
    Color backgroundColor = AppTheme.roseLight,
  }) {
    return ClipOval(
      child: Container(
        width: radius * 2,
        height: radius * 2,
        color: backgroundColor,
        child: buildProfileImage(
          url: url,
          fullName: fullName,
          width: radius * 2,
          height: radius * 2,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}

