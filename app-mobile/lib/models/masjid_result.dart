/// Data model returned by the Google Places Nearby Search / Text Search APIs.
class MasjidResult {
  final String  placeId;
  final String  name;
  final String  vicinity;   // short address / vicinity
  final double  lat;
  final double  lng;
  final double? rating;
  final int?    userRatingsTotal;
  final bool?   openNow;
  final String? photoRef;   // Google Places photo_reference
  double?       distanceKm; // populated after position is known

  MasjidResult({
    required this.placeId,
    required this.name,
    required this.vicinity,
    required this.lat,
    required this.lng,
    this.rating,
    this.userRatingsTotal,
    this.openNow,
    this.photoRef,
    this.distanceKm,
  });

  factory MasjidResult.fromJson(Map<String, dynamic> json) {
    final loc     = json['geometry']['location'] as Map<String, dynamic>;
    final hours   = json['opening_hours']        as Map<String, dynamic>?;
    final photos  = json['photos']               as List<dynamic>?;

    return MasjidResult(
      placeId:          json['place_id']          as String,
      name:             json['name']              as String,
      vicinity:         (json['vicinity']         as String?) ??
                        (json['formatted_address'] as String?) ?? '',
      lat:              (loc['lat']               as num).toDouble(),
      lng:              (loc['lng']               as num).toDouble(),
      rating:           (json['rating']           as num?)?.toDouble(),
      userRatingsTotal: json['user_ratings_total'] as int?,
      openNow:          hours?['open_now']        as bool?,
      photoRef:         photos?.isNotEmpty == true
                            ? (photos![0] as Map<String, dynamic>)['photo_reference'] as String?
                            : null,
    );
  }

  /// Human-readable distance string, e.g. "320 m" or "1.4 km".
  String get distanceText {
    if (distanceKm == null) return '';
    if (distanceKm! < 1.0) return '${(distanceKm! * 1000).round()} m';
    return '${distanceKm!.toStringAsFixed(1)} km';
  }

  /// Rating rounded to one decimal, e.g. "4.5".
  String get ratingText => rating != null ? rating!.toStringAsFixed(1) : '';
}
