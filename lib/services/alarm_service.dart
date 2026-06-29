import 'package:alarm/alarm.dart' as alarm_pkg;
import 'package:flutter/widgets.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/alarm.dart';
import '../models/alarm_sound.dart';
import '../models/zman_type.dart';
import 'database_service.dart';
import 'zmanim_calculator.dart';
import 'location_service.dart';

class ActiveRingInfo {
  final alarm_pkg.AlarmSettings settings;
  final Alarm? alarm;
  ActiveRingInfo({required this.settings, this.alarm});
}

class AlarmService {
  static final AlarmService instance = AlarmService._internal();
  AlarmService._internal();

  bool _initialized = false;

  // Notifier global : l'AlarmScreen écoute ce notifier pour s'afficher/disparaître.
  // Réinitialiser à null pour fermer l'écran d'alarme.
  static final activeRing = ValueNotifier<ActiveRingInfo?>(null);

  Future<void> initialize() async {
    if (_initialized) return;
    await alarm_pkg.Alarm.init(showDebugLogs: false);
    alarm_pkg.Alarm.ringStream.stream.listen(_onAlarmRing);
    _initialized = true;
  }

  void _onAlarmRing(alarm_pkg.AlarmSettings ringing) async {
    final dbAlarmId = ringing.id ~/ 100;
    final dbAlarm = await DatabaseService.instance.getAlarm(dbAlarmId);
    activeRing.value = ActiveRingInfo(settings: ringing, alarm: dbAlarm);

    // Mécanisme de secours : arrêt garanti même si AlarmScreen n'est pas visible
    // (MIUI peut bloquer le full-screen intent — le Dart tourne en arrière-plan,
    // ce Future.delayed s'exécute quand même).
    final duration = dbAlarm?.ringDurationSeconds ?? 0;
    if (duration > 0) {
      Future.delayed(Duration(seconds: duration), () async {
        await alarm_pkg.Alarm.stop(ringing.id);
        if (activeRing.value?.settings.id == ringing.id) {
          activeRing.value = null;
        }
      });
    }
  }

  String _resolveAudioPath(Alarm alarm) {
    if (alarm.customSoundPath != null && alarm.customSoundPath!.isNotEmpty) {
      return alarm.customSoundPath!;
    }
    return alarm.sound.legacyAssetPath;
  }

  Future<bool> requestNotificationPermission() async {
    final status = await Permission.notification.request();
    return status.isGranted;
  }

  Future<bool> requestExactAlarmPermission() async {
    if (await Permission.scheduleExactAlarm.isDenied) {
      final status = await Permission.scheduleExactAlarm.request();
      return status.isGranted;
    }
    return true;
  }

  Future<void> requestBatteryExemption() async {
    await Permission.ignoreBatteryOptimizations.request();
  }

  Future<bool> canScheduleExactAlarms() async {
    return Permission.scheduleExactAlarm.isGranted;
  }

  Future<bool> isBatteryOptimizationDisabled() async {
    return Permission.ignoreBatteryOptimizations.isGranted;
  }

  Future<void> openExactAlarmSettings() async {
    await Permission.scheduleExactAlarm.request();
  }

  Future<void> scheduleAll(
    List<Alarm> alarms,
    LocationData location, {
    int daysAhead = 14,
  }) async {
    await alarm_pkg.Alarm.stopAll();

    final calculator = ZmanimCalculator(
      latitude: location.latitude,
      longitude: location.longitude,
      elevation: location.elevation,
    );

    final now = DateTime.now();

    for (final alarm in alarms) {
      if (!alarm.isEnabled || alarm.id == null) continue;

      for (int d = 0; d < daysAhead; d++) {
        final date = now.add(Duration(days: d));
        if (!alarm.daysOfWeek.contains(date.weekday)) continue;

        final zmanTime = calculator.getZman(alarm.zmanType, date);
        if (zmanTime == null) continue;

        final triggerTime = zmanTime.add(Duration(minutes: alarm.offsetMinutes));
        if (triggerTime.isBefore(now.add(const Duration(seconds: 5)))) continue;

        await _scheduleEntry(alarm, triggerTime, d);
      }
    }
  }

