import 'package:flutter/foundation.dart';
import '../models/alarm.dart';
import '../services/database_service.dart';
import '../services/alarm_service.dart';
import '../services/location_service.dart';

class AlarmProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService.instance;
  final AlarmService _alarmSvc = AlarmService.instance;
  final LocationService _locationSvc = LocationService();

  List<Alarm> _alarms = [];
  bool _loading = false;
  String? _error;

  List<Alarm> get alarms => List.unmodifiable(_alarms);
  bool get loading => _loading;
  String? get error => _error;

  Future<void> loadAlarms() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _alarms = await _db.getAllAlarms();
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> addAlarm(Alarm alarm) async {
    final id = await _db.insertAlarm(alarm);
    final saved = alarm.copyWith(id: id);
    _alarms.add(saved);
    notifyListeners();
    await _reschedule(saved);
  }

  Future<void> updateAlarm(Alarm alarm) async {
    await _db.updateAlarm(alarm);
    final idx = _alarms.indexWhere((a) => a.id == alarm.id);
    if (idx >= 0) {
      _alarms[idx] = alarm;
      notifyListeners();
    }
    await _reschedule(alarm);
  }

  Future<void> deleteAlarm(Alarm alarm) async {
    if (alarm.id == null) return;
    await _db.deleteAlarm(alarm.id!);
    await _alarmSvc.cancelAlarm(alarm.id!);
    _alarms.removeWhere((a) => a.id == alarm.id);
    notifyListeners();
  }

  Future<void> toggleAlarm(Alarm alarm) async {
    final updated = alarm.copyWith(isEnabled: !alarm.isEnabled);
    await updateAlarm(updated);
  }

  Future<void> rescheduleAll() async {
    final location = await _locationSvc.getSavedLocation();
    await _alarmSvc.scheduleAll(_alarms, location);
  }

  Future<void> _reschedule(Alarm alarm) async {
    final location = await _locationSvc.getSavedLocation();
    await _alarmSvc.scheduleAlarm(alarm, location);
  }

  List<Alarm> get enabledAlarms =>
      _alarms.where((a) => a.isEnabled).toList();

  int get activeCount => enabledAlarms.length;
}
