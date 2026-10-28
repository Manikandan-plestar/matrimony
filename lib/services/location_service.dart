import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../config/theme.dart';

class LocationDetails {
  final String area;
  final String city;
  final String district;
  final String state;
  final String country;
  final String postalCode;
  final String fullAddress;
  final double latitude;
  final double longitude;

  LocationDetails({
    required this.area,
    required this.city,
    required this.district,
    required this.state,
    required this.country,
    this.postalCode = '',
    this.fullAddress = '',
    required this.latitude,
    required this.longitude,
  });

  String get formattedAddress {
    if (fullAddress.isNotEmpty) return fullAddress;
    final parts = [area, city, state, country].where((p) => p.trim().isNotEmpty).toList();
    return parts.join(', ');
  }
}

class LocationService extends ChangeNotifier {
  LocationDetails? _currentLocation;
  bool _hasPermission = false;
  bool _isFetching = false;

  LocationDetails? get currentLocation => _currentLocation;
  bool get hasPermission => _hasPermission;
  bool get isFetching => _isFetching;

  /// Google Play Mandatory: Prominent In-App Disclosure Dialog
  /// Must be shown BEFORE requesting Android system runtime location permission.
  static Future<bool> showProminentLocationDisclosure(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.location_on_rounded, color: AppTheme.burgundy, size: 24),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Location Permission',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: AppTheme.textPrimary),
              ),
            ),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Matrimonyer collects location data to automatically determine your current City, State, and Country to help you discover relevant matrimonial matches nearby.',
              style: TextStyle(fontSize: 13.5, color: AppTheme.textPrimary, height: 1.45),
            ),
            SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.check_circle_outline_rounded, color: AppTheme.success, size: 16),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Used only when you tap "Get GPS Address".',
                    style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                  ),
                ),
              ],
            ),
            SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.check_circle_outline_rounded, color: AppTheme.success, size: 16),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Never tracked in the background or shared with third parties.',
                    style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Not Now', style: TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.burgundy,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Continue', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    ) ?? false;
  }

  /// Request location permission from the user
  Future<bool> requestPermission([BuildContext? context]) async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _hasPermission = false;
        notifyListeners();
        return false;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        // Show prominent disclosure before system dialog if context is available
        if (context != null && context.mounted) {
          final agreed = await showProminentLocationDisclosure(context);
          if (!agreed) {
            _hasPermission = false;
            notifyListeners();
            return false;
          }
        }
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _hasPermission = false;
          notifyListeners();
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _hasPermission = false;
        notifyListeners();
        return false;
      }

      _hasPermission = true;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint("Error requesting location permission: $e");
      return false;
    }
  }

  /// Safe fetch method that handles permission check and returns null on failure
  Future<LocationDetails?> fetchCurrentLocation([BuildContext? context]) async {
    try {
      final hasPerm = await requestPermission(context);
      if (!hasPerm) return null;
      return await getCurrentLocation();
    } catch (e) {
      debugPrint("fetchCurrentLocation error: $e");
      return null;
    }
  }

  /// Get current user GPS location and reverse geocode into readable address details
  Future<LocationDetails> getCurrentLocation() async {
    _isFetching = true;
    notifyListeners();

    try {
      // 1. Get real GPS coordinates from device
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 12),
        ),
      );

      // 2. Reverse geocode coordinates to readable placemarks
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;

        String street = place.street ?? '';
        String subLocality = place.subLocality ?? '';
        String locality = place.locality ?? '';
        String subAdmin = place.subAdministrativeArea ?? '';
        String admin = place.administrativeArea ?? '';
        String postal = place.postalCode ?? '';
        String country = place.country ?? '';

        String area = subLocality.isNotEmpty
            ? subLocality
            : (street.isNotEmpty ? street : (locality.isNotEmpty ? locality : "Local Area"));
        String city = locality.isNotEmpty
            ? locality
            : (subAdmin.isNotEmpty ? subAdmin : (admin.isNotEmpty ? admin : "City"));
        String district = subAdmin.isNotEmpty ? subAdmin : city;
        String state = admin.isNotEmpty ? admin : (district.isNotEmpty ? district : "State");

        // Construct readable full address
        List<String> addressParts = [];
        if (street.isNotEmpty) addressParts.add(street);
        if (subLocality.isNotEmpty && subLocality != street) addressParts.add(subLocality);
        if (locality.isNotEmpty && locality != subLocality) addressParts.add(locality);
        if (admin.isNotEmpty) {
          if (postal.isNotEmpty) {
            addressParts.add("$admin - $postal");
          } else {
            addressParts.add(admin);
          }
        }
        if (country.isNotEmpty && !addressParts.contains(country)) {
          addressParts.add(country);
        }

        String full = addressParts.isNotEmpty
            ? addressParts.join(', ')
            : "$area, $city, $state, $country";

        _currentLocation = LocationDetails(
          area: area,
          city: city,
          district: district,
          state: state,
          country: country,
          postalCode: postal,
          fullAddress: full,
          latitude: position.latitude,
          longitude: position.longitude,
        );
      } else {
        throw Exception("No address placemark returned for GPS coordinates");
      }
    } catch (e) {
      debugPrint("Error fetching GPS location / geocoding: $e");
      rethrow;
    } finally {
      _isFetching = false;
      notifyListeners();
    }

    return _currentLocation!;
  }

  void setLocation(LocationDetails newLoc) {
    _currentLocation = newLoc;
    notifyListeners();
  }

  void clearLocation() {
    _currentLocation = null;
    notifyListeners();
  }
}
