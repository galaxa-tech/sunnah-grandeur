import 'package:cloud_firestore/cloud_firestore.dart';

class ProductModel {
  final String        id;
  final String        name;
  final String        category;
  final String        description;
  final int           priceInCents;   // always integer cents — never float dollars
  final List<String>  images;
  final String        sku;
  final int           stockQuantity;
  final bool          isActive;
  final String        categoryId;
  final int?          originalPriceInCents;
  final bool          isFeatured;
  final String?       badge;
  final String?       fragrance;
  final double?       volumeMl;

  const ProductModel({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.priceInCents,
    required this.images,
    required this.sku,
    required this.stockQuantity,
    required this.isActive,
    this.categoryId = '',
    this.originalPriceInCents,
    this.isFeatured = false,
    this.badge,
    this.fragrance,
    this.volumeMl,
  });

  // ── Computed display helpers ───────────────────────────────────────────────

  /// Price in dollars for calculations and display.
  double get price => priceInCents / 100;

  /// Formatted price string, e.g. "$24.99".
  String get priceDisplay => '\$${price.toStringAsFixed(2)}';

  double? get originalPrice =>
      originalPriceInCents == null ? null : originalPriceInCents! / 100;

  String? get originalPriceDisplay =>
      originalPrice == null ? null : '\$${originalPrice!.toStringAsFixed(2)}';

  /// Primary image URL. Falls back to empty string if no images.
  String get primaryImage => images.isNotEmpty ? images.first : '';

  /// Legacy alias — screens still referencing .stock continue to work.
  int get stock => stockQuantity;

  // ── Serialisation ─────────────────────────────────────────────────────────

  factory ProductModel.fromMap(Map<String, dynamic> map, String docId) {
    // Accept both new schema (priceInCents) and legacy float price field
    final int parsedPrice = map['priceInCents'] is int
        ? map['priceInCents'] as int
        : (((map['price'] ?? map['priceInCents'] ?? 0) as num).toDouble() * 100).round();

    return ProductModel(
      id:            docId,
      name:          (map['name']  ?? map['title'] ?? '')   as String,
      category:      (map['category']    ?? '')              as String,
      description:   (map['description'] ?? '')              as String,
      priceInCents:  parsedPrice,
      images:        List<String>.from(
                       map['images'] ??
                           (map['imageUrl'] != null
                               ? [map['imageUrl']]
                               : map['image'] != null
                                   ? [map['image']]
                                   : map['imagePath'] != null
                                       ? [map['imagePath']]
                                       : []),
                     ),
      sku:           (map['sku']          ?? '')             as String,
      stockQuantity: ((map['stockQuantity'] ?? map['stock'] ?? 0) as num).toInt(),
      isActive:      (map['isActive']     ?? true)           as bool,
      categoryId:     _slug(map['categoryId'] ?? map['categorySlug'] ?? map['category'] ?? ''),
      originalPriceInCents: map['originalPriceInCents'] is num
          ? (map['originalPriceInCents'] as num).toInt()
          : map['originalPrice'] == null
              ? null
              : ((map['originalPrice'] as num).toDouble() * 100).round(),
      isFeatured:     (map['isFeatured'] ?? map['featured'] ?? false) as bool,
      badge:          map['badge']     as String?,
      fragrance:      map['fragrance'] as String?,
      volumeMl:      (map['volumeMl']  as num?)?.toDouble(),
    );
  }

  factory ProductModel.fromDoc(DocumentSnapshot doc) =>
      ProductModel.fromMap(doc.data()! as Map<String, dynamic>, doc.id);

  static String _slug(Object value) {
    return value
        .toString()
        .toLowerCase()
        .replaceAll('&', '')
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
  }

  Map<String, dynamic> toMap() => {
    'name':          name,
    'category':      category,
    'description':   description,
    'priceInCents':  priceInCents,
    'images':        images,
    'sku':           sku,
    'stockQuantity': stockQuantity,
    'isActive':      isActive,
    'categoryId':     categoryId,
    if (originalPriceInCents != null) 'originalPriceInCents': originalPriceInCents,
    'isFeatured':     isFeatured,
    if (badge     != null) 'badge':     badge,
    if (fragrance != null) 'fragrance': fragrance,
    if (volumeMl  != null) 'volumeMl':  volumeMl,
  };
}
