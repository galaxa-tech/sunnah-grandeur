import Flutter
import UIKit
import GoogleMaps   // ← required for google_maps_flutter

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // ── Google Maps iOS SDK key ─────────────────────────────────────────
    // The key is NOT hardcoded here. It is injected at build time via the
    // xcconfig chain:
    //   ApiKeys.xcconfig  →  Debug/Release.xcconfig  →  Info.plist (GMS_API_KEY)
    // and read at runtime from Bundle.main so the raw value never appears
    // in any committed source file.
    let mapsKey = Bundle.main.object(forInfoDictionaryKey: "GMS_API_KEY") as? String ?? ""
    GMSServices.provideAPIKey(mapsKey)

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}
