import 'dart:math';
import '../models/zman_type.dart';

class ZmanimCalculator {
  final double latitude;
  final double longitude;
  final double elevation; // metres

  const ZmanimCalculator({
    required this.latitude,
    required this.longitude,
    this.elevation = 0.0,
  });

  double _toRad(double deg) => deg * pi / 180.0;
  double _toDeg(double rad) => rad * 180.0 / pi;

  int _dayOfYear(DateTime date) {
    final start = DateTime.utc(date.year, 1, 1);
    final d = DateTime.utc(date.year, date.month, date.day);
    return d.difference(start).inDays + 1;
  }

  // Returns event time in decimal hours (UTC), or null if sun never rises/sets
  // zenith: 90.833 for standard sunrise/sunset
  double? _sunEvent(DateTime date, double zenith, bool isSunrise) {
    final int doy = _dayOfYear(date);
    final double longHour = longitude / 15.0;

    // Approximate time of event
    final double t = isSunrise
        ? doy + (6.0 - longHour) / 24.0
        : doy + (18.0 - longHour) / 24.0;

    // Sun's mean anomaly
    double M = (0.9856 * t) - 3.289;

    // Sun's true longitude
    double L = M + (1.916 * sin(_toRad(M))) + (0.020 * sin(_toRad(2 * M))) + 282.634;
    L = ((L % 360) + 360) % 360;

    // Sun's right ascension
    double RA = _toDeg(atan(0.91764 * tan(_toRad(L))));
    RA = ((RA % 360) + 360) % 360;

    // Quadrant correction
    final double Lq = (L / 90).floor() * 90;
    final double RAq = (RA / 90).floor() * 90;
    RA = (RA + (Lq - RAq)) / 15.0; // hours

    // Sun's declination
    final double sinDec = 0.39782 * sin(_toRad(L));
    final double cosDec = cos(asin(sinDec));

    // Elevation-adjusted zenith
    final double adjustedZenith = zenith - _toDeg(acos(1.0 / (1.0 + elevation / 6371000.0)));

    // Hour angle
    final double cosH = (cos(_toRad(adjustedZenith)) -
            sinDec * sin(_toRad(latitude))) /
        (cosDec * cos(_toRad(latitude)));

    if (cosH > 1.0) return null; // Sun never rises
    if (cosH < -1.0) return null; // Sun never sets

    double H = isSunrise
        ? (360.0 - _toDeg(acos(cosH))) / 15.0
        : _toDeg(acos(cosH)) / 15.0;

    // Local mean time
    double T = H + RA - (0.06571 * t) - 6.622;

    // UTC
    double UT = T - longHour;
    UT = ((UT % 24) + 24) % 24;
    return UT;
  }

  DateTime? _utcToLocal(DateTime date, double? utcHours) {
    if (utcHours == null) return null;
    final h = utcHours.floor();
    final m = ((utcHours - h) * 60).round();
    final dt = DateTime.utc(date.year, date.month, date.day, h % 24, m);
    // Handle day overflow
    final adjusted = h >= 24
        ? dt.add(const Duration(days: 1))
        : h < 0
            ? dt.subtract(const Duration(days: 1))
            : dt;
    return adjusted.toLocal();
  }

  // Sunrise (Netz HaChamah) — 90.833° (refraction + sun diameter)
  DateTime? getNetz(DateTime date) =>
      _utcToLocal(date, _sunEvent(date, 90.833, true));

  // Sunset (Shkiah)
  DateTime? getShkiah(DateTime date) =>
      _utcToLocal(date, _sunEvent(date, 90.833, false));

  // Alot HaShachar — 16.1° below horizon
  DateTime? getAlotHashachar(DateTime date) =>
      _utcToLocal(date, _sunEvent(date, 106.1, true));

  // Misheyakir — 11.5° below horizon (common opinion)
  DateTime? getMisheyakir(DateTime date) =>
      _utcToLocal(date, _sunEvent(date, 101.5, true));

  // Tzait HaKochavim — 8.5° below horizon (3 stars)
  DateTime? getTzait(DateTime date) =>
      _utcToLocal(date, _sunEvent(date, 98.5, false));

  // Chatzot HaYom — solar noon (midpoint of day)
  DateTime? getChatzot(DateTime date) {
    final netz = _sunEvent(date, 90.833, true);
    final shkiah = _sunEvent(date, 90.833, false);
    if (netz == null || shkiah == null) return null;
    return _utcToLocal(date, (netz + shkiah) / 2.0);
  }

  // Shaah Zmanit GRA (sunrise→sunset divided by 12), in minutes
  double? _shaahGRA(DateTime date) {
    final netz = _sunEvent(date, 90.833, true);
    final shkiah = _sunEvent(date, 90.833, false);
    if (netz == null || shkiah == null) return null;
    return (shkiah - netz) * 60.0 / 12.0; // minutes
  }

  // Shaah Zmanit MGA (Alot72→Tzait72 divided by 12), in minutes
  double? _shaahMGA(DateTime date) {
    final alot = _sunEvent(date, 106.1, true);
    final shkiah = _sunEvent(date, 90.833, false);
    if (alot == null || shkiah == null) return null;
    final tzait72 = shkiah + 72.0 / 60.0;
    return (tzait72 - alot) * 60.0 / 12.0; // minutes
  }

