class HebrewDate {
  final int year;
  final int month;
  final int day;
  final bool isLeapYear;

  const HebrewDate({
    required this.year,
    required this.month,
    required this.day,
    required this.isLeapYear,
  });

  String get dayStr => HebrewDateService._toGematria(day);
  String get monthStr => HebrewDateService._monthName(month, isLeapYear);
  String get yearStr => HebrewDateService._toGematria(year % 1000);

  String get formatted => '$dayStr $monthStr $yearStr';
}

class HebrewDateService {
  // JDN of 1 Tishrei 1 AM (Hebrew epoch)
  static const int _epoch = 347998;

  static bool _isLeap(int year) => (7 * year + 1) % 19 < 7;

  static int _elapsedDays(int year) {
    final mo = 235 * ((year - 1) ~/ 19) +
        12 * ((year - 1) % 19) +
        (7 * ((year - 1) % 19) + 1) ~/ 19;
    final parts = 204 + 793 * (mo % 1080);
    final hours = 5 + 12 * mo + 793 * (mo ~/ 1080) + parts ~/ 1080;
    final conjDay = 1 + 29 * mo + hours ~/ 24;
    final conjParts = 1080 * (hours % 24) + parts % 1080;
    if (conjParts >= 19440 ||
        (conjDay % 7 == 2 && conjParts >= 9924 && !_isLeap(year)) ||
        (conjDay % 7 == 1 && conjParts >= 16789 && _isLeap(year - 1))) {
      return conjDay + 1;
    }
    return conjDay;
  }

  static int _newYear(int year) {
    int ny = _elapsedDays(year);
    if (ny % 7 == 0 || ny % 7 == 3 || ny % 7 == 5) ny++;
    return ny;
  }

  static int _yearLength(int year) => _newYear(year + 1) - _newYear(year);

  static int _daysInMonth(int month, int year) {
    if (month == 1) return 30; // Tishrei
    if (month == 2) return _yearLength(year) % 10 == 5 ? 30 : 29; // Cheshvan
    if (month == 3) return _yearLength(year) % 10 == 3 ? 29 : 30; // Kislev
    if (month == 4) return 29; // Tevet
    if (month == 5) return 30; // Shevat
    if (month == 6) return _isLeap(year) ? 30 : 29; // Adar I / Adar
    if (month == 7 && _isLeap(year)) return 29; // Adar II (leap only)
    // Nisan through Elul: alternating 30/29 starting from Nisan
    final nisan = _isLeap(year) ? 8 : 7;
    return (month - nisan) % 2 == 0 ? 30 : 29;
  }

  static int _lastMonth(int year) => _isLeap(year) ? 13 : 12;

  // Julian Day Number from Gregorian date
  static int _gregorianToJdn(int year, int month, int day) {
    final a = (14 - month) ~/ 12;
    final y = year + 4800 - a;
    final m = month + 12 * a - 3;
    return day +
        (153 * m + 2) ~/ 5 +
        365 * y +
        y ~/ 4 -
        y ~/ 100 +
        y ~/ 400 -
        32045;
  }

  // JDN for 1 Tishrei of the given Hebrew year
  static int _newYearJdn(int year) => _epoch + _newYear(year) - 1;

  static HebrewDate fromGregorian(DateTime date) {
    final jdn = _gregorianToJdn(date.year, date.month, date.day);

    // Approximate year, then converge
    int year = (jdn - _epoch) ~/ 365 + 1;
    while (_newYearJdn(year + 1) <= jdn) year++;
    while (_newYearJdn(year) > jdn) year--;

    // Find month by accumulating day counts
    int remaining = jdn - _newYearJdn(year) + 1; // 1-indexed day in year
    int month = 1;
    while (month < _lastMonth(year)) {
      final dim = _daysInMonth(month, year);
      if (remaining <= dim) break;
      remaining -= dim;
      month++;
    }

    return HebrewDate(
      year: year,
      month: month,
      day: remaining,
      isLeapYear: _isLeap(year),
    );
  }

  static String _toGematria(int num) {
    if (num <= 0) return '';
    const units = ['', 'א', 'ב', 'ג', 'ד', 'ה', 'ו', 'ז', 'ח', 'ט'];
    const tens = ['', 'י', 'כ', 'ל', 'מ', 'נ', 'ס', 'ע', 'פ', 'צ'];
    const hundreds = ['', 'ק', 'ר', 'ש', 'ת', 'תק', 'תר', 'תש', 'תת', 'תתק'];

    final buf = StringBuffer();
    int remaining = num;

    // Thousands (rare: years 1000-6999)
    if (remaining >= 1000) {
      buf.write(units[remaining ~/ 1000]);
      remaining %= 1000;
    }

    // Hundreds
    while (remaining >= 100) {
      final h = (remaining ~/ 100).clamp(1, 9);
      buf.write(hundreds[h]);
      remaining -= h * 100;
    }

    // Special cases to avoid writing God's name
    if (remaining == 15) {
      buf.write('טו');
      remaining = 0;
    } else if (remaining == 16) {
      buf.write('טז');
      remaining = 0;
    } else {
      if (remaining >= 10) {
        buf.write(tens[remaining ~/ 10]);
        remaining %= 10;
      }
      if (remaining > 0) buf.write(units[remaining]);
    }

    final s = buf.toString();
    if (s.isEmpty) return '';
    if (s.length == 1) return '$s׳';
    return '${s.substring(0, s.length - 1)}״${s[s.length - 1]}';
  }

  static String _monthName(int month, bool isLeap) {
    switch (month) {
      case 1:  return 'תשרי';
      case 2:  return 'חשוון';
      case 3:  return 'כסלו';
      case 4:  return 'טבת';
      case 5:  return 'שבט';
      case 6:  return isLeap ? 'אדר א׳' : 'אדר';
      case 7:  return isLeap ? 'אדר ב׳' : 'ניסן';
      case 8:  return isLeap ? 'ניסן' : 'אייר';
      case 9:  return isLeap ? 'אייר' : 'סיוון';
      case 10: return isLeap ? 'סיוון' : 'תמוז';
      case 11: return isLeap ? 'תמוז' : 'אב';
      case 12: return isLeap ? 'אב' : 'אלול';
      case 13: return 'אלול';
      default: return '';
    }
  }
}
