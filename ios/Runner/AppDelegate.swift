import Flutter
import UIKit
import GoogleMaps

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // google_maps_flutter needs its own iOS-restricted API key from Google
    // Cloud Console (Maps SDK for iOS) — separate from any Android key.
    // Without this call, every GoogleMap widget renders blank/grey.
    // TODO: replace with your real key before building for release.
    GMSServices.provideAPIKey("YOUR_IOS_GOOGLE_MAPS_API_KEY")
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
