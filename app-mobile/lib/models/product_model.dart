import 'package:cloud_firestore/cloud_firestore.dart';

// The admin panel's product form is labeled "Price (BDT)" and writes a plain
// decimal `price` field as Bangladeshi Taka (e.g. 550 meaning ৳550) — not
// already-USD dollars. The actual rate lives in Firestore
// (`settings/app_config.usdToLocalRate`, streamed by StoreProvider) so this,
// the admin panel, and the backend all read the SAME value at runtime
// instead of each hardcoding an independent copy that can silently drift.
// kDefaultBdtToUsdRate is only the fallback used before that doc loads.
// TODO: remove once the admin panel stores real USD prices directly.
const double kDefaultBdtToUsdRate = 1 / 118;

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

  factory ProductModel.fromMap(
    Map<String, dynamic> map,
    String docId, {
    double usdToLocalRate = kDefaultBdtToUsdRate,
  }) {
    // Every real product document carries BOTH fields today: `price` (the
    // BDT number the admin actually typed) and `priceInCents` (just that
    // same number × 100 — BDT paisa, NOT USD cents, despite the name). The
    // website and the order backend both read `price` first for exactly
    // this reason; this must match or the same product prices differently
    // on each surface. Only fall back to treating `priceInCents` as real
    // USD cents when `price` is absent (a product saved with real USD
    // pricing directly, once the admin panel is updated to do that).
    final int parsedPrice = map['price'] is num
        ? ((map['price'] as num).toDouble() * usdToLocalRate * 100).round()
        : (map['priceInCents'] is num ? (map['priceInCents'] as num).toInt() : 0);

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
      originalPriceInCents: map['originalPrice'] is num
          ? ((map['originalPrice'] as num).toDouble() * usdToLocalRate * 100).round()
          : (map['originalPriceInCents'] is num ? (map['originalPriceInCents'] as num).toInt() : null),
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
