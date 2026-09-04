// ─────────────────────────────────────────────────────────────────────────
// hijri_converter.dart
//
// Pure-Dart Gregorian <-> Hijri (Islamic) date conversion.
//
// Algorithm: the "tabular Islamic calendar" (civil / arithmetic Hijri
// calendar) — a well-documented, public-domain arithmetic scheme (the
// same one used internally by PHP's islamictojd()/jdtoislamic(), ICU's
// "islamic-civil" calendar, and countless calendrical-calculation
// references). It approximates the lunar Hijri calendar with a fixed
// 30-year cycle containing 11 leap years (each leap year's 12th month,
// Dhu al-Hijjah, has 30 days instead of 29), so it does not require
// moon-sighting data or astronomical tables. Real-world moon-sighting
// announcements (and the Umm al-Qura calendar) can differ by a day or
// two from this tabular result — which is expected and normal for any
// arithmetic Hijri calendar.
//
// No external packages are used — everything below is Julian Day Number
// (JDN) arithmetic implemented directly.
// ─────────────────────────────────────────────────────────────────────────

/// Julian Day Number for the first day of the Islamic calendar
/// (1 Muharram, AH 1) under the civil/tabular epoch convention.
const int _islamicEpochJdn = 1948440;

/// English names for the 12 Hijri months.
const List<String> hijriMonthNames = [
  'Muharram',
  'Safar',
  "Rabi' al-Awwal",
  "Rabi' al-Thani",
  'Jumada al-Awwal',
  'Jumada al-Thani',
  'Rajab',
  "Sha'ban",
  'Ramadan',
  'Shawwal',
  "Dhu al-Qi'dah",
  'Dhu al-Hijjah',
];

/// Short weekday labels (Sunday-first, matching DateTime.weekday % 7 order
/// used by the calendar grid).
const List<String> weekdayShortLabels = [
  'Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat',
];

int _ceilDiv29p5(int months) {
  // ceil(29.5 * months) computed with integer arithmetic to avoid any
  // floating-point rounding surprises: 29.5 * months == (59 * months) / 2.
  final numerator = 59 * months;
  return (numerator + 1) ~/ 2; // ceil for non-negative numerator
}

/// Converts a proleptic Gregorian calendar date to a Julian Day Number.
/// Standard Fliegel & Van Flandern integer algorithm.
int gregorianToJdn(int year, int month, int day) {
  final a = (14 - month) ~/ 12;
  final y = year + 4800 - a;
  final m = month + 12 * a - 3;
  return day +
      ((153 * m + 2) ~/ 5) +
      365 * y +
      (y ~/ 4) -
      (y ~/ 100) +
      (y ~/ 400) -
      32045;
}

/// Converts a Julian Day Number back to a proleptic Gregorian calendar date.
/// Returns (year, month, day).
(int, int, int) jdnToGregorian(int jdn) {
  final a = jdn + 32044;
  final b = (4 * a + 3) ~/ 146097;
  final c = a - (146097 * b) ~/ 4;
  final d = (4 * c + 3) ~/ 1461;
  final e = c - (1461 * d) ~/ 4;
  final m = (5 * e + 2) ~/ 153;
  final day = e - (153 * m + 2) ~/ 5 + 1;
  final month = m + 3 - 12 * (m ~/ 10);
  final year = 100 * b + d - 4800 + (m ~/ 10);
  return (year, month, day);
}

/// Converts a Hijri (Islamic tabular calendar) date to a Julian Day Number.
int islamicToJdn(int year, int month, int day) {
  return day +
      _ceilDiv29p5(month - 1) +
      (year - 1) * 354 +
      ((3 + 11 * year) ~/ 30) +
      _islamicEpochJdn -
      1;
}

/// Converts a Julian Day Number to a Hijri (Islamic tabular calendar) date.
/// Returns (year, month, day).
(int, int, int) jdnToIslamic(int jdn) {
  final year = ((30 * (jdn - _islamicEpochJdn) + 10646) / 10631).floor();
  final monthUpper =
      ((jdn - (29 + islamicToJdn(year, 1, 1))) / 29.5).ceil() + 1;
  final month = monthUpper > 12 ? 12 : monthUpper;
  final day = jdn - islamicToJdn(year, month, 1) + 1;
  return (year, month, day);
}

/// A simple Hijri calendar date value type with conversion helpers.
class HijriDate implements Comparable<HijriDate> {
  const HijriDate(this.year, this.month, this.day);

  final int year;
  final int month; // 1-12
  final int day; // 1-30

  /// Builds a [HijriDate] from a Gregorian [DateTime] (time-of-day ignored).
  factory HijriDate.fromGregorian(DateTime date) {
    final jdn = gregorianToJdn(date.year, date.month, date.day);
    final (y, m, d) = jdnToIslamic(jdn);
    return HijriDate(y, m, d);
  }

  /// Today's date, converted to Hijri.
  factory HijriDate.today() => HijriDate.fromGregorian(DateTime.now());

  /// Converts this Hijri date back to a Gregorian [DateTime] (midnight).
  DateTime toGregorian() {
    final jdn = islamicToJdn(year, month, day);
    final (y, m, d) = jdnToGregorian(jdn);
    return DateTime(y, m, d);
  }

  /// Number of days in [year]/[month] under the tabular calendar
  /// (29 or 30 — 30 in leap years for Dhu al-Hijjah, the 12th month).
  static int daysInMonth(int year, int month) {
    final thisMonthStart = islamicToJdn(year, month, 1);
    final int nextMonthStart;
    if (month >= 12) {
      nextMonthStart = islamicToJdn(year + 1, 1, 1);
    } else {
      nextMonthStart = islamicToJdn(year, month + 1, 1);
    }
    return nextMonthStart - thisMonthStart;
  }

  String get monthName => hijriMonthNames[month - 1];

  bool get isRamadan => month == 9;

  /// True for 1 Shawwal (Eid al-Fitr) or 10 Dhu al-Hijjah (Eid al-Adha).
  bool get isEid => (month == 10 && day == 1) || (month == 12 && day == 10);

  String? get eidLabel {
    if (month == 10 && day == 1) return 'Eid al-Fitr';
    if (month == 12 && day == 10) return 'Eid al-Adha';
    return null;
  }

  /// Returns a new [HijriDate] for the same day-of-month one month forward,
  /// clamped to the target month's length.
  HijriDate addMonths(int delta) {
    var totalMonths = (year * 12 + (month - 1)) + delta;
    final newYear = totalMonths ~/ 12;
    final newMonth = (totalMonths % 12) + 1;
    final maxDay = daysInMonth(newYear, newMonth);
    final newDay = day > maxDay ? maxDay : day;
    return HijriDate(newYear, newMonth, newDay);
  }

  bool isSameDay(HijriDate other) =>
      year == other.year && month == other.month && day == other.day;

  @override
  int compareTo(HijriDate other) {
    final jdn = islamicToJdn(year, month, day);
    final otherJdn = islamicToJdn(other.year, other.month, other.day);
    return jdn.compareTo(otherJdn);
  }

  @override
  bool operator ==(Object other) =>
      other is HijriDate && isSameDay(other);

  @override
  int get hashCode => Object.hash(year, month, day);

  @override
  String toString() => '$day $monthName $year AH';
}