  Future<void> scheduleAlarm(
    Alarm alarm,
    LocationData location, {
    int daysAhead = 14,
  }) async {
    if (alarm.id == null) return;

    await cancelAlarm(alarm.id!, daysAhead: daysAhead);
    if (!alarm.isEnabled) return;

    final calculator = ZmanimCalculator(
      latitude: location.latitude,
      longitude: location.longitude,
      elevation: location.elevation,
    );

    final now = DateTime.now();

    for (int d = 0; d < daysAhead; d++) {
      final date = now.add(Duration(days: d));
      if (!alarm.daysOfWeek.contains(date.weekday)) continue;

      final zmanTime = calculator.getZman(alarm.zmanType, date);
      if (zmanTime == null) continue;

      final triggerTime = zmanTime.add(Duration(minutes: alarm.offsetMinutes));
      if (triggerTime.isBefore(now.add(const Duration(seconds: 5)))) continue;

      await _scheduleEntry(alarm, triggerTime, d);
    }
  }

  Future<void> _scheduleEntry(
      Alarm alarm, DateTime triggerTime, int dayIndex) async {
    final id = (alarm.id ?? 0) * 100 + dayIndex;
    final offsetDesc = alarm.offsetMinutes == 0
        ? alarm.zmanType.frenchName
        : '${alarm.offsetDescription()} ${alarm.zmanType.frenchName}';

    await alarm_pkg.Alarm.set(
      alarmSettings: alarm_pkg.AlarmSettings(
        id: id,
        dateTime: triggerTime,
        assetAudioPath: _resolveAudioPath(alarm),
        loopAudio: alarm.ringDurationSeconds == 0, // boucle seulement si durée illimitée
        vibrate: alarm.vibrate,
        volume: null,
        fadeDuration: 0,
        androidFullScreenIntent: true,
        notificationSettings: alarm_pkg.NotificationSettings(
          title: alarm.name,
          body: offsetDesc,
          stopButton: 'Arrêter',
          icon: 'mipmap/ic_launcher',
        ),
      ),
    );
  }

  Future<void> cancelAlarm(int alarmId, {int daysAhead = 14}) async {
    for (int i = 0; i < daysAhead; i++) {
      await alarm_pkg.Alarm.stop(alarmId * 100 + i);
    }
  }

  Future<void> cancelAll() async {
    await alarm_pkg.Alarm.stopAll();
  }

  Future<void> testAlarm(Alarm alarm) async {
    const testId = 999999;
    await alarm_pkg.Alarm.stop(testId);

    const delaySeconds = 5;
    final triggerTime = DateTime.now().add(const Duration(seconds: delaySeconds));
    final duration = alarm.ringDurationSeconds;

    await alarm_pkg.Alarm.set(
      alarmSettings: alarm_pkg.AlarmSettings(
        id: testId,
        dateTime: triggerTime,
        assetAudioPath: _resolveAudioPath(alarm),
        loopAudio: duration == 0,
        vibrate: alarm.vibrate,
        volume: null,
        fadeDuration: 0,
        androidFullScreenIntent: false,
        notificationSettings: alarm_pkg.NotificationSettings(
          title: '🔔 Test — ${alarm.name}',
          body: alarm.ringDurationDescription(),
          stopButton: 'Arrêter',
          icon: 'mipmap/ic_launcher',
        ),
      ),
    );

    if (duration > 0) {
      Future.delayed(Duration(seconds: delaySeconds + duration), () async {
        await alarm_pkg.Alarm.stop(testId);
        if (activeRing.value?.settings.id == testId) {
          activeRing.value = null;
        }
      });
    }
  }

  Future<List<alarm_pkg.AlarmSettings>> getPendingAlarms() async {
    return alarm_pkg.Alarm.getAlarms();
  }
}
