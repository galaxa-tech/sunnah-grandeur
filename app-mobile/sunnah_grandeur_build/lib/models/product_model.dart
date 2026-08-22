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
    this.badge,
    this.fragrance,
    this.volumeMl,
  });

  // ── Computed display helpers ───────────────────────────────────────────────

  /// Price in dollars for calculations and display.
  double get price => priceInCents / 100;

  /// Formatted price string, e.g. "$24.99".
  String get priceDisplay => '\$${price.toStringAsFixed(2)}';

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
                       map['images'] ?? (map['imagePath'] != null ? [map['imagePath']] : []),
                     ),
      sku:           (map['sku']          ?? '')             as String,
      stockQuantity: (map['stockQuantity'] ?? map['stock'] ?? 0) as int,
      isActive:      (map['isActive']     ?? true)           as bool,
      badge:          map['badge']     as String?,
      fragrance:      map['fragrance'] as String?,
      volumeMl:      (map['volumeMl']  as num?)?.toDouble(),
    );
  }

  factory ProductModel.fromDoc(DocumentSnapshot doc) =>
      ProductModel.fromMap(doc.data()! as Map<String, dynamic>, doc.id);

  Map<String, dynamic> toMap() => {
    'name':          name,
    'category':      category,
    'description':   description,
    'priceInCents':  priceInCents,
    'images':        images,
    'sku':           sku,
    'stockQuantity': stockQuantity,
    'isActive':      isActive,
    if (badge     != null) 'badge':     badge,
    if (fragrance != null) 'fragrance': fragrance,
    if (volumeMl  != null) 'volumeMl':  volumeMl,
  };
}
