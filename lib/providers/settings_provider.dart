import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/location_service.dart';
import '../services/zmanim_calculator.dart';

class SettingsProvider extends ChangeNotifier {
  final LocationService _locationSvc = LocationService();
  final Completer<void> _loadCompleter = Completer<void>();

  LocationData _location = LocationData.jerusalem;
  bool _useGPS = true;
  String _calculationMethod = 'GRA';
  String _locale = 'fr';
  bool _darkMode = true;
  bool _loaded = false;
  ZmanimCalculator? _calculator;

  LocationData get location => _location;
  bool get useGPS => _useGPS;
  String get calculationMethod => _calculationMethod;
  String get locale => _locale;
  bool get darkMode => _darkMode;
  bool get loaded => _loaded;

  /// Se complète une seule fois quand [load] termine.
  Future<void> get loadFuture => _loadCompleter.future;

  /// Calculateur mis en cache, invalidé à chaque changement de localisation.
  ZmanimCalculator get calculator => _calculator ??= ZmanimCalculator(
        latitude: _location.latitude,
        longitude: _location.longitude,
        elevation: _location.elevation,
      );

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _useGPS = prefs.getBool('use_gps') ?? true;
    _calculationMethod = prefs.getString('calculation_method') ?? 'GRA';
    _locale = prefs.getString('locale') ?? 'fr';
    _darkMode = prefs.getBool('dark_mode') ?? true;
    _location = await _locationSvc.getSavedLocation();
    _loaded = true;
    _calculator = null;
    if (!_loadCompleter.isCompleted) _loadCompleter.complete();
    notifyListeners();
  }

  Future<void> refreshGPSLocation() async {
    final loc = await _locationSvc.getCurrentLocation();
    if (loc != null) {
      _location = loc;
      _calculator = null;
      await _locationSvc.saveLocation(loc);
      notifyListeners();
    }
  }

  Future<void> setManualLocation(LocationData location) async {
    _location = location;
    _calculator = null;
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