  DateTime? _addMinutesToEvent(DateTime date, double? baseUtcHours, double minutes) {
    if (baseUtcHours == null) return null;
    return _utcToLocal(date, baseUtcHours + minutes / 60.0);
  }

  // Sof Zman Kriat Shema GRA — 3 Shaot from Netz
  DateTime? getSofZmanShmaGRA(DateTime date) {
    final netz = _sunEvent(date, 90.833, true);
    final shaah = _shaahGRA(date);
    if (netz == null || shaah == null) return null;
    return _addMinutesToEvent(date, netz, shaah * 3.0);
  }

  // Sof Zman Kriat Shema MGA — 3 Shaot from Alot
  DateTime? getSofZmanShmaMGA(DateTime date) {
    final alot = _sunEvent(date, 106.1, true);
    final shaah = _shaahMGA(date);
    if (alot == null || shaah == null) return null;
    return _addMinutesToEvent(date, alot, shaah * 3.0);
  }

  // Sof Zman Tefilla GRA — 4 Shaot from Netz
  DateTime? getSofZmanTefillaGRA(DateTime date) {
    final netz = _sunEvent(date, 90.833, true);
    final shaah = _shaahGRA(date);
    if (netz == null || shaah == null) return null;
    return _addMinutesToEvent(date, netz, shaah * 4.0);
  }

  // Sof Zman Tefilla MGA — 4 Shaot from Alot
  DateTime? getSofZmanTefillaMGA(DateTime date) {
    final alot = _sunEvent(date, 106.1, true);
    final shaah = _shaahMGA(date);
    if (alot == null || shaah == null) return null;
    return _addMinutesToEvent(date, alot, shaah * 4.0);
  }

  // Mincha Gedola — 6.5 Shaot from Netz (Chatzot + 30 min)
  DateTime? getMinchaGedola(DateTime date) {
    final netz = _sunEvent(date, 90.833, true);
    final shaah = _shaahGRA(date);
    if (netz == null || shaah == null) return null;
    return _addMinutesToEvent(date, netz, shaah * 6.5);
  }

  // Mincha Ketana — 9.5 Shaot from Netz
  DateTime? getMinchaKetana(DateTime date) {
    final netz = _sunEvent(date, 90.833, true);
    final shaah = _shaahGRA(date);
    if (netz == null || shaah == null) return null;
    return _addMinutesToEvent(date, netz, shaah * 9.5);
  }

  // Plag HaMincha — 10.75 Shaot from Netz
  DateTime? getPlagHamincha(DateTime date) {
    final netz = _sunEvent(date, 90.833, true);
    final shaah = _shaahGRA(date);
    if (netz == null || shaah == null) return null;
    return _addMinutesToEvent(date, netz, shaah * 10.75);
  }

  // Tzait 42 minutes after sunset
  DateTime? getTzait42(DateTime date) {
    final shkiah = _sunEvent(date, 90.833, false);
    if (shkiah == null) return null;
    return _addMinutesToEvent(date, shkiah, 42.0);
  }

  // Tzait Rabbenu Tam — 72 minutes after sunset
  DateTime? getTzaitRabbenuvTam(DateTime date) {
    final shkiah = _sunEvent(date, 90.833, false);
    if (shkiah == null) return null;
    return _addMinutesToEvent(date, shkiah, 72.0);
  }

  // Chatzot HaLayla — midpoint of the night (midway between sunset and next sunrise)
  DateTime? getChatzotLayla(DateTime date) {
    final shkiah = _sunEvent(date, 90.833, false);
    final tomorrow = date.add(const Duration(days: 1));
    final netzTomorrow = _sunEvent(tomorrow, 90.833, true);
    if (shkiah == null || netzTomorrow == null) return null;
    // netzTomorrow is in UTC hours of tomorrow, add 24 to get hours from today midnight
    final midnightUtc = (shkiah + (netzTomorrow + 24.0)) / 2.0;
    return _utcToLocal(date, midnightUtc);
  }

  DateTime? getZman(ZmanType type, DateTime date) {
    switch (type) {
      case ZmanType.alotHashachar:
        return getAlotHashachar(date);
      case ZmanType.misheyakir:
        return getMisheyakir(date);
      case ZmanType.netzHachamah:
        return getNetz(date);
      case ZmanType.sofZmanShmaGRA:
        return getSofZmanShmaGRA(date);
      case ZmanType.sofZmanShmaMGA:
        return getSofZmanShmaMGA(date);
      case ZmanType.sofZmanTefillaGRA:
        return getSofZmanTefillaGRA(date);
      case ZmanType.sofZmanTefillaMGA:
        return getSofZmanTefillaMGA(date);
      case ZmanType.chatzot:
        return getChatzot(date);
      case ZmanType.minchaGedola:
        return getMinchaGedola(date);
      case ZmanType.minchaKetana:
        return getMinchaKetana(date);
      case ZmanType.plagHamincha:
        return getPlagHamincha(date);
      case ZmanType.shkiah:
        return getShkiah(date);
      case ZmanType.tzait8_5:
        return getTzait(date);
      case ZmanType.tzait42:
        return getTzait42(date);
      case ZmanType.tzaitRabbenuvTam:
        return getTzaitRabbenuvTam(date);
      case ZmanType.chatzotLayla:
        return getChatzotLayla(date);
    }
  }

  Map<ZmanType, DateTime?> getAllZmanim(DateTime date) {
    return {
      for (final type in ZmanType.values) type: getZman(type, date),
    };
  }
}
