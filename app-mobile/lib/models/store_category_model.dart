import 'package:flutter/material.dart';

class StoreCategoryModel {
  const StoreCategoryModel({
    required this.id,
    required this.name,
    required this.iconKey,
    required this.accentColor,
    required this.sortOrder,
    this.featuredImage,
  });

  final String id;
  final String name;
  final String iconKey;
  final Color accentColor;
  final int sortOrder;
  final String? featuredImage;

  factory StoreCategoryModel.fromMap(Map<String, dynamic> map, String docId) {
    return StoreCategoryModel(
      id: _slug(map['id'] ?? docId),
      name: (map['name'] ?? docId).toString(),
      iconKey: (map['icon'] ?? map['iconKey'] ?? 'storefront').toString(),
      accentColor: _parseColor(map['accentColor']),
      sortOrder: ((map['sortOrder'] ?? map['order'] ?? 999) as num).toInt(),
      featuredImage: map['featuredImage'] as String?,
    );
  }

  static Color _parseColor(dynamic value) {
    if (value is int) return Color(value);
    if (value is String) {
      final hex = value.replaceAll('#', '').replaceAll('0x', '');
      final parsed = int.tryParse(hex.length == 6 ? 'FF$hex' : hex, radix: 16);
      if (parsed != null) return Color(parsed);
    }
    return const Color(0xFFC9A84C);
  }

  static String _slug(Object value) {
    return value
        .toString()
        .toLowerCase()
        .replaceAll('&', '')
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
  }
}

class StoreBannerModel {
  const StoreBannerModel({
    required this.id,
    required this.title,
    required this.subtitle,
    this.imageUrl,
    this.cta = 'Shop now',
  });

  final String id;
  final String title;
  final String subtitle;
  final String? imageUrl;
  final String cta;

  factory StoreBannerModel.fromMap(Map<String, dynamic> map, String docId) {
    return StoreBannerModel(
      id: docId,
      title: (map['title'] ?? 'Premium Islamic Lifestyle').toString(),
      subtitle: (map['subtitle'] ?? map['description'] ?? 'Curated goods for the modern ummah').toString(),
      imageUrl: map['imageUrl'] ?? map['image'],
      cta: (map['cta'] ?? 'Shop now').toString(),
    );
  }
}
