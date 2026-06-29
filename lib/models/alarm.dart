import 'zman_type.dart';
import 'alarm_sound.dart';

class Alarm {
  final int? id;
  final String name;
  final ZmanType zmanType;
  final int offsetMinutes; // negative = avant, positive = après
  final List<int> daysOfWeek; // 1=Lun, 2=Mar, ..., 7=Dim (ISO 8601)
  final bool isEnabled;
  final int snoozeDuration; // minutes, 0 = pas de snooze
  final bool vibrate;
  final AlarmSound sound;
  final int ringDurationSeconds; // 0 = jusqu'à désactivation manuelle
  final String? customSoundPath; // chemin absolu vers un fichier audio sur l'appareil
  final DateTime? createdAt;

  const Alarm({
    this.id,
    required this.name,
    required this.zmanType,
    this.offsetMinutes = 0,
    required this.daysOfWeek,
    this.isEnabled = true,
    this.snoozeDuration = 5,
    this.vibrate = true,
    this.sound = AlarmSound.system,
    this.ringDurationSeconds = 0,
    this.customSoundPath,
    this.createdAt,
  });

  Alarm copyWith({
    int? id,
    String? name,
    ZmanType? zmanType,
    int? offsetMinutes,
    List<int>? daysOfWeek,
    bool? isEnabled,
    int? snoozeDuration,
    bool? vibrate,
    AlarmSound? sound,
    int? ringDurationSeconds,
    String? customSoundPath,
    bool clearCustomSoundPath = false,
  }) {
    return Alarm(
      id: id ?? this.id,
      name: name ?? this.name,
      zmanType: zmanType ?? this.zmanType,
      offsetMinutes: offsetMinutes ?? this.offsetMinutes,
      daysOfWeek: daysOfWeek ?? this.daysOfWeek,
      isEnabled: isEnabled ?? this.isEnabled,
      snoozeDuration: snoozeDuration ?? this.snoozeDuration,
      vibrate: vibrate ?? this.vibrate,
      sound: sound ?? this.sound,
      ringDurationSeconds: ringDurationSeconds ?? this.ringDurationSeconds,
      customSoundPath: clearCustomSoundPath ? null : (customSoundPath ?? this.customSoundPath),
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'zman_type': zmanType.name,
      'offset_minutes': offsetMinutes,
      'days_of_week': daysOfWeek.join(','),
      'is_enabled': isEnabled ? 1 : 0,
      'snooze_duration': snoozeDuration,
      'vibrate': vibrate ? 1 : 0,
      'sound_key': sound.name,
      'ring_duration_seconds': ringDurationSeconds,
      'custom_sound_path': customSoundPath,
      'created_at': (createdAt ?? DateTime.now()).millisecondsSinceEpoch,
    };
  }

  factory Alarm.fromMap(Map<String, dynamic> map) {
    return Alarm(
      id: map['id'] as int?,
      name: map['name'] as String,
      zmanType: ZmanType.values.firstWhere(
        (e) => e.name == map['zman_type'],
        orElse: () => ZmanType.netzHachamah,
      ),
      offsetMinutes: map['offset_minutes'] as int,
      daysOfWeek: (map['days_of_week'] as String).split(',').map(int.parse).toList(),
      isEnabled: (map['is_enabled'] as int) == 1,
      snoozeDuration: map['snooze_duration'] as int,
      vibrate: (map['vibrate'] as int) == 1,
      sound: AlarmSound.values.firstWhere(
        (e) => e.name == (map['sound_key'] as String? ?? 'system'),
        orElse: () => AlarmSound.system,
      ),
      ringDurationSeconds: map['ring_duration_seconds'] as int? ?? 0,
      customSoundPath: map['custom_sound_path'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
    );
  }

  String get offsetDescription {
    if (offsetMinutes == 0) return 'Exactement';
    final abs = offsetMinutes.abs();
    final h = abs ~/ 60;
    final m = abs % 60;
    final timeStr = h > 0
        ? (m > 0 ? '${h}h${m.toString().padLeft(2, '0')}' : '${h}h')
        : '$m min';
    return offsetMinutes < 0 ? '$timeStr avant' : '$timeStr après';
  }

  String get daysDescription {
    if (daysOfWeek.length == 7) return 'Tous les jours';
    const dayNames = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
    final sorted = List<int>.from(daysOfWeek)..sort();
    return sorted.map((d) => dayNames[d - 1]).join(', ');
  }

  String get ringDurationDescription {
    if (ringDurationSeconds == 0) return "Jusqu'à désactivation";
    final m = ringDurationSeconds ~/ 60;
    final s = ringDurationSeconds % 60;
    if (m == 0) return '$s sec';
    if (s == 0) return '$m min';
    return '$m min $s sec';
  }

  bool get isEveryDay => daysOfWeek.length == 7;
}
