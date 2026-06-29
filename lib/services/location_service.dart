import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocationData {
  final double latitude;
  final double longitude;
  final double elevation;
  final String name;

  const LocationData({
    required this.latitude,
    required this.longitude,
    this.elevation = 0.0,
    this.name = '',
  });

  static const LocationData jerusalem = LocationData(
    latitude: 31.7683,
    longitude: 35.2137,
    elevation: 754,
    name: 'Jérusalem',
  );

  static const LocationData paris = LocationData(
    latitude: 48.8566,
    longitude: 2.3522,
    elevation: 35,
    name: 'Paris',
  );
}

class LocationService {
  static const String _latKey = 'location_latitude';
  static const String _lonKey = 'location_longitude';
  static const String _elevKey = 'location_elevation';
  static const String _nameKey = 'location_name';
  static const String _useGpsKey = 'use_gps';

  Future<bool> requestPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return false;
    }
    if (permission == LocationPermission.deniedForever) return false;
    return true;
  }

  Future<LocationData?> getCurrentLocation() async {
    try {
      final hasPermission = await requestPermission();
      if (!hasPermission) return null;

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 15),
      );

      return LocationData(
        latitude: position.latitude,
        longitude: position.longitude,
        elevation: position.altitude,
        name: 'Position actuelle',
      );
    } catch (_) {
      return null;
    }
  }

  Future<LocationData> getSavedLocation() async {
    final prefs = await SharedPreferences.getInstance();
    final lat = prefs.getDouble(_latKey);
    final lon = prefs.getDouble(_lonKey);
    if (lat == null || lon == null) return LocationData.jerusalem;
    return LocationData(
      latitude: lat,
      longitude: lon,
      elevation: prefs.getDouble(_elevKey) ?? 0.0,
      name: prefs.getString(_nameKey) ?? '',
    );
  }

  Future<void> saveLocation(LocationData location) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_latKey, location.latitude);
    await prefs.setDouble(_lonKey, location.longitude);
    await prefs.setDouble(_elevKey, location.elevation);
    await prefs.setString(_nameKey, location.name);
  }

  Future<bool> getUseGPS() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_useGpsKey) ?? true;
  }

  Future<void> setUseGPS(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_useGpsKey, value);
  }
}
