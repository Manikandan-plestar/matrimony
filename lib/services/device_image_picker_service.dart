import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

/// Shared service for picking real local device images for candidate profile photos.
class DeviceImagePickerService {
  static final ImagePicker _picker = ImagePicker();

  /// Opens native picker for a single image (from Gallery by default)
  static Future<String?> pickSingleImage({
    ImageSource source = ImageSource.gallery,
  }) async {
    try {
      final XFile? file = await _picker.pickImage(
        source: source,
        maxWidth: 1800,
        maxHeight: 2400,
        imageQuality: 90,
      );
      return file?.path;
    } catch (e) {
      debugPrint('DeviceImagePickerService error during pickImage: $e');
      return null;
    }
  }
}
