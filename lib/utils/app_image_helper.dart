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
      final initial = fullName.trim().isNotEmpty ? fullName.trim()[0].toUpperCase() : (gender == 'Bride' ? 'B' : 'G');
      return Container(
        width: width,
        height: height,
        color: const Color(0xFFF1EAE0),
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              gender == 'Bride' ? Icons.female_rounded : Icons.male_rounded,
              size: (height != null && height < 80) ? 28 : 64,
              color: AppTheme.burgundy.withValues(alpha: 0.5),
            ),
            if (height == null || height >= 100) ...[
              const SizedBox(height: 6),
              Text(
                fullName.isNotEmpty ? fullName : initial,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ],
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
}
