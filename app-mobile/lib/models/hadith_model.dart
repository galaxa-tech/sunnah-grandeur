import 'package:cloud_firestore/cloud_firestore.dart';

class HadithModel {
  final String id;
  final String title;
  final String content;
  final String source;
  final DateTime createdAt;

  // Sihah Sittah fields
  final String book;
  final String chapter;
  final int hadithNumber;
  final String textEn;
  final String textAr;
  final String textBn;
  final int globalIndex;

  HadithModel({
    required this.id,
    required this.title,
    required this.content,
    required this.source,
    required this.createdAt,
    this.book = '',
    this.chapter = '',
    this.hadithNumber = 0,
    this.textEn = '',
    this.textAr = '',
    this.textBn = '',
    this.globalIndex = 0,
  });

  factory HadithModel.fromMap(Map<String, dynamic> map, String docId) {
    return HadithModel(
      id: docId,
      title: map['title'] ?? map['textEn'] ?? '',
      content: map['content'] ?? map['textEn'] ?? '',
      source: map['source'] ?? map['book'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      book: map['book'] ?? '',
      chapter: map['chapter'] ?? '',
      hadithNumber: (map['hadithNumber'] as num?)?.toInt() ?? 0,
      textEn: map['textEn'] ?? map['content'] ?? '',
      textAr: map['textAr'] ?? '',
      textBn: map['textBn'] ?? '',
      globalIndex: (map['globalIndex'] as num?)?.toInt() ?? 0,
    );
  }

  String get displayText => textEn.isNotEmpty ? textEn : content;
  String get displaySource {
    if (book.isNotEmpty && hadithNumber > 0) return '$book #$hadithNumber';
    return source;
  }
}
