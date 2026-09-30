import 'package:flutter_test/flutter_test.dart';
import 'package:sunnah_grandeur/utils/hijri_converter.dart';
import 'package:sunnah_grandeur/services/quran_api_service.dart';

void main() {
  group('HijriDate (Umm al-Qura)', () {
    test('1 Ramadan 1447 is 18 Feb 2026', () {
      final h = HijriDate.fromGregorian(DateTime(2026, 2, 18));
      expect([h.year, h.month, h.day], [1447, 9, 1]);
    });

    test('round-trips Gregorian -> Hijri -> Gregorian', () {
      for (var d = DateTime(2025, 1, 1); d.isBefore(DateTime(2027, 1, 1)); d = d.add(const Duration(days: 17))) {
        final back = HijriDate.fromGregorian(d).toGregorian();
        expect(back, DateTime(d.year, d.month, d.day));
      }
    });

    test('months are 29 or 30 days', () {
      for (var m = 1; m <= 12; m++) {
        expect([29, 30], contains(HijriDate.daysInMonth(1447, m)));
      }
    });
  });

  test('stripBismillah removes the 4-word prefix only', () {
    const ayah = 'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ الٓمٓ';
    expect(QuranApiService.stripBismillah(ayah), 'الٓمٓ');
    expect(QuranApiService.stripBismillah('الٓمٓ'), 'الٓمٓ');
  });
}
