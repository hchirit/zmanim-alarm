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
  final String? customSoundPath;
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

  String offsetDescription([String locale = 'fr']) {
    if (offsetMinutes == 0) {
      switch (locale) {
        case 'en': return 'Exactly';
        case 'he': return 'בדיוק';
        default: return 'Exactement';
      }
    }
    final abs = offsetMinutes.abs();
    final h = abs ~/ 60;
    final m = abs % 60;
    final String timeStr;
    if (locale == 'he') {
      final hPart = h > 0 ? '${h}ש\' ' : '';
      final mPart = m > 0 ? '${m}ד\'' : '';
      timeStr = '$hPart$mPart'.trim();
    } else {
      timeStr = h > 0
          ? (m > 0 ? '${h}h${m.toString().padLeft(2, '0')}' : '${h}h')
          : '$m min';
    }
    final before = locale == 'en' ? 'before' : locale == 'he' ? 'לפני' : 'avant';
    final after  = locale == 'en' ? 'after'  : locale == 'he' ? 'אחרי'  : 'après';
    return offsetMinutes < 0 ? '$timeStr $before' : '$timeStr $after';
  }

  String daysDescription([String locale = 'fr']) {
    if (daysOfWeek.length == 7) {
      switch (locale) {
        case 'en': return 'Every day';
        case 'he': return 'כל יום';
        default: return 'Tous les jours';
      }
    }
    final List<String> names;
    switch (locale) {
      case 'he':
        names = ['שני', 'שלישי', 'רביעי', 'חמישי', 'שישי', 'שבת', 'ראשון'];
        break;
      case 'en':
        names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        break;
      default:
        names = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
    }
    final sorted = List<int>.from(daysOfWeek)..sort();
    return sorted.map((d) => names[d - 1]).join(', ');
  }

  String ringDurationDescription([String locale = 'fr']) {
    if (ringDurationSeconds == 0) {
      switch (locale) {
        case 'en': return 'Until dismissed';
        case 'he': return 'עד כיבוי';
        default: return "Jusqu'à désactivation";
      }
    }
    final m = ringDurationSeconds ~/ 60;
    final s = ringDurationSeconds % 60;
    if (locale == 'he') {
      if (m == 0) return '$s ש\'';
      if (s == 0) return '$m ד\'';
      return '$m ד\' $s ש\'';
    }
    if (m == 0) return '$s sec';
    if (s == 0) return '$m min';
    return '$m min $s sec';
  }

  bool get isEveryDay => daysOfWeek.length == 7;
}
