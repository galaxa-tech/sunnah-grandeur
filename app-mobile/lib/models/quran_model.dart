/// Lightweight metadata for one of the 114 surahs, as returned by
/// GET https://api.alquran.cloud/v1/surah
class SurahMeta {
  final int number;
  final String name;                 // Arabic name, e.g. "سُورَةُ ٱلْفَاتِحَةِ"
  final String englishName;          // e.g. "Al-Faatiha"
  final String englishNameTranslation; // e.g. "The Opening"
  final int numberOfAyahs;
  final String revelationType;       // "Meccan" | "Medinan"

  const SurahMeta({
    required this.number,
    required this.name,
    required this.englishName,
    required this.englishNameTranslation,
    required this.numberOfAyahs,
    required this.revelationType,
  });

  factory SurahMeta.fromJson(Map<String, dynamic> json) => SurahMeta(
        number: json['number'] as int,
        name: json['name'] as String? ?? '',
        englishName: json['englishName'] as String? ?? '',
        englishNameTranslation:
            json['englishNameTranslation'] as String? ?? '',
        numberOfAyahs: json['numberOfAyahs'] as int? ?? 0,
        revelationType: json['revelationType'] as String? ?? '',
      );
}

/// A single ayah paired with its Arabic text and English translation.
class Ayah {
  final int numberInSurah;
  final String arabicText;
  final String translationText;

  const Ayah({
    required this.numberInSurah,
    required this.arabicText,
    required this.translationText,
  });
}

/// A fully-loaded surah: metadata plus every ayah paired with its
/// Arabic text and English (Sahih International) translation.
class SurahDetail {
  final SurahMeta meta;
  final List<Ayah> ayahs;

  const SurahDetail({required this.meta, required this.ayahs});
}
