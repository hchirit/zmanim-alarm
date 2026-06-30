import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/location_service.dart';

class SettingsProvider extends ChangeNotifier {
  final LocationService _locationSvc = LocationService();

  LocationData _location = LocationData.jerusalem;
  bool _useGPS = true;
  String _calculationMethod = 'GRA';
  String _locale = 'fr';
  bool _darkMode = true;
  bool _loaded = false;

  LocationData get location => _location;
  bool get useGPS => _useGPS;
  String get calculationMethod => _calculationMethod;
  String get locale => _locale;
  bool get darkMode => _darkMode;
  bool get loaded => _loaded;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _useGPS = prefs.getBool('use_gps') ?? true;
    _calculationMethod = prefs.getString('calculation_method') ?? 'GRA';
    _locale = prefs.getString('locale') ?? 'fr';
    _darkMode = prefs.getBool('dark_mode') ?? true;
    _location = await _locationSvc.getSavedLocation();
    _loaded = true;
    notifyListeners();
  }

  Future<void> refreshGPSLocation() async {
    final loc = await _locationSvc.getCurrentLocation();
    if (loc != null) {
      _location = loc;
      await _locationSvc.saveLocation(loc);
      notifyListeners();
    }
  }

  Future<void> setManualLocation(LocationData location) async {
    _location = location;
    await _locationSvc.saveLocation(location);
    notifyListeners();
  }

  Future<void> setUseGPS(bool value) async {
    _useGPS = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('use_gps', value);
    notifyListeners();
    if (value) await refreshGPSLocation();
  }

  Future<void> setCalculationMethod(String method) async {
    _calculationMethod = method;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('calculation_method', method);
    notifyListeners();
  }

  Future<void> setLocale(String locale) async {
    _locale = locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('locale', locale);
    notifyListeners();
  }

  Future<void> setDarkMode(bool value) async {
    _darkMode = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dark_mode', value);
    notifyListeners();
  }
}
