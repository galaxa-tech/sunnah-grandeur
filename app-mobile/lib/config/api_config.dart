// ─────────────────────────────────────────────────────────────────────────────
// ApiConfig — compile-time API key injection.
//
// Keys are NEVER hardcoded here.  They are injected at build time by passing:
//   flutter run  --dart-define-from-file=api_keys.json
//   flutter build apk --dart-define-from-file=api_keys.json
//
// The api_keys.json file lives at the project root and is gitignored.
// Copy  api_keys.template.json  →  api_keys.json  and fill in your keys.
// ─────────────────────────────────────────────────────────────────────────────
class ApiConfig {
  ApiConfig._(); // non-instantiable

  // ── Google Places API (server-side HTTP calls from Dart) ──────────────────
  //
  // Reads the value set in api_keys.json: { "PLACES_API_KEY": "..." }
  // Falls back to empty string if the dart-define was not passed.
  static const placesApiKey =
      String.fromEnvironment('PLACES_API_KEY', defaultValue: '');

  static bool get isPlacesConfigured => placesApiKey.isNotEmpty;

  // ── Runtime guard (call from PlacesService) ───────────────────────────────
  //
  // Call this during development to catch missing key early.
  static void assertConfigured() {
    assert(
      isPlacesConfigured,
      '\n\n'
      '╔══════════════════════════════════════════════════════╗\n'
      '║  PLACES_API_KEY is not set!                         ║\n'
      '║  Run the app with:                                  ║\n'
      '║    flutter run --dart-define-from-file=api_keys.json║\n'
      '╚══════════════════════════════════════════════════════╝\n',
    );
  }
}
